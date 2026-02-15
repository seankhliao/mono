package webstyle

import (
	"bytes"
	_ "embed"
	"fmt"
	"io"
	"net/url"

	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

var (
	//go:embed code_block.js
	codeBlockScript string
	//go:embed header_link.js
	headerLinkScript string
	//go:embed gtag_inline.js
	gtagInlineScript string
	gtagConfig       = `gtag('config', '%s');`
	//go:embed tablesort.js
	tableSortScript string

	//go:embed base.css
	baseCss string
	//go:embed compact.css
	compactCss string

	defaultFooter = []OptionsFooter{
		{"me", "https://seankhliao.com/"},
		{"blog", "https://seankhliao.com/blog/"},
		{"elsewhere", "https://sean.liao.dev/"},
	}
)

const (
	DefaultGTAG = "G-9GLEE4YLNC"
)

type Options struct {
	Gtag         string
	CanonicalURL string
	Manifest     string
	CompactStyle bool
	HideTitles   bool
	CustomCSS    string
	Minify       bool

	Title       string // title, h1
	Subtitle    string // link home, h2
	Description string // meta description

	Head    []gomponents.Node
	Content []gomponents.Node

	FooterLinks []OptionsFooter
}
type OptionsFooter struct {
	Name string
	URL  string
}

func NewOptions(title, subtitle string, content []gomponents.Node) Options {
	return Options{
		Gtag:         DefaultGTAG,
		CompactStyle: true,
		Minify:       true,

		Title:    title,
		Subtitle: subtitle,

		Content: content,
	}
}

func Structured(w io.Writer, o Options) error {
	var head []gomponents.Node
	head = append(head, html.Meta(html.Charset("utf-8")))
	head = append(head, html.Meta(html.Name("viewport"), html.Content("width=device-width,minimum-scale=1,initial-scale=1")))
	head = append(head, o.Head...)
	head = append(head, html.Meta(html.Name("theme-color"), html.Content("#000")))
	head = append(head, html.TitleEl(gomponents.Text(o.Title)))
	head = append(head, html.Meta(html.Name("description"), html.Content(o.Description)))
	if o.Gtag != "" {
		head = append(head, html.Script(html.Async(), html.Src("https://www.googletagmanager.com/gtag/js?id="+o.Gtag)))
		head = append(head, html.Script(gomponents.Raw(gtagInlineScript), gomponents.Rawf(gtagConfig, o.Gtag)))
	}
	head = append(head, html.Link(html.Rel("icon"), html.Href("https://seankhliao.com/favicon.ico")))
	head = append(head, html.Link(html.Rel("icon"), html.Href("https://seankhliao.com/static/icon.svg"), html.Type("image/svg+xml"), gomponents.Attr("sizes", "any")))
	head = append(head, html.Link(html.Rel("apple-touch-icon"), html.Href("https://seankhliao.com/static/icon-192.png")))
	if o.CanonicalURL != "" {
		head = append(head, html.Link(html.Rel("canonical"), html.Href(o.CanonicalURL)))
	}
	if o.Manifest != "" {
		head = append(head, html.Link(html.Rel("manifest"), html.Href(o.Manifest)))
	}
	head = append(head, html.StyleEl(gomponents.Raw(baseCss)))
	if o.CompactStyle {
		head = append(head, html.StyleEl(gomponents.Raw(compactCss)))
	}
	if o.CustomCSS != "" {
		head = append(head, html.StyleEl(gomponents.Raw(o.CustomCSS)))
	}

	var body []gomponents.Node
	// header
	hgroup := []gomponents.Node{}
	for i, c := range "SEANK.H.LIAO" {
		if 3 < i && i < 8 {
			hgroup = append(hgroup, html.Em(gomponents.Text(string(c))))
		} else {
			hgroup = append(hgroup, html.Span(gomponents.Text(string(c))))
		}
	}
	body = append(body, html.HGroup(html.A(html.Href("/"), gomponents.Group(hgroup))))
	if !o.HideTitles {
		body = append(body, html.H1(gomponents.Text(o.Title)))
		body = append(body, html.H2(html.A(html.Href("/"), gomponents.Text(o.Subtitle))))
	}

	// content
	body = append(body, o.Content...)

	// footer
	footerLinks := defaultFooter
	if len(o.FooterLinks) > 0 {
		footerLinks = o.FooterLinks
	} else {
		u, err := url.Parse(o.CanonicalURL)
		if err == nil {
			vals := make(url.Values)
			vals.Set("subject", "Comment on "+o.Title)
			vals.Set("body", "Regarding "+o.CanonicalURL)
			footerLinks = append(footerLinks, OptionsFooter{
				"email me a comment",
				fmt.Sprintf("mailto:webcomment+%s@liao.dev?%s", u.Host, vals.Encode()),
			})
		}
	}

	var footer []gomponents.Node
	for i, l := range footerLinks {
		if i != 0 {
			footer = append(footer, gomponents.Text(" | "))
		}
		footer = append(footer, html.A(html.Href(l.URL), gomponents.Text(l.Name)))
	}
	body = append(body, html.Footer(footer...))
	body = append(body, html.Script(gomponents.Raw(headerLinkScript)))
	body = append(body, html.Script(gomponents.Raw(codeBlockScript)))
	body = append(body, html.Script(gomponents.Raw(tableSortScript)))

	page := html.Doctype(
		html.HTML(
			html.Lang("en"),
			html.Head(head...),
			html.Body(body...),
		),
	)

	if !o.Minify {
		return page.Render(w)
	}

	var buf bytes.Buffer
	err := page.Render(&buf)
	if err != nil {
		return err
	}
	return minifier.Minify("text/html", w, &buf)
}
