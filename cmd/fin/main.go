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
	"path"
	"path/filepath"
	"strings"

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
			"chase",
			"convert chase statements",
			nil,
			c.chase,
		),
		ycli.New(
			"hsbc",
			"convert hsbc statements",
			nil,
			c.hsbc,
		),
		ycli.New("trading",
			"convert trading212 statements",
			nil,
			c.trading,
		),
	)
}

func (c *Convert) register(fs *flag.FlagSet) {
	fs.StringVar(&c.filepath, "file", "", "path to statement file")
	fs.StringVar(&c.hsbcCard, "hsbc", "debit", "hsbc account debit or credit")
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

type View struct {
	configPath string
}

func ViewCommand() ycli.Command {
	v := &View{}
	return ycli.New(
		"view",
		"view summarizes the data into different views, printed to the console.",
		v.register,
		v.viewAll,
	)
}

func (v *View) register(fs *flag.FlagSet) {
	fs.StringVar(&v.configPath, "config", "gbp.fin.cue", "path to config file")
}

func (v *View) viewAll(stdout, stderr io.Writer) error {
	cur, err := DecodeFile(v.configPath)
	if err != nil {
		return fmt.Errorf("decode data: %w", err)
	}
	Summarize(&cur)
	Print(stdout, &cur)

	return nil
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
