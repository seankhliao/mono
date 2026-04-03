package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/csv"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"maps"
	"os"
	"path"
	"slices"
	"strconv"
	"strings"

	"go.seankhliao.com/mono/run"
)

func runWrap(f func(stdout, stderr io.Writer) error) run.Runner {
	return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
		return f(stdout, stderr)
	}
}

type Convert struct {
	filepath string
	hsbcCard string
}

func ConvertCommand() run.Commander {
	return run.Group(
		"convert",
		"convert card statements to fin data",
		run.Simple("amex", "amex transactions in csv", &ConvertAmex{}),
		run.Simple("chasedebit", "chase current transactions in tsv", &ConvertChaseDebit{}),
		run.Simple("chasesave", "chase saver transactions in tsv", &ConvertChaseSave{}),
		run.Simple("chasecredit", "chase credit transactions as txt", &ConvertChaseCredit{}),
		run.Simple("hsbcdebit", "hsbc transactions in csv", &ConvertHSBCDebit{}),
		run.Simple("trading212", "trading212 transactions in csv", &ConvertTrading212{}),
		run.Simple("virgin", "virgin transactions in csv", &ConvertVirgin{}),
	)
}

func (c *Convert) register(fs *flag.FlagSet) {
	fs.StringVar(&c.filepath, "file", "", "path to statement file")
	fs.StringVar(&c.hsbcCard, "hsbc", "debit", "hsbc account debit or credit")
}

func (c *Convert) Flags(fset *flag.FlagSet, args **[]string) error {
	c.register(fset)
	return nil
}

func (c *Convert) reader() ([][]string, error) {
	if c.filepath == "" {
		return nil, fmt.Errorf("no file given")
	}
	b, err := os.ReadFile(c.filepath)
	if err != nil {
		return nil, fmt.Errorf("read file: %w", err)
	}
	cr := csv.NewReader(bytes.NewReader(b))

	if path.Ext(c.filepath) == ".tsv" {
		cr.Comma = '\t'
	}

	records, err := cr.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("read all records: %w", err)
	}
	return records, nil
}

var (
	_ run.Simpler = &ConvertAmex{}
	_ run.Simpler = &ConvertChaseDebit{}
	_ run.Simpler = &ConvertChaseSave{}
	_ run.Simpler = &ConvertChaseCredit{}
	_ run.Simpler = &ConvertHSBCDebit{}
	_ run.Simpler = &ConvertTrading212{}
	_ run.Simpler = &ConvertVirgin{}
)

type ConvertAmex struct {
	Convert
}

func (c *ConvertAmex) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
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

		src := "AMC"
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

type ConvertChaseDebit struct {
	Convert
}

func (c *ConvertChaseDebit) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	records, err := c.reader()
	if err != nil {
		return fmt.Errorf("read input: %w", err)
	}

	records = records[2:] // skip title + header
	for _, rec := range records {
		date, time_ := rec[0], rec[1]
		tx, desc := rec[2], rec[3]
		val := rec[4]
		val = strings.ReplaceAll(val, ",", "")
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

type ConvertChaseSave struct {
	Convert
}

func (c *ConvertChaseSave) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	records, err := c.reader()
	if err != nil {
		return fmt.Errorf("read input: %w", err)
	}

	records = records[2:] // skip title + header
	for _, rec := range records {
		date := rec[0]
		ts := rec[1]
		trtype := rec[2]
		desc := rec[3]
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

		src, dst := "_", "_"

		switch trtype {
		case "Payment":
			src, dst = "_", "CSS"
			if value < 0 {
				value *= -1
				src, dst = dst, src
			}
		case "Interest":
			src, dst = "FIN", "CSS"
		}

		desc = fmt.Sprintf("%s %s %s", date, ts, desc)

		fmt.Fprintf(stdout, "[%s, %s, %d, %q],\n", src, dst, value, desc)
	}
	return nil
}

type ConvertChaseCredit struct {
	Convert
}

func (c *ConvertChaseCredit) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
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
		name := strings.TrimSpace(s[11:])
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

type ConvertHSBCDebit struct {
	Convert
}

func (c *ConvertHSBCDebit) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	records, err := c.reader()
	if err != nil {
		return fmt.Errorf("read input: %w", err)
	}

	card := "HSB"
	for i := len(records) - 1; i >= 0; i-- {
		rec := records[i]
		date, desc_, val := rec[0], rec[1], rec[2]
		desc := date + " " + desc_
		desc = strings.Join(strings.Fields(desc), " ")

		dst := card
		src := categorize(desc_, "")

		val = strings.ReplaceAll(val, ".", "")
		val = strings.ReplaceAll(val, ",", "")
		if val[0] == '-' {
			val = val[1:]
			src, dst = dst, src
		}

		val = strings.TrimLeft(val, "0")

		fmt.Fprintf(stdout, "[%s, %s, %s, %q],\n", src, dst, val, desc)
	}
	return nil
}

type ConvertTrading212 struct {
	Convert
}

func (c *ConvertTrading212) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	records, err := c.reader()
	if err != nil {
		return fmt.Errorf("read input: %w", err)
	}

	interest := make(map[string]map[string]int)
	cashback := make(map[string]map[string]int)

	idxs := make(map[string]int)
	for idx, name := range records[0] {
		idxs[name] = idx
	}

	bufs := make(map[string]*bytes.Buffer)

	records = records[1:]
	for _, rec := range records {
		curr := rec[idxs["Currency (Total)"]]
		buf, ok := bufs[curr]
		if !ok {
			buf = new(bytes.Buffer)
			bufs[curr] = buf
		}

		val := rec[idxs["Total"]]
		val = strings.ReplaceAll(val, ".", "")
		val = strings.TrimPrefix(val, "0")
		value, _ := strconv.Atoi(val)
		switch action := rec[idxs["Action"]]; action {
		case "Deposit", "Withdrawal":
			// ignore, recorded from HSBC
		case "Interest on cash":
			months, ok := interest[curr]
			if !ok {
				months = make(map[string]int)
				interest[curr] = months
			}

			ym := rec[idxs["Time"]][:7]
			months[ym] += value

		case "Spending cashback":
			months, ok := cashback[curr]
			if !ok {
				months = make(map[string]int)
				cashback[curr] = months
			}

			ym := rec[idxs["Time"]][:7]
			months[ym] += value

		case "New card cost":
			value *= -1
			fmt.Fprintf(buf, "[TOC, FIN, %d, %q],\n", value, action)

		case "Card debit":
			value *= -1
			merchant := rec[idxs["Merchant name"]]
			category := rec[idxs["Merchant category"]]
			desc := strings.Join([]string{rec[idxs["Time"]], category, merchant}, " ")
			fmt.Fprintf(buf, "[TOC, %s, %d, %q],\n", categorize(merchant, category), value, desc)

		case "Card credit":
			merchant := rec[idxs["Merchant name"]]
			category := rec[idxs["Merchant category"]]
			desc := strings.Join([]string{rec[idxs["Time"]], category, merchant}, " ")
			fmt.Fprintf(buf, "[%s, TOC, %d, %q],\n", categorize(merchant, category), value, desc)

		case "Currency conversion":
			desc := strings.Join([]string{rec[idxs["Time"]], rec[idxs["Notes"]]}, " ")
			fromCurr := rec[idxs["Currency (Currency conversion from amount)"]]
			fromVal := rec[idxs["Currency conversion from amount"]]
			fromVal = strings.ReplaceAll(fromVal, ".", "")
			fromVal = strings.TrimPrefix(fromVal, "0")
			fromValue, _ := strconv.Atoi(fromVal)
			toCurr := rec[idxs["Currency (Currency conversion to amount)"]]
			toVal := rec[idxs["Currency conversion to amount"]]
			toVal = strings.ReplaceAll(toVal, ".", "")
			toVal = strings.TrimPrefix(toVal, "0")
			toValue, _ := strconv.Atoi(toVal)
			feeCurr := rec[idxs["Currency (Currency conversion fee)"]]
			feeVal := rec[idxs["Currency conversion fee"]]
			feeVal = strings.ReplaceAll(feeVal, ".", "")
			feeVal = strings.TrimPrefix(feeVal, "0")
			feeValue, _ := strconv.Atoi(feeVal)
			feeValue *= -1

			buf = bufs[fromCurr]
			if buf == nil {
				buf = new(bytes.Buffer)
				bufs[fromCurr] = buf
			}
			fmt.Fprintf(buf, "[TOC, FRX, %d, %q],\n", fromValue, desc)
			buf = bufs[toCurr]
			if buf == nil {
				buf = new(bytes.Buffer)
				bufs[toCurr] = buf
			}
			fmt.Fprintf(buf, "[FRX, TOC, %d, %q],\n", toValue, desc)

			buf = bufs[feeCurr]
			fmt.Fprintf(buf, "[TOC, FIN, %d, %q],\n", feeValue, "Currency conversion fee")

		case "Market sell", "Limit sell", "Stop sell":
			desc := strings.Join([]string{rec[idxs["Time"]], rec[idxs["Ticker"]], rec[idxs["Name"]]}, " ")
			fmt.Fprintf(buf, "[TOT, TOC, %d, %q],\n", value, desc)

		case "Market buy", "Limit buy":
			desc := strings.Join([]string{rec[idxs["Time"]], rec[idxs["Ticker"]], rec[idxs["Name"]]}, " ")
			fmt.Fprintf(buf, "[TOC, TOT, %d, %q],\n", value, desc)

		case "Dividend (Dividend)":
			desc := strings.Join([]string{rec[idxs["Time"]], rec[idxs["Ticker"]], rec[idxs["Name"]]}, " ")
			fmt.Fprintf(buf, "[FIN, TOC, %d, %q],\n", value, desc)

		case "Lending interest":
			desc := strings.Join([]string{rec[idxs["Time"]], "Share lending interest"}, " ")
			fmt.Fprintf(buf, "[FIN, TOC, %d, %q],\n", value, desc)
		case "Stock split open", "Stock split close":
			continue
		case "Card ATM Withdrawal":
			merchant := rec[idxs["Merchant name"]]
			category := rec[idxs["Merchant category"]]
			dst := "CSH"
			resCurr := rec[idxs["Currency (Currency conversion fee)"]]
			if resCurr != "GBP" {
				dst = "FRX"
			}
			desc := strings.Join([]string{rec[idxs["Time"]], "Card ATM Withdrawal", merchant, category}, " ")
			fmt.Fprintf(buf, "[TOC, %s, %d, %q],\n", dst, value, desc)
		default:
			panic("unhandled action " + action)
		}
	}
	for curr, months := range interest {
		for _, month := range slices.Sorted(maps.Keys(months)) {
			value := months[month]
			buf := bufs[curr]
			fmt.Fprintf(buf, `[FIN, TOC, %d, "%s Interest on cash"],`+"\n", value, month)
		}
	}
	for curr, months := range cashback {
		for _, month := range slices.Sorted(maps.Keys(months)) {
			value := months[month]
			buf := bufs[curr]
			fmt.Fprintf(buf, `[FIN, TOC, %d, "%s Spending cashback"],`+"\n", value, month)
		}
	}

	curr := slices.Collect(maps.Keys(bufs))
	slices.Sort(curr)
	for _, key := range curr {
		fmt.Printf("\n\n%s:\n\n%s", key, bufs[key].String())
	}

	return nil
}

type ConvertVirgin struct {
	Convert
}

func (c *ConvertVirgin) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
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
		case "CRDT":
			src, dst = dst, src

		default:
			return fmt.Errorf("unknown debit/credit: %s", dir)
		}

		desc := fmt.Sprintf("%s %s %s %s", date, merchant, city, state)

		fmt.Fprintf(stdout, "[%s, %s, %d, %q],\n", src, dst, val, desc)
	}
	return nil
}
