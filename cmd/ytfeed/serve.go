package main

import (
	"bytes"
	"context"
	"errors"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"slices"
	"sync"
	"time"

	"cuelang.org/go/cue/cuecontext"
	"github.com/maragudk/gomponents"
	"github.com/maragudk/gomponents/html"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/observability"
	"go.seankhliao.com/mono/webstyle"
	"google.golang.org/api/option"
	"google.golang.org/api/youtube/v3"
)

const (
	urlVideo   = `https://www.youtube.com/watch?`
	urlChannel = `https://www.youtube.com/channel/`
)

func New(ctx context.Context, o *observability.O, conf *Config) (*App, error) {
	yt, err := youtube.NewService(ctx,
		option.WithAPIKey(os.Getenv("GCP_APIKEY")),
		option.WithScopes(youtube.YoutubeReadonlyScope),
	)
	if err != nil {
		return nil, o.Err(ctx, "create youtube service", err)
	}
	return &App{
		o:             o,
		yt:            yt,
		startupConfig: *conf,

		feedMu: new(sync.Mutex),
		feeds:  make(map[string]FeedData),
	}, nil
}

type App struct {
	yt            *youtube.Service
	o             *observability.O
	startupConfig Config

	feedMu *sync.Mutex
	feeds  map[string]FeedData
}

func (a *App) Register(mux *http.ServeMux) {
	mux.Handle("GET /{$}", httpencoding.Handler(a.index()))
	mux.Handle("GET /feeds/{feed}", httpencoding.Handler(http.HandlerFunc(a.handleFeed)))
	mux.Handle("GET /lookup", httpencoding.Handler(http.HandlerFunc(a.handleLookup)))
	mux.Handle("POST /lookup", httpencoding.Handler(http.HandlerFunc(a.handleLookup)))

	// mux.HandleFunc("POST /api/v1/refresh", a.handleAPIRefresh)
}

func (a *App) index() http.Handler {
	content := []gomponents.Node{
		html.H3(html.Em(gomponents.Text("things")), gomponents.Text(" to watch")),
		html.P(
			gomponents.Text("To update config, find channel config with:"),
			html.A(html.Href("/lookup"), gomponents.Text("lookup")),
		),
	}

	var feeds []string
	for feed := range a.startupConfig.Feeds {
		feeds = append(feeds, feed)
	}
	slices.Sort(feeds)

	var list []gomponents.Node
	for _, feed := range feeds {
		list = append(list, html.Li(
			html.A(
				html.Href("/feeds/"+feed),
				gomponents.Text(feed),
			),
		))
	}
	content = append(content, html.Ul(list...))

	o := webstyle.NewOptions("ytfeed", "ytfeed", content)
	var buf bytes.Buffer
	webstyle.Structured(&buf, o)

	t := time.Now()
	b := buf.Bytes()
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		http.ServeContent(rw, r, "index.html", t, bytes.NewReader(b))
	})
}

func (a *App) handleFeed(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handle feed")
	defer span.End()

	feed := r.PathValue("feed")
	fd, ok := func(feed string) (FeedData, bool) {
		a.feedMu.Lock()
		defer a.feedMu.Unlock()
		fd, ok := a.feeds[feed]
		return fd, ok
	}(feed)
	if !ok {
		a.o.HTTPErr(ctx, "feed not found", errors.New("unknown feed"), rw, http.StatusNotFound)
		return
	}

	var body []gomponents.Node
	for _, video := range fd.Videos {
		body = append(body, html.Tr(
			html.Td(gomponents.Text(video.Published.Format(time.DateTime))),
			html.Td(
				html.A(
					html.Href(video.ChannelLink),
					gomponents.Text(video.ChannelTitle),
				),
			),
			html.Td(
				html.A(
					html.Href(video.VideoLink),
					gomponents.Text(video.VideoTitle),
				),
			),
		))
	}

	o := webstyle.NewOptions("ytfeed", feed, []gomponents.Node{
		html.H3(html.Em(gomponents.Text(fd.Name))),
		html.P(gomponents.Text(fd.Description)),
		html.P(html.A(html.Href("https://www.youtube.com/feed/history"), gomponents.Text("history control"))),
		html.P(gomponents.Textf("Updated: %s", fd.Updated.Format(time.DateTime))),
		html.Table(
			html.THead(
				html.Tr(
					html.Th(gomponents.Text("time")),
					html.Th(gomponents.Text("channel")),
					html.Th(gomponents.Text("video")),
				),
			),
			html.TBody(body...),
		),
	})
	webstyle.Structured(rw, o)
}

type FeedData struct {
	Name        string
	Description string
	Updated     time.Time

	Videos []FeedVideo
}
type FeedVideo struct {
	Published    time.Time
	ChannelTitle string
	ChannelLink  string
	VideoTitle   string
	VideoLink    string
}

func (a *App) RunPeriodicRefresh(ctx context.Context, period time.Duration) {
	a.runRefresh(ctx)
	tick := time.NewTicker(period)
	for {
		select {
		case <-tick.C:
			a.runRefresh(ctx)
		case <-ctx.Done():
			tick.Stop()
			return
		}
	}
}

func (a *App) runRefresh(ctx context.Context) {
	ctx, span := a.o.T.Start(ctx, "refresh feeds")
	defer span.End()

	cutoff := time.Now().Add(-a.startupConfig.MaxAge)

	a.o.L.LogAttrs(ctx, slog.LevelDebug, "running refresh")

	feeds := make(map[string]FeedData)
	for feed, feedConfig := range a.startupConfig.Feeds {
		feeds[feed] = a.refreshFeed(ctx, cutoff, feed, feedConfig)
	}

	a.feedMu.Lock()
	a.feeds = feeds
	a.feedMu.Unlock()
}

func (a *App) refreshFeed(ctx context.Context, cutoff time.Time, feed string, config ConfigFeed) FeedData {
	ctx, span := a.o.T.Start(ctx, "refresh feed",
		trace.WithAttributes(attribute.String("feed", feed)),
	)
	defer span.End()

	a.o.L.LogAttrs(ctx, slog.LevelDebug, "refreshing feed", slog.String("feed", feed))

	fd := FeedData{
		Name:        feed,
		Description: config.Description,
		Updated:     time.Now(),
	}

	for username, channel := range config.Channels {
		fd.Videos = append(fd.Videos, a.refreshChannel(ctx, cutoff, config.exclude, username, channel.UploadsID)...)
	}

	slices.SortFunc(fd.Videos, func(a, b FeedVideo) int {
		return b.Published.Compare(a.Published)
	})

	return fd
}

func (a *App) refreshChannel(ctx context.Context, cutoff time.Time, excludes map[string]*regexp.Regexp, username, playlistID string) []FeedVideo {
	ctx, span := a.o.T.Start(ctx, "refresh channel",
		trace.WithAttributes(attribute.String("username", username)),
	)
	defer span.End()

	a.o.L.LogAttrs(ctx, slog.LevelDebug, "refreshing user",
		slog.String("username", username),
		slog.String("playlist_id", playlistID),
	)

	res, err := a.yt.PlaylistItems.List([]string{"id", "snippet"}).
		PlaylistId(playlistID).
		MaxResults(50).
		Context(ctx).
		Do()
	if err != nil {
		a.o.Err(ctx, "list playlist", err,
			slog.String("username", username),
		)
		return nil
	}

	var videos []FeedVideo
itemLoop:
	for _, it := range res.Items {
		if it.Snippet.ResourceId.Kind != "youtube#video" {
			continue
		}
		for _, r := range excludes {
			if r.MatchString(it.Snippet.Title) {
				continue itemLoop
			}
		}

		dt, err := time.Parse(time.RFC3339, it.Snippet.PublishedAt)
		if err != nil {
			a.o.Err(ctx, "parse time as rfc3339", err,
				slog.String("username", username),
				slog.String("input_time", it.Snippet.PublishedAt),
			)
			continue
		}
		if dt.Before(cutoff) {
			continue
		}

		videos = append(videos, FeedVideo{
			Published:    dt,
			ChannelTitle: it.Snippet.ChannelTitle,
			ChannelLink:  urlChannel + it.Snippet.ChannelId,
			VideoTitle:   it.Snippet.Title,
			VideoLink:    urlVideo + url.Values{"v": []string{it.Snippet.ResourceId.VideoId}}.Encode(),
		})
	}
	return videos
}

func (a *App) handleLookup(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handle lookup")
	defer span.End()

	content := []gomponents.Node{
		html.H3(html.Em(gomponents.Text("lookup")), gomponents.Text(" channels")),
		html.FormEl(
			html.Action("/lookup"), html.Method("post"),
			html.Label(html.For("term"), gomponents.Text("search term:")),
			html.Input(
				html.Type("text"), html.Placeholder("some youtube search term"),
				html.ID("term"), html.Name("term"),
			),
			html.Input(html.Type("submit")),
		),
	}

	searchTerm := r.PostFormValue("term")
	if r.Method == http.MethodPost && searchTerm != "" {
		res, err := a.runLookup(ctx, searchTerm)
		if err != nil {
			content = append(content, html.Pre(gomponents.Text(err.Error())))
		} else {
			cuectx := cuecontext.New()
			content = append(content, html.Pre(gomponents.Textf("\n%s\n", cuectx.Encode(res))))
		}
	}

	o := webstyle.NewOptions("ytfeed", "lookup", content)
	webstyle.Structured(rw, o)
}
