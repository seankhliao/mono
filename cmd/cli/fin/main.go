package main

import (
	"bytes"
	"context"
	"crypto/md5"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"go.seankhliao.com/mono/run"
	"gocloud.dev/blob"
	_ "gocloud.dev/blob/gcsblob"
)

func main() {
	run.OSExec(run.Group(
		"fin",
		"custom tool for expense tracking",
		run.Simple("view", "view processed results", &View{}),
		run.Simple("push", "upload local data to remote storage", &Push{}),
		run.Simple("pull", "download remote data from remote storage", &Pull{}),
		ConvertCommand(),
		TradingCommand(),
	))
}

type View struct {
	configPath string
}

func (v *View) Flags(fset *flag.FlagSet, args **[]string) error {
	fset.StringVar(&v.configPath, "config", "gbp.fin.cue", "path to config file")
	return nil
}

func (v *View) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	cur, err := DecodeFile(v.configPath)
	if err != nil {
		return fmt.Errorf("decode data: %w", err)
	}
	Summarize(&cur)
	Print(stdout, &cur)

	return nil
}

type Push struct {
	bucketName string
	localGlob  string
}

func (p *Push) Flags(fset *flag.FlagSet, args **[]string) error {
	fset.StringVar(&p.bucketName, "bucket", "gs://fin-liao-dev", "bucket identifier")
	fset.StringVar(&p.localGlob, "glob", "*.fin.cue", "a glob pattern patching local files")
	return nil
}

func (p *Push) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	err := runPush(stdout, p.bucketName, p.localGlob)
	if err != nil {
		return fmt.Errorf("push: %w", err)
	}
	return nil
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

type Pull struct {
	bucketName string
}

func (p *Pull) Flags(fset *flag.FlagSet, args **[]string) error {
	fset.StringVar(&p.bucketName, "bucket", "gs://fin-liao-dev", "bucket identifier")
	return nil
}

func (p *Pull) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	err := runPull(stdout, p.bucketName)
	if err != nil {
		return fmt.Errorf("pull: %w", err)
	}
	return nil
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
