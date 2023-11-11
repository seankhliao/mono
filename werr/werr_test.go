package werr

import (
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"testing"
)

func TestNew(t *testing.T) {
	t.Parallel()
	base := errors.New("base error")
	a1, a2, a3, a4 := slog.String("a", "b"), slog.Int("c", 4), slog.String("e", "f"), slog.Int("g", 8)

	t.Run("simple", func(t *testing.T) {
		t.Parallel()

		msg := "wrapping"
		e := New(msg, nil)
		if e.Error() != msg {
			t.Errorf("New(msg).Error() = %q, want %q", e.Error(), msg)
		}
	})

	t.Run("extract", func(t *testing.T) {
		t.Parallel()

		e1 := New("wrap1", base, a1, a2)
		e2 := New("wrap2", e1, a3, a4)
		checkAttrs(t, e2.(Error).attrs, []slog.Attr{a1, a2, a3, a4})
	})

	t.Run("extract_multi", func(t *testing.T) {
		t.Parallel()

		e1 := New("wrap1", base, a1, a2)
		e2 := fmt.Errorf("fmtWrap: %w", e1)
		e3 := New("wrap2", e2, a3, a4)
		checkAttrs(t, e3.(Error).attrs, []slog.Attr{a1, a2, a3, a4})
	})
}

func TestError_Error(t *testing.T) {
	t.Parallel()

	msg := "an error occurred"

	t.Run("no_base", func(t *testing.T) {
		t.Parallel()

		e := Error{msg: msg}
		str := e.Error()
		if !strings.Contains(str, msg) {
			t.Errorf("e.Error() = %q, missing msg %q", str, msg)
		}
	})

	t.Run("base", func(t *testing.T) {
		t.Parallel()

		base := "a different error"
		e := Error{msg: msg, base: errors.New(base)}
		str := e.Error()
		if !strings.Contains(str, msg) {
			t.Errorf("e.Error() = %q, missing message %q", str, msg)
		}
		if !strings.Contains(str, base) {
			t.Errorf("e.Error() = %q, missing base %q", str, msg)
		}
	})
}

type ErrorUnwrapper interface {
	Unwrap() error
}

func TestError_Unwrap(t *testing.T) {
	t.Parallel()

	base := errors.New("base error")
	wrapped := New("wrapping", base)

	t.Run("direct_unwrap", func(t *testing.T) {
		t.Parallel()

		unwrapped := wrapped.(ErrorUnwrapper).Unwrap()
		if unwrapped != base {
			t.Errorf("e.Unwrap() = (%[1]v, %[1]p), original error: (%[2]v, %[2]p)", unwrapped, base)
		}
	})
	t.Run("errors_is", func(t *testing.T) {
		t.Parallel()

		if !errors.Is(wrapped, base) {
			t.Errorf("errors.Is(err, base) = false")
		}
	})
}

func TestError_LogValue(t *testing.T) {
	t.Parallel()

	base := errors.New("base error")
	a1, a2 := slog.String("a", "b"), slog.Int("c", 4)
	wrapped := New("wrapping", base, a1, a2)
	logValue := wrapped.(slog.LogValuer).LogValue()

	if logValue.Kind() != slog.KindGroup {
		t.Fatalf("e.LogValue kind = %s kind not group", logValue.Kind())
	}

	checkAttrs(t, logValue.Group(), []slog.Attr{a1, a2, slog.String("msg", "wrapping: "+base.Error())})
}

func checkAttrs(t *testing.T, output, want []slog.Attr) {
	t.Helper()

	for _, a := range want {
		var found bool
		for _, t := range output {
			if t.Equal(a) {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("attrs = %v, missing attr %s", output, a.String())
		}
	}
}
