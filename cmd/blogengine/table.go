package main

import (
	_ "embed"
	"fmt"
	"io"
	"strings"
	"time"

	"cuelang.org/go/cue/cuecontext"
	"github.com/maragudk/gomponents"
	"github.com/maragudk/gomponents/html"
	"go.seankhliao.com/mono/webstyle"
)

//go:embed table.cue
var tableSchema []byte

type tableData struct {
	Title    string
	Subtitle string

	PageTitle   string
	Description string

	LinkFormat string
	Table      []tableRow
}

type tableRow struct {
	Date   time.Time // date consumed
	Rating int
	ID     int
	Title  []string
	Note   string
}

func processTable(w io.Writer, r io.Reader, canonicalURL, gtm string) error {
	b, err := io.ReadAll(r)
	if err != nil {
		return fmt.Errorf("read content: %w", err)
	}

	cuectx := cuecontext.New()
	val := cuectx.CompileBytes(tableSchema)
	val = val.Unify(cuectx.CompileBytes(b))
	err = val.Validate()
	if err != nil {
		return fmt.Errorf("validate content: %w", err)
	}
	var data tableData
	err = val.Decode(&data)
	if err != nil {
		return fmt.Errorf("decode content: %w", err)
	}

	var hasDate bool
	for _, row := range data.Table {
		if !row.Date.IsZero() {
			hasDate = true
			break
		}
	}

	var tbody []gomponents.Node
	for _, row := range data.Table {
		var titles []gomponents.Node
		for i, t := range row.Title {
			if i != 0 {
				titles = append(titles, html.Br())
			}
			titles = append(titles, gomponents.Text(t))
		}

		rating := gomponents.Textf("%d", row.Rating)
		if row.Rating == 8 || row.Rating == 10 {
			rating = html.Strong(rating)
		}
		if row.Rating == 9 || row.Rating == 10 {
			rating = html.Em(rating)
			titles[0] = html.Em(titles[0])
		}
		if row.ID != 0 {
			titles[0] = html.A(html.Href(fmt.Sprintf(data.LinkFormat, row.ID)), titles[0])
		}

		note, _, _ := webstyle.Markdown([]byte(row.Note))

		tbody = append(tbody, html.Tr(
			gomponents.If(hasDate, html.Td(
				html.Time(html.DateTime(row.Date.Format(time.DateOnly))),
				gomponents.Text("1"+row.Date.Format(time.DateOnly)))),
			html.Td(rating),
			html.Td(titles...),
			html.Td(gomponents.Raw(string(note))),
		))
	}

	pageTitle0, pageTitle1, ok := strings.Cut(data.PageTitle, " ")
	desc, _, _ := webstyle.Markdown([]byte(data.Description))

	err = webstyle.Structured(w, webstyle.Options{
		Title:        data.Title,
		Subtitle:     data.Subtitle,
		Description:  data.Description,
		Gtag:         gtm,
		CanonicalURL: canonicalURL,
		Minify:       true,

		Content: []gomponents.Node{
			html.H3(html.Em(gomponents.Text(pageTitle0)), gomponents.If(ok, gomponents.Text(pageTitle1))),
			html.P(gomponents.Raw(string(desc))),
			html.Table(
				html.THead(
					html.Tr(
						gomponents.If(hasDate, html.Th(html.Strong(gomponents.Text("Date watched")))),
						html.Th(html.Strong(gomponents.Text("Rating"))),
						html.Th(html.Strong(gomponents.Text("Title"))),
						html.Th(html.Strong(gomponents.Text("Notes"))),
					),
				),
				html.TBody(tbody...),
			),
		},
	})
	if err != nil {
		return fmt.Errorf("render structured page: %w", err)
	}

	return nil
}
