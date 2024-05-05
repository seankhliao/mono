package serve

import (
	"context"
	"fmt"

	"go.etcd.io/bbolt"
)

func NewStore(ctx context.Context, path string) (*bbolt.DB, error) {
	db, err := bbolt.Open(path, 0o644, &bbolt.Options{})
	if err != nil {
		return nil, fmt.Errorf("open db at %s: %w", path, err)
	}
	return db, nil
}
