# mono

[![Go Reference][pkgsitebadge]][pkgsite]
[![License][licensebadge]](LICENSE)

[licensebadge]: https://img.shields.io/github/license/seankhliao/mono.svg?style=flat-square
[pkgsitebadge]: https://pkg.go.dev/badge/go.seankhliao.com/mono.svg
[pkgsite]: https://pkg.go.dev/go.seankhliao.com/mono

This is a monorepo full of.... experimental stuff.
Mostly in [go] and [cue].

## directory layout

- [_data](./_data/): placeholder directories with sensitive data stored in google cloud storage buckets.
- [_web](./_web/): website content in markdown source, rendered by [blogengine](./cmd//blogengine)
- [cmd/](./cmd/): various commands
- [deploy](./deploy/): k8s manifests in cue source

## tooling

commands for mainting the codebase

### code generation

```sh
go tool buf generate

# in a deploy/*/ directory
go tool cue cmd k8smanifests
```

### formatting

```sh
go tool gofumpt -w .
go tool buf format -w .
go tool cue fmt ./...
```

### linting

```sh
go vet ./...
go tool staticcheck ./...
go tool buf lint .
go tool cue vet -c=false ./...
go tool govulncheck ./...
```

### deploy

```sh
# in a _web/*/ directory
go tool blogengine

# targeting a cmd/*/ directory
go tool ko apply -f ./cmd/

# in a deploy/*/ directory
kpt live apply --server-side --output table
```

[go]: https://go.dev/
[cue]: https://cuelang.org/
