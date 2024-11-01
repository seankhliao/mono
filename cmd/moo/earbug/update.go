package earbug

import (
	"context"
	"log/slog"
	"time"

	"github.com/zmb3/spotify/v2"
	"go.seankhliao.com/mono/cmd/moo/earbug/earbugv4"
	"google.golang.org/protobuf/types/known/durationpb"
)

func (a *App) update(ctx context.Context) {
	ctx, span := a.o.T.Start(ctx, "UpdateRecentlyPlayed")
	defer span.End()

	items, err := a.spot.PlayerRecentlyPlayedOpt(ctx, &spotify.RecentlyPlayedOptions{Limit: 50})
	if err != nil {
		a.Err(ctx, "get recently played", err)
		return
	}

	var added int
	a.store.Do(func(s *earbugv4.Store) {
		for _, item := range items {
			ts := item.PlayedAt.Format(time.RFC3339Nano)
			if _, ok := s.Playbacks[ts]; !ok {
				added++
				s.Playbacks[ts] = &earbugv4.Playback{
					TrackId:     item.Track.ID.String(),
					TrackUri:    string(item.Track.URI),
					ContextType: item.PlaybackContext.Type,
					ContextUri:  string(item.PlaybackContext.URI),
				}
			}

			if _, ok := s.Tracks[item.Track.ID.String()]; !ok {
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
				s.Tracks[item.Track.ID.String()] = t
			}
		}
	})

	if added > 0 {
		a.o.L.LogAttrs(ctx, slog.LevelInfo, "updated record", slog.Int("added", added))
		a.store.Sync(ctx)
	}
}
