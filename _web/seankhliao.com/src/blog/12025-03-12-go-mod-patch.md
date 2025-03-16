# patch versions in go.mod

## ratcheting the go version

### _patch_ versions in go.mod

Since [go1.21](https://go.dev/doc/go1.21), 
the `go` directive in `go.mod` files include the patch versions:

```gomod
module example.com/my-mod

go 1.21.0
```

This is different from previous versions like:

```gomod
module example.com/my-mod

go 1.20
```

Starting with `go1.21.0`,
`go1.21` refers to the development versions before release candidates are cut,
and `go1.21.0` is the first released version.
For libraries, using `go1.21.0` is more correct than `go1.21`,
as it signals support for actual releases.

For companies,
the patch version has an additional advantage,
as you can now force all downstream applications that use your library to upgrade.
