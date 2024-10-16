package earbug

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
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
	"github.com/maragudk/gomponents"
	"github.com/maragudk/gomponents/html"
	"github.com/zmb3/spotify/v2"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/cmd/moo/earbug/earbugv4"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/webstyle"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
	_ "gocloud.dev/blob/gcsblob"
	"golang.org/x/oauth2"
	oauthspotify "golang.org/x/oauth2/spotify"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/durationpb"
)

type Config struct {
	Host string

	Bucket  string
	Key     string
	AuthURL string

	UpdateFreq time.Duration
	ExportFreq time.Duration
}

func Register(a *App, r yrun.HTTPRegistrar) {
	r.Pattern("GET", a.host, "/", httpencoding.Handler(http.HandlerFunc(a.handleIndex)))
	r.Pattern("GET", a.host, "/artists", httpencoding.Handler(http.HandlerFunc(a.handleArtists)))
	r.Pattern("GET", a.host, "/playbacks", httpencoding.Handler(http.HandlerFunc(a.handlePlaybacks)))
	r.Pattern("GET", a.host, "/tracks", httpencoding.Handler(http.HandlerFunc(a.handleTracks)))
	r.Pattern("GET", a.host, "/api/export", http.HandlerFunc(a.hExport))
	r.Pattern("POST", a.host, "/api/export", http.HandlerFunc(a.hExport))
	r.Pattern("GET", a.host, "/api/auth", http.HandlerFunc(a.hAuthorize))
	r.Pattern("GET", a.host, "/api/update", http.HandlerFunc(a.hUpdate))
	r.Pattern("POST", a.host, "/api/update", http.HandlerFunc(a.hUpdate))
	r.Pattern("GET", a.host, "/auth/callback", http.HandlerFunc(a.hAuthCallback))
}

type App struct {
	o yrun.O11y

	// New
	http    *http.Client
	spot    *spotify.Client
	storemu sync.Mutex
	store   earbugv4.Store

	// config
	host       string
	dataBucket string
	dataKey    string
	authURL    string

	authState atomic.Pointer[AuthState]
}

func New(c Config, o yrun.O11y) (*App, error) {
	ctx := context.Background()

	a := &App{
		o: yrun.O11y{
			T: otel.Tracer("earbug"),
			M: otel.Meter("earbug"),
			L: o.L.WithGroup("earbug"),
			H: o.H.WithGroup("earbug"),
		},
		http: &http.Client{
			Transport: otelhttp.NewTransport(http.DefaultTransport),
		},
		host:       c.Host,
		dataBucket: c.Bucket,
		dataKey:    c.Key,
		authURL:    c.AuthURL,
	}

	ctx, span := o.T.Start(ctx, "initData")
	defer span.End()

	bkt, err := blob.OpenBucket(ctx, a.dataBucket)
	if err != nil {
		return nil, a.Err(ctx, "open bucket", err)
	}
	defer bkt.Close()
	or, err := bkt.NewReader(ctx, a.dataKey, nil)
	if err != nil {
		return nil, a.Err(ctx, "open object", err)
	}
	defer or.Close()
	zr, err := zstd.NewReader(or)
	if err != nil {
		return nil, a.Err(ctx, "new zstd reader", err)
	}
	defer or.Close()
	b, err := io.ReadAll(zr)
	if err != nil {
		return nil, a.Err(ctx, "read object", err)
	}
	err = proto.Unmarshal(b, &a.store)
	if err != nil {
		return nil, a.Err(ctx, "unmarshal store", err)
	}

	var token oauth2.Token
	if a.store.Auth != nil && len(a.store.Auth.Token) > 0 {
		rawToken := a.store.Auth.Token // new value
		err = json.Unmarshal(rawToken, &token)
		if err != nil {
			return nil, a.Err(ctx, "unmarshal oauth token", err)
		}
	} else {
		o.L.LogAttrs(ctx, slog.LevelWarn, "no auth token found")
	}

	httpClient := &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)}
	ctx = context.WithValue(ctx, oauth2.HTTPClient, httpClient)
	as := NewAuthState(a.store.Auth.ClientId, a.store.Auth.ClientSecret, "")
	httpClient = as.conf.Client(ctx, &token)
	a.spot = spotify.New(httpClient)

	go a.exportLoop(ctx, c.ExportFreq)
	go a.updateLoop(ctx, c.UpdateFreq)

	return a, nil
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
		a.HTTPErr(ctx, "no client id/secret", errors.New("missing oauth client"), rw, http.StatusBadRequest)
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
		a.HTTPErr(ctx, "get token from request", err, rw, http.StatusBadRequest)
		return
	}

	httpClient := &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)}
	ctx = context.WithValue(ctx, oauth2.HTTPClient, httpClient)
	httpClient = as.conf.Client(ctx, token)
	spotClient := spotify.New(httpClient)

	tokenMarshaled, err := json.Marshal(token)
	if err != nil {
		a.HTTPErr(ctx, "marshal token", err, rw, http.StatusBadRequest)
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
		a.HTTPErr(ctx, "marshal store", err, rw, http.StatusInternalServerError)
		return
	}

	bkt, err := blob.OpenBucket(ctx, a.dataBucket)
	if err != nil {
		a.HTTPErr(ctx, "open destination bucket", err, rw, http.StatusFailedDependency)
		return
	}

	ow, err := bkt.NewWriter(ctx, a.dataKey, nil)
	if err != nil {
		a.HTTPErr(ctx, "open destination key", err, rw, http.StatusFailedDependency)
		return
	}
	defer ow.Close()
	zw, err := zstd.NewWriter(ow)
	if err != nil {
		a.HTTPErr(ctx, "new zstd writer", err, rw, http.StatusFailedDependency)
		return
	}
	defer zw.Close()
	_, err = io.Copy(zw, bytes.NewReader(b))
	if err != nil {
		a.HTTPErr(ctx, "write store", err, rw, http.StatusFailedDependency)
		return
	}
	fmt.Fprintln(rw, "ok")
}

func (a *App) hUpdate(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "UpdateRecentlyPlayed")
	defer span.End()

	items, err := a.spot.PlayerRecentlyPlayedOpt(ctx, &spotify.RecentlyPlayedOptions{Limit: 50})
	if err != nil {
		a.HTTPErr(ctx, "get recently played", err, rw, http.StatusFailedDependency)
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
		From:   time.Now().Add(-720 * time.Hour),
		To:     time.Now(),
	}
	if t := r.FormValue("from"); t != "" {
		ts, err := time.Parse(time.DateOnly, t)
		if err == nil {
			o.From = ts
		}
	}
	if t := r.FormValue("to"); t != "" {
		ts, err := time.Parse(time.DateOnly, t)
		if err == nil {
			o.To = ts
		}
	}
	return o
}

func (a *App) handleIndex(rw http.ResponseWriter, r *http.Request) {
	_, span := a.o.T.Start(r.Context(), "handleIndex")
	defer span.End()

	o := webstyle.NewOptions("earbug", "earbug", []gomponents.Node{
		html.H3(gomponents.Text("earbug")),
		html.Ul(
			html.Li(html.A(html.Href("/artists?sort=track"), gomponents.Text("artists by track"))),
			html.Li(html.A(html.Href("/artists?sort=plays"), gomponents.Text("artists by plays"))),
			html.Li(html.A(html.Href("/artists?sort=time"), gomponents.Text("artists by time"))),
			html.Li(html.A(html.Href("/playbacks"), gomponents.Text("playbacks"))),
			html.Li(html.A(html.Href("/tracks?sort=plays"), gomponents.Text("tracks by plays"))),
			html.Li(html.A(html.Href("/tracks?sort=time"), gomponents.Text("tracks by time"))),
		),
	})
	webstyle.Structured(rw, o)
}

func (a *App) handleArtists(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handleArtists")
	defer span.End()

	sortOrder := r.FormValue("sort")
	if sortOrder == "" {
		sortOrder = "plays"
	}

	opts := optionsFromRequest(r)
	plays := a.getPlaybacks(ctx, opts)

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

	var body []gomponents.Node
	for _, artist := range artistData {
		var row []gomponents.Node
		rowspan := strconv.Itoa(len(artist.Tracks))
		var totalVal string
		switch sortOrder {
		case "tracks":
			totalVal = strconv.Itoa(len(artist.Tracks))
		case "time":
			totalVal = artist.Time.Round(time.Second).String()
		case "plays":
			fallthrough
		default:
			totalVal = strconv.Itoa(artist.Plays)
		}
		row = append(row,
			html.Td(html.RowSpan(rowspan), gomponents.Text(artist.Name)),
			html.Td(html.RowSpan(rowspan), gomponents.Text(totalVal)),
		)
		for _, track := range artist.Tracks {
			row = append(row,
				html.Td(gomponents.Text(track.Name)),
				html.Td(gomponents.Text(strconv.Itoa(track.Plays))),
				html.Td(gomponents.Text(track.Time.Round(time.Second).String())),
			)
			body = append(body, html.Tr(row...))
			row = []gomponents.Node{}
		}
	}

	o := webstyle.NewOptions("earbug", "artists", []gomponents.Node{
		html.H3(html.Em(gomponents.Text("artist")), gomponents.Text(" by "+sortOrder)),
		form("/artists", sortOrder, opts),
		html.Table(
			html.THead(
				html.Tr(
					html.Th(gomponents.Text("artist")),
					html.Th(gomponents.Text("total")),
					html.Th(gomponents.Text("track")),
					html.Th(gomponents.Text("plays")),
					html.Th(gomponents.Text("time")),
				),
			),
			html.TBody(body...),
		),
	})
	webstyle.Structured(rw, o)
}

func (a *App) handleTracks(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handleTracks")
	defer span.End()

	sortOrder := r.FormValue("sort")
	if sortOrder == "" {
		sortOrder = "plays"
	}

	opts := optionsFromRequest(r)
	plays := a.getPlaybacks(ctx, opts)

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

	var body []gomponents.Node
	for _, track := range trackData {
		var artists []string
		for _, artist := range track.Artists {
			artists = append(artists, artist.Name)
		}
		body = append(body, html.Tr(
			html.Td(gomponents.Text(track.Name)),
			html.Td(gomponents.Text(strconv.Itoa(track.Plays))),
			html.Td(gomponents.Text(track.Time.Round(time.Second).String())),
			html.Td(gomponents.Text(strings.Join(artists, ", "))),
		))
	}
	o := webstyle.NewOptions("earbug", "playbacks", []gomponents.Node{
		html.H3(html.Em(gomponents.Text("tracks")), gomponents.Textf(" by %s", sortOrder)),
		form("/tracks", sortOrder, opts),
		html.Table(
			html.THead(
				html.Tr(
					html.Th(gomponents.Text("track")),
					html.Th(gomponents.Text("plays")),
					html.Th(gomponents.Text("time")),
					html.Th(gomponents.Text("artists")),
				),
			),
			html.TBody(body...),
		),
	})
	webstyle.Structured(rw, o)
}

func (a *App) handlePlaybacks(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handlePlaybacks")
	defer span.End()

	opts := optionsFromRequest(r)
	plays := a.getPlaybacks(ctx, opts)

	var body []gomponents.Node
	for _, play := range plays {
		var artists []string
		for _, artist := range play.Track.Artists {
			artists = append(artists, artist.Name)
		}
		body = append(body, html.Tr(
			html.Td(gomponents.Text(play.StartTime.Format(time.DateTime))),
			html.Td(gomponents.Text(play.PlaybackTime.Round(time.Second).String())),
			html.Td(gomponents.Text(play.Track.Name)),
			html.Td(gomponents.Text(strings.Join(artists, ", "))),
		))
	}

	o := webstyle.NewOptions("earbug", "playbacks", []gomponents.Node{
		html.H3(html.Em(gomponents.Text("playbacks"))),
		form("/playbacks", "", opts),
		html.Table(
			html.THead(
				html.Tr(
					html.Th(gomponents.Text("time")),
					html.Th(gomponents.Text("duration")),
					html.Th(gomponents.Text("track")),
					html.Th(gomponents.Text("artists")),
				),
			),
			html.TBody(body...),
		),
	})
	webstyle.Structured(rw, o)
}

func form(page, sort string, o getPlaybacksOptions) gomponents.Node {
	var sortOption []gomponents.Node
	for _, order := range []string{"plays", "time", "tracks", ""} {
		sortOption = append(sortOption,
			html.Option(
				html.Value(order),
				gomponents.Text(order),
				gomponents.If(order == sort, html.Selected())))
	}
	return html.Form(
		html.Action(page), html.Method("get"),

		html.Label(html.For("sort"), gomponents.Text("Sort by")),
		html.Select(
			html.ID("sort"), html.Name("sort"), html.Required(),
			gomponents.Group(sortOption),
		),

		html.Label(html.For("from"), gomponents.Text("From")),
		html.Input(html.Type("date"), html.ID("from"), html.Name("from"), html.Required(), html.Value(o.From.Format(time.DateOnly))),

		html.Label(html.For("to"), gomponents.Text("To")),
		html.Input(html.Type("date"), html.ID("to"), html.Name("to"), html.Required(), html.Value(o.To.Format(time.DateOnly))),

		html.Label(html.For("artist"), gomponents.Text("Artist")),
		html.Input(html.Type("text"), html.ID("artist"), html.Name("artist"), html.Value(o.Artist)),

		html.Label(html.For("track"), gomponents.Text("Track")),
		html.Input(html.Type("text"), html.ID("track"), html.Name("track"), html.Value(o.Track)),

		html.Input(html.Type("submit"), html.Value("search")),
	)
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

func (a *App) Err(ctx context.Context, msg string, err error, attrs ...slog.Attr) error {
	a.o.L.LogAttrs(ctx, slog.LevelError, msg,
		append(attrs, slog.String("error", err.Error()))...,
	)
	if span := trace.SpanFromContext(ctx); span.SpanContext().IsValid() {
		span.RecordError(err)
		span.SetStatus(codes.Error, msg)
	}

	return fmt.Errorf("%s: %w", msg, err)
}

func (a *App) HTTPErr(ctx context.Context, msg string, err error, rw http.ResponseWriter, code int, attrs ...slog.Attr) {
	err = a.Err(ctx, msg, err, attrs...)
	http.Error(rw, err.Error(), code)
}
