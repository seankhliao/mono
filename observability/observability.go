package observability

import (
	"context"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"path"
	"runtime/debug"
	"strings"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/propagation"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/observability/jsonlog"
)

type Config struct {
	LogFormat string
	LogOutput io.Writer
	LogLevel  slog.Level
}

func (c *Config) SetFlags(f *flag.FlagSet) {
	f.TextVar(&c.LogLevel, "log.level", slog.LevelInfo, "log level: debug|info|warn|error")
	c.LogFormat = "json" // default
	f.Func("log.format", "log format: logfmt|json", func(s string) error {
		switch s {
		case "logfmt", "json":
		default:
			return fmt.Errorf("unknown log format: %q", s)
		}
		c.LogFormat = s
		return nil
	})
}

type O struct {
	N string
	L *slog.Logger
	H slog.Handler
	T trace.Tracer
	M metric.Meter

	ZLogs http.Handler
}

func New(c *Config) *O {
	o := &O{}

	bi, _ := debug.ReadBuildInfo()
	fullname := bi.Main.Path
	d, b := path.Split(fullname)
	if strings.HasPrefix(b, "v") && !strings.ContainsAny(b[1:], "abcdefghijklmnopqrstuvwxyz-") {
		b = path.Base(d)
	}
	o.N = b

	defer func() {
		// always set instrumentation, even if they may be noops
		o.T = otel.Tracer(fullname)
		o.M = otel.Meter(fullname)
	}()

	out := c.LogOutput
	if out == nil {
		out = os.Stdout
	}

	zlogs := jsonlog.NewZPage(256)
	out = io.MultiWriter(out, zlogs)

	switch c.LogFormat {
	case "json":
		o.H = jsonlog.New(c.LogLevel, out)
	case "logfmt":
		o.H = slog.NewTextHandler(out, &slog.HandlerOptions{
			Level: c.LogLevel,
		})
	}
	o.L = slog.New(o.H)
	o.ZLogs = zlogs

	if os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT") != "" {
		ctx := context.Background()

		// opentelemetry error handler
		otelLog := o.L.WithGroup("otel")
		otel.SetErrorHandler(otel.ErrorHandlerFunc(func(err error) {
			otelLog.LogAttrs(ctx, slog.LevelWarn, "otel error",
				slog.String("error", err.Error()),
			)
		}))

		// grpc common
		serviceConfig := `{"loadBalancingConfig":[{"round_robin":{}}]}`

		// tracing
		te, err := otlptracegrpc.New(ctx,
			otlptracegrpc.WithServiceConfig(serviceConfig),
		)
		if err != nil {
			otelLog.LogAttrs(ctx, slog.LevelError, "create trace exporter",
				slog.String("error", err.Error()),
			)
			return o
		}
		tp := sdktrace.NewTracerProvider(
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
			otelLog.LogAttrs(ctx, slog.LevelError, "create metric exporter",
				slog.String("error", err.Error()),
			)
			return o
		}
		mp := sdkmetric.NewMeterProvider(
			sdkmetric.WithReader(
				sdkmetric.NewPeriodicReader(me),
			),
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
		)
		otel.SetMeterProvider(mp)
	}

	return o
}

func (o *O) Component(name string) *O {
	return &O{
		N: o.N,
		L: o.L.WithGroup(name),
		H: o.H.WithGroup(name),
		T: o.T,
		M: o.M,
	}
}
