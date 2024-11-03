package multilog

import (
	"context"
	"errors"
	"log/slog"
)

func Handler(handlers ...slog.Handler) slog.Handler {
	return &handler{
		handlers: handlers,
	}
}

var _ slog.Handler = &handler{}

type handler struct {
	handlers []slog.Handler
}

func (h *handler) Enabled(ctx context.Context, lvl slog.Level) bool {
	for _, hand := range h.handlers {
		if hand.Enabled(ctx, lvl) {
			return true
		}
	}
	return false
}

func (h *handler) Handle(ctx context.Context, r slog.Record) error {
	var errs []error
	for _, hand := range h.handlers {
		if !hand.Enabled(ctx, r.Level) {
			continue
		}
		rn := r.Clone()
		err := hand.Handle(ctx, rn)
		if err != nil {
			errs = append(errs, err)
		}
	}
	if len(errs) > 0 {
		return errors.Join(errs...)
	}
	return nil
}

func (h *handler) WithAttrs(attrs []slog.Attr) slog.Handler {
	hands := &handler{make([]slog.Handler, len(h.handlers))}
	for i, hand := range h.handlers {
		hands.handlers[i] = hand.WithAttrs(attrs)
	}
	return hands
}

func (h *handler) WithGroup(name string) slog.Handler {
	hands := &handler{make([]slog.Handler, len(h.handlers))}
	for i, hand := range h.handlers {
		hands.handlers[i] = hand.WithGroup(name)
	}
	return hands
}
