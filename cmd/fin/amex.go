package main

import (
	"fmt"
	"io"
	"strings"
)

func (c *Convert) amex(stdout, stderr io.Writer) error {
	records, err := c.reader()
	if err != nil {
		return fmt.Errorf("read input: %w", err)
	}

	records = records[1:]
	for i := len(records) - 1; i >= 0; i-- {
		rec := records[i]
		date, desc_, val := rec[0], rec[1], rec[2]
		desc_ = strings.Join(strings.Fields(desc_), " ")
		desc := date + " " + desc_

		src := "AMX"
		dst := categorize(desc_, "")

		val = strings.ReplaceAll(val, ".", "")
		if val[0] == '-' {
			val = val[1:]
			src, dst = dst, src
		}
		val = strings.TrimLeft(val, "0")

		fmt.Fprintf(stdout, "[%s, %s, %s, %q],\n", src, dst, val, desc)
	}
	return nil
}
