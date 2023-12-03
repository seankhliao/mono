package main

import (
	"encoding/json"
	"errors"
	"net/http"

	"go.etcd.io/bbolt"
)

var ErrNoSession = errors.New("session not found")

func (a *App) apiv1SessionToken() http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := a.o.T.Start(r.Context(), "apiv1SessionToken")
		defer span.End()

		token := r.PathValue("token")
		if token == "" {
			err := errors.New("token not in path")
			a.jsonErr(ctx, rw, "no token provided", err, http.StatusBadRequest, err)
			return
		}

		var info SessionInfo
		err := a.db.View(func(tx *bbolt.Tx) error {
			bkt := tx.Bucket(bucketSession)
			rawInfo := bkt.Get([]byte(token))
			if len(rawInfo) == 0 {
				return ErrNoSession
			}
			return json.Unmarshal(rawInfo, &info)
		})
		if err != nil {
			a.jsonErr(ctx, rw, "lookup session token", err, http.StatusNotFound, err)
			return
		}

		a.jsonOk(ctx, rw, info)
	})
}
