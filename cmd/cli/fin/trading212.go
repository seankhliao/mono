package main

import (
	"bytes"
	"fmt"
	"io"
	"maps"
	"slices"
	"strconv"
	"strings"
)

func (c *Convert) trading(stdout, stderr io.Writer) error {
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
