# offline buf generate

## why does codegen need internet...

### _buf_ generate offline

Recently I was on a plane,
and decided to do a bit of refactoring,
moving some of my protobuf definitions around.
Naturally, I wanted to regenerate the code,
to make sure everything still worked.

I use [buf](https://buf.build/),
so I ran `buf generate`.
I was quite disappointed to receive the message:

```sh
$ buf generate
Failure: the server hosted at that remote is unavailable.
```

Why? Looking at my `bug.gen.yaml` file, it had:

```yaml
version: v2
plugins:
  - remote: buf.build/protocolbuffers/go
    out: .
    opt:
      - paths=source_relative
```

At first I thought it was just because I was following
[buf's examples](https://buf.build/docs/configuration/v2/buf-gen-yaml/)
and recommendations to not pin versions or revisions.
However, with a little more experimenting,
I realized that `buf generate` with remote plugins
[just won't work offline](https://github.com/bufbuild/buf/issues/2543),
apparently with no plans to make it work either...

So, what's the right way?
I think it's to use a `local` plugin,
specifically using the same version of `protoc-gen-go` as your code,
running it via `go`:

```yaml
version: v2
plugins:
  - local: ["go", "run", "google.golang.org/protobuf/cmd/protoc-gen-go"]
    out: .
    opt:
      - paths=source_relative
```
