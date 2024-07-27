package webstyle

import (
	"bytes"
	_ "embed"
	"fmt"
	"io"
	"slices"
	"text/template"

	chromahtml "github.com/alecthomas/chroma/v2/formatters/html"
	"github.com/yuin/goldmark"
	highlighting "github.com/yuin/goldmark-highlighting/v2"
	"github.com/yuin/goldmark/ast"
	"github.com/yuin/goldmark/extension"
	"github.com/yuin/goldmark/parser"
	"github.com/yuin/goldmark/renderer"
	"github.com/yuin/goldmark/renderer/html"
	"github.com/yuin/goldmark/text"
	"go.seankhliao.com/mono/webstyle/picture"
)

var (
	//go:embed layout.html.gotmpl
	layoutTpl string
	//go:embed base.css
	baseCss string
	//go:embed compact.css
	compactCss string

	templateBase    = template.Must(template.New("basecss").Parse(baseCss))
	templateCompact = template.Must(template.New("basecss").Parse(baseCss + compactCss))

	TemplateFull    = template.Must(templateBase.New("").Parse(layoutTpl))
	TemplateCompact = template.Must(templateCompact.New("").Parse(layoutTpl))
)

// Data holds the metadata to render a given page
type Data struct {
	Main string

	// Optional
	Style    string
	Title    string // defaults to h1
	Subtitle string // defaults to h2
	Desc     string // defaults to subtitle
	Head     string
	GTM      string
	URL      string
}

type Renderer struct {
	extensions []goldmark.Extender
	parserOpts []parser.Option
	renderOpts []renderer.Option
	Template   *template.Template
}

// NewRenderer creates a rendered with default options
func NewRenderer(t *template.Template) Renderer {
	return Renderer{
		extensions: []goldmark.Extender{
			extension.Strikethrough,
			extension.Table,
			extension.TaskList,
			picture.Picture,
		},
		parserOpts: []parser.Option{
			parser.WithHeadingAttribute(), // {#some-id}
			parser.WithAutoHeadingID(),    // based on heading
		},
		renderOpts: []renderer.Option{
			html.WithUnsafe(),
		},
		Template: t,
	}
}

func (r Renderer) Render(w io.Writer, src io.Reader, d Data) error {
	b, err := io.ReadAll(src)
	if err != nil {
		return err
	}

	var block int
	highlightCSS := bytes.NewBufferString(d.Style)
	highlightCSS.WriteString("\n")
	hl := highlighting.NewHighlighting(
		highlighting.WithStyle("borland"),
		highlighting.WithCSSWriter(highlightCSS),
		highlighting.WithFormatOptions(
			chromahtml.WithLineNumbers(true),
			chromahtml.WithClasses(true),
		),
		highlighting.WithCodeBlockOptions(func(c highlighting.CodeBlockContext) []chromahtml.Option {
			block++
			return []chromahtml.Option{
				chromahtml.WithLinkableLineNumbers(true, fmt.Sprintf("block%d-", block)),
			}
		}),
	)

	Markdown := goldmark.New(
		goldmark.WithExtensions(append(slices.Clone(r.extensions), hl)...),
		goldmark.WithParserOptions(r.parserOpts...),
		goldmark.WithRendererOptions(r.renderOpts...),
	)

	node := Markdown.Parser().Parse(text.NewReader(b))
	for n := node.FirstChild(); n != nil; n = n.NextSibling() {
		if hd, ok := n.(*ast.Heading); ok {
			if hd.Level == 1 && d.Title == "" {
				d.Title = string(hd.Text(b))
			} else if hd.Level == 2 {
				d.Subtitle = string(hd.Text(b))
				if d.Desc == "" {
					d.Desc = d.Subtitle
				}
			}
		}
	}

	var mdBuf bytes.Buffer
	err = Markdown.Renderer().Render(&mdBuf, b, node)
	if err != nil {
		return fmt.Errorf("render markdown: %w", err)
	}
	d.Main = mdBuf.String() + d.Main
	d.Style = highlightCSS.String()

	err = r.Template.Execute(w, d)
	if err != nil {
		return fmt.Errorf("render template: %w", err)
	}
	return nil
}

func (r Renderer) RenderBytes(src []byte, d Data) ([]byte, error) {
	var buf bytes.Buffer
	err := r.Render(&buf, bytes.NewReader(src), d)
	return buf.Bytes(), err
}
