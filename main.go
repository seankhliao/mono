//go:build !(lint || deps || codegen || upload)

package main

import "fmt"

//go:generate go run .
func main() {
	fmt.Println("run one of:")
	fmt.Println()
	fmt.Println("\t", "go generate -x -tags codegen")
	fmt.Println("\t", "go generate -x -tags deps")
	fmt.Println("\t", "go generate -x -tags lint")
	fmt.Println("\t", "go generate -x -tags upload")
}
