package earbug

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/go-json-experiment/json"
	"github.com/zmb3/spotify/v2"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/earbug/earbugv5"
	"golang.org/x/oauth2"
)

func (a *App) FillAudioFeatures() error {
	wait := time.Minute
	for {
		time.Sleep(wait)
		wait = a.backfillAudioFeatures()
	}
}

func (a *App) backfillAudioFeatures() time.Duration {
	ctx := context.Background()
	ctx, span := a.o.T.Start(ctx, "audio features backfill")
	defer span.End()

	token := new(oauth2.Token)
	var backfillTrackIDs []spotify.ID
	a.o.Region(ctx, "check for backfill ids", func(ctx context.Context, span trace.Span) error {
		a.store.RDo(ctx, func(s *earbugv5.Store) {
			for _, t := range s.GetTracks() {
				if t.Features == nil {
					backfillTrackIDs = append(backfillTrackIDs, spotify.ID(t.GetId()))
				}
				if len(backfillTrackIDs) >= 100 {
					break
				}
			}
			if len(backfillTrackIDs) > 0 {
				for _, u := range s.Users {
					if rawToken := u.GetToken(); len(rawToken) > 0 {
						err := json.Unmarshal(rawToken, token)
						if err != nil {
							continue
						}
						break
					}
				}
			}
		})
		return nil
	})

	if len(backfillTrackIDs) == 0 {
		return time.Hour
	}

	err := a.o.Region(ctx, "backfill audio features", func(ctx context.Context, span trace.Span) error {
		if token == nil {
			return fmt.Errorf("no oauth2 token")
		}
		client := spotify.New(a.oauth2.Client(ctx, token))

		trackFeatures, err := client.GetAudioFeatures(ctx, backfillTrackIDs...)
		if err != nil {
			return fmt.Errorf("get audio features: %w", err)
		}
		a.store.Do(ctx, func(s *earbugv5.Store) {
			for _, feat := range trackFeatures {
				track := s.Tracks[feat.ID.String()]
				track.Features = &earbugv5.AudioFeatures{
					Acousticness:     ptr(feat.Acousticness),
					Danceability:     ptr(feat.Danceability),
					Energy:           ptr(feat.Energy),
					Instrumentalness: ptr(feat.Instrumentalness),
					Key:              ptr(int32(feat.Key)),
					Liveness:         ptr(feat.Liveness),
					Loudness:         ptr(feat.Loudness),
					Mode:             ptr(int32(feat.Mode)),
					Speechiness:      ptr(feat.Speechiness),
					Tempo:            ptr(feat.Tempo),
					TimeSignature:    ptr(int32(feat.TimeSignature)),
					Valence:          ptr(feat.Valence),
				}
				s.Tracks[track.GetId()] = track
			}
		})
		return nil
	})
	if err != nil {
		a.o.Err(ctx, "backfill err", err)
		return 5 * time.Minute
	}

	a.o.L.LogAttrs(ctx, slog.LevelInfo, "backfill run", slog.Int("backfill.tracks", len(backfillTrackIDs)))
	if len(backfillTrackIDs) == 100 {
		return time.Minute
	}
	return time.Hour
}
