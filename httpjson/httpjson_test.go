package httpjson

import (
	"errors"
	"io"
	"net/http/httptest"
	"testing"
)

func TestOK(t *testing.T) {
	tcs := []struct {
		name     string
		data     any
		expected string
	}{
		{
			name:     "msh-ok",
			data:     map[string]any{"msg": "ok"},
			expected: `{"msg":"ok"}`,
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			err := OK(rec, tc.data)
			if err != nil {
				t.Errorf("unexpected error response: %v", err)
			}
			res := rec.Result()
			if code := res.StatusCode; code < 200 || code > 299 {
				t.Errorf("status code = %v, want 200 <= code <= 299", code)
			}
			if ct := res.Header.Get("content-type"); ct != "application/json" {
				t.Errorf("content-type = %v, want = application/json", ct)
			}
			if b, _ := io.ReadAll(res.Body); string(b) != tc.expected {
				t.Errorf("body = %v, want = %v", string(b), tc.expected)
			}
		})
	}
}

func TestErr(t *testing.T) {
	tcs := []struct {
		name     string
		code     int
		msg      string
		err      error
		expected string
	}{
		{
			name:     "msg-err",
			code:     404,
			msg:      "page not found",
			err:      errors.New("file not found"),
			expected: `{"title":"page not found","status":404,"detail":"file not found"}`,
		},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			err := Err(rec, tc.code, tc.msg, tc.err)
			if err != nil {
				t.Errorf("unexpected error response: %v", err)
			}
			res := rec.Result()
			if code := res.StatusCode; code != tc.code {
				t.Errorf("status code = %v, want = %v", code, tc.code)
			}
			if ct := res.Header.Get("content-type"); ct != "application/problem+json" {
				t.Errorf("content-type = %v, want = application/json", ct)
			}
			if b, _ := io.ReadAll(res.Body); string(b) != tc.expected {
				t.Errorf("body = %v, want = %v", string(b), tc.expected)
			}
		})
	}
}
