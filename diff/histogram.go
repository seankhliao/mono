package diff

import (
	"bytes"
	"fmt"
	"slices"
)

type op rune

const (
	opEqual  op = ' '
	opInsert op = '+'
	opDelete op = '-'
)

type diffRecord struct {
	Payload []byte
	Type    op
}

func toRecords(lines [][]byte, op op) []diffRecord {
	res := make([]diffRecord, len(lines))
	for i, l := range lines {
		res[i] = diffRecord{Payload: l, Type: op}
	}
	return res
}

const ContextLines = 3

var noNewlineMsg = []byte("\\ No newline at end of file")

// HistogramDiff generates a unified diff using the histogram algorithm
// similar to git / jgit.
func HistogramDiff(a, b []byte, aName, bName string) []byte {
	linesA := splitLines(a)
	linesB := splitLines(b)

	diffs := histogramDiff(linesA, linesB)
	if !slices.ContainsFunc(diffs, func(e diffRecord) bool { return e.Type != opEqual }) {
		return nil
	}

	hunks := groupHunks(diffs)

	var out bytes.Buffer
	fmt.Fprintf(&out, "diff %s %s\n", aName, bName)
	fmt.Fprintf(&out, "--- %s\n", aName)
	fmt.Fprintf(&out, "+++ %s\n", bName)

	for _, h := range hunks {
		if h.aStart == 1 && h.aLen == 0 {
			h.aStart = 0
		}
		if h.bStart == 1 && h.bLen == 0 {
			h.bStart = 0
		}
		fmt.Fprintf(&out, "@@ -%d,%d +%d,%d @@\n", h.aStart, h.aLen, h.bStart, h.bLen)

		for _, c := range h.Changes {
			out.WriteRune(rune(c.Type))
			out.Write(c.Payload)
		}
	}

	return out.Bytes()
}

func splitLines(b []byte) [][]byte {
	if len(b) == 0 {
		return nil
	}
	hasNL := bytes.HasSuffix(b, []byte("\n"))
	if hasNL {
		b = b[:len(b)-1]
	}
	lines := bytes.Split(b, []byte("\n"))
	for i, l := range lines {
		lines[i] = append(bytes.TrimRight(l, "\r"), '\n')
	}
	if !hasNL {
		lines[len(lines)-1] = append(lines[len(lines)-1], noNewlineMsg...)
		lines[len(lines)-1] = append(lines[len(lines)-1], '\n')
	}
	return lines
}

func histogramDiff(a, b [][]byte) []diffRecord {
	if len(a) == 0 {
		return toRecords(b, opInsert)
	}
	if len(b) == 0 {
		return toRecords(a, opDelete)
	}

	idxA, idxB := findPivot(a, b)
	if idxA == -1 {
		return append(toRecords(a, opDelete), toRecords(b, opInsert)...)
	}

	before := histogramDiff(a[:idxA], b[:idxB])
	pivot := diffRecord{Payload: a[idxA], Type: opEqual}
	after := histogramDiff(a[idxA+1:], b[idxB+1:])

	return append(append(before, pivot), after...)
}

func findPivot(a, b [][]byte) (int, int) {
	type stats struct{ ca, cb, ia, ib int }
	counts := make(map[string]*stats)
	for i, s := range a {
		ss := string(s)
		if _, ok := counts[ss]; !ok {
			counts[ss] = &stats{}
		}
		counts[ss].ca++
		counts[ss].ia = i
	}
	for i, s := range b {
		if sInfo, ok := counts[string(s)]; ok {
			sInfo.cb++
			sInfo.ib = i
		}
	}
	bestIdxA, bestIdxB, minCount := -1, -1, int(^uint(0)>>1)
	for i, s := range a {
		info := counts[string(s)]
		if info.ca > 0 && info.cb > 0 {
			total := info.ca + info.cb
			if total < minCount {
				minCount, bestIdxA, bestIdxB = total, info.ia, info.ib
			}
			if total == 2 {
				return i, info.ib
			}
		}
	}
	return bestIdxA, bestIdxB
}

type hunk struct {
	aStart, aLen int
	bStart, bLen int
	Changes      []diffRecord
}

func groupHunks(diffs []diffRecord) []hunk {
	var hunks []hunk
	n := len(diffs)
	i := 0
	for i < n {
		for i < n && diffs[i].Type == opEqual {
			i++
		}
		if i >= n {
			break
		}

		start := max(i-ContextLines, 0)

		aStart, bStart := 1, 1
		for j := range start {
			if diffs[j].Type != opInsert {
				aStart++
			}
			if diffs[j].Type != opDelete {
				bStart++
			}
		}

		end, lastChange := i, i
		for end < n {
			if diffs[end].Type != opEqual {
				lastChange = end
			} else if end-lastChange >= ContextLines*2 {
				break
			}
			end++
		}

		hunkEnd := min(lastChange+ContextLines+1, n)

		h := hunk{aStart: aStart, bStart: bStart, Changes: diffs[start:hunkEnd]}
		for _, c := range h.Changes {
			if c.Type != opInsert {
				h.aLen++
			}
			if c.Type != opDelete {
				h.bLen++
			}
		}
		hunks = append(hunks, h)
		i = hunkEnd
	}
	return hunks
}
