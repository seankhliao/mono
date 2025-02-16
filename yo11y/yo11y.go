// yo11y contains helpers for setting up the opentelemetry (otel) sdk.
// The sdks primarily take configuration from the "OTEL_" environment variables.
package yo11y

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
	"go.opentelemetry.io/otel/attribute"
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
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.27.0"
	"go.opentelemetry.io/otel/trace"
	tracenoop "go.opentelemetry.io/otel/trace/noop"
	"go.seankhliao.com/mono/jsonlog"
	"go.seankhliao.com/mono/multilog"
)

const defaultServiceConfig = `{"loadBalancingConfig":[{"round_robin":{}}]}`

type Config struct {
	LogLevel  slog.Level `env:"LOG_LEVEL"`
	LogFormat string     `env:"LOG_FORMAT"`
}

type O11y struct {
	T trace.Tracer
	M metric.Meter
	L *slog.Logger
	H slog.Handler

	component string
	errCount  metric.Int64Counter
}

type O11yReg struct {
	LogZpage   http.Handler
	TraceZpage http.Handler

	ShutTrace  func(context.Context) error
	ShutMetric func(context.Context) error
}

func (o O11y) Sub(name string) O11y {
	o2 := O11y{
		T:         otel.Tracer(name),
		M:         otel.Meter(name),
		L:         o.L.WithGroup(name),
		H:         o.H.WithGroup(name),
		component: name,
		errCount:  o.errCount,
	}
	if o.component != "" {
		o2.component = o.component + "." + o2.component
	}
	return o2
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
	o.errCount.Add(ctx, 1, metric.WithAttributes(attribute.String("component", o.component)))
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

func New(c Config) (O11y, O11yReg) {
	var r O11yReg

	bi, _ := debug.ReadBuildInfo()
	fullname := bi.Path
	d, shortName := path.Split(fullname)
	if strings.HasPrefix(shortName, "v") && !strings.ContainsAny(shortName[1:], "abcdefghijklmnopqrstuvwxyz-") {
		shortName = path.Base(d)
	}
	res, _ := resource.Merge(
		resource.Default(),
		resource.NewSchemaless(
			semconv.ServiceName(bi.Path),
			semconv.ServiceVersion(bi.Main.Version),
		),
	)

	ctx := context.Background()

	var o O11y
	var err error
	o.L, o.H, r.LogZpage, err = NewLog(ctx, res, c)
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

	r.TraceZpage, r.ShutTrace, err = NewTrace(ctx, res, c)
	if err != nil {
		otelLog.LogAttrs(ctx, slog.LevelWarn, "failed to create trace exporter", slog.String("error", err.Error()))
		otel.SetTracerProvider(tracenoop.NewTracerProvider())
	}
	o.T = otel.Tracer(shortName)

	r.ShutMetric, err = NewMetric(ctx, res, c)
	if err != nil {
		otelLog.LogAttrs(ctx, slog.LevelWarn, "failed to create metric exporter", slog.String("error", err.Error()))
		otel.SetMeterProvider(noop.NewMeterProvider())
	}
	o.M = otel.Meter(shortName)

	o.errCount, _ = o.M.Int64Counter("mono.error", metric.WithUnit("error"))

	runtime.Start()

	return o, r
}

func NewLog(ctx context.Context, res *resource.Resource, c Config) (*slog.Logger, slog.Handler, http.Handler, error) {
	zpage := jsonlog.NewZPage(256)
	writer := io.MultiWriter(os.Stderr, zpage)
	var handler slog.Handler
	switch c.LogFormat {
	case "json":
		handler = jsonlog.New(c.LogLevel, writer)
	case "text":
		fallthrough
	default:
		handler = slog.NewTextHandler(writer, &slog.HandlerOptions{Level: c.LogLevel})
	}

	le, err := otlploggrpc.New(ctx,
		otlploggrpc.WithServiceConfig(defaultServiceConfig),
	)
	if err != nil {
		return nil, nil, nil, err
	}

	lp := sdklog.NewLoggerProvider(
		sdklog.WithResource(res),
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

func NewMetric(ctx context.Context, res *resource.Resource, c Config) (func(context.Context) error, error) {
	me, err := otlpmetricgrpc.New(ctx,
		otlpmetricgrpc.WithServiceConfig(defaultServiceConfig),
	)
	if err != nil {
		return nil, err
	}
	mp := sdkmetric.NewMeterProvider(
		sdkmetric.WithResource(res),
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

	return me.Shutdown, nil
}

func NewTrace(ctx context.Context, res *resource.Resource, c Config) (http.Handler, func(context.Context) error, error) {
	ztrace := zpages.NewSpanProcessor()
	traceZpage := zpages.NewTracezHandler(ztrace)

	te, err := otlptracegrpc.New(ctx,
		otlptracegrpc.WithServiceConfig(defaultServiceConfig),
	)
	if err != nil {
		return nil, nil, err
	}
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithResource(res),
		sdktrace.WithBatcher(te),
		sdktrace.WithSpanProcessor(ztrace),
	)
	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.Baggage{},
		propagation.TraceContext{},
	))

	return traceZpage, te.Shutdown, nil
}
