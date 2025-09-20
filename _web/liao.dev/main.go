package main

import (
	_ "embed"
	"flag"
	"fmt"
	"io"
	"math/rand/v2"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strings"

	"cuelang.org/go/cue/cuecontext"
	"github.com/tdewolff/minify/v2"
	"github.com/tdewolff/minify/v2/css"
	mhtml "github.com/tdewolff/minify/v2/html"
	"github.com/tdewolff/minify/v2/js"
	"github.com/tdewolff/minify/v2/json"
	"github.com/tdewolff/minify/v2/svg"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

//go:generate go run .

var minifier = func() *minify.M {
	m := minify.New()
	m.AddFunc("text/css", css.Minify)
	m.AddFunc("text/html", mhtml.Minify)
	m.AddFunc("image/svg+xml", svg.Minify)
	m.AddFuncRegexp(regexp.MustCompile("^(application|text)/(x-)?(java|ecma)script$"), js.Minify)
	m.AddFuncRegexp(regexp.MustCompile("[/+]json$"), json.Minify)
	return m
}()

type Config struct {
	Title  string
	Text   string
	GTM    string
	Repeat int
	// link text: link url
	Links map[string]string
}

func main() {
	rng := rand.New(rand.NewPCG(0, 1))

	var configFile, outputFile string
	flag.StringVar(&configFile, "config", "generate.cue", "input config file")
	flag.StringVar(&outputFile, "out", "src/index.html", "output file")
	flag.Parse()

	err := run(rng, configFile, outputFile)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(rng *rand.Rand, configFile, outputFile string) error {
	var c Config
	b, err := os.ReadFile(configFile)
	if err != nil {
		return fmt.Errorf("read config file: %w", err)
	}
	err = cuecontext.New().CompileBytes(b).Decode(&c)
	if err != nil {
		return fmt.Errorf("parse config file: %w", err)
	}

	if dir := filepath.Dir(outputFile); dir != "." {
		os.MkdirAll(dir, 0o755)
	}
	f, err := os.Create(outputFile)
	if err != nil {
		return fmt.Errorf("create output file: %w", err)
	}
	defer f.Close()
	err = page(rng, c, f)
	if err != nil {
		return fmt.Errorf("render page: %w", err)
	}
	return nil
}

func page(rng *rand.Rand, c Config, w io.Writer) error {
	var head []gomponents.Node

	head = append(head, html.Meta(html.Charset("utf-8")))
	head = append(head, html.Meta(html.Name("viewport"), html.Content("width=device-width,minimum-scale=1,initial-scale=1")))
	head = append(head, html.Meta(html.Name("theme-color"), html.Content("#000")))
	head = append(head, html.TitleEl(gomponents.Text(c.Title)))
	if c.GTM != "" {
		head = append(head, html.Script(html.Async(), html.Src("https://www.googletagmanager.com/gtag/js?id="+c.GTM)))
		head = append(head, html.Script(gomponents.Raw(gtagInlineScript), gomponents.Rawf(gtagConfig, c.GTM)))
	}
	head = append(head, html.Link(html.Rel("icon"), html.Href("https://seankhliao.com/favicon.ico")))
	head = append(head, html.Link(html.Rel("icon"), html.Href("https://seankhliao.com/static/icon.svg"), html.Type("image/svg+xml"), gomponents.Attr("sizes", "any")))
	head = append(head, html.Link(html.Rel("apple-touch-icon"), html.Href("https://seankhliao.com/static/icon-192.png")))
	head = append(head, html.StyleEl(gomponents.Raw(baseCss)))

	rep := strings.NewReplacer(".", "-", " ", "-")

	// CSS selectors for the same links
	sels := make([]string, 0, len(c.Links))
	for txt := range c.Links {
		class := rep.Replace(txt)
		sel := fmt.Sprintf("main:has(> .%[1]s:hover) > .%[1]s", class)
		sels = append(sels, sel)
	}
	head = append(head, html.StyleEl(gomponents.Rawf(selectorf, strings.Join(sels, ","))))

	// Body of links
	var main []gomponents.Node
	links := make([]gomponents.Node, 0, len(c.Links))
	for txt, link := range c.Links {
		lnk := html.A(
			html.Class(rep.Replace(txt)),
			html.Rel("me"),
			html.Href(link),
			gomponents.Text(txt),
		)
		links = append(links, lnk)

		// ensure main site is the first link
		if txt == "seankhliao.com" {
			main = append(main, lnk)
		}
	}
	links = slices.Repeat(links, c.Repeat)

	// random order
	rng.Shuffle(len(links), func(i, j int) {
		links[i], links[j] = links[j], links[i]
	})
	for _, l := range links {
		main = append(main, gomponents.Text("\n"), l)
	}

	// main message
	message := []gomponents.Node{
		gomponents.Text("\n"),
		html.Span(
			gomponents.Text("Hi, I'm"),
			html.Em(gomponents.Text("sean")),
			gomponents.Text("khliao"),
		),
	}
	main = append(main, message...)

	// random order
	rng.Shuffle(len(links), func(i, j int) {
		links[i], links[j] = links[j], links[i]
	})
	for _, l := range links {
		main = append(main, gomponents.Text("\n"), l)
	}

	var body []gomponents.Node
	body = append(body, html.Main(main...))

	page := html.Doctype(
		html.HTML(
			html.Lang("en"),
			html.Head(head...),
			html.Body(body...),
		),
	)

	// var buf bytes.Buffer
	return page.Render(w)
	// err := page.Render(&buf)
	// if err != nil {
	// 	return err
	// }
	//
	// return minifier.Minify("text/html", w, &buf)
}

const selectorf = `%s {
  color: var(--primary);
  transition: color 0.16s;
  text-decoration: underline 1px var(--primary);
}`

const gtagInlineScript = `
window.dataLayer = window.dataLayer || [];
function gtag() {
  dataLayer.push(arguments);
}
gtag("js", new Date());
`
const gtagConfig = `gtag('config', '%s');`

//go:embed base.css
var baseCss string
