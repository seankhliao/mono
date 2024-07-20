package spanlog_test

import (
	"context"
	"errors"
	"log/slog"
	"os"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/sdk/trace/tracetest"
	apitrace "go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/spanlog"
)

func ExampleProcessor() {
	tp := trace.NewTracerProvider(
		trace.WithSpanProcessor(
			&spanlog.Processor{
				LogID: true,
				Handler: slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
					Level: slog.LevelDebug,
				}),
			},
		),
		trace.WithSyncer(tracetest.NewNoopExporter()),
	)

	tr := tp.Tracer("testing")

	func() {
		ctx := context.Background()
		ctx, span := tr.Start(ctx, "level 1", apitrace.WithAttributes(
			attribute.Bool("l1 k1", true),
		))
		defer span.End()

		span.SetAttributes(
			attribute.String("l1 k2", "aaa"),
		)

		span.AddEvent("l1 e1", apitrace.WithAttributes(
			attribute.String("l1 k3", "bar"),
		))

		func() {
			ctx, span := tr.Start(ctx, "level 2a", apitrace.WithAttributes(
				attribute.Int64("l2a k1", 567),
			))
			defer span.End()

			_ = ctx

			span.AddEvent("l2a e1", apitrace.WithAttributes(
				attribute.Float64("l2a k3", 976.765),
			))
		}()

		func() {
			ctx, span := tr.Start(ctx, "level 2b", apitrace.WithAttributes(
				attribute.String("l2b k1", "sdfghjk"),
			))
			defer span.End()

			span.RecordError(errors.New("oops"), apitrace.WithAttributes(
				attribute.Bool("l2b k2", false),
			))

			_ = ctx

			span.SetStatus(codes.Error, "an error occurred")

			span.AddEvent("l2b e2", apitrace.WithAttributes(
				attribute.Float64("l2b k3", 976.765),
			))
		}()
	}()
}
