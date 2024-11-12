# go iterators as with

## magic function scoping

### _go_ iterators as python's with

[Go 1.23](https://go.dev/doc/go1.23) introduced a new feature,
[range over function types](https://go.dev/blog/range-functions)
or more commonly known as "iterators".

What's special about these is the way control flow works.
The loop body is converted to a function, passed to the interator,
but a return (or any other change in control flow) from the loop body skips through enclosing iterator,
while still calling defers,
affecting control flow of the outer function.
Example:

```go
package main

import "fmt"

func Iterator(yield func() bool) {
        fmt.Println("start")
        defer fmt.Println("done")

        yield()
}

func foo() {
        for range Iterator {
                fmt.Println("inside loop")
                return
        }
        fmt.Println("outside loop")
}

func ExampleIterator() {
        // Output:
        // start
        // inside loop
        // done
        foo()
}
```

What's this useful for?
Well it's a lot like python's `with` blocks:

```go
package main

import (
        "io"
        "os"
)

func OpenFile(name string) func(func(*os.File, error) bool) {
        return func(yield func(*os.File, error) bool) {
                f, err := os.Open(name)
                if err == nil {
                        defer f.Close()
                }
                yield(f, err)
        }
}

func main() {
        for f, err := range OpenFile("hello.txt") {
                if err != nil {
                        // handle error
                }
                _, _ = io.ReadAll(f)
        }
}
```

Or something like:

```go
package main

import "sync"

type mutex struct {
        m sync.Mutex
}

func (m *mutex) do(yield func() bool) {
        m.m.Lock()
        defer m.m.Unlock()
        yield()
}

func main() {
        var mu mutex
        for range mu.do {
                // do protected thing
        }

        // old way
        mu.do(func() bool {
                // do protected thing
        })
}
```

