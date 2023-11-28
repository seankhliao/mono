//go:build ignore

package main

import (
	"log"
	"os"

	"github.com/alecthomas/chroma/v2/quick"
	"github.com/alecthomas/chroma/v2/styles"
	"go.seankhliao.com/mono/webstyle/midnight"
)

func main() {
	s, err := midnight.Style()
	if err != nil {
		panic(err)
	}
	styles.Register(s)

	f, err := os.Create("out.html")
	if err != nil {
		panic(err)
	}
	defer f.Close()

	for _, c := range []struct {
		lang    string
		content string
	}{
		{"c", C},
		{"go", GO},
		{"json", JSON},
		{"bash", BASH},
		{"yaml", YAML},
		{"terraform", TERRAFORM},
		{"proto", PROTO},
		{"makefile", MAKE},
		{"Dockerfile", DOCKERFILE},
		{"javascript", JAVASCRIPT},
		{"Diff", DIFF},
	} {

		err := quick.Highlight(f, c.content, c.lang, "html", "midnight")
		if err != nil {
			log.Fatalln("processing", c.lang, err)
		}
	}
}

var (
	C = `
#include <stdio.h>
int main() {
   // printf() displays the string inside quotation
   printf("Hello, World!");
   return 0;
}
 `
	GO = `
package main
import "fmt"
func main() {
    fmt.Println("hello world")
}
        `
	JSON = `
{
  "squadName": "Super hero squad",
  "homeTown": "Metro City",
  "formed": 2016,
  "secretBase": "Super tower",
  "active": true
}
        `
	BASH = `
var="Hello World"
 
# print it 
echo "$var"
 
# Another way of printing it
printf "%s\n" "$var"
        `
	YAML = `
question: Hello, world!
buttons:
  - Exit: exit
mandatory: True
        `
	TERRAFORM = `
terraform {
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.12.26"
}

# website::tag::1:: The simplest possible Terraform module: it just outputs "Hello, World!"
output "hello_world" {
  value = "Hello, World!"
}
        `
	PROTO = `
syntax = "proto3";

package helloworld;

// The greeting service definition
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
        `
	MAKE = `
# This is the default target, which will be built when 
# you invoke make
.PHONY: all
all: hello

# This rule tells make how to build hello from hello.cpp
hello: hello.cpp
    g++ -o hello hello.cpp

# This rule tells make to copy hello to the binaries subdirectory,
# creating it if necessary
.PHONY: install
install:
    mkdir -p binaries
    cp -p hello binaries

# This rule tells make to delete hello and hello.o
.PHONY: clean 
clean:
    rm -f hello
        `
	DOCKERFILE = `
FROM ubuntu:20.04

RUN apt update && apt install -y sbcl

WORKDIR /usr/src
        `
	JAVASCRIPT = `
// the hello world program
console.log('Hello World');
        `
	DIFF = `
--- lao	2002-02-21 23:30:39.942229878 -0800
+++ tzu	2002-02-21 23:30:50.442260588 -0800
@@ -1,7 +1,6 @@
-The Way that can be told of is not the eternal Way;
-The name that can be named is not the eternal name.
 The Nameless is the origin of Heaven and Earth;
-The Named is the mother of all things.
+The named is the mother of all things.
+
 Therefore let there always be non-being,
   so we may see their subtlety,
 And let there always be being,
@@ -9,3 +8,6 @@
 The two are the same,
 But after they are produced,
   they have different names.
+They both may be called deep and profound.
+Deeper and more profound,
+The door of all subtleties!
        `
)
