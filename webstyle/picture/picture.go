// picture is a goldmark extension to render images as html picture blocks
// instead of img tags in a paragraph
package picture

import (
	"fmt"
	"path"
	"strings"

	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/ast"
	"github.com/yuin/goldmark/renderer"
	"github.com/yuin/goldmark/renderer/html"
	"github.com/yuin/goldmark/util"
)

var Picture = &Renderer{}

type Renderer struct{}

func (r *Renderer) Extend(m goldmark.Markdown) {
	m.Renderer().AddOptions(
		renderer.WithNodeRenderers(
			util.Prioritized(r, 0),
		),
	)
}

func (r *Renderer) RegisterFuncs(reg renderer.NodeRendererFuncRegisterer) {
	reg.Register(ast.KindParagraph, r.renderParagraph)
	reg.Register(ast.KindImage, r.renderImage)
}

func (r *Renderer) renderParagraph(w util.BufWriter, source []byte, n ast.Node, entering bool) (ast.WalkStatus, error) {
	var pic bool
	if n.ChildCount() == 1 && n.FirstChild().Kind() == ast.KindImage {
		pic = true
	}

	if entering {
		if pic {
			_, _ = w.WriteString("<picture ")
		} else {
			_, _ = w.WriteString("<p ")
		}
		if n.Attributes() != nil {
			html.RenderAttributes(w, n, html.ParagraphAttributeFilter)
		}
		_ = w.WriteByte('>')
		if pic {
			_ = w.WriteByte('\n')
		}
	} else {
		if n.ChildCount() == 1 && n.FirstChild().Kind() == ast.KindImage {
			_, _ = w.WriteString("</picture>\n")
		} else {
			_, _ = w.WriteString("</p>\n")
		}
	}
	return ast.WalkContinue, nil
}

func (r *Renderer) renderImage(w util.BufWriter, source []byte, node ast.Node, entering bool) (ast.WalkStatus, error) {
	if !entering {
		return ast.WalkContinue, nil
	}
	n := node.(*ast.Image)
	dst := string(n.Destination)
	ext := path.Ext(dst)
	if strings.HasPrefix(dst, "/") {
		for _, e := range []string{"png", "avif"} {
			fmt.Fprintf(w, `<source type="image/%[1]s" srcset="%[2]s.%[1]s">`+"\n", e, strings.TrimSuffix(dst, ext))
		}
	}
	var extraAttrs string
	if strings.TrimSuffix(path.Base(dst), ext) == "map" {
		extraAttrs = `width="1639" height="1080"`
	}
	fmt.Fprintf(w, `<img src=%q alt=%q %s loading="lazy" fetchpriority="low">`+"\n",
		strings.TrimSuffix(dst, ext)+".avif",
		util.EscapeHTML(n.Text(source)),
		extraAttrs,
	)
	return ast.WalkSkipChildren, nil
}
