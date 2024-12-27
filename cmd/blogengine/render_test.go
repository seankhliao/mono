package main

import "testing"

var testPage = `
# a blog

## a blog must start somewhere
`

func TestFindTitles(t *testing.T) {
	gotTitle, gotSubtitle := findTitles([]byte(testPage))
	wantTitle := "a blog"
	wantSubtitle := "a blog must start somewhere"
	if gotTitle != wantTitle {
		t.Errorf("title = %q, want = %q", gotTitle, wantTitle)
	}
	if gotSubtitle != wantSubtitle {
		t.Errorf("subtitle = %q, want = %q", gotSubtitle, wantSubtitle)
	}
}
