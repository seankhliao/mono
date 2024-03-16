package spanlog

import (
	"context"
	"log/slog"
	"path"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.24.0"
)

var _ trace.SpanProcessor = &Processor{}

// Processor is a [go.opentelemetry.io/otel/sdk/trace.SpanProcessor]
// that converts span start/end and events into log lines.
// Span start is [log/slog.LevelDebug].
// Span end is [log/slog.LevelInfo] or [log/slog.LevelError] if the span status is
// [go.opentelemetry.io/otel/codes.Error].
// Events are normally [log/slog.LevelDebug], and [log/slog.LevelWarn] if the span status is
// [go.opentelemetry.io/otel/codes.Error],
// and [log/slog.LevelError] if created by [go.opentelemetry.io/otel/trace.Span.RecordError].
type Processor struct {
	// LogID controls whether span_id and trace_id are logged
	LogID bool
	// Handler is where the output is sent.
	// Span metadata such as trace_id, span_id, span type, duration, etc.
	// are grouped under "span".
	// Span names are used as the message,
	// span attributes grouped under the instrumentation scope base name.
	Handler slog.Handler
}

func (p *Processor) commonAttrs(s trace.ReadOnlySpan, attrs ...slog.Attr) []slog.Attr {
	n := make([]slog.Attr, 0, len(attrs)+2)
	if p.LogID {
		n = append(attrs,
			slog.String("trace_id", s.SpanContext().TraceID().String()),
			slog.String("span_id", s.SpanContext().SpanID().String()),
		)
	}
	n = append(n, attrs...)
	return n
}

func (p *Processor) OnStart(parent context.Context, s trace.ReadWriteSpan) {
	ctx := context.Background()
	// span start: debug
	if p.Handler.Enabled(ctx, slog.LevelDebug) {
		h := p.Handler.WithAttrs(p.commonAttrs(s,
			slog.Group("span",
				slog.String("type", "start"),
			),
		))
		h = h.WithGroup(path.Base(s.InstrumentationScope().Name))
		rec := slog.NewRecord(s.StartTime(), slog.LevelDebug, s.Name(), 0)
		rec.AddAttrs(attr2attr(s.Attributes())...)
		h.Handle(ctx, rec)
	}
}

func (p *Processor) OnEnd(s trace.ReadOnlySpan) {
	ctx := context.Background()

	// events: debug or warn
	level := slog.LevelDebug
	if s.Status().Code == codes.Error {
		level = slog.LevelWarn
	}
	if p.Handler.Enabled(ctx, level) {
		h := p.Handler.WithAttrs(p.commonAttrs(s,
			slog.Group("span",
				slog.String("type", "event"),
			),
		))
		h = h.WithGroup(path.Base(s.InstrumentationScope().Name))
		for _, event := range s.Events() {
			level := level
			if event.Name == semconv.ExceptionEventName {
				level = slog.LevelError
			}
			rec := slog.NewRecord(event.Time, level, event.Name, 0)
			rec.AddAttrs(attr2attr(event.Attributes)...)
			h.Handle(ctx, rec)
		}
	}

	// span end: info or error
	level = slog.LevelInfo
	if s.Status().Code == codes.Error {
		level = slog.LevelError
	}
	if p.Handler.Enabled(ctx, level) {
		spanAttrs := make([]any, 0, 3)
		spanAttrs = append(spanAttrs,
			slog.String("type", "end"),
			slog.Duration("duration", s.EndTime().Sub(s.StartTime())),
		)
		if s.Status().Code != codes.Unset {
			spanAttrs = append(spanAttrs, slog.Group("status",
				slog.String("code", s.Status().Code.String()),
				slog.String("description", s.Status().Description),
			))
		}
		h := p.Handler.WithAttrs(p.commonAttrs(s,
			slog.Group("span", spanAttrs...),
		))
		h = h.WithGroup(path.Base(s.InstrumentationScope().Name))
		rec := slog.NewRecord(s.EndTime(), level, s.Name(), 0)
		rec.AddAttrs(attr2attr(s.Attributes())...)
		h.Handle(ctx, rec)
	}
}

func (p *Processor) Shutdown(ctx context.Context) error   { return nil }
func (p *Processor) ForceFlush(ctx context.Context) error { return nil }

func attr2attr(attrs []attribute.KeyValue) []slog.Attr {
	out := make([]slog.Attr, 0, len(attrs))
	for _, attr := range attrs {
		switch attr.Value.Type() {
		case attribute.BOOL:
			out = append(out, slog.Bool(string(attr.Key), attr.Value.AsBool()))
		case attribute.INT64:
			out = append(out, slog.Int64(string(attr.Key), attr.Value.AsInt64()))
		case attribute.FLOAT64:
			out = append(out, slog.Float64(string(attr.Key), attr.Value.AsFloat64()))
		case attribute.STRING:
			out = append(out, slog.String(string(attr.Key), attr.Value.AsString()))
		default:
			out = append(out, slog.Any(string(attr.Key), attr.Value.AsInterface()))
		}
	}
	return out
}
