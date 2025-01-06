package main

import (
	_ "embed"
	"fmt"
	"io"
	"os"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
)

//go:embed schema.cue
var rawSchema []byte

func decode[T any](b []byte, p string) (T, error) {
	cuectx := cuecontext.New()
	val := cuectx.CompileBytes(b)
	schema := cuectx.CompileBytes(rawSchema)
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

type (
	Currency struct {
		Currency string
		Assets   []string
		Debts    []string
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

func DecodeFile(filePath string) (Currency, error) {
	b, err := os.ReadFile(filePath)
	if err != nil {
		return Currency{}, fmt.Errorf("findata: read data from %q: %w", filePath, err)
	}

	currency, err := decode[Currency](b, "output")
	if err != nil {
		return Currency{}, fmt.Errorf("validate data from %q against schema: %w", filePath, err)
	}

	return currency, nil
}

type Summary struct {
	Year     int
	Month    int
	Assets   map[string]int
	Debts    map[string]int
	Incomes  map[string]int
	Expenses map[string]int
}

func SummarizeMonthly(c Currency) []Summary {
	var summaries []Summary
	for _, month := range c.Months {
		m := make(map[string]int)
		for _, tr := range month.Transactions {
			m[tr.Src] -= tr.Val
			m[tr.Dst] += tr.Val
		}
		summary := Summary{
			Year:     month.Year,
			Month:    month.Month,
			Assets:   make(map[string]int),
			Debts:    make(map[string]int),
			Incomes:  make(map[string]int),
			Expenses: make(map[string]int),
		}
		for _, asset := range c.Assets {
			summary.Assets[asset] += m[asset]
		}
		for _, debt := range c.Debts {
			summary.Debts[debt] -= m[debt]
		}
		for _, income := range c.Incomes {
			summary.Incomes[income] -= m[income]
		}
		for _, expense := range c.Expenses {
			summary.Expenses[expense] += m[expense]
		}
		summaries = append(summaries, summary)
	}
	return summaries
}

func SummarizeYearly(c Currency) []Summary {
	var summaries []Summary
	summary := Summary{
		Year:     c.Months[0].Year,
		Assets:   make(map[string]int),
		Debts:    make(map[string]int),
		Incomes:  make(map[string]int),
		Expenses: make(map[string]int),
	}
	for _, month := range c.Months {
		m := make(map[string]int)
		for _, tr := range month.Transactions {
			m[tr.Src] -= tr.Val
			m[tr.Dst] += tr.Val
		}

		if month.Year != summary.Year {
			summaries = append(summaries, summary)
			summary = Summary{
				Year:     month.Year,
				Assets:   make(map[string]int),
				Debts:    make(map[string]int),
				Incomes:  make(map[string]int),
				Expenses: make(map[string]int),
			}
		}

		for _, asset := range c.Assets {
			summary.Assets[asset] += m[asset]
		}
		for _, debt := range c.Debts {
			summary.Debts[debt] -= m[debt]
		}
		for _, income := range c.Incomes {
			summary.Incomes[income] -= m[income]
		}
		for _, expense := range c.Expenses {
			summary.Expenses[expense] += m[expense]
		}
	}
	summaries = append(summaries, summary)
	return summaries
}

func SummarizeAll(c Currency) []Summary {
	summary := Summary{
		Assets:   make(map[string]int),
		Debts:    make(map[string]int),
		Incomes:  make(map[string]int),
		Expenses: make(map[string]int),
	}
	for _, month := range c.Months {
		m := make(map[string]int)
		for _, tr := range month.Transactions {
			m[tr.Src] -= tr.Val
			m[tr.Dst] += tr.Val
		}
		for _, asset := range c.Assets {
			summary.Assets[asset] += m[asset]
		}
		for _, debt := range c.Debts {
			summary.Debts[debt] -= m[debt]
		}
		for _, income := range c.Incomes {
			summary.Incomes[income] -= m[income]
		}
		for _, expense := range c.Expenses {
			summary.Expenses[expense] += m[expense]
		}
	}
	return []Summary{summary}
}

func (s Summary) MarshalTSV(w io.Writer, name string, names []string) {
	s.printDate(w)
	var m map[string]int
	switch name {
	case "ASSETS":
		m = s.Assets
	case "DEBTS":
		m = s.Debts
	case "INCOMES":
		m = s.Incomes
	case "EXPENSES":
		m = s.Expenses
	}
	for _, name := range names {
		fmt.Fprintf(w, "%.2f\t", float64(m[name])/100)
	}
	fmt.Fprintln(w)
}

func (s Summary) printDate(w io.Writer) {
	if s.Year == 0 {
		fmt.Fprintf(w, "%s\t", "all")
	} else if s.Month == 0 {
		fmt.Fprintf(w, "%4d\t", s.Year)
	} else {
		fmt.Fprintf(w, "%4d-%02d\t", s.Year, s.Month)
	}
}
