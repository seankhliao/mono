package main

import (
	"fmt"
	"io"
	"strconv"
	"strings"
)

func (c *Convert) yonder(stdout, stderr io.Writer) error {
	records, err := c.reader()
	if err != nil {
		return fmt.Errorf("read input: %w", err)
	}
	for _, rec := range records[1:] {
		date := rec[0]
		name, category := rec[1], rec[5]
		src, dst := "YON", categorize(name, category)

		val := rec[2]
		pound, pence, ok := strings.Cut(val, ".")
		if !ok {
			pence = "00"
		} else if len(pence) == 1 {
			pence += "0"
		}
		val = pound + pence
		value, err := strconv.Atoi(val)
		if err != nil {
			return fmt.Errorf("convert %s into int: %v", rec[4], err)
		}

		direction := rec[6]
		switch direction {
		case "Credit":
			src, dst = dst, src
		case "Debit":
		// noop
		default:
			return fmt.Errorf("unhandled credit/debit: %s", direction)
		}

		country := rec[7]
		desc := fmt.Sprintf("%s %s %s", date, name, country)
		fmt.Printf(`[%s, %s, %d, %q],`+"\n", src, dst, value, desc)

	}

	return nil
}
