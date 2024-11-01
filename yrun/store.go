package yrun

import (
	"context"
	"fmt"
	"io"
	"sync"
	"time"

	"github.com/klauspost/compress/zstd"
	"gocloud.dev/blob"
	"google.golang.org/protobuf/proto"
)

type Store[T proto.Message] struct {
	bkt *blob.Bucket
	key string

	mu   sync.RWMutex
	data T

	lastUpdate time.Time
	nextUpdate *time.Timer
}

type storer[T any] interface {
	proto.Message
	*T
}

func NewStore[T any, P storer[T]](ctx context.Context, bkt *blob.Bucket, key string, init func() P) (*Store[P], error) {
	s := &Store[P]{
		bkt:  bkt,
		key:  key,
		data: new(T),
	}
	s.nextUpdate = time.AfterFunc(24*time.Hour, s.sync)

	if exists, err := bkt.Exists(ctx, key); err != nil {
		return nil, fmt.Errorf("check for key %q: %w", key, err)
	} else if !exists {
		return s, nil
	}
	obj, err := bkt.NewReader(ctx, key, nil)
	if err != nil {
		return nil, fmt.Errorf("open key %q: %w", key, err)
	}
	defer obj.Close()
	zr, err := zstd.NewReader(obj)
	if err != nil {
		return nil, fmt.Errorf("create zstd decompressor: %w", err)
	}
	defer zr.Close()
	b, err := io.ReadAll(zr)
	if err != nil {
		return nil, fmt.Errorf("read from key %q: %w", key, err)
	}

	err = proto.Unmarshal(b, s.data)
	if err != nil {
		return nil, fmt.Errorf("unmarshal data for key %q: %w", key, err)
	}
	return s, nil
}

func (s *Store[T]) RDo(f func(T)) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	f(s.data)
}

func (s *Store[T]) Do(f func(T)) {
	defer s.Sync(context.Background())

	s.mu.Lock()
	defer s.mu.Unlock()
	f(s.data)
}

func (s *Store[T]) Sync(ctx context.Context) {
	d := time.Since(s.lastUpdate)
	if d < 3*time.Minute {
		s.nextUpdate.Reset(3*time.Minute - d)
		return
	}
	s.nextUpdate.Reset(5 * time.Second)
}

func (s *Store[T]) sync() {
	ctx := context.Background()
	ctx, cancel := context.WithTimeout(ctx, 3*time.Minute)
	defer cancel()

	// TODO: handle error
	_ = func(ctx context.Context) error {
		var b []byte
		var err error
		s.RDo(func(t T) {
			b, err = proto.Marshal(t)
		})
		if err != nil {
			return fmt.Errorf("marshal data: %w", err)
		}

		obj, err := s.bkt.NewWriter(ctx, s.key, nil)
		if err != nil {
			return fmt.Errorf("open key %q for writing: %w", s.key, err)
		}
		defer obj.Close()
		zw, err := zstd.NewWriter(obj)
		if err != nil {
			return fmt.Errorf("create zstd compressor: %w", err)
		}
		defer zw.Close()
		_, err = zw.Write(b)
		if err != nil {
			return fmt.Errorf("write marshaled data: %w", err)
		}

		s.lastUpdate = time.Now()
		return nil
	}(ctx)
}
