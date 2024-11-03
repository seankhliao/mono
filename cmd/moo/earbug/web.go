package earbug

import (
	"context"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"time"

	"go.seankhliao.com/mono/webstyle"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

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
			idx, ok := artistIdx[artist.GetId()]
			if !ok {
				artistIdx[artist.GetId()] = len(artistData)
				idx = len(artistData)
				artistData = append(artistData, ArtistData{
					Name: artist.GetName(),
				})
			}
			artistData[idx].Plays += 1
			artistData[idx].Time += play.PlaybackTime

			var foundTrack bool
			for i, track := range artistData[idx].Tracks {
				if track.ID == play.Track.GetId() {
					foundTrack = true
					artistData[idx].Tracks[i].Plays += 1
					artistData[idx].Tracks[i].Time += play.PlaybackTime
				}
			}
			if !foundTrack {
				artistData[idx].Tracks = append(artistData[idx].Tracks, TrackData{
					ID:    play.Track.GetId(),
					Name:  play.Track.GetName(),
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
		Artists []*Artist
	}

	trackIdx := make(map[string]int)
	trackData := []TrackData{}

	for _, play := range plays {
		idx, ok := trackIdx[play.Track.GetId()]
		if !ok {
			trackIdx[play.Track.GetId()] = len(trackData)
			idx = len(trackData)
			trackData = append(trackData, TrackData{
				Name:    play.Track.GetName(),
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
			artists = append(artists, artist.GetName())
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
			artists = append(artists, artist.GetName())
		}
		body = append(body, html.Tr(
			html.Td(gomponents.Text(play.StartTime.Format(time.DateTime))),
			html.Td(gomponents.Text(play.PlaybackTime.Round(time.Second).String())),
			html.Td(gomponents.Text(play.Track.GetName())),
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

	labelStyle := html.Style(`display: inline-block`)
	inputStyle := html.Style(`width: 40%`)
	return html.Form(
		html.Action(page), html.Method("get"),

		html.FieldSet(
			html.Legend(gomponents.Text("Date range (required)")),

			html.Label(html.For("from"), gomponents.Text("From *"), labelStyle),
			html.Input(html.Type("date"), html.ID("from"), html.Name("from"), html.Required(), html.Value(o.From.Format(time.DateOnly)), inputStyle),

			html.Label(html.For("to"), gomponents.Text("To *"), labelStyle),
			html.Input(html.Type("date"), html.ID("to"), html.Name("to"), html.Required(), html.Value(o.To.Format(time.DateOnly)), inputStyle),
		),

		html.FieldSet(
			html.Legend(gomponents.Text("Filtering (optinal)")),

			html.Label(html.For("artist"), gomponents.Text("Artist"), labelStyle),
			html.Input(html.Type("text"), html.ID("artist"), html.Name("artist"), html.Value(o.Artist), inputStyle),

			html.Label(html.For("track"), gomponents.Text("Track"), labelStyle),
			html.Input(html.Type("text"), html.ID("track"), html.Name("track"), html.Value(o.Track), inputStyle),
		),

		html.Label(html.For("sort"), gomponents.Text("Sort by")),
		html.Select(
			html.ID("sort"), html.Name("sort"), html.Required(),
			gomponents.Group(sortOption),
		),

		html.Input(html.Type("submit"), html.Value("search")),
	)
}

type getPlaybacksOptions struct {
	From time.Time
	To   time.Time

	Artist string
	Track  string
}

type DisplayPlayback struct {
	StartTime    time.Time
	PlaybackTime time.Duration
	Track        *Track
}

func (a *App) getPlaybacks(ctx context.Context, o getPlaybacksOptions) []DisplayPlayback {
	_, span := a.o.T.Start(ctx, "getPlaybacks")
	defer span.End()

	var plays []DisplayPlayback

	a.store.RDo(func(s *Store) {
		for ts, play := range s.Playbacks {
			startTime, _ := time.Parse(time.RFC3339, ts)

			if !o.From.IsZero() && o.From.After(startTime) {
				continue
			} else if !o.To.IsZero() && o.To.Before(startTime) {
				continue
			}

			track := s.Tracks[play.GetTrackId()]

			if o.Track != "" && !strings.Contains(strings.ToLower(track.GetName()), strings.ToLower(o.Track)) {
				continue
			}

			artistMatch := o.Artist == ""
			for _, artist := range track.Artists {
				if !artistMatch && strings.Contains(strings.ToLower(artist.GetName()), strings.ToLower(o.Artist)) {
					artistMatch = true
				}
			}
			if !artistMatch {
				continue
			}

			plays = append(plays, DisplayPlayback{
				StartTime: startTime,
				Track:     track,
			})
		}
	})

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
