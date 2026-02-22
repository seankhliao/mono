# git hosting http

## say no to ssh

### _git_ hosting with http

`git` is what they call a decentralized vcs,
there is no canonical server,
and you can push / pull from any copy.
You can even push / pull from a different directory
on disk.

That's why people say it's easy to host:
just have a directory on a server,
and use ssh to access it.
`git` natively understands how to interact with that.
But: now you have to deal with ssh,
managing users and permissions, etc.

Plus, I generally find http more reliable:
it's blocked less often,
doesn't have as many issues with connection management.
So comes the problem:
how do you host a git server with http?

#### _git-htto-backend_

The docs point you to [git-http-backend](https://git-scm.com/docs/git-http-backend).
This is built in to `git`, invoked as a CGI script: `git http-backend`.
CGI: the process needs to be invoked for every http request.
The docs go on to describe some example configs with
Apache and Lighttpd.
The [arch wiiki](https://wiki.archlinux.org/title/Git_server)
includes some talk of Nginx,
elsewhere you might find mentions of Caddy.
But these are all big servers with too many features I don't use,
and most of them want you to run something else to wrap
CGI into fastCGI.

Instead, we can write a tiny bit of Go.
The Go standard library has the [`net/http/cgi`](https://pkg.go.dev/net/http/cgi)
package which can invoke CGI scripts for you.

So all we need is a parent directory containing bare git repos:

```sh
mkdir gitrepos
cd gitrepos
REPO=$myrepo

# create the git repo
git init --bare $reponame.git

# allow cloning
touch $reponame.git/git-daemon-export-ok

# allow pushing
git -C $reponame.git config set http.receivepack true
```

And a simple Go server:

```go
package main

import (
        "log"
        "net/http"
        "net/http/cgi"
        "os"
        "os/exec"
)

func main() {
        gitPath, err := exec.LookPath("git")
        if err != nil {
                log.Fatalln("find git", err)
        }
        pwd, err := os.Getwd()
        if err != nil {
                log.Fatalln("get cwd", err)
        }

        http.HandleFunc("/{repo}/{action...}", func(w http.ResponseWriter, r *http.Request) {
                if r.URL.Query().Get("service") == "git-receive-pack" || r.PathValue("action") == "git-receive-pack" {
                        if _, _, ok := r.BasicAuth(); !ok {
                                w.Header().Set("www-authenticate", "Basic realm='my git server'")
                                http.Error(w, "please log in to push", http.StatusUnauthorized)
                                return
                        }
                        // TODO: actually implement auth.
                }
                c := &cgi.Handler{
                        Path: gitPath,
                        Dir:  pwd,
                        Env: append(os.Environ(),
                                "GIT_PROJECT_ROOT="+pwd,
                        ),
                        Args: []string{"http-backend"},
                }
                c.ServeHTTP(w, r)
        })
        log.Println("starting on http://localhost:8080/")
        http.ListenAndServe(":8080", nil)
}
```

And you can clone, and push, e.g. with:

```sh
git clone http://localhost:8080/$myrepo.git
```

#### _cgit_

So `git http-backend` is good for interactions with `git`,
but what if you want to browse the repo from a web browser.
You need something that renders html.

[`cgit`](https://git.zx2c4.com/cgit/about/) is a popular frontend,
it's also a CGI script,
and again the [arch wiki](https://wiki.archlinux.org/title/Cgit)
has a few examples for how to run those with popular web servers.

A proof of concept might look something like this:
it serves git using `git http-backend`,
and web views using `cgit`.

```go
package main

import (
        "log"
        "net/http"
        "net/http/cgi"
        "os"
        "os/exec"
)

func main() {
        gitPath, err := exec.LookPath("git")
        if err != nil {
                log.Fatalln("find git", err)
        }
        _ = gitPath
        cgitPath := "/usr/lib/cgit/cgit.cgi"
        pwd, err := os.Getwd()
        if err != nil {
                log.Fatalln("get cwd", err)
        }

        cgit := &cgi.Handler{
                Path: cgitPath,
                Dir:  pwd,
                Env: append(os.Environ(),
                        "CGIT_CONFIG="+pwd+"/cgitrc",
                ),
        }
        http.HandleFunc("/{repo}/{action...}", func(w http.ResponseWriter, r *http.Request) {
                action := r.PathValue("action")
                if action == "info/refs" || action == "git-upload-pack" || action == "git-receive-pack" {
                        if r.URL.Query().Get("service") == "git-receive-pack" || action == "git-receive-pack" {
                                if _, _, ok := r.BasicAuth(); !ok {
                                        w.Header().Set("www-authenticate", "Basic realm='frobb'")
                                        http.Error(w, "need auth", http.StatusUnauthorized)
                                        return
                                }
                        }
                        c := &cgi.Handler{
                                Path: gitPath,
                                Dir:  pwd,
                                Env: append(os.Environ(),
                                        "GIT_PROJECT_ROOT="+pwd,
                                ),
                                Args: []string{"http-backend"},
                        }
                        c.ServeHTTP(w, r)
                }
                cgit.ServeHTTP(w, r)
        })
        http.Handle("/", cgit)
        http.Handle("GET /static/", http.StripPrefix("/static", http.FileServer(http.Dir("static"))))
        log.Println("starting on http://localhost:8080/")
        http.ListenAndServe(":8080", nil)
}
```

This needs a `cgitrc` file like:

```
virtual-root=/
scan-path=/home/user/tmp/testrepo1402

js=/static/cgit.js
css=/static/cgit.css
favicon=/static/favicon.ico
logo=/static/mylogo.png
```

To do auth properly, you'd probably want to construct a per user
cgitrc file that lists the valid repos.

cgit does natively have an auth filter system,
but looking at the [example lua](https://github.com/zx2c4/cgit/blob/master/filters/simple-authentication.lua)
I think it'd be much easier to handle auth at the server level,
and configure cgit with a list of valid repos for the (non)user to to see.
