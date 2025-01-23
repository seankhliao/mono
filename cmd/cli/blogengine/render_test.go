package main

import "testing"

var testPage = `
# a blog

## a blog must start somewhere
` + testPageMain

var testPageMain = `
### a third title

some text

#### another section

more text
`

func TestFindTitles(t *testing.T) {
	gotPage, gotTitle, gotSubtitle := stripTitles([]byte(testPage))
	wantTitle := "a blog"
	wantSubtitle := "a blog must start somewhere"
	wantPage := "\n\n" + testPageMain
	if gotTitle != wantTitle {
		t.Errorf("title = %q, want = %q", gotTitle, wantTitle)
	}
	if gotSubtitle != wantSubtitle {
		t.Errorf("subtitle = %q, want = %q", gotSubtitle, wantSubtitle)
	}
	if string(gotPage) != wantPage {
		t.Errorf("page = %q, want = %q", string(gotPage), wantPage)
	}
}
