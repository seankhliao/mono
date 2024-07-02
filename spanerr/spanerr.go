package spanerr

import (
	"fmt"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
)

// Err wraps the error in the given message,
// and also records the information as part of the [trace.Span].
func Err(span trace.Span, msg string, err error, attrs ...attribute.KeyValue) error {
	span.RecordError(err, trace.WithAttributes(attrs...))
	span.SetStatus(codes.Error, msg)
	return fmt.Errorf("%s: %w", msg, err)
}
