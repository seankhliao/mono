# http early hints

## using a 100 series http response code

### _bttp_ early hints

We have a k8s pod sidecar that talks to a daemonset pod on the same node.
It makes an HTTP request and blocks until it gets a response.

It ran for a few weeks,
but I realized my coworkers were used to looking at logs though the sidecar was hanging...
I wanted to tell them to go look at the logs for the daemonset pod,
but then I need a way to return that information.
I still wanted to keep the blocking behavior so the HTTP response code was meaningful,
and I didn't want to implement a poll loop.

Then I remembered [HTTP 103 Early Hints](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/103).
The server can return some headers along with this status code while it works on a response.
So I can return some headers that say the pod name/namespace that was handling the request,
and on the client construct a kubectl command to show the user.

In Go, both the server and client support it.
On the server side it's just regular writes to header and writeheader.
On the client side, you need to use httptrace to get the notifications for hints.

```go
package main

import (
        "context"
        "fmt"
        "net/http"
        "net/http/httptest"
        "net/http/httptrace"
        "net/textproto"
        "time"
)

func main() {
        ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
                w.Header().Set("xxx", "yyy")
                w.Header().Set("aaa", "bbb")
                w.Header().Set("sss", "ttt")
                w.WriteHeader(http.StatusEarlyHints)

                time.Sleep(2 * time.Second)
                w.Header().Set("xxx", "zzz")
                w.Header().Set("ccc", "ddd")
                w.Header().Add("sss", "uuu")
                w.WriteHeader(http.StatusOK)
        }))

        ctx := httptrace.WithClientTrace(context.Background(), &httptrace.ClientTrace{
                Got1xxResponse: func(code int, header textproto.MIMEHeader) error {
                        if code == http.StatusEarlyHints {
                                fmt.Println("hinted", header.Values("xxx"))
                                fmt.Println("hinted", header.Values("aaa"))
                                fmt.Println("hinted", header.Values("ccc"))
                                fmt.Println("hinted", header.Values("sss"))
                        }
                        return nil
                },
        })
        req, _ := http.NewRequestWithContext(ctx, http.MethodGet, ts.URL, nil)
        res, err := ts.Client().Do(req)
        if err != nil {
                fmt.Println("do error", err)
                return
        }

        fmt.Println("final", res.Status)
        fmt.Println("final", res.Header.Values("xxx"))
        fmt.Println("final", res.Header.Values("aaa"))
        fmt.Println("final", res.Header.Values("ccc"))
        fmt.Println("final", res.Header.Values("sss"))
}
```

Output:

```
hinted [yyy]
hinted [bbb]
hinted []
hinted [ttt]
final 200 OK
final [zzz]
final [bbb]
final [ddd]
final [ttt uuu]
```
