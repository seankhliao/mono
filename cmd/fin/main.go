package main

import (
	"flag"
	"fmt"
	"io"
	"text/tabwriter"

	"go.seankhliao.com/mono/cmd/fin/findata"
	"go.seankhliao.com/mono/ycli"
)

func main() {
	ycli.OSExec(ycli.NewGroup(
		"fin",
		"fin is a custom tool to track expenses",
		func(fs *flag.FlagSet) {},
		ViewCommand(),
	))
}

type View struct {
	configPath string
}

func ViewCommand() ycli.Command {
	v := &View{}
	return ycli.NewGroup(
		"view",
		"view summarizes the data into different views, printed to the console.",
		v.register,
		ycli.New(
			"all",
			"all shows the current amount held in each category",
			nil,
			v.viewAll,
		),
		ycli.New(
			"year",
			"year shows the amount change for each category rolled up by year",
			nil,
			v.viewYearly,
		),
		ycli.New(
			"month",
			"monthh shows the amount change for each category rolled up by month",
			nil,
			v.viewMonthly,
		),
	)
}

func (v *View) register(fs *flag.FlagSet) {
	fs.StringVar(&v.configPath, "config", "gbp.fin.cue", "path to config file")
}

func (v *View) viewMonthly(stdout, stderr io.Writer) error {
	cur, err := findata.DecodeFile(v.configPath)
	if err != nil {
		return fmt.Errorf("decode data: %w", err)
	}

	sum := findata.SummarizeMonthly(cur)

	w := tabwriter.NewWriter(stdout, 1, 8, 2, ' ', tabwriter.AlignRight)
	printTable(w, sum, "ASSETS", cur.Assets)
	printTable(w, sum, "DEBTS", cur.Debts)
	printTable(w, sum, "INCOMES", cur.Incomes)
	printTable(w, sum, "EXPENSES", cur.Expenses)

	return nil
}

func (v *View) viewYearly(stdout, stderr io.Writer) error {
	cur, err := findata.DecodeFile(v.configPath)
	if err != nil {
		return fmt.Errorf("decode data: %w", err)
	}

	sum := findata.SummarizeYearly(cur)

	w := tabwriter.NewWriter(stdout, 1, 8, 2, ' ', tabwriter.AlignRight)
	printTable(w, sum, "ASSETS", cur.Assets)
	printTable(w, sum, "DEBTS", cur.Debts)
	printTable(w, sum, "INCOMES", cur.Incomes)
	printTable(w, sum, "EXPENSES", cur.Expenses)

	return nil
}

func (v *View) viewAll(stdout, stderr io.Writer) error {
	cur, err := findata.DecodeFile(v.configPath)
	if err != nil {
		return fmt.Errorf("decode data: %w", err)
	}

	sum := findata.SummarizeAll(cur)

	w := tabwriter.NewWriter(stdout, 1, 8, 2, ' ', tabwriter.AlignRight)
	printTable(w, sum, "ASSETS", cur.Assets)
	printTable(w, sum, "DEBTS", cur.Debts)
	printTable(w, sum, "INCOMES", cur.Incomes)
	printTable(w, sum, "EXPENSES", cur.Expenses)

	return nil
}

func printTable(w io.Writer, sum []findata.Summary, name string, names []string) {
	fmt.Fprintf(w, "%s\t", name)
	for _, name := range names {
		fmt.Fprint(w, name, "\t")
	}
	fmt.Fprintln(w)
	for _, month := range sum {
		month.MarshalTSV(w, name, names)
	}
	fmt.Fprintln(w)
}
