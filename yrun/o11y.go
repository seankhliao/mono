package yrun

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"os"
	"path"
	"runtime/debug"
	"strings"

	"go.opentelemetry.io/contrib/instrumentation/runtime"
	"go.opentelemetry.io/contrib/zpages"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/metric/noop"
	"go.opentelemetry.io/otel/propagation"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/trace"
	tracenoop "go.opentelemetry.io/otel/trace/noop"
	"go.seankhliao.com/mono/observability/jsonlog"
)

const defaultServiceConfig = `{"loadBalancingConfig":[{"round_robin":{}}]}`

type O11yConfig struct {
	Log    LogConfig
	Metric MetricConfig
	Trace  TraceConfig
}

type O11yReg struct {
	LogZpage   http.Handler
	TraceZpage http.Handler
}

type O11y struct {
	T trace.Tracer
	M metric.Meter
	L *slog.Logger
	H slog.Handler
}

func NewO11y(c O11yConfig) (O11y, O11yReg) {
	var r O11yReg

	bi, _ := debug.ReadBuildInfo()
	fullname := bi.Main.Path
	d, shortName := path.Split(fullname)
	if strings.HasPrefix(shortName, "v") && !strings.ContainsAny(shortName[1:], "abcdefghijklmnopqrstuvwxyz-") {
		shortName = path.Base(d)
	}

	_ = shortName

	var o O11y
	o.L, o.H, r.LogZpage = NewLog(c.Log)

	ctx := context.Background()

	// otel error handling
	otelLog := o.L.WithGroup("otel")
	otel.SetErrorHandler(otel.ErrorHandlerFunc(func(err error) {
		otelLog.LogAttrs(ctx, slog.LevelWarn, "otel error",
			slog.String("error", err.Error()),
		)
	}))

	var err error
	r.TraceZpage, err = NewTrace(ctx, c.Trace)
	if err != nil {
		otelLog.LogAttrs(ctx, slog.LevelWarn, "failed to create trace exporter", slog.String("error", err.Error()))
		otel.SetTracerProvider(tracenoop.NewTracerProvider())
	}
	o.T = otel.Tracer(shortName)

	err = NewMetric(ctx, c.Metric)
	if err != nil {
		otelLog.LogAttrs(ctx, slog.LevelWarn, "failed to create metric exporter", slog.String("error", err.Error()))
		otel.SetMeterProvider(noop.NewMeterProvider())
	}
	o.M = otel.Meter(shortName)

	runtime.Start()

	return o, r
}

type LogConfig struct {
	Format string
	Level  slog.Level
}

func NewLog(c LogConfig) (*slog.Logger, slog.Handler, http.Handler) {
	zpage := jsonlog.NewZPage(256)
	writer := io.MultiWriter(os.Stderr, zpage)
	var handler slog.Handler
	switch c.Format {
	case "json":
		handler = jsonlog.New(c.Level, writer)
	case "text":
		fallthrough
	default:
		handler = slog.NewTextHandler(writer, &slog.HandlerOptions{Level: c.Level})
	}
	logger := slog.New(handler)
	return logger, handler, zpage
}

type MetricConfig struct{}

func NewMetric(ctx context.Context, c MetricConfig) error {
	me, err := otlpmetricgrpc.New(ctx,
		otlpmetricgrpc.WithServiceConfig(defaultServiceConfig),
	)
	if err != nil {
		return err
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
	return nil
}

type TraceConfig struct{}

func NewTrace(ctx context.Context, c TraceConfig) (http.Handler, error) {
	ztrace := zpages.NewSpanProcessor()
	traceZpage := zpages.NewTracezHandler(ztrace)

	te, err := otlptracegrpc.New(ctx,
		otlptracegrpc.WithServiceConfig(defaultServiceConfig),
	)
	if err != nil {
		return nil, err
	}
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(te),
		sdktrace.WithSpanProcessor(ztrace),
	)
	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.Baggage{},
		propagation.TraceContext{},
	))

	return traceZpage, nil
}
