package webstyle

import "testing"

func TestEmbedded(t *testing.T) {
	if len(layoutTpl) == 0 {
		t.Errorf("len(layoutTpl) = 0, want embedded content")
	}
	if len(baseCss) == 0 {
		t.Errorf("len(baseCss) = 0, want embedded content")
	}
	if len(compactCss) == 0 {
		t.Errorf("len(compactCss) = 0, want embedded content")
	}
}
