package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"slices"
	"strings"
	"sync"
	"time"

	"cuelang.org/go/cue/cuecontext"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
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

To update config: [lookup](./lookup)

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
	mux.HandleFunc("GET /lookup", a.handleLookup)
	mux.HandleFunc("POST /lookup", a.handleLookup)

	// mux.HandleFunc("POST /api/v1/refresh", a.handleAPIRefresh)
}

func (a *App) handleIndex(rw http.ResponseWriter, r *http.Request) {
	_, span := a.o.T.Start(r.Context(), "serve index")
	defer span.End()

	http.ServeContent(rw, r, "index.html", a.startupTime, bytes.NewReader(a.indexRendered))
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

	content := bytes.NewBufferString(fmt.Sprintf(`
# %s

## [youtube feeds](/)

### _%s_

%s

Updated: %v

| time | channel | video |
| --- | --- | --- |
`, fd.Name, fd.Name, fd.Description, fd.Updated.Format(time.DateTime)))
	for _, video := range fd.Videos {
		fmt.Fprintf(content, "| %s | [%s](%s) | [%s](%s) |\n",
			video.Published.Format(time.DateTime),
			video.ChannelTitle, video.ChannelLink,
			video.VideoTitle, video.VideoLink,
		)
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
		fd.Videos = append(fd.Videos, a.refreshChannel(ctx, cutoff, username, channel.UploadsID)...)
	}

	slices.SortFunc(fd.Videos, func(a, b FeedVideo) int {
		return b.Published.Compare(a.Published)
	})

	return fd
}

func (a *App) refreshChannel(ctx context.Context, cutoff time.Time, username, playlistID string) []FeedVideo {
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
		Context(ctx).
		Do()
	if err != nil {
		a.o.Err(ctx, "list playlist", err,
			slog.String("username", username),
		)
		return nil
	}

	var videos []FeedVideo
	for _, it := range res.Items {
		if it.Snippet.ResourceId.Kind != "youtube#video" {
			continue
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
			ChannelTitle: escapeMDTable(it.Snippet.ChannelTitle),
			ChannelLink:  urlChannel + it.Snippet.ChannelId,
			VideoTitle:   escapeMDTable(it.Snippet.Title),
			VideoLink:    urlVideo + url.Values{"v": []string{it.Snippet.ResourceId.VideoId}}.Encode(),
		})
	}
	return videos
}

func (a *App) handleLookup(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handle lookup")
	defer span.End()

	content := bytes.NewBufferString(`
# lookup

## [youtube feeds](/)

### _lookup_ config

<form action="/lookup" method="post">
<label for="term">search term:</label>
<input type="text" placehandler="some youtube term" id="term" name="term" />

<input type="submit" />
</form>

`)

	searchTerm := r.PostFormValue("term")
	if r.Method == http.MethodPost && searchTerm != "" {
		content.WriteString("```cue\n")

		res, err := a.runLookup(ctx, searchTerm)
		if err != nil {
			fmt.Fprintln(content, err.Error())
		} else {
			cuectx := cuecontext.New()
			fmt.Fprintln(content, cuectx.Encode(res))
		}

		content.WriteString("```\n")
	}

	a.render.Render(rw, content, webstyle.Data{
		Desc: "generate config for a user",
	})
}

func escapeMDTable(s string) string {
	return strings.NewReplacer("|", "¦").Replace(s)
}
