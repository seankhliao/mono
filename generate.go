package main

//go:generate go tool cue fix ./...

//go:generate go -C _web/seankhliao.com tool blogengine
//go:generate go -C _web/liao.dev tool blogengine
//go:generate go -C _web/sean.liao.dev tool blogengine
//go:generate go -C _web/newtab.liao.dev tool blogengine

func main() {}
