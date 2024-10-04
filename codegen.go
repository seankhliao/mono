//go:build codegen

package main

import (
	_ "github.com/bufbuild/buf/cmd/buf"
)

//go:generate go run github.com/bufbuild/buf/cmd/buf generate
