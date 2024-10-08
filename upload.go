//go:build upload

package main

//go:generate go run -C ./_web/liao.dev go.seankhliao.com/mono/cmd/blogengine
//go:generate go run -C ./_web/sean.liao.dev go.seankhliao.com/mono/cmd/blogengine
//go:generate go run -C ./_web/newtab.liao.dev go.seankhliao.com/mono/cmd/blogengine
//go:generate go run -C ./_web/seankhliao.com go.seankhliao.com/mono/cmd/blogengine
//go:generate go run -C ./_data/fin go.seankhliao.com/mono/cmd/fin push
//go:generate go generate -C ./_data/config -x -tags upload
