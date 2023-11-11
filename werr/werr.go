package werr

import (
	"errors"
	"log/slog"
	"strings"
)

var _ slog.LogValuer = Error{}

type Error struct {
	msg   string
	base  error
	attrs []slog.Attr
}

func New(msg string, err error, attrs ...slog.Attr) error {
	return Error{
		msg:   msg,
		base:  err,
		attrs: attrs,
	}
}

func (e Error) Error() string {
	if e.base == nil && len(e.attrs) == 0 {
		return e.msg
	}

	var buf strings.Builder
	buf.WriteString(e.msg)
	var extract Error
	if errors.As(e.base, &extract) {
		buf.WriteString(" [")
		for i, a := range extract.attrs {
			if i != 0 {
				buf.WriteString(" ")
			}
			buf.WriteString(a.String())
		}
		buf.WriteString("]")
	}

	if e.base != nil {
		buf.WriteString(": ")
		buf.WriteString(e.base.Error())
	}

	return buf.String()
}

func (e Error) Unwrap() error {
	return e.base
}

func (e Error) LogValue() slog.Value {
	attrs := make([]slog.Attr, 0, len(e.attrs)+2)
	attrs = append(attrs, slog.String("msg", e.Error()))
	attrs = append(attrs, e.attrs...)
	for e0 := e.base; e0 != nil; {
		var extract Error
		if errors.As(e0, &extract) {
			attrs = append(attrs, extract.attrs...)
			e0 = extract.base
		} else {
			break
		}
	}
	return slog.GroupValue(attrs...)
}
