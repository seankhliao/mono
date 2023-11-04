package jsonlog

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"math"
	"math/big"
	"net/netip"
	"os"
	"reflect"
	"testing"
	"testing/slogtest"
	"time"

	"go.opentelemetry.io/otel/trace"
)

func TestHandlerSlogtest(t *testing.T) {
	t.Parallel()

	buf := new(bytes.Buffer)
	handler := New(slog.LevelInfo, buf)
	err := slogtest.TestHandler(handler, func() []map[string]any {
		all := buf.String()
		dec := json.NewDecoder(buf)
		var results []map[string]any
		for dec.More() {
			var result map[string]any
			err := dec.Decode(&result)
			if err != nil {
				t.Errorf("unmarshal log: %v\n%v", err, all)
				break
			}
			results = append(results, result)
		}
		return results
	})
	if err != nil {
		t.Errorf("testhandler: %v", err)
	}
}

func TestHandler(t *testing.T) {
	t.Parallel()

	tid, _ := trace.TraceIDFromHex("5b8aa5a2d2c872e8321cf37308d69df2")
	sid, _ := trace.SpanIDFromHex("051581bf3cb55c13")
	tcs := []struct {
		name  string
		args  []any
		level slog.Level
		msg   string
		ctx   context.Context
		want  map[string]any
	}{
		{
			name: "simple message",
			msg:  "a simple message!",
			want: map[string]any{
				"message": "a simple message!",
				"level":   "INFO",
			},
		}, {
			name: "complex message",
			msg:  "msg with quotes \" and newlines \n and slash \\ and nul \x00",
			want: map[string]any{
				"message": "msg with quotes \" and newlines \n and slash \\ and nul \x00",
				"level":   "INFO",
			},
		}, {
			name: "ints",
			msg:  "ints",
			args: []any{[]slog.Attr{slog.Int("a", 0), slog.Int("b", 1), slog.Int("c", -1), slog.Int("d", math.MaxInt64)}},
			want: map[string]any{
				"message": "ints",
				"level":   "INFO",
				"a":       0.0,
				"b":       1.0,
				"c":       -1.0,
				"d":       float64(math.MaxInt64),
			},
		}, {
			name: "floats",
			msg:  "floats",
			args: []any{[]slog.Attr{slog.Float64("a", 0.0), slog.Float64("b", -1.0), slog.Float64("c", 1.1), slog.Float64("d", math.MaxFloat64)}},
			want: map[string]any{
				"message": "floats",
				"level":   "INFO",
				"a":       0.0,
				"b":       -1.0,
				"c":       1.1,
				"d":       math.MaxFloat64,
			},
		}, {
			name: "bools",
			msg:  "bools",
			args: []any{[]slog.Attr{slog.Bool("a", true), slog.Bool("b", false)}},
			want: map[string]any{
				"message": "bools",
				"level":   "INFO",
				"a":       true,
				"b":       false,
			},
		}, {
			name: "strings",
			msg:  "strings",
			args: []any{[]slog.Attr{slog.String("a", "hello world")}},
			want: map[string]any{
				"message": "strings",
				"level":   "INFO",
				"a":       "hello world",
			},
		}, {
			name: "time",
			msg:  "time",
			args: []any{[]slog.Attr{slog.Time("a", time.Date(2023, 10, 16, 6, 4, 2, 123456789, time.UTC)), slog.Duration("b", 13*time.Hour+17*time.Minute+5*time.Second+734*time.Millisecond)}},
			want: map[string]any{
				"message": "time",
				"level":   "INFO",
				"a":       "2023-10-16T06:04:02.123456789Z",
				"b":       "13h17m5.734s",
			},
		}, {
			name: "simple groups",
			msg:  "simple groups",
			args: []any{[]any{slog.Group("a", slog.Int("b", 1))}, "c", "d", []slog.Attr{slog.Group("e", slog.Int("f", 1))}},
			want: map[string]any{
				"message": "simple groups",
				"level":   "INFO",
				"a": map[string]any{
					"b": 1.0,
				},
				"c": map[string]any{
					"d": map[string]any{
						"e": map[string]any{
							"f": 1.0,
						},
					},
				},
			},
		}, {
			name: "empty groups",
			msg:  "empty groups",
			args: []any{[]any{slog.Group("a")}, []any{slog.Group("b", slog.Group("c"))}, "d", []any{slog.Group("e")}, []slog.Attr{slog.Group("e", slog.Group("f"))}},
			want: map[string]any{
				"message": "empty groups",
				"level":   "INFO",
			},
		}, {
			name: "alternating",
			msg:  "alternating",
			args: []any{"a", []any{slog.Group("b", slog.Int("c", 1), slog.Group("d", slog.Int("e", 2), slog.Group("f"))), slog.Int("g", 3)}, "h", []any{slog.Int("i", 4), slog.Group("j", slog.Int("k", 5))}, "l", []slog.Attr{slog.Int("m", 6), slog.Group("n", slog.Group("o")), slog.Int("p", 7)}},
			want: map[string]any{
				"message": "alternating",
				"level":   "INFO",
				"a": map[string]any{
					"b": map[string]any{
						"c": 1.0,
						"d": map[string]any{
							"e": 2.0,
						},
					},
					"g": 3.0,
					"h": map[string]any{
						"i": 4.0,
						"j": map[string]any{
							"k": 5.0,
						},
						"l": map[string]any{
							"m": 6.0,
							"p": 7.0,
						},
					},
				},
			},
		}, {
			name: "context trace",
			msg:  "context trace",
			ctx:  trace.ContextWithSpanContext(context.Background(), trace.NewSpanContext(trace.SpanContextConfig{TraceID: tid, SpanID: sid})),
			want: map[string]any{
				"message":  "context trace",
				"level":    "INFO",
				"trace_id": "5b8aa5a2d2c872e8321cf37308d69df2",
				"span_id":  "051581bf3cb55c13",
			},
		},
	}
	for _, tc := range tcs {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			buf := new(bytes.Buffer)
			lg := slog.New(New(slog.LevelDebug, buf))
			for i, arg := range tc.args {
				if i == len(tc.args)-1 {
					break
				}
				switch v := arg.(type) {
				case string:
					lg = lg.WithGroup(v)
				case []any:
					lg = lg.With(v...)
				}
			}
			if len(tc.args) > 0 {
				lg.LogAttrs(tc.ctx, tc.level, tc.msg, tc.args[len(tc.args)-1].([]slog.Attr)...)
			} else {
				lg.LogAttrs(tc.ctx, tc.level, tc.msg)
			}

			//
			var got map[string]any
			err := json.Unmarshal(buf.Bytes(), &got)
			if err != nil {
				t.Errorf("unmarshaling log line: %v", err)
			}
			delete(got, "time")
			if !reflect.DeepEqual(got, tc.want) {
				t.Errorf("\ngot = %v\nwnt = %v", got, tc.want)
				for k := range got {
					if got[k] != tc.want[k] {
						t.Errorf("diff: %v %+v %+v", k, got[k], tc.want[k])
					}
				}
			}
		})
	}
}

func BenchmarkHandler(b *testing.B) {
	ctx := context.Background()
	handlers := map[string]*slog.Logger{
		"slog":    slog.New(slog.NewJSONHandler(io.Discard, &slog.HandlerOptions{})),
		"jsonlog": slog.New(New(slog.LevelDebug, io.Discard)),
	}
	for name, lg := range handlers {
		b.Run(name+"/ints", func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				lg.LogAttrs(ctx, slog.LevelInfo, "benchmark msg", slog.Int("a", 1), slog.Int("b", 2), slog.Int("c", 3), slog.Int("d", 4), slog.Int("e", 5))
			}
		})
		b.Run(name+"/floats", func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				lg.LogAttrs(ctx, slog.LevelInfo, "benchmark msg", slog.Float64("a", 1), slog.Float64("b", 2), slog.Float64("c", 3), slog.Float64("d", 4), slog.Float64("e", 5))
			}
		})
		b.Run(name+"/bools", func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				lg.LogAttrs(ctx, slog.LevelInfo, "benchmark msg", slog.Bool("a", true), slog.Bool("b", true), slog.Bool("c", false), slog.Bool("d", true), slog.Bool("e", true))
			}
		})
		b.Run(name+"/strings", func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				lg.LogAttrs(ctx, slog.LevelInfo, "benchmark msg", slog.String("a", "zzzzzz"), slog.String("b", "yyy yyy"), slog.String("c", "x x x x x x"), slog.String("d", "w w ww w w"), slog.String("e", "vvv v vvv"))
			}
		})
		b.Run(name+"/objects", func(b *testing.B) {
			err := errors.New("zzz")      // error
			ip := netip.IPv6Unspecified() // encoding.TextMarshaler
			bi := big.NewInt(1234567890)  // json.Marshaler
			zz := struct {
				A string
				B int
			}{
				"aaa", 4567,
			}
			for i := 0; i < b.N; i++ {
				lg.LogAttrs(ctx, slog.LevelInfo, "benchmark msg", slog.Any("a", err), slog.Any("b", ip), slog.Any("c", bi), slog.Any("d", fs.ModeDir), slog.Any("e", zz))
			}
		})
		b.Run(name+"/mixed", func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				lg.LogAttrs(ctx, slog.LevelInfo, "benchmark msg", slog.Int("a", 1), slog.Float64("b", 2), slog.Bool("c", true), slog.String("d", "benchy"), slog.Duration("e", 12345678*time.Millisecond))
			}
		})
	}
}

func FuzzHandler(f *testing.F) {
	f.Fuzz(func(t *testing.T, lines uint8, level, level2 int, nargs uint64, i1, i2, i3, i4, i5, i6, i7, i8, i9, i0, msg string) {
		strs := []string{i0, i1, i2, i3, i4, i5, i6, i7, i8, i9}
		buf := new(bytes.Buffer)
		lg := slog.New(New(slog.Level(level), buf))
		fmt.Fprintln(os.Stderr, lines, level, level2, nargs, msg)
		for i := uint8(0); i < lines; i++ {
			nlg := lg
			nargs := nargs * uint64(lines)
			var args []any
			for nargs > 0 {
				switch nargs % 6 {
				case 0:
					nlg = nlg.With(args...)
					args = nil
				case 1:
					nlg = nlg.WithGroup(strs[nargs%10])
				case 2:
					args = append(args, strs[nargs%10], strs[(nargs*7)%10])
				case 4:
					args = append(args, strs[nargs%10], nargs)
				case 5:
					args = append(args, strs[nargs%10], nargs%2 == 0)
				case 6:
					lop := int(nargs) % (len(args) / 2)
					args = append(args[:lop*2], strs[nargs%10], slog.Group(strs[(nargs*13)%10], args[lop*2:]...))
				}
				nargs /= 6
			}
			nlg.Log(context.Background(), slog.Level(level2), msg, args...)
		}

		all := buf.String()
		fmt.Fprintln(os.Stderr, all)
		dec := json.NewDecoder(buf)
		for dec.More() {
			var out any
			err := dec.Decode(&out)
			if err != nil {
				t.Error(err, all)
			}
		}
	})
}
