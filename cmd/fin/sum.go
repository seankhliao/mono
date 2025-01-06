package main

import (
	"fmt"
	"io"
	"slices"
)

// Assets
// -       Group1
//         Rolling_Sum | Monthly_Delta
// Incomes
// Expenses

type Results struct {
	Assets   MonthlyResults
	Debts    MonthlyResults
	Incomes  MonthlyResults
	Expenses MonthlyResults
}
type MonthlyResults struct {
	GroupName string
	Headings  []string
	Months    []MonthlyResult
}
type MonthlyResult struct {
	Year     int
	Month    int
	Category map[string]*CategoryResult
}
type CategoryResult struct {
	Add, Sub   int
	RollingSum int
}

func Summarize(c Currency) Results {
	var r Results

	slices.Sort(c.Assets)
	r.Assets.GroupName = "ASSETS"
	r.Assets.Headings = slices.Clone(c.Assets)
	slices.Sort(c.Debts)
	r.Debts.GroupName = "DEBTS"
	r.Debts.Headings = slices.Clone(c.Debts)
	slices.Sort(c.Incomes)
	r.Incomes.GroupName = "INCOMES"
	r.Incomes.Headings = slices.Clone(c.Incomes)
	slices.Sort(c.Expenses)
	r.Expenses.GroupName = "EXPENSES"
	r.Expenses.Headings = slices.Clone(c.Expenses)

	for _, m := range c.Months {
		head := [4]*MonthlyResults{&r.Assets, &r.Debts, &r.Incomes, &r.Expenses}
		monthly := [4]MonthlyResult{}
		for i := range monthly {
			monthly[i].Year = m.Year
			monthly[i].Month = m.Month
			monthly[i].Category = make(map[string]*CategoryResult)
			for _, cat := range head[i].Headings {
				monthly[i].Category[cat] = &CategoryResult{}
				if len(head[i].Months) > 0 {
					monthly[i].Category[cat].RollingSum = head[i].Months[len(head[i].Months)-1].Category[cat].RollingSum
				}
			}
		}

		for _, transaction := range m.Transactions {
			var group int
			for g, headings := range head {
				if slices.Contains(headings.Headings, transaction.Src) {
					group = g
					break
				}
			}
			if _, ok := monthly[group].Category[transaction.Src]; !ok {
				monthly[group].Category[transaction.Src] = &CategoryResult{}
			}
			if transaction.Val >= 0 {
				monthly[group].Category[transaction.Src].Add -= transaction.Val
			} else {
				monthly[group].Category[transaction.Src].Sub -= transaction.Val
			}
			monthly[group].Category[transaction.Src].RollingSum -= transaction.Val

			for g, headings := range head {
				if slices.Contains(headings.Headings, transaction.Dst) {
					group = g
					break
				}
			}
			if _, ok := monthly[group].Category[transaction.Dst]; !ok {
				monthly[group].Category[transaction.Dst] = &CategoryResult{}
			}
			if transaction.Val >= 0 {
				monthly[group].Category[transaction.Dst].Sub += transaction.Val
			} else {
				monthly[group].Category[transaction.Dst].Add += transaction.Val
			}
			monthly[group].Category[transaction.Dst].RollingSum += transaction.Val
		}

		r.Assets.Months = append(r.Assets.Months, monthly[0])
		r.Debts.Months = append(r.Debts.Months, monthly[1])
		r.Incomes.Months = append(r.Incomes.Months, monthly[2])
		r.Expenses.Months = append(r.Expenses.Months, monthly[3])
	}

	return r
}

func Print(w io.Writer, r Results) {
	printGroup(w, r.Assets)
	printGroup(w, r.Debts)
	printGroup(w, r.Incomes)
	printGroup(w, r.Expenses)
}

func printGroup(w io.Writer, r MonthlyResults) {
	fmt.Fprintln(w, r.GroupName)
	for start, end := 0, min(5, len(r.Headings)); start < len(r.Headings); start, end = start+5, min(end+5, len(r.Headings)) {
		fmt.Fprintf(w, "       ")
		for _, cat := range r.Headings[start:end] {
			fmt.Fprintf(w, " | %29s", cat)
		}
		fmt.Fprintln(w)
		for _, m := range r.Months {
			fmt.Fprintf(w, "%d-%02d", m.Year, m.Month)
			for _, cat := range r.Headings[start:end] {
				fmt.Fprintf(w, " |%+9.2f /%+9.2f %9.2f", float64(m.Category[cat].Sub)/100, float64(m.Category[cat].Add)/100, float64(m.Category[cat].RollingSum)/100)
			}
			fmt.Fprintln(w)
		}
		fmt.Fprintln(w)
	}
}
