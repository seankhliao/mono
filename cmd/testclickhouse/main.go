package main

import (
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"time"

	"github.com/ClickHouse/clickhouse-go/v2"
	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/observability"
)

func main() {
	framework.Run(framework.Config{
		Start: func(ctx context.Context, o *observability.O, sm *http.ServeMux) (cleanup func(), err error) {
			conn, err := connect()
			if err != nil {
				return nil, o.Err(ctx, "connect", err)
			}
			go func() {
				for range time.NewTicker(5 * time.Second).C {
					o.L.LogAttrs(ctx, slog.LevelInfo, "ping db", slog.Any("err", conn.Ping(ctx)))
				}
			}()

			sm.HandleFunc("/dump", func(w http.ResponseWriter, r *http.Request) {
				ctx := r.Context()
				var obj map[string]any
				b, _ := io.ReadAll(r.Body)
				err := json.Unmarshal(b, &obj)
				o.L.LogAttrs(ctx, slog.LevelInfo, "dump", slog.Any("obj", obj), slog.Any("err", err))
			})

			return func() { conn.Close() }, nil
		},
	})
}

func connect() (clickhouse.Conn, error) {
	return clickhouse.Open(&clickhouse.Options{
		Addr: []string{"clickhouse-clickhouses.clickhouse-operator.svc.cluster.local:9000"},
		Auth: clickhouse.Auth{
			Database: "default",
			Username: "user",
			Password: "user",
		},
		Compression: &clickhouse.Compression{
			Method: clickhouse.CompressionZSTD,
		},
		DialTimeout:          time.Second * 30,
		MaxOpenConns:         5,
		MaxIdleConns:         5,
		ConnMaxLifetime:      time.Duration(10) * time.Minute,
		ConnOpenStrategy:     clickhouse.ConnOpenInOrder,
		BlockBufferSize:      10,
		MaxCompressionBuffer: 10240,
	})
}
