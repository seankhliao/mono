# pruned module graph

## slimmer modules graphs

### _pruned_ module graph

I haven't had a very clear idea of what Go 
[Module graph pruning](https://go.dev/ref/mod#graph-pruning)
actually meant.

Some notes:

* `go list -m all` shows the full set of dependencies
* `go list all` only shows packages that are not pruned out
* `go.mod` only contains modules that are not pruned out

I tried to draw a graph (unrelated to the repo above):

![module graph](/static/pruned-module-graph.png)

A [txtar](https://pkg.go.dev/golang.org/x/tools/txtar) script
for the graph above.
Use with:

```sh
$ go install golang.org/x/exp/cmd/txtar@latest
$ txtar -extract < script.txtar
```

```text
cd root
go mod tidy
cat go.mod
go list all
go list -m all
go test example.com/m
go test example.com/d
-- root/go.mod --
module example.com/root
go 1.24
tool example.com/o
require (
    example.com/m v0.0.0
    example.com/n v0.0.0
    example.com/o v0.0.0
)
replace (
    example.com/a => ../a
    example.com/b => ../b
    example.com/c => ../c
    example.com/d => ../d
    example.com/e => ../e
    example.com/f => ../f
    example.com/g => ../g
    example.com/h => ../h
    example.com/i => ../i
    example.com/j => ../j
    example.com/k => ../k
    example.com/m => ../m
    example.com/n => ../n
    example.com/o => ../o
)
-- root/main.go --
package main
import _ "example.com/m"
-- root/main_test.go --
package main
import _ "example.com/n"
-- m/go.mod --
module example.com/m
go 1.24
tool example.com/e
require (
    example.com/a v0.0.0
    example.com/b v0.0.0
    example.com/c v0.0.0
    example.com/d v0.0.0
    example.com/e v0.0.0
)
replace (
    example.com/a => ../a
    example.com/b => ../b
    example.com/c => ../c
    example.com/d => ../d
    example.com/e => ../e
)
-- m/l/l.go --
package l
import _ "example.com/a"
-- m/l/l_test.go --
package l
import _ "example.com/b"
-- m/m.go --
package m
import _ "example.com/c"
-- m/m_test.go --
package m
import _ "example.com/d"
-- n/go.mod --
module example.com/n
go 1.24
tool example.com/h
require (
    example.com/f v0.0.0
    example.com/g v0.0.0
    example.com/h v0.0.0
)
replace (
    example.com/f => ../f
    example.com/g => ../g
    example.com/h => ../h
)
-- n/n.go --
package n
import _ "example.com/f"
-- n/n_test.go --
package n
import _ "example.com/g"
-- o/go.mod --
module example.com/o
go 1.24
tool example.com/k
require (
    example.com/i v0.0.0
    example.com/j v0.0.0
    example.com/k v0.0.0
)
replace (
    example.com/i => ../i
    example.com/j => ../j
    example.com/k => ../k
)
-- o/o.go --
package o
import _ "example.com/i"
-- o/o_test.go --
package o
import _ "example.com/j"
-- a/go.mod --
module example.com/a
go 1.24
-- a/a.go --
package a
-- b/go.mod --
module example.com/b
go 1.24
-- b/b.go --
package b
-- c/go.mod --
module example.com/c
go 1.24
-- c/c.go --
package c
-- d/go.mod --
module example.com/d
go 1.24
-- d/d.go --
package d
-- e/go.mod --
module example.com/e
go 1.24
-- e/e.go --
package e
-- f/go.mod --
module example.com/f
go 1.24
-- f/f.go --
package f
-- g/go.mod --
module example.com/g
go 1.24
-- g/g.go --
package g
-- h/go.mod --
module example.com/h
go 1.24
-- h/h.go --
package h
-- i/go.mod --
module example.com/i
go 1.24
-- i/i.go --
package i
-- j/go.mod --
module example.com/j
go 1.24
-- j/j.go --
package j
-- k/go.mod --
module example.com/k
go 1.24
-- k/k.go --
package k

```
