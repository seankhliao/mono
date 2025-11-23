package main

import (
	_ "embed"
	"fmt"
	"io"
	"strings"
	"time"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"go.seankhliao.com/mono/webstyle"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

type tableData struct {
	Title    string
	Subtitle string

	PageTitle   string
	Description string

	Tables []tableTable
}

type tableTable struct {
	Heading     string
	Description string
	LinkFormat  string
	Rows        []tableRow
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

	p := cue.ParsePath("out")
	cuectx := cuecontext.New()
	val := cuectx.CompileString(configSchema)
	val = val.FillPath(p, val.LookupPath(cue.MakePath(cue.Def("#TablePage"))))
	val = val.FillPath(p, cuectx.CompileBytes(b))
	val = val.LookupPath(p)
	err = val.Validate()
	if err != nil {
		return fmt.Errorf("validate content: %w", err)
	}
	var data tableData
	err = val.Decode(&data)
	if err != nil {
		return fmt.Errorf("decode content: %w", err)
	}

	pageTitle0, pageTitle1, ok := strings.Cut(data.PageTitle, " ")
	desc, _, _ := webstyle.Markdown([]byte(data.Description))
	content := []gomponents.Node{
		html.H3(html.Em(gomponents.Text(pageTitle0)), gomponents.If(ok, gomponents.Text(pageTitle1))),
		html.P(gomponents.Raw(string(desc))),
	}

	for _, table := range data.Tables {
		var hasDate bool
		for _, row := range table.Rows {
			if !row.Date.IsZero() {
				hasDate = true
				break
			}
		}
		var tbody []gomponents.Node
		for _, row := range table.Rows {
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
				titles[0] = html.A(html.Href(fmt.Sprintf(table.LinkFormat, row.ID)), titles[0])
			}

			note, _, _ := webstyle.Markdown([]byte(row.Note))

			var tr []gomponents.Node
			if hasDate {
				tr = append(tr, html.Td(html.Time(
					html.DateTime(row.Date.Format(time.DateOnly)),
					gomponents.Text("1"+row.Date.Format(time.DateOnly)),
				)))
			}
			tr = append(tr,
				html.Td(rating),
				html.Td(titles...),
				html.Td(gomponents.Raw(string(note))),
			)

			tbody = append(tbody, html.Tr(gomponents.Group(tr)))
		}

		heading0, heading1, _ := strings.Cut(table.Heading, " ")
		content = append(content,
			html.H4(html.Em(gomponents.Text(heading0), gomponents.Text(" "+heading1))),
			html.P(gomponents.Text(table.Description)),
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
		)
	}

	err = webstyle.Structured(w, webstyle.Options{
		Title:        data.Title,
		Subtitle:     data.Subtitle,
		Description:  data.Description,
		Gtag:         gtm,
		CanonicalURL: canonicalURL,
		CustomCSS: `
td:nth-child(1) {
  min-width: 14ch;
}
`,
		Minify: true,

		Content: content,
	})
	if err != nil {
		return fmt.Errorf("render structured page: %w", err)
	}

	return nil
}
