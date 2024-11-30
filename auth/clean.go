package auth

import (
	"context"
	"time"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
	authv1 "go.seankhliao.com/mono/auth/v1"
)

func (a *App) CleanSessions() error {
	for range time.NewTimer(6 * time.Hour).C {
		ctx := context.Background()
		var anon, admin, user int64
		a.store.Do(ctx, func(s *authv1.Store) {
			for k, v := range s.Sessions {
				expiry := 24 * time.Hour
				switch {
				case v.GetUserId() < 0:
					anon++
				case v.GetUserId() == 0:
					admin++
				case v.GetUserId() > 0:
					user++
					expiry = 7 * 24 * time.Hour
				}
				if time.Since(v.GetCreated().AsTime()) >= expiry {
					delete(s.Sessions, k)
				}
			}
		})
		a.mSessions.Record(ctx, anon, metric.WithAttributes(attribute.String("authstate", "anonymous")))
		a.mSessions.Record(ctx, admin, metric.WithAttributes(attribute.String("authstate", "admin")))
		a.mSessions.Record(ctx, user, metric.WithAttributes(attribute.String("authstate", "registered")))
	}
	return nil
}
