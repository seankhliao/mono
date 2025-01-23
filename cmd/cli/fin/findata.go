package main

import (
	_ "embed"
	"fmt"
	"io"
	"maps"
	"os"
	"strings"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
)

//go:embed schema.cue
var rawSchema []byte

type (
	Currency struct {
		Currency  string
		Groupings []Group
		Months    []Month

		invert map[string]int
	}
	Group struct {
		Name   string
		Names  []string
		Invert bool
	}

	Month struct {
		Year         int
		Month        int
		Transactions []Transaction

		add map[string]int
		sub map[string]int
		sum map[string]int
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

	// initialize output structs

	currency.invert = make(map[string]int)

	allNames := []string{}
	for i := range currency.Groupings {
		allNames = append(allNames, currency.Groupings[i].Names...)

		mod := 1
		if currency.Groupings[i].Invert {
			mod = -1
		}

		for _, n := range currency.Groupings[i].Names {
			currency.invert[n] = mod
		}
	}

	for i := range currency.Months {
		m := make(map[string]int)
		for _, n := range allNames {
			m[n] = 0
		}
		currency.Months[i].add = maps.Clone(m)
		currency.Months[i].sub = maps.Clone(m)
		currency.Months[i].sum = maps.Clone(m)

	}

	return currency, nil
}

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

func Summarize(c *Currency) {
	for i := range c.Months {
		if i > 0 {
			for n, v := range c.Months[i-1].sum {
				c.Months[i].sum[n] = v
			}
		}
		for _, tr := range c.Months[i].Transactions {
			mod := c.invert[tr.Src]
			if mod < 0 {
				c.Months[i].add[tr.Src] += tr.Val
			} else {
				c.Months[i].sub[tr.Src] += tr.Val
			}
			c.Months[i].sum[tr.Src] -= mod * tr.Val

			mod = c.invert[tr.Dst]
			if mod < 0 {
				c.Months[i].sub[tr.Dst] += tr.Val
			} else {
				c.Months[i].add[tr.Dst] += tr.Val
			}
			c.Months[i].sum[tr.Dst] += mod * tr.Val
		}
	}
}

func Print(w io.Writer, c *Currency) {
	for _, group := range c.Groupings {
		fmt.Println(group.Name)
		fmt.Println()

		for start, end := 0, min(5, len(group.Names)); start < len(group.Names); start, end = start+5, min(end+5, len(group.Names)) {
			fmt.Fprint(w, strings.Repeat(" ", 7)) // padding for date
			for _, n := range group.Names[start:end] {
				fmt.Fprintf(w, " |    %31s", n) // account name
			}
			fmt.Fprintln(w)

			for _, m := range c.Months {
				fmt.Fprintf(w, "%d-%02d", m.Year, m.Month) // date
				for _, n := range group.Names[start:end] {
					fmt.Fprintf(w, " |   %+9.2f /%+9.2f  %+10.2f", float64(m.add[n])/100, -float64(m.sub[n])/100, float64(m.sum[n])/100)
				}
				fmt.Fprintln(w)
			}
			fmt.Fprintln(w)
		}
		fmt.Fprintln(w)
	}
}
