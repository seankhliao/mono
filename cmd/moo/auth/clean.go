package auth

import (
	"context"
	"time"

	"go.seankhliao.com/mono/cmd/moo/auth/authv1"
)

func (a *App) CleanSessions() error {
	for range time.NewTimer(6 * time.Hour).C {
		ctx := context.Background()
		a.store.Do(ctx, func(s *authv1.Store) {
			for k, v := range s.Sessions {
				if v.GetUserId() <= 0 && time.Since(v.GetCreated().AsTime()) >= 24*time.Hour {
					delete(s.Sessions, k)
				} else if v.GetUserId() > 0 && time.Since(v.GetCreated().AsTime()) >= 7*24*time.Hour {
					delete(s.Sessions, k)
				}
			}
		})
	}
	return nil
}
