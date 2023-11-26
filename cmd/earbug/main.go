package main

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"sort"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/klauspost/compress/zstd"
	"github.com/zmb3/spotify/v2"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.seankhliao.com/mono/cmd/earbug/earbugv4"
	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/observability"
	"go.seankhliao.com/mono/webstyle"
	"gocloud.dev/blob"
	_ "gocloud.dev/blob/gcsblob"
	"golang.org/x/oauth2"
	oauthspotify "golang.org/x/oauth2/spotify"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/durationpb"
)

func main() {
	conf := &Config{}
	framework.Run(framework.Config{
		RegisterFlags: conf.SetFlags,
		Start: func(ctx context.Context, o *observability.O, m *http.ServeMux) (func(), error) {
			app, err := New(ctx, o, conf)
			if err != nil {
				return nil, err
			}
			app.Register(m)
			return func() { app.export(context.Background()) }, nil
		},
	})
}

type Config struct {
	dataBucket string
	dataKey    string
	authURL    string

	updateFreq time.Duration
	exportFreq time.Duration
}

func (c *Config) SetFlags(fset *flag.FlagSet) {
	fset.StringVar(&c.dataBucket, "data.bucket", "gs://earbug-liao-dev", "bucket to load/store data")
	fset.StringVar(&c.dataKey, "data.key", "ihwa.pb.zstd", "key to load/store data")
	fset.StringVar(&c.authURL, "auth.url", "http://earbug-ihwa.badger-altered.ts.net/auth/callback", "auth callback url")
	fset.DurationVar(&c.updateFreq, "update.interval", 5*time.Minute, "how often to update")
	fset.DurationVar(&c.exportFreq, "export.interval", 30*time.Minute, "how often to export")
}

type App struct {
	o      *observability.O
	render webstyle.Renderer

	// New
	http    *http.Client
	spot    *spotify.Client
	storemu sync.Mutex
	store   earbugv4.Store

	// config
	dataBucket string
	dataKey    string
	authURL    string

	authState atomic.Pointer[AuthState]
}

func New(ctx context.Context, o *observability.O, conf *Config) (*App, error) {
	a := &App{
		o:      o,
		render: webstyle.NewRenderer(webstyle.TemplateCompact),
		http: &http.Client{
			Transport: otelhttp.NewTransport(http.DefaultTransport),
		},
		dataBucket: conf.dataBucket,
		dataKey:    conf.dataKey,
		authURL:    conf.authURL,
	}

	ctx, span := o.T.Start(ctx, "initData")
	defer span.End()

	bkt, err := blob.OpenBucket(ctx, conf.dataBucket)
	if err != nil {
		return nil, o.Err(ctx, "open bucket", err)
	}
	defer bkt.Close()
	or, err := bkt.NewReader(ctx, conf.dataKey, nil)
	if err != nil {
		return nil, o.Err(ctx, "open object", err)
	}
	defer or.Close()
	zr, err := zstd.NewReader(or)
	if err != nil {
		return nil, o.Err(ctx, "new zstd reader", err)
	}
	defer or.Close()
	b, err := io.ReadAll(zr)
	if err != nil {
		return nil, o.Err(ctx, "read object", err)
	}
	err = proto.Unmarshal(b, &a.store)
	if err != nil {
		return nil, o.Err(ctx, "unmarshal store", err)
	}

	var token oauth2.Token
	if a.store.Auth != nil && len(a.store.Auth.Token) > 0 {
		rawToken := a.store.Auth.Token // new value
		err = json.Unmarshal(rawToken, &token)
		if err != nil {
			return nil, o.Err(ctx, "unmarshal oauth token", err)
		}
	} else {
		o.L.LogAttrs(ctx, slog.LevelWarn, "no auth token found")
	}

	httpClient := &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)}
	ctx = context.WithValue(ctx, oauth2.HTTPClient, httpClient)
	as := NewAuthState(a.store.Auth.ClientId, a.store.Auth.ClientSecret, "")
	httpClient = as.conf.Client(ctx, &token)
	a.spot = spotify.New(httpClient)

	go a.exportLoop(ctx, conf.exportFreq)
	go a.updateLoop(ctx, conf.updateFreq)

	return a, nil
}

func (a *App) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /", a.handleIndex)
	mux.HandleFunc("GET /artists", a.handleArtists)
	mux.HandleFunc("GET /playbacks", a.handlePlaybacks)
	mux.HandleFunc("GET /tracks", a.handleTracks)
	mux.HandleFunc("GET /api/export", a.hExport)
	mux.HandleFunc("POST /api/export", a.hExport)
	mux.HandleFunc("GET /api/auth", a.hAuthorize)
	mux.HandleFunc("GET /api/update", a.hUpdate)
	mux.HandleFunc("POST /api/update", a.hUpdate)
	mux.HandleFunc("GET /auth/callback", a.hAuthCallback)
	mux.HandleFunc("GET /-/ready", func(rw http.ResponseWriter, r *http.Request) { rw.Write([]byte("ok")) })
}

func (a *App) hAuthorize(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "Authorize")
	defer span.End()

	clientID, clientSecret := func() (clientID, clientSecret string) {
		a.storemu.Lock()
		defer a.storemu.Unlock()
		clientID = r.FormValue("client_id")
		if clientID == "" && (a.store.Auth != nil && a.store.Auth.ClientId != "") {
			clientID = a.store.Auth.ClientId
		} else {
			if a.store.Auth == nil {
				a.store.Auth = &earbugv4.Auth{}
			}
			a.store.Auth.ClientId = clientID
		}
		clientSecret = r.FormValue("client_secret")
		if clientSecret == "" && (a.store.Auth != nil && a.store.Auth.ClientSecret != "") {
			clientSecret = a.store.Auth.ClientSecret
		} else {
			a.store.Auth.ClientSecret = clientSecret
		}
		return
	}()
	if clientID == "" || clientSecret == "" {
		a.o.HTTPErr(ctx, "no client id/secret", errors.New("missing oauth client"), rw, http.StatusBadRequest)
		return
	}

	as := NewAuthState(clientID, clientSecret, a.authURL)
	a.authState.Store(as)

	http.Redirect(rw, r, as.conf.AuthCodeURL(as.state), http.StatusTemporaryRedirect)
}

func (a *App) hAuthCallback(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "hAuthCallback")
	defer span.End()

	as := a.authState.Load()
	token, err := as.conf.Exchange(ctx, r.FormValue("code"))
	if err != nil {
		a.o.HTTPErr(ctx, "get token from request", err, rw, http.StatusBadRequest)
		return
	}

	httpClient := &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)}
	ctx = context.WithValue(ctx, oauth2.HTTPClient, httpClient)
	httpClient = as.conf.Client(ctx, token)
	spotClient := spotify.New(httpClient)

	tokenMarshaled, err := json.Marshal(token)
	if err != nil {
		a.o.HTTPErr(ctx, "marshal token", err, rw, http.StatusBadRequest)
		return
	}

	func() {
		a.storemu.Lock()
		defer a.storemu.Unlock()
		a.store.Auth.Token = tokenMarshaled
		a.spot = spotClient
	}()

	rw.Write([]byte("success"))
}

type AuthState struct {
	state string
	conf  *oauth2.Config
}

func NewAuthState(clientID, clientSecret, redirectURL string) *AuthState {
	buf := make([]byte, 256)
	rand.Read(buf)
	return &AuthState{
		state: base64.StdEncoding.EncodeToString(buf),
		conf: &oauth2.Config{
			ClientID:     clientID,
			ClientSecret: clientSecret,
			Endpoint: oauth2.Endpoint{
				AuthURL:   oauthspotify.Endpoint.AuthURL,
				TokenURL:  oauthspotify.Endpoint.TokenURL,
				AuthStyle: oauth2.AuthStyleInHeader,
			},
			RedirectURL: redirectURL,
			Scopes:      []string{"user-read-recently-played"},
		},
	}
}

func (a *App) hExport(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "Export")
	defer span.End()

	b, err := func() ([]byte, error) {
		a.storemu.Lock()
		defer a.storemu.Unlock()
		return proto.Marshal(&a.store)
	}()
	if err != nil {
		a.o.HTTPErr(ctx, "marshal store", err, rw, http.StatusInternalServerError)
		return
	}

	bkt, err := blob.OpenBucket(ctx, a.dataBucket)
	if err != nil {
		a.o.HTTPErr(ctx, "open destination bucket", err, rw, http.StatusFailedDependency)
		return
	}

	ow, err := bkt.NewWriter(ctx, a.dataKey, nil)
	if err != nil {
		a.o.HTTPErr(ctx, "open destination key", err, rw, http.StatusFailedDependency)
		return
	}
	defer ow.Close()
	zw, err := zstd.NewWriter(ow)
	if err != nil {
		a.o.HTTPErr(ctx, "new zstd writer", err, rw, http.StatusFailedDependency)
		return
	}
	defer zw.Close()
	_, err = io.Copy(zw, bytes.NewReader(b))
	if err != nil {
		a.o.HTTPErr(ctx, "write store", err, rw, http.StatusFailedDependency)
		return
	}
	fmt.Fprintln(rw, "ok")
}

func (a *App) hUpdate(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "UpdateRecentlyPlayed")
	defer span.End()

	items, err := a.spot.PlayerRecentlyPlayedOpt(ctx, &spotify.RecentlyPlayedOptions{Limit: 50})
	if err != nil {
		a.o.HTTPErr(ctx, "get recently played", err, rw, http.StatusFailedDependency)
		return
	}

	var added int
	for _, item := range items {
		ts := item.PlayedAt.Format(time.RFC3339Nano)
		if _, ok := a.store.Playbacks[ts]; !ok {
			added++
			a.store.Playbacks[ts] = &earbugv4.Playback{
				TrackId:     item.Track.ID.String(),
				TrackUri:    string(item.Track.URI),
				ContextType: item.PlaybackContext.Type,
				ContextUri:  string(item.PlaybackContext.URI),
			}
		}

		if _, ok := a.store.Tracks[item.Track.ID.String()]; !ok {
			t := &earbugv4.Track{
				Id:       item.Track.ID.String(),
				Uri:      string(item.Track.URI),
				Type:     item.Track.Type,
				Name:     item.Track.Name,
				Duration: durationpb.New(item.Track.TimeDuration()),
			}
			for _, artist := range item.Track.Artists {
				t.Artists = append(t.Artists, &earbugv4.Artist{
					Id:   artist.ID.String(),
					Uri:  string(artist.URI),
					Name: artist.Name,
				})
			}
			a.store.Tracks[item.Track.ID.String()] = t
		}
	}
	fmt.Fprintln(rw, "added", added)
}

// /artists?sort=tracks
// /artists?sort=plays
// /artists?sort=time
// /playbacks
// /tracks?sort=plays
// /tracks?sort=time

func optionsFromRequest(r *http.Request) getPlaybacksOptions {
	o := getPlaybacksOptions{
		Artist: r.FormValue("artist"),
		Track:  r.FormValue("track"),
	}
	if t := r.FormValue("from"); t != "" {
		ts, err := time.Parse(time.RFC3339, t)
		if err == nil {
			o.From = ts
		}
	} else {
		o.From = time.Now().Add(-720 * time.Hour)
	}
	if t := r.FormValue("to"); t != "" {
		ts, err := time.Parse(time.RFC3339, t)
		if err == nil {
			o.To = ts
		}
	}
	return o
}

func (a *App) handleIndex(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handleIndex")
	defer span.End()

	if r.URL.Path != "/" {
		http.Redirect(rw, r, "/", http.StatusFound)
		return
	}

	c := `
# earbug

## spotify

### _earbug_

- [artists by track](/artists?sort=track)
- [artists by plays](/artists?sort=plays)
- [artists by time](/artists?sort=time)
- [playbacks](/playbacks)
- [tracks by plays](/tracks?sort=plays)
- [tracks by time](/tracks?sort=time)
`

	err := a.render.Render(rw, strings.NewReader(c), webstyle.Data{})
	if err != nil {
		a.o.HTTPErr(ctx, "render", err, rw, http.StatusInternalServerError)
		return
	}
}

func (a *App) handleArtists(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handleArtists")
	defer span.End()

	sortOrder := r.FormValue("sort")
	if sortOrder == "" {
		sortOrder = "plays"
	}

	plays := a.getPlaybacks(ctx, optionsFromRequest(r))

	type TrackData struct {
		ID    string
		Name  string
		Plays int
		Time  time.Duration
	}
	type ArtistData struct {
		Name   string
		Plays  int
		Time   time.Duration
		Tracks []TrackData
	}

	artistIdx := make(map[string]int)
	artistData := []ArtistData{}

	for _, play := range plays {
		for _, artist := range play.Track.Artists {
			idx, ok := artistIdx[artist.Id]
			if !ok {
				artistIdx[artist.Id] = len(artistData)
				idx = len(artistData)
				artistData = append(artistData, ArtistData{
					Name: artist.Name,
				})
			}
			artistData[idx].Plays += 1
			artistData[idx].Time += play.PlaybackTime

			var foundTrack bool
			for i, track := range artistData[idx].Tracks {
				if track.ID == play.Track.Id {
					foundTrack = true
					artistData[idx].Tracks[i].Plays += 1
					artistData[idx].Tracks[i].Time += play.PlaybackTime
				}
			}
			if !foundTrack {
				artistData[idx].Tracks = append(artistData[idx].Tracks, TrackData{
					ID:    play.Track.Id,
					Name:  play.Track.Name,
					Plays: 1,
					Time:  play.PlaybackTime,
				})
			}
		}
	}

	sort.Slice(artistData, func(i, j int) bool {
		switch sortOrder {
		case "tracks":
			if len(artistData[i].Tracks) == len(artistData[j].Tracks) {
				return artistData[i].Name < artistData[j].Name
			}
			return len(artistData[i].Tracks) > len(artistData[j].Tracks)
		case "time":
			return artistData[i].Time > artistData[j].Time
		case "plays":
			fallthrough
		default:
			if artistData[i].Plays == artistData[j].Plays {
				return artistData[i].Name < artistData[j].Name
			}
			return artistData[i].Plays > artistData[j].Plays
		}
	})
	for _, artist := range artistData {
		sort.Slice(artist.Tracks, func(i, j int) bool {
			switch sortOrder {
			case "time":
				return artist.Tracks[i].Time > artist.Tracks[j].Time
			case "plays":
				fallthrough
			default:
				if artist.Tracks[i].Plays == artist.Tracks[j].Plays {
					return artist.Tracks[i].Name < artist.Tracks[j].Name
				}
				return artist.Tracks[i].Plays > artist.Tracks[j].Plays
			}
		})
	}

	var buf bytes.Buffer
	buf.WriteString(`### Artists by `)
	buf.WriteString(sortOrder)
	buf.WriteString("\n\n")
	buf.WriteString("<table><thead><tr><th>artist<th>total<th>track<th>plays<th>time</tr></thead>\n<tbody>")
	for _, artist := range artistData {
		buf.WriteString("<tr><td rowspan=\"")
		buf.WriteString(strconv.Itoa(len(artist.Tracks)))
		buf.WriteString("\">")
		buf.WriteString(artist.Name)
		buf.WriteString("<td rowspan=\"")
		buf.WriteString(strconv.Itoa(len(artist.Tracks)))
		buf.WriteString("\">")
		switch sortOrder {
		case "tracks":
			buf.WriteString(strconv.Itoa(len(artist.Tracks)))
		case "time":
			buf.WriteString(artist.Time.String())
		case "plays":
			fallthrough
		default:
			buf.WriteString(strconv.Itoa(artist.Plays))
		}
		for i, track := range artist.Tracks {
			if i != 0 {
				buf.WriteString("</tr>\n<tr>")
			}
			buf.WriteString("<td>")
			buf.WriteString(track.Name)
			buf.WriteString("<td>")
			buf.WriteString(strconv.Itoa(track.Plays))
			buf.WriteString("<td>")
			buf.WriteString(track.Time.String())
		}
		buf.WriteString("</tr>\n")
	}
	buf.WriteString("</tbody></table>")

	err := a.render.Render(rw, &buf, webstyle.Data{})
	if err != nil {
		a.o.HTTPErr(ctx, "render", err, rw, http.StatusInternalServerError)
		return
	}
}

func (a *App) handleTracks(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handleTracks")
	defer span.End()

	sortOrder := r.FormValue("sort")
	if sortOrder == "" {
		sortOrder = "plays"
	}

	plays := a.getPlaybacks(ctx, optionsFromRequest(r))

	type TrackData struct {
		Name    string
		Plays   int
		Time    time.Duration
		Artists []*earbugv4.Artist
	}

	trackIdx := make(map[string]int)
	trackData := []TrackData{}

	for _, play := range plays {
		idx, ok := trackIdx[play.Track.Id]
		if !ok {
			trackIdx[play.Track.Id] = len(trackData)
			idx = len(trackData)
			trackData = append(trackData, TrackData{
				Name:    play.Track.Name,
				Artists: play.Track.Artists,
			})
		}
		trackData[idx].Plays += 1
		trackData[idx].Time += play.PlaybackTime
	}

	sort.Slice(trackData, func(i, j int) bool {
		switch sortOrder {
		case "time":
			return trackData[i].Time > trackData[j].Time
		case "plays":
			fallthrough
		default:
			if trackData[i].Plays == trackData[j].Plays {
				return trackData[i].Name < trackData[j].Name
			}
			return trackData[i].Plays > trackData[j].Plays
		}
	})

	var buf bytes.Buffer
	buf.WriteString(`### Tracks by `)
	buf.WriteString(sortOrder)
	buf.WriteString("\n\n")
	buf.WriteString("<table><thead><tr><th>track<th>plays<th>time<th>artists</tr></thead>\n<tbody>")
	for _, track := range trackData {
		var artists []string
		for _, artist := range track.Artists {
			artists = append(artists, artist.Name)
		}
		buf.WriteString("<tr><td>")
		buf.WriteString(track.Name)
		buf.WriteString("<td>")
		buf.WriteString(strconv.Itoa(track.Plays))
		buf.WriteString("<td>")
		buf.WriteString(track.Time.String())
		buf.WriteString("<td>")
		buf.WriteString(strings.Join(artists, ", "))
		buf.WriteString("</tr>\n")
	}
	buf.WriteString("</tbody></table>")

	err := a.render.Render(rw, &buf, webstyle.Data{})
	if err != nil {
		a.o.HTTPErr(ctx, "render", err, rw, http.StatusInternalServerError)
		return
	}
}

func (a *App) handlePlaybacks(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handlePlaybacks")
	defer span.End()

	plays := a.getPlaybacks(ctx, optionsFromRequest(r))

	var buf bytes.Buffer
	buf.WriteString(`### Playbacks `)
	buf.WriteString("\n\n")
	buf.WriteString("<table><thead><tr><th>time<th>duration<th>track<th>artists</tr></thead>\n<tbody>")
	for _, play := range plays {
		var artists []string
		for _, artist := range play.Track.Artists {
			artists = append(artists, artist.Name)
		}
		buf.WriteString("<tr><td>")
		buf.WriteString(play.StartTime.Format(time.DateTime))
		buf.WriteString("<td>")
		buf.WriteString(play.PlaybackTime.Round(time.Second).String())
		buf.WriteString("<td>")
		buf.WriteString(play.Track.Name)
		buf.WriteString("<td>")
		buf.WriteString(strings.Join(artists, ", "))
		buf.WriteString("</tr>\n")
	}

	buf.WriteString("</tbody></table>")

	err := a.render.Render(rw, &buf, webstyle.Data{})
	if err != nil {
		a.o.HTTPErr(ctx, "render", err, rw, http.StatusInternalServerError)
		return
	}
}

type getPlaybacksOptions struct {
	From time.Time
	To   time.Time

	Artist string
	Track  string
}

type Playback struct {
	StartTime    time.Time
	PlaybackTime time.Duration
	Track        *earbugv4.Track
}

func (a *App) getPlaybacks(ctx context.Context, o getPlaybacksOptions) []Playback {
	_, span := a.o.T.Start(ctx, "getPlaybacks")
	defer span.End()

	var plays []Playback

	a.storemu.Lock()
	defer a.storemu.Unlock()
	for ts, play := range a.store.Playbacks {
		startTime, _ := time.Parse(time.RFC3339, ts)

		if !o.From.IsZero() && o.From.After(startTime) {
			continue
		} else if !o.To.IsZero() && o.To.Before(startTime) {
			continue
		}

		track := a.store.Tracks[play.TrackId]

		if o.Track != "" && !strings.Contains(strings.ToLower(track.Name), strings.ToLower(o.Track)) {
			continue
		}

		artistMatch := o.Artist == ""
		for _, artist := range track.Artists {
			if !artistMatch && strings.Contains(strings.ToLower(artist.Name), strings.ToLower(o.Artist)) {
				artistMatch = true
			}
		}
		if !artistMatch {
			continue
		}

		plays = append(plays, Playback{
			StartTime: startTime,
			Track:     track,
		})
	}

	sort.Slice(plays, func(i, j int) bool {
		return plays[i].StartTime.After(plays[j].StartTime)
	})

	for i := range plays {
		plays[i].PlaybackTime = plays[i].Track.Duration.AsDuration()
		if i > 0 {
			gap := plays[i-1].StartTime.Sub(plays[i].StartTime)
			if gap < plays[i].PlaybackTime {
				plays[i].PlaybackTime = gap
			}
		}
	}

	return plays
}

func (a *App) exportLoop(ctx context.Context, dur time.Duration) {
	ticker := time.NewTicker(dur).C
	init := make(chan struct{}, 1)
	init <- struct{}{}
	for {
		select {
		case <-init:
		case <-ticker:
		case <-ctx.Done():
			return
		}
		ctx := context.Background()
		a.export(ctx)
	}
}

func (a *App) export(ctx context.Context) {
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, "http://localhost/api/export", nil)
	rec := httptest.NewRecorder()
	a.hExport(rec, req)
}

func (a *App) updateLoop(ctx context.Context, dur time.Duration) {
	a.update(ctx)

	ticker := time.NewTicker(dur).C
	init := make(chan struct{}, 1)
	init <- struct{}{}
	for {
		select {
		case <-init:
		case <-ticker:
		case <-ctx.Done():
			return
		}
		ctx := context.Background()
		a.update(ctx)
	}
}

func (a *App) update(ctx context.Context) {
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, "http://localhost/api/update", nil)
	rec := httptest.NewRecorder()
	a.hUpdate(rec, req)
}
