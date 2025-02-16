package multilog

import (
	"bytes"
	"log/slog"
	"testing"
)

func dropTime(groups []string, a slog.Attr) slog.Attr {
	if a.Key == "time" {
		return slog.Attr{}
	}
	return a
}

func TestMultiLog(t *testing.T) {
	bufText, bufJson := new(bytes.Buffer), new(bytes.Buffer)
	h := Handler(
		slog.NewTextHandler(bufText, &slog.HandlerOptions{
			ReplaceAttr: dropTime,
		}),
		slog.NewJSONHandler(bufJson, &slog.HandlerOptions{
			ReplaceAttr: dropTime,
		}),
	)
	l := slog.New(h)

	if l.Enabled(t.Context(), slog.LevelWarn) {
		l.With("a", 1).WithGroup("b").Error("c", "d", 3)
	}

	wantText := "level=ERROR msg=c a=1 b.d=3\n"
	if got := bufText.String(); got != wantText {
		t.Errorf("mismatched log line:\ngot: %s\nwnt: %s", got, wantText)
	}

	wantJson := `{"level":"ERROR","msg":"c","a":1,"b":{"d":3}}` + "\n"
	if got := bufJson.String(); got != wantJson {
		t.Errorf("mismatched log line:\ngot: %s\nwnt: %s", got, wantJson)
	}
}
