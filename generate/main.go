package main

import (
	"flag"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"cuelang.org/go/cue/cuecontext"
)

type Config struct {
	Title  string
	Text   string
	GTM    string
	Repeat int
	// link text: link url
	Links map[string]string
}

type Data struct {
	Title     string
	GTM       string
	Selectors string
	Main      string
}

func handle(msg string, err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, msg, err)
	}
}

func main() {
	var templateFile, configFile, outputFile string
	flag.StringVar(&templateFile, "tmpl", "index.tmpl", "input template file")
	flag.StringVar(&configFile, "config", "generate.cue", "input config file")
	flag.StringVar(&outputFile, "out", "src/index.html", "output file")
	flag.Parse()

	t := template.New("")
	b, err := os.ReadFile(templateFile)
	handle("read template file", err)
	t, err = t.Parse(string(b))
	handle("parse template file", err)

	var c Config
	b, err = os.ReadFile(configFile)
	handle("read config file", err)
	err = cuecontext.New().CompileBytes(b).Decode(&c)
	handle("parse config file", err)

	d := Data{
		Title: c.Title,
		GTM:   c.GTM,
	}

	rep := strings.NewReplacer(".", "-", " ", "-")
	sels := make([]string, 0, len(c.Links))
	for txt := range c.Links {
		class := rep.Replace(txt)
		sel := fmt.Sprintf("main:has(> .%[1]s:hover) > .%[1]s", class)
		sels = append(sels, sel)
	}
	d.Selectors = strings.Join(sels, ",")

	var main strings.Builder
	links := make([]string, 0, len(c.Links))
	for txt, link := range c.Links {
		class := rep.Replace(txt)
		a := fmt.Sprintf(`<a class="%s" href="%s">%s</a>`, class, link, txt)
		links = append(links, a)

		// ensure first link
		if txt == "seankhliao.com" {
			main.WriteString(a)
			main.WriteString("\n")
		}
	}

	for r := 0; r < c.Repeat; r++ {
		rand.Shuffle(len(links), func(i, j int) {
			links[i], links[j] = links[j], links[i]
		})
		for _, link := range links {
			main.WriteString(link)
			main.WriteString("\n")
		}
	}
	fmt.Fprintf(&main, "<span>%s</span>\n", c.Text)
	for r := 0; r < c.Repeat; r++ {
		rand.Shuffle(len(links), func(i, j int) {
			links[i], links[j] = links[j], links[i]
		})
		for _, link := range links {
			main.WriteString(link)
			main.WriteString("\n")
		}
	}
	d.Main = main.String()

	if dir := filepath.Dir(outputFile); dir != "." {
		os.MkdirAll(dir, 0o755)
	}
	f, err := os.Create(outputFile)
	handle("create output file", err)
	defer f.Close()
	err = t.Execute(f, d)
	handle("execute template", err)
}
