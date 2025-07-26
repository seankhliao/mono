package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"os"
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

		tx, _, _ = strings.Cut(tx, " |")
		src, dst := "CSE", categorize(desc, "")
		desc = strings.Join([]string{date, time_, desc}, " ")
		switch tx {
		case "Cash withdrawal":
			value *= -1
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
		case "Transfer":
			src, dst = dst, src
			if value < 0 {
				value *= -1
				src, dst = dst, src
			}
		default:
			return fmt.Errorf("unhandled transaction type: %s", tx)
		}

		fmt.Fprintf(stdout, `[%s, %s, %d, %q],`+"\n", src, dst, value, desc)

	}

	return nil
}

func (c *Convert) chasetxt(stdout, stderr io.Writer) error {
	if c.filepath == "" {
		return fmt.Errorf("no file given")
	}
	b, err := os.ReadFile(c.filepath)
	if err != nil {
		return fmt.Errorf("read file: %w", err)
	}
	sc := bufio.NewScanner(bytes.NewReader(b))
	for sc.Scan() {
		// dd Mmm Yyyy <name>
		s := sc.Text()
		date := s[:11]
		name := strings.TrimSpace(s[12:])
		dst := categorize(name, "")

		ok := sc.Scan()
		if !ok {
			return fmt.Errorf("expected transaction details after: %q", s)
		}
		s = sc.Text()
		act, det, ok := strings.Cut(s, " ")
		if !ok {
			return fmt.Errorf("expected category [details] amount in: %q", s)
		}
		src := ""
		switch act {
		case "Purchase":
			src = "CSC"
		case "Repayment":
			src = "CSE"
			dst = "CSC"
		case "Refund":
			src = dst
			dst = "CSC"
		default:
			return fmt.Errorf("unhandled action: %q", act)
		}

		delim := "£"
		i := strings.LastIndex(det, delim)
		extra, vals := det[:i], det[i+len(delim):]
		vals = strings.ReplaceAll(vals, ".", "")
		val, err := strconv.Atoi(vals)
		if err != nil {
			return fmt.Errorf("convert amount %q: %w", vals, err)
		}

		desc := date + " " + name
		extra = strings.Trim(extra, "| ")
		if extra != "" {
			desc += " | " + extra
		}

		fmt.Fprintf(stdout, `[%s, %s, %d, %q],`+"\n", src, dst, val, desc)
	}
	return nil
}
