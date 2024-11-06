package earbug

import (
	"cmp"
	"context"
	"fmt"
	"maps"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/google/cel-go/cel"
	"github.com/google/cel-go/common/types/ref"
	"github.com/google/cel-go/interpreter"
	"go.seankhliao.com/mono/cmd/moo/auth"
	"go.seankhliao.com/mono/cmd/moo/earbug/earbugv5"
	"go.seankhliao.com/mono/webstyle"
	"google.golang.org/protobuf/types/known/timestamppb"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

type queryOptions struct {
	userID   int64
	primary  string      // playbacks, artists, tracks
	sort     string      // name, plays, totaltime
	filter   cel.Program // cel
	filterS  string
	from, to time.Time
}

var (
	validPrimary = []string{"playbacks", "artists", "tracks"}
	validSort    = []string{"name", "plays", "totaltime", "timestamp"}
)

func newQueryOptions(r *http.Request, userID int64) (queryOptions, error) {
	opts := queryOptions{
		userID:  userID,
		primary: "playbacks",
		sort:    "timestamp",
		from:    time.Now().Add(-720 * time.Hour),
		to:      time.Now(),
	}
	if primary := r.FormValue("get"); slices.Contains(validPrimary, primary) {
		opts.primary = primary
	}
	if sort := r.FormValue("sort"); slices.Contains(validSort, sort) {
		opts.sort = sort
	}
	if opts.primary == "playbacks" {
		opts.sort = "timestamp"
	} else if opts.primary != "playbacks" && opts.sort == "timestamp" {
		opts.sort = "plays"
	}
	if t := r.FormValue("from"); t != "" {
		ts, err := time.Parse(time.DateOnly, t)
		if err == nil {
			opts.from = ts
		}
	}
	if t := r.FormValue("to"); t != "" {
		ts, err := time.Parse(time.DateOnly, t)
		if err == nil {
			opts.to = ts
		}
	}

	if filter := r.FormValue("filter"); filter != "" {
		opts.filterS = filter
		var filterCtx *earbugv5.QueryFilterContext
		celEnv, err := cel.NewEnv(
			cel.DeclareContextProto(filterCtx.ProtoReflect().Descriptor()),
		)
		if err != nil {
			return opts, fmt.Errorf("prepare cel env: %w", err)
		}
		celAst, issues := celEnv.Compile(filter)
		if issues.Err() != nil {
			return opts, fmt.Errorf("bad filter: %w", issues.Err())
		}
		opts.filter, err = celEnv.Program(celAst)
		if err != nil {
			return opts, fmt.Errorf("generate filter program: %w", err)
		}

	}

	return opts, nil
}

func (a *App) handleIndex(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handleIndex")
	defer span.End()

	info := auth.FromContext(ctx)
	userID := info.GetUserId()
	if userID <= 0 {
		userID = a.publicID
	}

	opts, err := newQueryOptions(r, userID)
	if err != nil {
		a.HTTPErr(ctx, "bad query", err, rw, http.StatusBadRequest)
		return
	}
	playbacks, err := a.getPlaybacks(ctx, opts)
	if err != nil {
		a.HTTPErr(ctx, "bad query", err, rw, http.StatusBadRequest)
		return
	}

	var thead []gomponents.Node
	var tbody []gomponents.Node

	switch opts.primary {
	case "playbacks":
		// only one sort order
		slices.SortFunc(playbacks, func(a, b DisplayPlayback) int { return b.StartTime.Compare(a.StartTime) }) // oldest first

		for _, row := range playbacks {
			tbody = append(tbody, html.Tr(
				html.Td(gomponents.Text(row.StartTime.Format(time.DateTime))),
				html.Td(gomponents.Text(row.PlaybackTime.String())),
				html.Td(gomponents.Text(row.Track.GetName())),
				html.Td(gomponents.Text(artistsString(row.Track.GetArtists()))),
			))
		}
		thead = []gomponents.Node{
			html.Th(gomponents.Text("time")),
			html.Th(gomponents.Text("duration")),
			html.Th(gomponents.Text("track")),
			html.Th(gomponents.Text("artists")),
		}

	case "artists":
		type artistRow struct {
			artist string
			plays  int
			time   time.Duration
		}
		artists := make(map[string]artistRow)
		for _, play := range playbacks {
			for _, artist := range play.Track.GetArtists() {
				row := artists[artist.GetName()]
				row.artist = artist.GetName()
				row.plays += 1
				row.time += play.PlaybackTime
				artists[artist.GetName()] = row
			}
		}
		artistRows := slices.Collect(maps.Values(artists))
		switch opts.sort {
		case "name":
			slices.SortFunc(artistRows, func(a, b artistRow) int { return cmp.Compare(a.artist, b.artist) })
		case "plays":
			slices.SortFunc(artistRows, func(a, b artistRow) int { return cmp.Compare(b.plays, a.plays) }) // descending
		case "totaltime":
			slices.SortFunc(artistRows, func(a, b artistRow) int { return cmp.Compare(b.time, a.time) }) // descending
		}

		for _, row := range artistRows {
			tbody = append(tbody, html.Tr(
				html.Td(gomponents.Text(row.artist)),
				html.Td(gomponents.Textf("%d", row.plays)),
				html.Td(gomponents.Text(row.time.String())),
			))
		}
		thead = []gomponents.Node{
			html.Th(gomponents.Text("artist")),
			html.Th(gomponents.Text("total plays")),
			html.Th(gomponents.Text("total time")),
		}

	case "tracks":
		type trackRow struct {
			track   string
			artists string
			plays   int
			time    time.Duration
		}
		tracks := make(map[string]trackRow)
		for _, play := range playbacks {
			row := tracks[play.Track.GetId()]
			row.track = play.Track.GetName()
			if row.artists == "" {
				row.artists = artistsString(play.Track.GetArtists())
			}
			row.plays += 1
			row.time += play.PlaybackTime
			tracks[play.Track.GetId()] = row
		}
		trackRows := slices.Collect(maps.Values(tracks))
		switch opts.sort {
		case "name":
			slices.SortFunc(trackRows, func(a, b trackRow) int { return cmp.Compare(a.track, b.track) })
		case "plays":
			slices.SortFunc(trackRows, func(a, b trackRow) int { return cmp.Compare(b.plays, a.plays) }) // descending
		case "totaltime":
			slices.SortFunc(trackRows, func(a, b trackRow) int { return cmp.Compare(b.time, a.time) }) // descending
		}

		for _, row := range trackRows {
			tbody = append(tbody, html.Tr(
				html.Td(gomponents.Text(row.track)),
				html.Td(gomponents.Text(row.artists)),
				html.Td(gomponents.Textf("%d", row.plays)),
				html.Td(gomponents.Text(row.time.String())),
			))
		}

		thead = []gomponents.Node{
			html.Th(gomponents.Text("track")),
			html.Th(gomponents.Text("artists")),
			html.Th(gomponents.Text("total plays")),
			html.Th(gomponents.Text("total time")),
		}
	}

	o := webstyle.NewOptions("earbug", opts.primary, []gomponents.Node{
		html.H3(html.Em(gomponents.Text(opts.primary)), gomponents.Text(" by "+opts.sort)),
		form(opts),
		html.Table(
			html.THead(
				html.Tr(thead...),
			),
			html.TBody(tbody...),
		),
	})
	webstyle.Structured(rw, o)
}

func form(o queryOptions) gomponents.Node {
	var sortOption, getOption []gomponents.Node
	for _, order := range validSort {
		sortOption = append(sortOption, html.Option(
			html.Value(order),
			gomponents.Text(order),
			gomponents.If(order == o.sort, html.Selected()),
		))
	}
	for _, primary := range validPrimary {
		getOption = append(getOption, html.Option(
			html.Value(primary),
			gomponents.Text(primary),
			gomponents.If(primary == o.primary, html.Selected()),
		))
	}

	labelStyle := html.Style(`display: inline-block`)
	inputStyle := html.Style(`width: 40%`)
	return html.Form(
		html.Action("/"), html.Method("get"),

		html.FieldSet(
			html.Legend(gomponents.Text("Get")),

			html.Label(html.For("get"), gomponents.Text("Get *"), labelStyle),
			html.Select(
				html.ID("get"), html.Name("get"), html.Required(),
				gomponents.Group(getOption), inputStyle,
			),

			html.Label(html.For("sort"), gomponents.Text("Sort by"), labelStyle),
			html.Select(
				html.ID("sort"), html.Name("sort"), html.Required(),
				gomponents.Group(sortOption), inputStyle,
			),
		),

		html.FieldSet(
			html.Legend(gomponents.Text("Date range (required)")),

			html.Label(html.For("from"), gomponents.Text("From *"), labelStyle),
			html.Input(html.Type("date"), html.ID("from"), html.Name("from"), html.Required(), html.Value(o.from.Format(time.DateOnly)), inputStyle),

			html.Label(html.For("to"), gomponents.Text("To *"), labelStyle),
			html.Input(html.Type("date"), html.ID("to"), html.Name("to"), html.Required(), html.Value(o.to.Format(time.DateOnly)), inputStyle),
		),

		html.FieldSet(
			html.Legend(gomponents.Text("Filter with cel (optional)")),

			html.Label(html.For("filter"),
				gomponents.Text(
					"cel query, context( track: string, artists: []string, play_time: Timestamp, track_duration: Duration )\n"+
						`example: track.contains("0") && artists.exists(a, a.contains("Ado"))`)),
			html.Input(html.Type("text"), html.ID("filter"), html.Name("filter"), html.Value(o.filterS)),
		),

		html.Input(html.Type("submit"), html.Value("search")),
	)
}

type DisplayPlayback struct {
	StartTime    time.Time
	PlaybackTime time.Duration
	Track        *earbugv5.Track
}

func (a *App) getPlaybacks(ctx context.Context, o queryOptions) ([]DisplayPlayback, error) {
	_, span := a.o.T.Start(ctx, "getPlaybacks")
	defer span.End()

	var plays []DisplayPlayback
	var err error
	a.store.RDo(func(s *earbugv5.Store) {
		userData, ok := s.Users[o.userID]
		if !ok {
			return
		}

		for ts, play := range userData.GetPlaybacks() {
			startTime, _ := time.Parse(time.RFC3339, ts)

			if startTime.Before(o.from) || startTime.After(o.to) {
				continue
			}

			track := s.Tracks[play.GetTrackId()]
			var artists []string
			for _, a := range track.GetArtists() {
				artists = append(artists, a.GetName())
			}

			if o.filter != nil {
				var activation interpreter.Activation
				activation, err = cel.ContextProtoVars(&earbugv5.QueryFilterContext{
					Track:         track.Name,
					Artists:       artists,
					PlayTime:      timestamppb.New(startTime),
					TrackDuration: track.Duration,
				})
				if err != nil {
					err = fmt.Errorf("prepare activation: %w", err)
					return
				}
				var res ref.Val
				res, _, err = o.filter.ContextEval(ctx, activation)
				if err != nil {
					err = fmt.Errorf("eval filter: %w", err)
					return
				}
				if keep, ok := res.Value().(bool); !ok {
					err = fmt.Errorf("filter didn't eval to bool: %T", res.Value())
				} else if !keep {
					continue
				}
			}

			plays = append(plays, DisplayPlayback{
				StartTime: startTime,
				Track:     track,
			})
		}
	})
	if err != nil {
		return nil, err
	}

	slices.SortFunc(plays, func(a, b DisplayPlayback) int {
		return b.StartTime.Compare(a.StartTime)
	})

	// estimate PlaybackTime
	for i := range plays {
		plays[i].PlaybackTime = plays[i].Track.Duration.AsDuration()
		if i > 0 {
			gap := plays[i-1].StartTime.Sub(plays[i].StartTime)
			if gap < plays[i].PlaybackTime {
				plays[i].PlaybackTime = gap
			}
		}
	}

	return plays, nil
}

func artistsString(artists []*earbugv5.Artist) string {
	var as []string
	for _, a := range artists {
		as = append(as, a.GetName())
	}
	return strings.Join(as, ", ")
}
