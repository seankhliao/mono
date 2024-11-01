package main

import (
	"bytes"
	"context"
	"crypto/md5"
	"encoding/csv"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"text/tabwriter"

	"go.seankhliao.com/mono/cmd/fin/findata"
	"go.seankhliao.com/mono/ycli"
	"gocloud.dev/blob"
	_ "gocloud.dev/blob/gcsblob"
)

func main() {
	ycli.OSExec(ycli.NewGroup(
		"fin",
		"fin is a custom tool to track expenses",
		func(fs *flag.FlagSet) {},
		ViewCommand(),
		PushCommand(),
		PullCommand(),
		ConvertCommand(),
	))
}

type Convert struct {
	filepath string
	hsbcCard string
}

func ConvertCommand() ycli.Command {
	c := &Convert{}
	return ycli.NewGroup(
		"convert",
		"convert card statements to fin data",
		c.register,
		ycli.New(
			"amex",
			"convert amex statements",
			nil,
			c.amex,
		),
		ycli.New(
			"hsbc",
			"convert hsbc statements",
			nil,
			c.hsbc,
		),
	)
}

func (c *Convert) register(fs *flag.FlagSet) {
	fs.StringVar(&c.filepath, "file", "", "path to statement file")
	fs.StringVar(&c.hsbcCard, "hsbc", "debit", "hsbc account debit or credit")
}

func (c *Convert) amex(stdout, stderr io.Writer) error {
	if c.filepath == "" {
		return fmt.Errorf("no file given")
	}
	b, err := os.ReadFile(c.filepath)
	if err != nil {
		return fmt.Errorf("read file: %w", err)
	}
	cr := csv.NewReader(bytes.NewReader(b))
	records, err := cr.ReadAll()
	if err != nil {
		return fmt.Errorf("read all records: %w", err)
	}

	records = records[1:]
	for i := len(records) - 1; i >= 0; i-- {
		rec := records[i]
		date, desc, val := rec[0], rec[1], rec[2]
		desc = date + " " + desc
		desc = strings.Join(strings.Fields(desc), " ")

		src := "AMX"
		dst := categorize(desc)

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

func (c *Convert) hsbc(stdout, stderr io.Writer) error {
	if c.filepath == "" {
		return fmt.Errorf("no file given")
	}
	b, err := os.ReadFile(c.filepath)
	if err != nil {
		return fmt.Errorf("read file: %w", err)
	}
	cr := csv.NewReader(bytes.NewReader(b))
	records, err := cr.ReadAll()
	if err != nil {
		return fmt.Errorf("read all records: %w", err)
	}

	card := "HSB"
	if c.hsbcCard == "credit" {
		card = "HSC"
	}

	for i := len(records) - 1; i >= 0; i-- {
		rec := records[i]
		date, desc, val := rec[0], rec[1], rec[2]
		desc = date + " " + desc
		desc = strings.Join(strings.Fields(desc), " ")

		dst := card
		src := categorize(desc)

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

// func (c *Convert) trading(stdout, stderr io.Writer) error {
// 	if c.filepath == "" {
// 		return fmt.Errorf("no file given")
// 	}
// 	b, err := os.ReadFile(c.filepath)
// 	if err != nil {
// 		return fmt.Errorf("read file: %w", err)
// 	}
// 	cr := csv.NewReader(bytes.NewReader(b))
// 	records, err := cr.ReadAll()
// 	if err != nil {
// 		return fmt.Errorf("read all records: %w", err)
// 	}
//
// 	var cashback, interest int
//
// 	records = records[1:]
// 	for i := len(records) - 1; i >= 0; i-- {
// 		rec := records[i]
// 		cur := rec[3]
// 		if cur != "GBP" {
// 			continue
// 		}
//
// 		val := rec[2]
// 		val = strings.ReplaceAll(val, ".", "")
// 		val = strings.TrimPrefix(val, "0")
// 		value, _ := strconv.Atoi(val)
// 		switch rec[0] {
// 		case "Interest on cash":
// 			interest += value
// 		case "Spending cashback":
// 			cashback += value
// 		case "Card debit":
// 			date := rec[1]
//
// 		}
//
// 	}
//
// 	return nil
// }

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
	if len(names) == 0 {
		return
	}
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

func PushCommand() ycli.Command {
	var bucketName string
	var localGlob string
	return ycli.New(
		"push",
		"upload local data to a storage bucket",
		func(fs *flag.FlagSet) {
			fs.StringVar(&bucketName, "bucket", "gs://fin-liao-dev", "bucket identifier")
			fs.StringVar(&localGlob, "glob", "*.fin.cue", "a glob pattern patching local files")
		},
		func(stdout, stderr io.Writer) error {
			err := runPush(stdout, bucketName, localGlob)
			if err != nil {
				return fmt.Errorf("push: %w", err)
			}
			return nil
		},
	)
}

func runPush(stdout io.Writer, bucketName, localGlob string) error {
	files, err := filepath.Glob(localGlob)
	if err != nil {
		return fmt.Errorf("match local files %q: %w", localGlob, err)
	}

	ctx := context.Background()
	bkt, err := blob.OpenBucket(ctx, bucketName)
	if err != nil {
		return fmt.Errorf("open bucket %q: %q", bucketName, err)
	}

	for _, file := range files {
		b, err := os.ReadFile(file)
		if err != nil {
			return err
		}

		localMD5 := md5.Sum(b)

		fileName := filepath.Base(file)
		attrs, err := bkt.Attributes(ctx, fileName)
		if err == nil {
			if bytes.Equal(localMD5[:], attrs.MD5) {
				fmt.Fprintln(stdout, "skipping unchanged file", file)
				continue
			}
		}

		err = bkt.WriteAll(ctx, fileName, b, &blob.WriterOptions{
			ContentType: "text/plain",
		})
		if err != nil {
			return fmt.Errorf("upload %q: %w", file, err)
		}

		fmt.Fprintln(stdout, "uploaded", file)
	}
	return nil
}

func PullCommand() ycli.Command {
	var bucketName string
	return ycli.New(
		"pull",
		"download remote data from a storage bucket",
		func(fs *flag.FlagSet) {
			fs.StringVar(&bucketName, "bucket", "gs://fin-liao-dev", "bucket identifier")
		},
		func(stdout, stderr io.Writer) error {
			err := runPull(stdout, bucketName)
			if err != nil {
				return fmt.Errorf("push: %w", err)
			}
			return nil
		},
	)
}

func runPull(stdout io.Writer, bucketName string) error {
	ctx := context.Background()
	bkt, err := blob.OpenBucket(ctx, bucketName)
	if err != nil {
		return fmt.Errorf("open bucket %q: %q", bucketName, err)
	}

	items := bkt.List(&blob.ListOptions{})
	for {
		item, err := items.Next(ctx)
		if err == io.EOF {
			break
		} else if err != nil {
			return fmt.Errorf("list bucket %q: %w", bucketName, err)
		} else if !strings.HasSuffix(item.Key, ".fin.cue") {
			continue
		}

		fileName := filepath.Base(item.Key)

		b, err := os.ReadFile(fileName)
		if err == nil {
			localMD5 := md5.Sum(b)
			if bytes.Equal(localMD5[:], item.MD5) {
				fmt.Fprintln(stdout, "skipping unchanged file", item.Key)
				continue
			}
		}

		b, err = bkt.ReadAll(ctx, item.Key)
		if err != nil {
			return fmt.Errorf("read %q: %w", item.Key, err)
		}

		err = os.WriteFile(fileName, b, 0o644)
		if err != nil {
			return fmt.Errorf("write %q: %w", fileName, err)
		}

		fmt.Fprintln(stdout, "downloaded", item.Key)
	}

	return nil
}
