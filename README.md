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

[go]: https://go.dev/
[cue]: https://cuelang.org/
