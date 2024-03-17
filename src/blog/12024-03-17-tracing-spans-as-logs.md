# tracing spans as logs

## a common event system?

### _spans_ as logs 

In observability, 
(distributed) tracing with its spans covering a range of time,
has quite a significant overlap with logging.
This is especially true if you buy into wide events 
where each span or log line carries a large amount of extra information
in structured attributes.

All this got me wondering, 
why should I log everything two or more times?
For example, in Go you pass the error to tracing, to logs,
and maybe pass it back up the stack 
(whether you both log and pass back up is debatable):

```go
func foo(ctx context.Context) error {
        ctx, span := tracer.Start(ctx, "foo")
        defer span.End()

        err := bar("fizzz")
        if err != nil {
                span.RecordError(err, trace.WithAttributes(
                        attribute.String("arg", "fizzz")
                ))
                span.SetStatus(codes.Error, "doing bar failed")
                slog.Debug("doing bar failed", "err", err, slog.String("arg", "fizzz"))
                return fmt.Errorf("doing bar failed: %w", err)
        }

        return nil
}
```

What I also found to be an inconvenience was the differing attribute systems 
between tracing with OpenTelemetry and logging with log/slog.
So it occured to me that if I pass the same information to both,
I could drive the lower fidelty logging from the information I pass to tracing.

#### _spanlog_ processor 

##### _decisions_

The first point of decision is do we make a span exporter or processor?
It didn't take too much thinking to conclude that a processor was more appropriate 
since it was somewhat closer to realtime rather than receiving batched events for export.
This was something I considered important with logging as you want logs at the point of a crash.

The second point was do we take a slog.Logger or slog.Handler?
I started with Logger, 
but soon realized I needed use the time recorded from events,
so switched to Handler.

And finally, what level do we log at?
I went with debug for most, info for span ends, and warn/error when a span was marked for error.

##### _problems_

I think the output most works, 
but I did see some issues.
First was the (potentially) out of order output of events in parallel:
events are only processed on span end, so they may be delayed by quite a bit before they are output.
Second was it was unclear how to log singular events,
e.g. I like to log the port when an http server starts,
but since an http server blocks until the end,
where do I put a span.
Plus, all the other systems that expect a simple logger,
what do I give them (so far, it ends up being we still need a normal logger).

##### _implementation_

```go
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

func (p *Processor) appendCommon(attrs []slog.Attr, s trace.ReadOnlySpan) []slog.Attr {
        if p.LogID {
                attrs = append(attrs,
                        slog.String("trace_id", s.SpanContext().TraceID().String()),
                        slog.String("span_id", s.SpanContext().SpanID().String()),
                )
        }
        return attrs
}

func (p *Processor) OnStart(parent context.Context, s trace.ReadWriteSpan) {
        ctx := context.Background()
        // span start: debug
        if p.Handler.Enabled(ctx, slog.LevelDebug) {
                attrs := p.appendCommon(make([]slog.Attr, 0, 10), s)
                attrs = append(attrs,
                        slog.Group("span", slog.String("type", "start")),
                        slog.Any(path.Base(s.InstrumentationScope().Name), slog.GroupValue(attr2attr(s.Attributes())...)),
                )
                rec := slog.NewRecord(s.StartTime(), slog.LevelDebug, s.Name(), 0)
                rec.AddAttrs(attrs...)
                p.Handler.Handle(ctx, rec)
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
                attrs := p.appendCommon(make([]slog.Attr, 0, 10), s)
                attrs = append(attrs, slog.Group("span", slog.String("type", "event")))
                attrs = p.appendCommon(attrs, s)
                h := p.Handler.WithAttrs(attrs).WithGroup(path.Base(s.InstrumentationScope().Name))
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
                spanAttrs := make([]slog.Attr, 0, 3)
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

                attrs := p.appendCommon(make([]slog.Attr, 0, 10), s)
                attrs = append(attrs,
                        slog.Any("span", slog.GroupValue(spanAttrs...)),
                        slog.Any(path.Base(s.InstrumentationScope().Name), slog.GroupValue(attr2attr(s.Attributes())...)),
                )
                rec := slog.NewRecord(s.EndTime(), level, s.Name(), 0)
                rec.AddAttrs(attrs...)
                p.Handler.Handle(ctx, rec)
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
```
