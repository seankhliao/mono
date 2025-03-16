# go vanity imports in repo subdirectories

## subdirectories....

### _vanity_ imports in sub directories

Go import paths don't have to match the repo where the code is hosted.
Go uses html meta tags to [find a repo for a given import path](https://go.dev/ref/mod#vcs-find).

For example, a module can be imported with `import "example.com/my-mod"`
with its repo at `git.example.com/my/mod` if it serves:

```html
<!-- served at https://example.com/my-mod -->

<meta name="go-import" content="example.com/my-mod git https;//git.example.com/my/mod">
```

What if you had your module not at the root of your repo:

```
mod/
  .git/
  lib/
    go/
      go.mod
        # contents:
        module example.com/my-mod/lib/go
        go 1.24.0
```

Now the import would be `import "example.com/my-mod/lib/go"`.
The following meta tags need to be served at 2 locations:
At the location corresponding to the module root,
and at the location for the repo root.

Served at the module root,
it's non authoritative (since it's only a prefix match),
but necessary to mark it as a module boundary
since there's no delineation from modules and packages in just the import path.

Served at the repo root,
it's authoritative for the git repo,
to avoid having different subdirectories pointing to different repos.

Since go follows redirects,
it should be possible to have `/my-mod/lib/go` redirect to `/my-mod`,
and have it all work.

```html
<!-- served at https://example.com/my-mod/lib/go -->
<!-- served at https://example.com/my-mod -->

<meta name="go-import" content="example.com/my-mod git https;//git.example.com/my/mod">
```
