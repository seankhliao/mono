package yrun

import (
	"context"
	"fmt"
	"io"
	"sync"
	"time"

	"github.com/klauspost/compress/zstd"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/trace"
	"gocloud.dev/blob"
	"google.golang.org/protobuf/proto"
)

type Store[T proto.Message] struct {
	bkt *blob.Bucket
	key string

	mu   sync.RWMutex
	data T

	t        trace.Tracer
	muLinks  sync.Mutex
	links    []trace.Link
	dataType string

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
		t:    otel.Tracer("yrun/store"),
	}
	s.nextUpdate = time.AfterFunc(24*time.Hour, s.sync)
	s.dataType = fmt.Sprintf("%T", s.data)

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

func (s *Store[T]) RDo(ctx context.Context, f func(T)) {
	_, span := s.t.Start(ctx, "store read")
	defer span.End()

	s.mu.RLock()
	defer s.mu.RUnlock()

	f(s.data)
}

func (s *Store[T]) Do(ctx context.Context, f func(T)) {
	ctx, span := s.t.Start(ctx, "store write")
	defer span.End()

	defer s.Sync(ctx)

	s.mu.Lock()
	defer s.mu.Unlock()
	f(s.data)
}

func (s *Store[T]) Sync(ctx context.Context) {
	spanCtx := trace.SpanContextFromContext(ctx)
	if spanCtx.IsValid() {
		s.muLinks.Lock()
		s.links = append(s.links, trace.LinkFromContext(ctx))
		s.muLinks.Unlock()
	}

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

	s.muLinks.Lock()
	linkOpt := trace.WithLinks(s.links...)
	s.links = s.links[:0]
	s.muLinks.Unlock()

	ctx, span := s.t.Start(ctx, "sync "+s.dataType, linkOpt)
	defer span.End()

	// TODO: handle error
	_ = func(ctx context.Context) error {
		var b []byte
		var err error
		s.RDo(ctx, func(t T) {
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
