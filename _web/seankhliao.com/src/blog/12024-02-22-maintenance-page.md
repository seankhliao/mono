# maintenance page

## go hello world http server

### _basic_ http app

At work, we recently took down our site for a 6 hour maintenance window,
during which, we wanted to show our users a pretty maintenance page.
But as a SaaS company, we also have an API, 
and legacy stuff means it's a bit intermixed with the human facing routes.
So after staring at Akamai documentation for a bit too long,
I decided a hello world Go http server would be the easiest path to serving
the customized maintenance pages.

So I deployed the thing into our cluster with 3 replicas,
ran a quick and dirty load test against it with 
[`github.com/rakyll/hey`](https://github.com/rakyll/hey),
and just left it running.

Come the day of our maintenance window,
we switched traffic over.
The traffic it served out with approx 1000 req/sec,
and gradually crept up to around 1700 req/sec at the end of our window,
api traffic remained steady, 
it was the ui traffic that almost doubled.

What was more surprising was just how little resources it needed.
Unconstrained by resource limits,
the 3 replicas each ran with just 100 millicores cpu and 800 mebibyte of memory.
From our metrics, 
we could also see p99 latency for serving the html page was 200ms,
compared to mere microseconds for the api responses.
I think it may have to do with the page being 10kb.

I may have to reevaluate how resource hungry http servers need to be.


#### _app_ code

Not very interesting,
but the code is included below:

```go
package main

import (
        "context"
        "embed"
        "io"
        "log/slog"
        "net/http"
        "strings"
        "time"

        "github.com/work/otelsdk"
        "go.opentelemetry.io/otel"
        "go.opentelemetry.io/otel/attribute"
        "go.opentelemetry.io/otel/metric"
)

var (
        //go:embed assets
        assets embed.FS

        //go:embed maintenance.html
        maintenanceHTML string

        maintenanceAPI = `{
  "msg": "... some message ..."
}`

        maintenanceCLI = `{
  "alerts": [{
    "msg": "... some message ...",
    "type": "info"
  }]
}`
)

func main() {
        exp, err := otelsdk.Init(context.Background(), otelsdk.Config{})
        if err != nil {
                panic(err)
        }
        defer exp.Shutdown(context.Background())

        meter := otel.GetMeterProvider().Meter("maintenance-page")
        pageHist, _ := meter.Float64Histogram("maintenance.page.latency", metric.WithUnit("s"))
        mahtml := []metric.RecordOption{metric.WithAttributeSet(attribute.NewSet(attribute.String("page", "html")))}
        maapi := []metric.RecordOption{metric.WithAttributeSet(attribute.NewSet(attribute.String("page", "api")))}
        macli := []metric.RecordOption{metric.WithAttributeSet(attribute.NewSet(attribute.String("page", "cli")))}

        http.Handle("/assets/", http.FileServer(http.FS(assets)))
        http.HandleFunc("/-/healthcheck", func(rw http.ResponseWriter, r *http.Request) {
                io.WriteString(rw, "ok")
        })
        http.HandleFunc("/", func(rw http.ResponseWriter, r *http.Request) {
                if strings.HasPrefix(r.UserAgent(), "GoogleHC") {
                        io.WriteString(rw, "ok")
                        return
                }

                t0 := time.Now()
                response := maintenanceHTML
                mattrs := mahtml

                // ensure akamai doesn't cache our maintenance page
                rw.Header().Set("cache-control", "no-cache")
                rw.Header().Set("retry-after", "3600") // seconds, maintenance takes a long time
                // fun
                rw.Header().Set("server", "work")
                rw.Header().Set("x-recruiting", "come join us @ careers page")

                if r.Header.Get("x-work-cli-version") != "" {
                        rw.Header().Set("content-type", "application/json")
                        response = maintenanceCLI
                        mattrs = macli
                } else if strings.HasPrefix(r.URL.Path, "/api") || strings.HasPrefix(r.URL.Path, "/rest") || r.Header.Get("accept") == "application/json" {
                        rw.Header().Set("content-type", "application/json")
                        response = maintenanceAPI
                        mattrs = maapi
                }

                rw.WriteHeader(http.StatusServiceUnavailable)
                io.WriteString(rw, response)

                pageHist.Record(r.Context(), float64(time.Since(t0).Seconds()), mattrs...)
        })

        slog.Info("starting on :8080")
        http.ListenAndServe(":8080", nil)
}
```
