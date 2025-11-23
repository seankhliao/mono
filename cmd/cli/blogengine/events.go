package main

import (
	"bytes"
	_ "embed"
	"fmt"
	"io"
	"log/slog"
	"strings"
	"time"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"go.seankhliao.com/mono/webstyle"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

type eventsData struct {
	Title    string
	Subtitle string

	PageTitle   string
	Description string

	Events []eventsEvent

	Links eventsLinks
}

type eventsEvent struct {
	Date     time.Time
	Name     string
	Headline string
	Support  []string
	Text     string
}

type eventsLinks struct {
	Ignore map[string]struct{}
	Known  map[string]string
}

func processEvents(w io.Writer, r io.Reader, canonicalURL, gtm string) error {
	b, err := io.ReadAll(r)
	if err != nil {
		return fmt.Errorf("read content: %w", err)
	}

	p := cue.ParsePath("out")
	cuectx := cuecontext.New()
	val := cuectx.CompileString(configSchema)
	val = val.FillPath(p, val.LookupPath(cue.MakePath(cue.Def("#EventPage"))))
	val = val.FillPath(p, cuectx.CompileBytes(b))
	val = val.LookupPath(p)
	err = val.Validate()
	if err != nil {
		return fmt.Errorf("validate content: %w", err)
	}
	var data eventsData
	err = val.Decode(&data)
	if err != nil {
		return fmt.Errorf("decode content: %w", err)
	}

	var listFuture, listPast, contentPast []gomponents.Node
	var futureCount, pastCount, artistCount int
	for _, p := range data.Events {
		if p.Text == "" {
			futureCount++
			listFuture = append(listFuture, html.Li(
				html.Time(
					html.DateTime(p.Date.Format(time.DateOnly)),
					gomponents.Text("1"+p.Date.Format(time.DateOnly)),
				),
				gomponents.Text(" | "),
				gomponents.Text(p.Name),
			))
		} else {
			pastCount++
			listPast = append(listPast, html.Li(
				html.Time(
					html.DateTime(p.Date.Format(time.DateOnly)),
					gomponents.Text("1"+p.Date.Format(time.DateOnly)),
				),
				gomponents.Text(" | "),
				html.A(
					html.Href("#"+p.Date.Format("1"+time.DateOnly)),
					gomponents.Text(p.Name),
				),
			))
			contentPast = append(contentPast,
				html.H5(
					html.ID(p.Date.Format("1"+time.DateOnly)),
					html.Time(
						html.DateTime(p.Date.Format(time.DateOnly)),
						gomponents.Text("1"+p.Date.Format(time.DateOnly)),
					),
					gomponents.Text(" | "),
					html.Em(gomponents.Text(p.Name)),
				),
			)

			var acts []gomponents.Node
			if p.Headline != "" {
				n := html.Em(gomponents.Text(p.Headline))
				link, ok := data.Links.Known[p.Headline]
				if !ok {
					if _, ok := data.Links.Ignore[p.Headline]; !ok {
						slog.Warn("Missing link for headline", "name", p.Headline)
					}
					continue
				}
				n = html.A(html.Href(link), n)
				acts = append(acts, gomponents.Text("Headline "), n)
				artistCount++
			}
			for i, s := range p.Support {
				n := html.Em(gomponents.Text(s))
				link, ok := data.Links.Known[s]
				if !ok {
					if _, ok := data.Links.Ignore[s]; !ok {
						slog.Warn("Missing link for support", "name", s)
					}
					continue
				}
				n = html.A(html.Href(link), n)

				if i == 0 {
					if len(acts) == 0 {
						acts = append(acts, gomponents.Text("With "), n)
					} else {
						acts = append(acts, gomponents.Text(", with "), n)
					}
				} else {
					acts = append(acts, gomponents.Text(", "), n)
				}
				artistCount++
			}
			if len(acts) > 0 {
				contentPast = append(contentPast, html.P(acts...))
			}

			if len(p.Text) > 0 {
				var linkBuf bytes.Buffer
				var offset int
				for {
					start := strings.Index(p.Text[offset:], "[")
					end := strings.Index(p.Text[offset:], "]")
					if start == -1 {
						break
					}
					linkName := p.Text[offset+start+1 : offset+end]
					offset += end + 1

					link, ok := data.Links.Known[linkName]
					if !ok {
						if _, ok := data.Links.Ignore[linkName]; !ok {
							slog.Warn("missing link in text", "name", linkName)
						}
						continue
					}
					linkBuf.WriteString("[")
					linkBuf.WriteString(linkName)
					linkBuf.WriteString("]: ")
					linkBuf.WriteString(link)
					linkBuf.WriteString("\n")

				}
				linkBuf.WriteString("\n")
				linkBuf.WriteString(p.Text)

				text, _, _ := webstyle.Markdown(linkBuf.Bytes())
				contentPast = append(contentPast, gomponents.Raw(string(text)))
			}

		}
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

			html.H4(html.Em(gomponents.Text("List")), gomponents.Text(" of events")),
			html.H5(html.Em(gomponents.Text("Future"))),
			html.P(gomponents.Textf("%d events planned.", futureCount)),
			html.Ul(listFuture...),
			html.H5(html.Em(gomponents.Text("Past"))),
			html.P(gomponents.Textf("%d artists over %d events.", artistCount, pastCount)),
			html.Ul(listPast...),
			html.H4(html.Em(gomponents.Text("Thoughts")), gomponents.Text(" on events")),
			gomponents.Group(contentPast),
		},
	})
	if err != nil {
		return fmt.Errorf("render structured page: %w", err)
	}

	return nil
}
