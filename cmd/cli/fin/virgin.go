package main

import (
	"fmt"
	"io"
	"slices"
	"strconv"
	"strings"
)

func (c *Convert) virgin(stdout, stderr io.Writer) error {
	records, err := c.reader()
	if err != nil {
		return fmt.Errorf("read input: %w", err)
	}

	// Transaction Date,Posting Date,Billing Amount,Merchant,Merchant City,Merchant State,Merchant Postcode,Reference Number,Debit or Credit,SICMCC Code,Status,Transaction Currency,Additional Card Holder,Card Used
	records = records[1:]
	slices.Reverse(records)
	for i, rec := range records {
		date := rec[0]
		vals := rec[2]
		vals = strings.ReplaceAll(vals, ".", "")
		val, err := strconv.Atoi(vals)
		if err != nil {
			return fmt.Errorf("convert line %d value %s to int: %w", i+1, vals, err)
		}

		merchant, city, state := rec[3], rec[4], rec[5]

		src := "VIR"
		dst := categorize(merchant, "")
		dir := rec[8]
		switch dir {
		case "DBIT":
		// noop

		default:
			return fmt.Errorf("unknown debit/credit: %s", dir)
		}

		desc := fmt.Sprintf("%s %s %s %s", date, merchant, city, state)

		fmt.Fprintf(stdout, "[%s, %s, %d, %q],\n", src, dst, val, desc)
	}
	return nil
}
