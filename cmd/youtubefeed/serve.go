package main

import (
	"bytes"
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"slices"
	"strings"
	"sync"
	"time"

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
	a := &App{
		o:             o,
		yt:            yt,
		render:        webstyle.NewRenderer(webstyle.TemplateCompact),
		startupConfig: *conf,
		startupTime:   time.Now(),

		feedMu: new(sync.Mutex),
		feeds:  make(map[string]FeedData),
	}

	content := bytes.NewBufferString(`
# youtube feeds

## things to watch

### _feeds_
`)
	var feeds []string
	for feed := range a.startupConfig.Feeds {
		feeds = append(feeds, feed)
	}
	slices.Sort(feeds)

	content.WriteRune('\n')
	for _, feed := range feeds {
		fmt.Fprintf(content, "- [%s](./feeds/%s)\n", feed, feed)
	}

	a.indexRendered, err = a.render.RenderBytes(content.Bytes(), webstyle.Data{})

	return a, err
}

type App struct {
	yt            *youtube.Service
	o             *observability.O
	render        webstyle.Renderer
	startupConfig Config
	startupTime   time.Time
	indexRendered []byte

	feedMu *sync.Mutex
	feeds  map[string]FeedData
}

func (a *App) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /{$}", a.handleIndex)
	mux.HandleFunc("GET /feeds/{feed}", a.handleFeed)
	// mux.HandleFunc("GET /lookup", a.handleLookup)

	// mux.HandleFunc("POST /api/v1/lookup", a.handleAPILookup)
	// mux.HandleFunc("POST /api/v1/refresh", a.handleAPIRefresh)
}

func (a *App) handleIndex(rw http.ResponseWriter, r *http.Request) {
	http.ServeContent(rw, r, "index.html", a.startupTime, bytes.NewReader(a.indexRendered))
}

func (a *App) handleFeed(rw http.ResponseWriter, r *http.Request) {
	feed := r.PathValue("feed")

	fd, ok := func(feed string) (FeedData, bool) {
		a.feedMu.Lock()
		defer a.feedMu.Unlock()
		fd, ok := a.feeds[feed]
		return fd, ok
	}(feed)
	if !ok {
		http.Error(rw, http.StatusText(http.StatusNotFound), http.StatusNotFound)
		return
	}

	content := bytes.NewBufferString(fmt.Sprintf(`
# %s

## [youtube feeds](/)

### _%s_

%s

Updated: %v

| time | channel | video |
| --- | --- | --- |
`, fd.Name, fd.Name, fd.Description, fd.Updated))
	for _, video := range fd.Videos {
		fmt.Fprintf(content, "| %v | [%s](%s) | [%s](%s) |\n", video.Published, video.ChannelTitle, video.ChannelLink, video.VideoTitle, video.VideoLink)
	}

	a.render.Render(rw, content, webstyle.Data{
		Desc: fd.Description,
	})
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
	cutoff := time.Now().Add(-a.startupConfig.MaxAge)

	a.o.L.LogAttrs(ctx, slog.LevelDebug, "running refresh")

	feeds := make(map[string]FeedData)
	for feed, feedConfig := range a.startupConfig.Feeds {
		a.o.L.LogAttrs(ctx, slog.LevelDebug, "refreshing feed", slog.String("feed", feed))

		fd := FeedData{
			Name:        feed,
			Description: feedConfig.Description,
			Updated:     time.Now(),
		}

		for username, channelConfig := range feedConfig.Channels {
			a.o.L.LogAttrs(ctx, slog.LevelDebug, "refreshing user",
				slog.String("feed", feed),
				slog.String("username", username),
				slog.String("playlist_id", channelConfig.UploadsID),
			)

			res, err := a.yt.PlaylistItems.List([]string{"id", "snippet"}).
				PlaylistId(channelConfig.UploadsID).
				Context(ctx).
				Do()
			if err != nil {
				a.o.Err(ctx, "list playlist", err,
					slog.String("feed", feed),
					slog.String("username", username),
				)
				continue
			}

			for _, it := range res.Items {
				dt, err := time.Parse(time.RFC3339, it.Snippet.PublishedAt)
				if err != nil {
					a.o.Err(ctx, "parse time as rfc3339", err,
						slog.String("feed", feed),
						slog.String("username", username),
						slog.String("input_time", it.Snippet.PublishedAt),
					)
					continue
				}
				if dt.Before(cutoff) {
					continue
				}
				fd.Videos = append(fd.Videos, FeedVideo{
					Published:    dt,
					ChannelTitle: escapeMDTable(it.Snippet.ChannelTitle),
					ChannelLink:  urlChannel + it.Snippet.ChannelId,
					VideoTitle:   escapeMDTable(it.Snippet.Title),
					VideoLink:    urlVideo + url.Values{"q": []string{it.Id}}.Encode(),
				})
			}
		}

		slices.SortFunc(fd.Videos, func(a, b FeedVideo) int {
			return b.Published.Compare(a.Published)
		})

		feeds[feed] = fd
	}

	a.feedMu.Lock()
	a.feeds = feeds
	a.feedMu.Unlock()
}

func escapeMDTable(s string) string {
	return strings.NewReplacer("|", "¦").Replace(s)
}
