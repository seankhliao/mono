package main

import (
	"bytes"
	"context"
	"crypto/md5"
	"encoding/csv"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"strings"

	"go.seankhliao.com/mono/cmdline"
	"gocloud.dev/blob"
	_ "gocloud.dev/blob/gcsblob"
)

func main() {
	cmdline.RunOS(&cmdline.CommandGroup{
		Name: "fin",
		Desc: "fin is a custom tool to track expenses",
		Subs: []cmdline.Commander{
			ViewCommand(),
			PushCommand(),
			PullCommand(),
			ConvertCommand(),
			TradingCommand(),
		},
	})
}

func runWrap(f func(stdout, stderr io.Writer) error) cmdline.Runner {
	return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
		err := f(stdout, stderr)
		if err != nil {
			fmt.Fprintln(stderr, err)
			return 1
		}
		return 0
	}
}

type Convert struct {
	filepath string
	hsbcCard string
}

func ConvertCommand() cmdline.Commander {
	c := &Convert{}
	return &cmdline.CommandGroup{
		Name: "convert",
		Desc: "convert card statements to fin data",
		Flags: func(fs *flag.FlagSet) error {
			c.register(fs)
			return nil
		},
		Subs: []cmdline.Commander{
			cmdline.CommandRun("amex", "convert amex statements", runWrap(c.amex)),
			cmdline.CommandRun("chase", "convert chase statements", runWrap(c.chase)),
			cmdline.CommandRun("hsbc", "convert hsbc statements", runWrap(c.hsbc)),
			cmdline.CommandRun("trading", "convert trading212 statements", runWrap(c.trading)),
			cmdline.CommandRun("chasetxt", "convert copied chase pdf statements", runWrap(c.chasetxt)),
			cmdline.CommandRun("chasesave", "convert chase saver statements", runWrap(c.chasesave)),
			cmdline.CommandRun("virgin", "convert virgin credit card transactions", runWrap(c.virgin)),
		},
	}
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

func ViewCommand() cmdline.Commander {
	return &cmdline.CommandBasic[View]{
		Name: "view",
		Desc: "view summarizes the data into different views, printed to the console.",
		Flags: func(v *View, fs *flag.FlagSet) error {
			fs.StringVar(&v.configPath, "config", "gbp.fin.cue", "path to config file")
			return nil
		},
		Do: func(v *View) cmdline.Runner {
			return runWrap(v.viewAll)
		},
	}
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

func PushCommand() cmdline.Commander {
	type Config struct {
		bucketName string
		localGlob  string
	}
	return &cmdline.CommandBasic[Config]{
		Name: "push",
		Desc: "upload local data to a storage bucket",
		Flags: func(c *Config, fs *flag.FlagSet) error {
			fs.StringVar(&c.bucketName, "bucket", "gs://fin-liao-dev", "bucket identifier")
			fs.StringVar(&c.localGlob, "glob", "*.fin.cue", "a glob pattern patching local files")
			return nil
		},
		Do: func(c *Config) cmdline.Runner {
			return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
				err := runPush(stdout, c.bucketName, c.localGlob)
				if err != nil {
					fmt.Fprintf(stderr, "push: %v\n", err)
					return 1
				}
				return 0
			}
		},
	}
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

func PullCommand() cmdline.Commander {
	type Config struct {
		bucketName string
	}
	return &cmdline.CommandBasic[Config]{
		Name: "pull",
		Desc: "download remote data from a storage bucket",
		Flags: func(c *Config, fs *flag.FlagSet) error {
			fs.StringVar(&c.bucketName, "bucket", "gs://fin-liao-dev", "bucket identifier")
			return nil
		},
		Do: func(c *Config) cmdline.Runner {
			return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
				err := runPull(stdout, c.bucketName)
				if err != nil {
					fmt.Fprintf(stderr, "pull: %v\n", err)
					return 1
				}
				return 0
			}
		},
	}
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
