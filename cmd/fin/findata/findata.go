package findata

import (
	"bytes"
	_ "embed"
	"fmt"
	"text/tabwriter"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
)

//go:embed schema.cue
var RawSchema []byte

func decode[T any](b []byte, p string) (T, error) {
	cuectx := cuecontext.New()
	val := cuectx.CompileBytes(b)
	schema := cuectx.CompileBytes(RawSchema)
	val = schema.Unify(val)

	var out T

	err := val.Validate()
	if err != nil {
		return out, fmt.Errorf("validate: %w", err)
	}

	err = val.LookupPath(cue.ParsePath(p)).Decode(&out)
	if err != nil {
		return out, fmt.Errorf("decode: %w", err)
	}

	return out, nil
}

func DecodeOne(b []byte) (Currency, error) {
	return decode[Currency](b, "one")
}

type (
	Currency struct {
		Currency string
		Holdings []string
		Incomes  []string
		Expenses []string
		Months   []Month
	}

	Month struct {
		Year         int
		Month        int
		Transactions []Transaction
	}

	Transaction struct {
		Src  string
		Dst  string
		Val  int
		Note string
	}
)

type View int

const (
	ViewHoldings = iota
	ViewIncomes
	ViewExpenses
)

func (c Currency) MarkdownTable(view View) []byte {
	var group []string
	switch view {
	case ViewHoldings:
		group = c.Holdings
	case ViewIncomes:
		group = c.Incomes
	case ViewExpenses:
		group = c.Expenses
	}

	// table header
	var buf bytes.Buffer
	buf.WriteString("|month|")
	for _, g := range group {
		buf.WriteString("**")
		buf.WriteString(g)
		buf.WriteString("**|")
	}
	buf.WriteString("\n")
	buf.WriteString("|---|")
	for range group {
		buf.WriteString("---|")
	}
	buf.WriteString("\n")

	// Months
	bag := make(map[string]int)
	for _, month := range c.Months {
		if view != ViewHoldings {
			// reset monthly for delta
			bag = make(map[string]int)
		}
		for _, transaction := range month.Transactions {
			bag[transaction.Src] -= transaction.Val
			bag[transaction.Dst] += transaction.Val
		}
		fmt.Fprintf(&buf, "|**%4d-%2d**|", month.Year, month.Month)
		for _, title := range group {
			val := float64(bag[title])
			if view == ViewIncomes && val != 0 {
				val *= -1
			}
			fmt.Fprintf(&buf, "%.2f|", val/100)
		}
		buf.WriteString("\n")
	}
	buf.WriteString("\n")

	return buf.Bytes()
}

func (c Currency) TabTable(view View) []byte {
	var group []string
	switch view {
	case ViewHoldings:
		group = c.Holdings
	case ViewIncomes:
		group = c.Incomes
	case ViewExpenses:
		group = c.Expenses
	}

	var buf bytes.Buffer
	tw := tabwriter.NewWriter(&buf, 1, 8, 2, ' ', tabwriter.AlignRight)
	fmt.Fprint(tw, "---\t")
	for _, g := range group {
		fmt.Fprint(tw, g, "\t")
	}
	fmt.Fprintln(tw)

	bag := make(map[string]int)
	for _, month := range c.Months {
		fmt.Fprint(tw, month.Year, "-", month.Month, "\t")
		for _, transaction := range month.Transactions {
			bag[transaction.Src] -= transaction.Val
			bag[transaction.Dst] += transaction.Val
		}
		for _, g := range group {
			fmt.Fprintf(tw, "%.2f\t", float64(bag[g])/100)
		}
		fmt.Fprintln(tw)
	}

	tw.Flush()

	return buf.Bytes()
}
