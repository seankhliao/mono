package earbug

import (
	"context"
	"encoding/json"
	"log/slog"
	"time"

	"github.com/zmb3/spotify/v2"
	"go.opentelemetry.io/otel/attribute"
	"go.seankhliao.com/mono/cmd/moo/earbug/earbugv5"
	"golang.org/x/oauth2"
	"google.golang.org/protobuf/types/known/durationpb"
)

func (a *App) update(ctx context.Context) {
	ctx, span := a.o.T.Start(ctx, "update all recently played")
	defer span.End()

	ctx = context.WithValue(ctx, oauth2.HTTPClient, a.http)

	clients := make(map[int64]spotify.Client)
	a.store.RDo(func(s *earbugv5.Store) {
		for userID, userData := range s.Users {
			var token oauth2.Token
			err := json.Unmarshal(userData.Token, &token)
			if err != nil {
				continue
			}
			clients[userID] = *spotify.New(a.oauth2.Client(ctx, &token))
		}
	})

	var added int
	for userID, spot := range clients {
		func() {
			ctx, span := a.o.T.Start(ctx, "update user recently played")
			defer span.End()
			span.SetAttributes(attribute.Int64("user.id", userID))

			items, err := spot.PlayerRecentlyPlayedOpt(ctx, &spotify.RecentlyPlayedOptions{Limit: 50})
			if err != nil {
				a.Err(ctx, "get recently played", err)
				return
			}

			a.store.Do(func(s *earbugv5.Store) {
				for _, item := range items {
					ts := item.PlayedAt.Format(time.RFC3339Nano)
					if _, ok := s.Users[userID].Playbacks[ts]; !ok {
						added++
						s.Users[userID].Playbacks[ts] = &earbugv5.Playback{
							TrackId:     ptr(item.Track.ID.String()),
							TrackUri:    ptr(string(item.Track.URI)),
							ContextType: ptr(item.PlaybackContext.Type),
							ContextUri:  ptr(string(item.PlaybackContext.URI)),
						}
					}

					if _, ok := s.Tracks[item.Track.ID.String()]; !ok {
						t := &earbugv5.Track{
							Id:       ptr(item.Track.ID.String()),
							Uri:      ptr(string(item.Track.URI)),
							Type:     ptr(item.Track.Type),
							Name:     ptr(item.Track.Name),
							Duration: durationpb.New(item.Track.TimeDuration()),
						}
						for _, artist := range item.Track.Artists {
							t.Artists = append(t.Artists, &earbugv5.Artist{
								Id:   ptr(artist.ID.String()),
								Uri:  ptr(string(artist.URI)),
								Name: ptr(artist.Name),
							})
						}
						s.Tracks[item.Track.ID.String()] = t
					}
				}
			})
		}()
	}

	if added > 0 {
		a.o.L.LogAttrs(ctx, slog.LevelInfo, "updated record", slog.Int("added", added))
		a.store.Sync(ctx)
	}
}
