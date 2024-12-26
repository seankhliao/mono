package earbug

import (
	"context"
	"log/slog"
	"time"

	"github.com/go-json-experiment/json"
	"github.com/zmb3/spotify/v2"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/trace"
	earbugv5 "go.seankhliao.com/mono/earbug/v5"
	"golang.org/x/oauth2"
	"google.golang.org/protobuf/types/known/durationpb"
)

func (a *App) update(ctx context.Context) {
	ctx, span := a.o.T.Start(ctx, "update all recently played")
	defer span.End()

	ctx = context.WithValue(ctx, oauth2.HTTPClient, a.http)

	clients := make(map[int64]spotify.Client)
	a.store.RDo(ctx, func(s *earbugv5.Store) {
		for userID, userData := range s.GetUsers() {
			var token oauth2.Token
			err := json.Unmarshal(userData.GetToken(), &token)
			if err != nil {
				continue
			}
			clients[userID] = *spotify.New(a.oauth2.Client(ctx, &token))
		}
	})

	var added, totalTracks int64
	for userID, spot := range clients {
		a.o.Region(ctx, "update user recently played", func(ctx context.Context, span trace.Span) error {
			span.SetAttributes(attribute.Int64("user.id", userID))
			var userAdded, userPlaybacks int64

			items, err := spot.PlayerRecentlyPlayedOpt(ctx, &spotify.RecentlyPlayedOptions{Limit: 50})
			if err != nil {
				return a.o.Err(ctx, "get recently played", err)
			}

			a.store.Do(ctx, func(s *earbugv5.Store) {
				for _, item := range items {
					ts := item.PlayedAt.Format(time.RFC3339Nano)
					if _, ok := s.GetUsers()[userID].GetPlaybacks()[ts]; !ok {
						userAdded++
						s.GetUsers()[userID].GetPlaybacks()[ts] = earbugv5.Playback_builder{
							TrackId:     ptr(item.Track.ID.String()),
							TrackUri:    ptr(string(item.Track.URI)),
							ContextType: ptr(item.PlaybackContext.Type),
							ContextUri:  ptr(string(item.PlaybackContext.URI)),
						}.Build()
					}

					if _, ok := s.GetTracks()[item.Track.ID.String()]; !ok {
						t := earbugv5.Track_builder{
							Id:       ptr(item.Track.ID.String()),
							Uri:      ptr(string(item.Track.URI)),
							Type:     ptr(item.Track.Type),
							Name:     ptr(item.Track.Name),
							Duration: durationpb.New(item.Track.TimeDuration()),
						}.Build()
						for _, artist := range item.Track.Artists {
							t.SetArtists(append(t.GetArtists(), earbugv5.Artist_builder{
								Id:   ptr(artist.ID.String()),
								Uri:  ptr(string(artist.URI)),
								Name: ptr(artist.Name),
							}.Build()))
						}
						s.GetTracks()[item.Track.ID.String()] = t
					}

				}

				userPlaybacks = int64(len(s.GetUsers()[userID].GetPlaybacks()))
				totalTracks = int64(len(s.GetTracks()))
			})

			a.mAdded.Add(ctx, userAdded, metric.WithAttributes(attribute.Int64("user.id", userID)))
			a.mPlaybacks.Record(ctx, userPlaybacks, metric.WithAttributes(attribute.Int64("user.id", userID)))
			added += userAdded
			return nil
		})
	}

	a.mTracks.Record(ctx, totalTracks)
	if added > 0 {
		a.o.L.LogAttrs(ctx, slog.LevelInfo, "updated record", slog.Int64("added", added))
		a.store.Sync(ctx)
	}
}
