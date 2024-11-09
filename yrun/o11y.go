package yrun

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"path"
	"runtime/debug"
	"strings"

	"github.com/go-json-experiment/json"
	"go.opentelemetry.io/contrib/bridges/otelslog"
	"go.opentelemetry.io/contrib/instrumentation/runtime"
	"go.opentelemetry.io/contrib/zpages"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploggrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/log/global"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/metric/noop"
	"go.opentelemetry.io/otel/propagation"
	sdklog "go.opentelemetry.io/otel/sdk/log"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/trace"
	tracenoop "go.opentelemetry.io/otel/trace/noop"
	"go.seankhliao.com/mono/observability/jsonlog"
	"go.seankhliao.com/mono/observability/multilog"
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

func (o O11y) Sub(name string) O11y {
	return O11y{
		T: otel.Tracer(name),
		M: otel.Meter(name),
		L: o.L.WithGroup(name),
		H: o.H.WithGroup(name),
	}
}

func (o O11y) Region(ctx context.Context, name string, do func(ctx context.Context, span trace.Span) error) error {
	ctx, span := o.T.Start(ctx, name)
	defer span.End()

	err := do(ctx, span)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, name)
	}
	return err
}

func (o O11y) Err(ctx context.Context, msg string, err error, attrs ...slog.Attr) error {
	o.L.LogAttrs(ctx, slog.LevelError, msg,
		append(attrs, slog.String("error", err.Error()))...,
	)
	if span := trace.SpanFromContext(ctx); span.SpanContext().IsValid() {
		span.RecordError(err)
		span.SetStatus(codes.Error, msg)
	}

	return fmt.Errorf("%s: %w", msg, err)
}

func (o O11y) HTTPErr(ctx context.Context, msg string, err error, rw http.ResponseWriter, code int, attrs ...slog.Attr) {
	err = o.Err(ctx, msg, err, attrs...)
	header := propagation.HeaderCarrier(rw.Header())
	propagation.TraceContext{}.Inject(ctx, header)
	rw.Header().Set("content-type", "application/json")
	json.MarshalWrite(rw, problemDetails{
		Type:     "custom", // TODO: custom error types
		Title:    msg,
		Status:   code,
		Detail:   err.Error(),
		Instance: rw.Header().Get("traceparent"),
	})
}

type problemDetails struct {
	Type     string `json:"type"`
	Title    string `json:"title"`
	Status   int    `json:"status"`
	Detail   string `json:"detail"`
	Instance string `json:"instance"`
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

	ctx := context.Background()

	var o O11y
	var err error
	o.L, o.H, r.LogZpage, err = NewLog(ctx, c.Log)
	if err != nil {
		panic(err)
	}

	// otel error handling
	otelLog := o.L.WithGroup("otel")
	otel.SetErrorHandler(otel.ErrorHandlerFunc(func(err error) {
		otelLog.LogAttrs(ctx, slog.LevelWarn, "otel error",
			slog.String("error", err.Error()),
		)
	}))

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

func NewLog(ctx context.Context, c LogConfig) (*slog.Logger, slog.Handler, http.Handler, error) {
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

	le, err := otlploggrpc.New(ctx,
		otlploggrpc.WithServiceConfig(defaultServiceConfig),
	)
	if err != nil {
		return nil, nil, nil, err
	}

	lp := sdklog.NewLoggerProvider(
		sdklog.WithProcessor(
			sdklog.NewBatchProcessor(le),
		),
	)
	global.SetLoggerProvider(lp)

	oh := otelslog.NewHandler("")
	handler = multilog.Handler(oh, handler)

	logger := slog.New(handler)
	return logger, handler, zpage, nil
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
