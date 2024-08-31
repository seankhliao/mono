package webstyle

import (
	"bytes"
	"fmt"

	chromahtml "github.com/alecthomas/chroma/v2/formatters/html"
	"github.com/alecthomas/chroma/v2/styles"
	"github.com/yuin/goldmark"
	highlighting "github.com/yuin/goldmark-highlighting/v2"
	"github.com/yuin/goldmark/extension"
	"github.com/yuin/goldmark/parser"
	"github.com/yuin/goldmark/renderer/html"
	"github.com/yuin/goldmark/text"
	"go.seankhliao.com/mono/webstyle/midnight"
	"go.seankhliao.com/mono/webstyle/picture"
)

func init() {
	s, err := midnight.Style()
	if err != nil {
		panic(err)
	}
	styles.Register(s)
}

func Markdown(src []byte) (htmlOut, cssOut []byte, err error) {
	var block int
	cssBuf := new(bytes.Buffer)
	hl := highlighting.NewHighlighting(
		highlighting.WithStyle("midnight"),
		highlighting.WithCSSWriter(cssBuf),
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
		goldmark.WithExtensions(
			extension.Strikethrough,
			extension.Table,
			extension.TaskList,
			picture.Picture,
			hl,
		),
		goldmark.WithParserOptions(
			parser.WithHeadingAttribute(), // {#some-id}
			parser.WithAutoHeadingID(),    // based on heading
		),
		goldmark.WithRendererOptions(
			html.WithUnsafe(),
		),
	)

	node := Markdown.Parser().Parse(text.NewReader(src))

	htmlBuf := new(bytes.Buffer)
	err = Markdown.Renderer().Render(htmlBuf, src, node)
	if err != nil {
		return nil, nil, fmt.Errorf("render markdown: %w", err)
	}

	return htmlBuf.Bytes(), cssBuf.Bytes(), nil
}
