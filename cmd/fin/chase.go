package main

import (
	"fmt"
	"io"
	"strconv"
	"strings"
)

func (c *Convert) chase(stdout, stderr io.Writer) error {
	records, err := c.reader()
	if err != nil {
		return fmt.Errorf("read input: %w", err)
	}

	records = records[2:] // skip title + header
	for _, rec := range records {
		date, time_ := rec[0], rec[1]
		tx, desc := rec[2], rec[3]
		val := rec[4]
		if strings.Contains(val, ".") {
			val = strings.ReplaceAll(val, ".", "")
		} else {
			val += "00"
		}
		value, err := strconv.Atoi(val)
		if err != nil {
			return fmt.Errorf("convert %s into int: %v", rec[4], err)
		}

		tx, _, _ = strings.Cut(tx, " |")
		src, dst := "CSE", categorize(desc, "")
		desc = strings.Join([]string{date, time_, desc}, " ")
		switch tx {
		case "Purchase":
			value *= -1
		case "Payment":
			if value > 0 {
				src, dst = dst, src
			} else {
				value *= -1
			}
		case "Direct Debit":
			value *= -1
		case "Refund":
			src, dst = dst, src
		default:
			return fmt.Errorf("unhandled transaction type: %s", tx)
		}

		fmt.Printf(`[%s, %s, %d, %q],`+"\n", src, dst, value, desc)

	}

	return nil
}
