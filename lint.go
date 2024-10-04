//go:build lint

package main

import (
	_ "honnef.co/go/tools/cmd/staticcheck"
)

//go:generate go vet ./...
//go:generate go run honnef.co/go/tools/cmd/staticcheck ./...
