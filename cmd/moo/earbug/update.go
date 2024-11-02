package earbug

import (
	"context"
	"log/slog"
	"time"

	"github.com/zmb3/spotify/v2"
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
	a.store.Do(func(s *Store) {
		for _, item := range items {
			ts := item.PlayedAt.Format(time.RFC3339Nano)
			if _, ok := s.Playbacks[ts]; !ok {
				added++
				s.Playbacks[ts] = &Playback{
					TrackId:     ptr(item.Track.ID.String()),
					TrackUri:    ptr(string(item.Track.URI)),
					ContextType: ptr(item.PlaybackContext.Type),
					ContextUri:  ptr(string(item.PlaybackContext.URI)),
				}
			}

			if _, ok := s.Tracks[item.Track.ID.String()]; !ok {
				t := &Track{
					Id:       ptr(item.Track.ID.String()),
					Uri:      ptr(string(item.Track.URI)),
					Type:     ptr(item.Track.Type),
					Name:     ptr(item.Track.Name),
					Duration: durationpb.New(item.Track.TimeDuration()),
				}
				for _, artist := range item.Track.Artists {
					t.Artists = append(t.Artists, &Artist{
						Id:   ptr(artist.ID.String()),
						Uri:  ptr(string(artist.URI)),
						Name: ptr(artist.Name),
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
