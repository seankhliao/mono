package jsonlog

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestZPageWrite(t *testing.T) {
	t.Parallel()
	tcs := []struct {
		name  string
		write []string
		want  []string
	}{
		{
			"one",
			[]string{"one"},
			[]string{"one", "", ""},
		}, {
			"full",
			[]string{"one", "two", "three"},
			[]string{"one", "two", "three"},
		}, {
			"wraparound",
			[]string{"one", "two", "three", "four"},
			[]string{"four", "two", "three"},
		},
	}
	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			z := NewZPage(3)
			for _, line := range tc.write {
				io.WriteString(z, line)
			}

			for i, bufLine := range z.buf {
				line := string(bufLine)
				if line != tc.want[i] {
					t.Errorf("buf[%d] = %q, want %q", i, line, tc.want[i])
				}
			}
		})
	}
}

func TestZPageServeHTTP(t *testing.T) {
	t.Parallel()
	tcs := []struct {
		name  string
		write []string
		want  string
	}{
		{
			"none",
			[]string{},
			"",
		}, {
			"one",
			[]string{"one"},
			"one\n",
		}, {
			"full",
			[]string{"one", "two", "three"},
			"one\ntwo\nthree\n",
		}, {
			"overflow",
			[]string{"one", "two", "three", "four"},
			"two\nthree\nfour\n",
		},
	}
	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			z := NewZPage(3)

			s := httptest.NewServer(z)
			defer s.Close()

			for _, line := range tc.write {
				io.WriteString(z, line+"\n")
			}

			res, err := http.Get(s.URL)
			if err != nil {
				t.Fatalf("error getting server response: %v", err)
			}
			defer res.Body.Close()
			if res.StatusCode != 200 {
				t.Fatalf("unexpected status code %s", res.Status)
			}
			if ct := res.Header.Get("content-type"); ct != "application/json" {
				t.Errorf("content-type = %q, want application/json", ct)
			}
			body, err := io.ReadAll(res.Body)
			if err != nil {
				t.Fatalf("read response body: %v", err)
			}
			if string(body) != tc.want {
				t.Errorf("response body\ngot = %q\nwnt = %q", string(body), tc.want)
			}
		})
	}
}
