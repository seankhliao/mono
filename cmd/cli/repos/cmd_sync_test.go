package main

import (
	"slices"
	"strconv"
	"testing"
)

func TestSplitRepos(t *testing.T) {
	cases := []struct {
		remote, local         []string
		download, sync, prune []string
	}{
		{
			[]string{"a", "b", "c"},
			[]string{"d", "e", "f"},
			[]string{"a", "b", "c"},
			[]string{},
			[]string{"d", "e", "f"},
		},
		{
			[]string{"a", "b", "c"},
			[]string{"b", "c", "d"},
			[]string{"a"},
			[]string{"b", "c"},
			[]string{"d"},
		},
		{
			[]string{"d", "e", "f"},
			[]string{"a", "b", "c"},
			[]string{"d", "e", "f"},
			[]string{},
			[]string{"a", "b", "c"},
		},
		{
			[]string{"a", "c", "e"},
			[]string{"b", "d", "e", "f"},
			[]string{"a", "c"},
			[]string{"e"},
			[]string{"b", "d", "f"},
		},
	}
	for i, tc := range cases {
		t.Run(strconv.Itoa(i), func(t *testing.T) {
			download, sync, prune := splitRepos(tc.remote, tc.local)
			if !slices.Equal(download, tc.download) || !slices.Equal(sync, tc.sync) || !slices.Equal(prune, tc.prune) {
				t.Log("got download: ", download)
				t.Log("want download:", tc.download)
				t.Log("got sync: ", sync)
				t.Log("want sync:", tc.sync)
				t.Log("got prune: ", prune)
				t.Log("want prune:", tc.prune)
				t.Errorf("wrong output")
			}
		})
	}
}
