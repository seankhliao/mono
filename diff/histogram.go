package diff

import (
	"bytes"
	"fmt"
	"slices"
	"strings"
)

type Op int

const (
	Equal Op = iota
	Insert
	Delete
)

type DiffRecord struct {
	Payload string
	Type    Op
}

const (
	ContextLines = 3
	NoNewlineMsg = "\\ No newline at end of file"
)

// HistogramDiff generates a unified diff using the histogram algorithm
// similar to git / jgit.
func HistogramDiff(a, b []byte, aName, bName string) []byte {
	linesA, aHasNL := splitLines(a)
	linesB, bHasNL := splitLines(b)

	diffs := histogramDiff(linesA, linesB)
	if slices.ContainsFunc(diffs, func(e DiffRecord) bool {
		return e.Type != Equal
	}) && aHasNL == bHasNL {
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

		for i, c := range h.Changes {
			// Determine if this specific change is the last line of its respective file
			isLastA := (c.Type == Equal || c.Type == Delete) && isLastInFile(h.Changes, i, true)
			isLastB := (c.Type == Equal || c.Type == Insert) && isLastInFile(h.Changes, i, false)

			switch c.Type {
			case Equal:
				out.WriteString(" " + c.Payload + "\n")
				if isLastA && !aHasNL {
					out.WriteString(NoNewlineMsg + "\n")
				} else if isLastB && !bHasNL {
					// In the rare case A has a newline but B doesn't at the same "Equal" line
					out.WriteString(NoNewlineMsg + "\n")
				}
			case Delete:
				out.WriteString("-" + c.Payload + "\n")
				if isLastA && !aHasNL {
					out.WriteString(NoNewlineMsg + "\n")
				}
			case Insert:
				out.WriteString("+" + c.Payload + "\n")
				if isLastB && !bHasNL {
					out.WriteString(NoNewlineMsg + "\n")
				}
			}
		}
	}

	return out.Bytes()
}

// splitLines returns the lines and a boolean indicating if the input ended with a newline.
func splitLines(data []byte) ([]string, bool) {
	if len(data) == 0 {
		return nil, true
	}
	hasNewline := data[len(data)-1] == '\n'

	// Split and normalize
	raw := string(data)
	if hasNewline {
		raw = raw[:len(raw)-1]
	}
	parts := strings.Split(raw, "\n")

	// Trim trailing \r for cross-platform consistency
	for i := range parts {
		parts[i] = strings.TrimRight(parts[i], "\r")
	}
	return parts, hasNewline
}

// isLastInFile checks if the record at index i is the final occurrence for file A or B in this hunk.
func isLastInFile(changes []DiffRecord, index int, isFileA bool) bool {
	for j := index + 1; j < len(changes); j++ {
		if isFileA && (changes[j].Type == Equal || changes[j].Type == Delete) {
			return false
		}
		if !isFileA && (changes[j].Type == Equal || changes[j].Type == Insert) {
			return false
		}
	}
	return true
}

// --- (Previous Histogram & Hunk Logic Integrated) ---

func histogramDiff(a, b []string) []DiffRecord {
	if len(a) == 0 {
		return toRecords(b, Insert)
	}
	if len(b) == 0 {
		return toRecords(a, Delete)
	}

	idxA, idxB := findPivot(a, b)
	if idxA == -1 {
		return append(toRecords(a, Delete), toRecords(b, Insert)...)
	}

	before := histogramDiff(a[:idxA], b[:idxB])
	pivot := DiffRecord{Payload: a[idxA], Type: Equal}
	after := histogramDiff(a[idxA+1:], b[idxB+1:])

	return append(append(before, pivot), after...)
}

func findPivot(a, b []string) (int, int) {
	type stats struct{ ca, cb, ia, ib int }
	counts := make(map[string]*stats)
	for i, s := range a {
		if _, ok := counts[s]; !ok {
			counts[s] = &stats{}
		}
		counts[s].ca++
		counts[s].ia = i
	}
	for i, s := range b {
		if sInfo, ok := counts[s]; ok {
			sInfo.cb++
			sInfo.ib = i
		}
	}
	bestIdxA, bestIdxB, minCount := -1, -1, int(^uint(0)>>1)
	for _, s := range a {
		info := counts[s]
		if info.ca > 0 && info.cb > 0 {
			total := info.ca + info.cb
			if total < minCount {
				minCount, bestIdxA, bestIdxB = total, info.ia, info.ib
			}
			if total == 2 {
				return info.ia, info.ib
			}
		}
	}
	return bestIdxA, bestIdxB
}

type Hunk struct {
	aStart, aLen int
	bStart, bLen int
	Changes      []DiffRecord
}

func groupHunks(diffs []DiffRecord) []Hunk {
	var hunks []Hunk
	n := len(diffs)
	i := 0
	for i < n {
		for i < n && diffs[i].Type == Equal {
			i++
		}
		if i >= n {
			break
		}

		start := max(i-ContextLines, 0)

		aStart, bStart := 1, 1
		for j := range start {
			if diffs[j].Type != Insert {
				aStart++
			}
			if diffs[j].Type != Delete {
				bStart++
			}
		}

		end, lastChange := i, i
		for end < n {
			if diffs[end].Type != Equal {
				lastChange = end
			} else if end-lastChange >= ContextLines*2 {
				break
			}
			end++
		}

		hunkEnd := min(lastChange+ContextLines+1, n)

		h := Hunk{aStart: aStart, bStart: bStart, Changes: diffs[start:hunkEnd]}
		for _, c := range h.Changes {
			if c.Type != Insert {
				h.aLen++
			}
			if c.Type != Delete {
				h.bLen++
			}
		}
		hunks = append(hunks, h)
		i = hunkEnd
	}
	return hunks
}

func toRecords(lines []string, op Op) []DiffRecord {
	res := make([]DiffRecord, len(lines))
	for i, l := range lines {
		res[i] = DiffRecord{Payload: l, Type: op}
	}
	return res
}

func isPurelyEqual(diffs []DiffRecord) bool {
	for _, d := range diffs {
		if d.Type != Equal {
			return false
		}
	}
	return true
}

// lines returns the lines in the file x, including newlines.
// If the file does not end in a newline, one is supplied
// along with a warning about the missing newline.
func lines(b []byte) [][]byte {
	ls := bytes.SplitAfter(b, []byte("\n"))
	if len(ls[len(ls)-1]) == 0 {
		ls = ls[:len(ls)-1]
	} else {
		// Treat last line as having a message about the missing newline attached,
		// using the same text as BSD/GNU diff (including the leading backslash).
		ls[len(ls)-1] = append(ls[len(ls)-1], "\n\\ No newline at end of file\n"...)
	}
	return ls
}
