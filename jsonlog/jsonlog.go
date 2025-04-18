package jsonlog

import (
	"context"
	"encoding"
	"encoding/json/jsontext"
	"encoding/json/v2"
	"fmt"
	"io"
	"log/slog"
	"os"
	"slices"
	"strconv"
	"sync"
	"time"

	"go.opentelemetry.io/otel/trace"
)

const (
	// magic numbers to reduce number of slice resizes
	// slog holds 5 attrs
	stateBufferSize = 1024

	rfc3339Milli = "2006-01-02T15:04:05.999Z07:00"
)

var (

	// shared
	globalSep = []byte(",")

	// assert it is a handler
	_ slog.Handler = new(handler)

	// reduce allocations in steady state
	pool = &sync.Pool{
		New: func() any {
			s := make([]byte, 0, stateBufferSize)
			return &s
		},
	}
)

// New returns a [slog.Handler] that outputs logs in JSON format.
// It has special handling to extract trace_id/span_id as top level keys
// from the context given to log calls.
func New(level slog.Level, out io.Writer) slog.Handler {
	return &handler{
		minLevel: level,
		gcp:      os.Getenv("K_SERVICE") != "",
		state:    new(state),
		mu:       new(sync.Mutex),
		w:        out,
	}
}

type handler struct {
	minLevel slog.Level
	gcp      bool
	state    *state
	mu       *sync.Mutex
	w        io.Writer
}

func (h *handler) clone() *handler {
	b0 := pool.Get().(*[]byte)
	return &handler{
		minLevel: h.minLevel,
		state:    h.state.clone(*b0),
		mu:       h.mu,
		w:        h.w,
	}
}

func (h *handler) Enabled(ctx context.Context, l slog.Level) bool {
	return l >= h.minLevel
}

func (h *handler) WithAttrs(attrs []slog.Attr) slog.Handler {
	if len(attrs) == 0 {
		return h
	}
	h2 := h.clone()
	for _, a := range attrs {
		h2.state.attr(a)
	}
	return h2
}

func (h *handler) WithGroup(name string) slog.Handler {
	if name == "" {
		return h
	}
	h2 := h.clone()
	h2.state.openGroup(name)
	return h2
}

func (h *handler) Handle(ctx context.Context, r slog.Record) error {
	// add attrs to state
	b0 := pool.Get().(*[]byte)
	defer func() { pool.Put(b0) }()
	state := h.state.clone(*b0)
	r.Attrs(func(a slog.Attr) bool {
		state.attr(a)
		return true
	})
	state.closeAll()

	// initialize write buffer
	var buf []byte
	if cap(state.buf)-len(state.buf) < 160+len(r.Message) {
		buf = make([]byte, 0, len(state.buf)+160+len(r.Message))
	} else {
		b1 := pool.Get().(*[]byte)
		defer func() { pool.Put(b1) }()
		buf = (*b1)[:0]
	}

	buf = append(buf, `{`...)

	// time
	if !r.Time.IsZero() {
		buf = append(buf, `"time":"`...)
		buf = r.Time.AppendFormat(buf, rfc3339Milli)
		buf = append(buf, `",`...)
	}
	// level
	buf = append(buf, `"level":"`...)
	buf = append(buf, r.Level.String()...)
	buf = append(buf, `"`...)
	if h.gcp {
		buf = append(buf, `,"severity":"`...)
		buf = append(buf, r.Level.String()...)
		buf = append(buf, `"`...)
	}

	// trace
	spanCtx := trace.SpanContextFromContext(ctx)
	if spanCtx.IsValid() {
		if h.gcp {
			buf = append(buf, `,"logging.googleapis.com/trace":"`...)
			buf = append(buf, spanCtx.TraceID().String()...)
			buf = append(buf, `"`...)
		}
		buf = append(buf, `,"trace_id":"`...)
		buf = append(buf, spanCtx.TraceID().String()...)
		buf = append(buf, `","span_id":"`...)
		buf = append(buf, spanCtx.SpanID().String()...)
		buf = append(buf, `"`...)

	}
	// any other special keys
	// e.g. file:line, attrs from ctx or extracted during attr processing by state.attr

	// message
	buf = append(buf, `,"message":`...)
	buf, _ = jsontext.AppendQuote(buf, r.Message)

	// attrs
	if len(state.buf) > 0 {
		buf = append(buf, `,`...)
		buf = append(buf, state.buf...)
	}
	buf = append(buf, "}\n"...)

	h.mu.Lock()
	defer h.mu.Unlock()
	_, err := h.w.Write(buf)
	return err
}

// state holds preformatted attributes
type state struct {
	confirmedLast int    // length of buf when we last wrote a complete attr
	groupOpenIdx  []int  // indexes before open groups, allows rollback on empty groups
	separator     []byte // separator to write before an attr or group
	buf           []byte // buffer of preformatted contents
	// TODO hold special keys to be placed in top level (eg error)
}

func (h *state) clone(buf []byte) *state {
	if cap(h.buf) > stateBufferSize {
		buf = slices.Clone(h.buf)
	} else {
		buf = buf[:len(h.buf)]
		copy(buf, h.buf)
	}
	s := &state{
		h.confirmedLast,
		slices.Clone(h.groupOpenIdx),
		slices.Clone(h.separator),
		buf,
	}
	return s
}

func (h *state) openGroup(n string) {
	h.groupOpenIdx = append(h.groupOpenIdx, len(h.buf)) // record rollback point
	h.buf = append(h.buf, h.separator...)               // maybe need a separator
	h.buf, _ = jsontext.AppendQuote(h.buf, n)           // key name
	h.buf = append(h.buf, []byte(":{")...)              // open group
	h.separator = nil                                   // no separator for first attr
}

func (h *state) closeGroup() {
	lastGroupIdx := h.groupOpenIdx[len(h.groupOpenIdx)-1] // pop off the rollback point for current group
	h.groupOpenIdx = h.groupOpenIdx[:len(h.groupOpenIdx)-1]
	if h.confirmedLast > lastGroupIdx { // group was non empty
		h.buf = append(h.buf, []byte("}")...) // close off the group
		h.confirmedLast = len(h.buf)          // record new last point
		return
	}
	h.buf = h.buf[:lastGroupIdx] // all open subgroups were empty, rollback
}

func (h *state) closeAll() {
	for range h.groupOpenIdx {
		h.closeGroup()
	}
	h.groupOpenIdx = nil
}

func (h *state) attr(attr slog.Attr) {
	val := attr.Value.Resolve()  // handle logvaluer
	if attr.Equal(slog.Attr{}) { // drop empty attr
		return
	} else if val.Kind() == slog.KindGroup { // recurse into group
		g := val.Group()
		if len(g) == 0 {
			return
		} else if attr.Key != "" { // inline empty keys
			h.openGroup(attr.Key)
		}
		for _, a := range val.Group() {
			h.attr(a)
		}
		if attr.Key != "" {
			h.closeGroup()
		}
		return
	} else if attr.Key == "" {
		return
	}
	// TODO: grab any special keys

	h.buf = append(h.buf, h.separator...)
	h.separator = globalSep
	h.buf, _ = jsontext.AppendQuote(h.buf, attr.Key)
	h.buf = append(h.buf, []byte(":")...)
	switch val.Kind() {
	case slog.KindAny:
		var err error
		var b []byte
		switch v := val.Any().(type) {
		case json.Marshaler:
			b, err = v.MarshalJSON()
			h.buf = append(h.buf, b...)
		case json.MarshalerTo:
			// no jsontext.Encoder available
			b, err = json.Marshal(v)
			h.buf = append(h.buf, b...)
		case encoding.TextAppender:
			h.buf, err = v.AppendText(h.buf)
		case encoding.TextMarshaler:
			b, err = v.MarshalText()
			h.buf, _ = jsontext.AppendQuote(h.buf, b)
		case fmt.Stringer:
			s := v.String()
			h.buf, _ = jsontext.AppendQuote(h.buf, s)
		case error:
			s := v.Error()
			h.buf, _ = jsontext.AppendQuote(h.buf, s)
		default:
			b, err = json.Marshal(v)
			h.buf = append(h.buf, b...)
		}
		if err != nil {
			// best effort representation
			h.buf = fmt.Appendf(h.buf, "%+v", val.Any())
		}
	case slog.KindBool:
		h.buf = strconv.AppendBool(h.buf, val.Bool())
	case slog.KindDuration:
		h.buf = append(h.buf, `"`...)
		h.buf = append(h.buf, val.Duration().String()...)
		h.buf = append(h.buf, `"`...)
	case slog.KindFloat64:
		h.buf = strconv.AppendFloat(h.buf, val.Float64(), 'f', -1, 64)
	case slog.KindInt64:
		h.buf = strconv.AppendInt(h.buf, val.Int64(), 10)
	case slog.KindString:
		h.buf, _ = jsontext.AppendQuote(h.buf, val.String())
	case slog.KindTime:
		h.buf = append(h.buf, `"`...)
		h.buf = val.Time().AppendFormat(h.buf, time.RFC3339Nano)
		h.buf = append(h.buf, `"`...)
	case slog.KindUint64:
		h.buf = strconv.AppendUint(h.buf, val.Uint64(), 10)
	default:
		panic("unhandled kind" + val.Kind().String())
	}
	h.confirmedLast = len(h.buf)
}
