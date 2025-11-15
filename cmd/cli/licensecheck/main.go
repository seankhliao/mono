package main

import (
	"fmt"
	"log/slog"
	"os"

	"github.com/google/licensecheck"
)

func main() {
	err := run()
	if err != nil {
		slog.Error("run", "err", err)
		os.Exit(1)
	}
}

func run() error {
	b, err := os.ReadFile(os.Args[1])
	if err != nil {
		return fmt.Errorf("read file %v: %w", os.Args[1], err)
	}

	cov := licensecheck.Scan(b)
	slog.Info("cov", "percent", cov.Percent)
	for _, m := range cov.Match {
		slog.Info("cov", "match", fmt.Sprintf("%+v", m))
	}
	return nil
}
