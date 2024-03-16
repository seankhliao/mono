package serve

import (
	"context"
	"fmt"
	"io"
	"log/slog"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.24.0"
	"go.seankhliao.com/mono/spanlog"
)

func NewTelemetry(ctx context.Context, c Config, out io.Writer) (func(), *slog.Logger, error) {
	lh := slog.NewTextHandler(out, &slog.HandlerOptions{
		Level: c.Log.Level,
	})
	lg := slog.New(lh)

	olg := lg.WithGroup("otel")
	otel.SetErrorHandler(otel.ErrorHandlerFunc(func(cause error) {
		olg.Warn("opentelemetry", "err", cause)
	}))

	res, err := resource.New(ctx,
		resource.WithFromEnv(),
		resource.WithTelemetrySDK(),
		resource.WithProcess(),
		resource.WithHost(),
		resource.WithContainer(),
		resource.WithAttributes(
			semconv.ServiceName("mono"),
		),
	)
	if err != nil {
		return nil, nil, fmt.Errorf("create otel resource: %w", err)
	}

	// grpc common
	serviceConfig := `{"loadBalancingConfig":[{"round_robin":{}}]}`

	// tracing
	te, err := otlptracegrpc.New(ctx,
		otlptracegrpc.WithServiceConfig(serviceConfig),
	)
	if err != nil {
		return nil, nil, fmt.Errorf("create trace exporter: %w", err)
	}
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithResource(res),
		sdktrace.WithSpanProcessor(&spanlog.Processor{
			Handler: lh,
		}),
		sdktrace.WithBatcher(te),
	)
	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.Baggage{},
		propagation.TraceContext{},
	))

	// metrics
	me, err := otlpmetricgrpc.New(ctx,
		otlpmetricgrpc.WithServiceConfig(serviceConfig),
	)
	if err != nil {
		return nil, nil, fmt.Errorf("create metric exporter: %w", err)
	}
	mp := sdkmetric.NewMeterProvider(
		sdkmetric.WithResource(res),
		sdkmetric.WithView(
			sdkmetric.NewView(sdkmetric.Instrument{
				Kind: sdkmetric.InstrumentKindHistogram,
			}, sdkmetric.Stream{
				Aggregation: sdkmetric.AggregationBase2ExponentialHistogram{
					MaxSize:  160,
					MaxScale: 20,
				},
			}),
		),
		sdkmetric.WithReader(
			sdkmetric.NewPeriodicReader(me),
		),
	)
	otel.SetMeterProvider(mp)

	return func() {
		tp.Shutdown(context.Background())
		mp.Shutdown(context.Background())
	}, lg, nil
}
