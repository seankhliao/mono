package werr

import (
	"errors"
	"log/slog"
)

var _ slog.LogValuer = Error{}

type Error struct {
	msg   string
	base  error
	attrs []slog.Attr
}

func New(msg string, err error, attrs ...slog.Attr) error {
	e := Error{
		msg:   msg,
		base:  err,
		attrs: attrs,
	}
	var extract Error
	if errors.As(err, &extract) {
		e.attrs = append(e.attrs, extract.attrs...)
	}
	return e
}

func (e Error) Error() string {
	if e.base != nil {
		return e.msg + ": " + e.base.Error()
	}
	return e.msg
}

func (e Error) Unwrap() error {
	return e.base
}

func (e Error) LogValue() slog.Value {
	attrs := make([]slog.Attr, 0, len(e.attrs)+2)
	attrs = append(attrs, slog.String("msg", e.Error()))
	attrs = append(attrs, e.attrs...)
	return slog.GroupValue(attrs...)
}
