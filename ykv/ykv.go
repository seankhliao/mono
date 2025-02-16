package ykv

import (
	"context"
	"fmt"

	"github.com/cockroachdb/pebble"
	"google.golang.org/protobuf/proto"
)

type KVOpener = func(ctx context.Context, dirname string) (*KV, error)

type KV struct {
	db *pebble.DB
}

type message[T any] interface {
	proto.Message
	*T
}

func New(ctx context.Context, dirname string) (*KV, error) {
	k := &KV{}
	var err error
	k.db, err = pebble.Open(dirname, &pebble.Options{})
	if err != nil {
		return nil, fmt.Errorf("open pebble db %v: %w", dirname, err)
	}
	return k, nil
}

func (k *KV) Shutdown(ctx context.Context) error {
	return k.db.Close()
}

func View[T any, M message[T]](k *KV) *KVView[T, M] {
	return &KVView[T, M]{k}
}

type KVView[T any, M message[T]] struct {
	*KV
}

func (k *KVView[T, M]) Get(key string) (M, error) {
	b, closer, err := k.db.Get([]byte(key))
	if err != nil {
		return nil, err
	}
	defer closer.Close()

	var val M = new(T)
	err = proto.Unmarshal(b, val)
	if err != nil {
		return nil, err
	}
	return val, nil
}

func (k *KVView[T, M]) Set(key string, val M) error {
	b, err := proto.Marshal(val)
	if err != nil {
		return err
	}
	err = k.db.Set([]byte(key), b, &pebble.WriteOptions{})
	if err != nil {
		return err
	}
	return nil
}
