package background

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"sync/atomic"
	"time"
)

type OnParallel int

const (
	Run OnParallel = iota
	Skip
	Cancel
)

type Task struct {
	Name       string
	Frequency  time.Duration
	OnParallel OnParallel
	concurrent atomic.Pointer[context.CancelFunc]
	Do         func(context.Context) error
}

func DoHTTP(name string, freq time.Duration, par OnParallel, method, endpoint string, header http.Header, body io.Reader) (Task, error) {
	req, err := http.NewRequest(method, endpoint, body)
	if err != nil {
		return Task{}, fmt.Errorf("create http request: %w", err)
	}
	return Task{
		Name:       name,
		Frequency:  freq,
		OnParallel: par,
		Do: func(ctx context.Context) error {
			req := req.Clone(ctx)
			res, err := http.DefaultClient.Do(req)
			if err != nil {
				return fmt.Errorf("make http request: %w", err)
			}
			if res.StatusCode < 200 || res.StatusCode > 299 {
				return fmt.Errorf("unsuccessful response: %v", res.Status)
			}
			return nil
		},
	}, nil
}

func StartTasks(ctx context.Context, tasks ...*Task) {
	c := make(chan *Task)
	for _, task := range tasks {
		go triggerTasks(ctx, c, task)
	}
}

func triggerTasks(ctx context.Context, c chan *Task, t *Task) {
	tick := time.NewTicker(t.Frequency)
	defer tick.Stop()
	for {
		select {
		case <-tick.C:
			c <- t
		case <-ctx.Done():
			return
		}
	}
}

func runTasks(ctx context.Context, c chan *Task) {
	for {
		select {
		case <-ctx.Done():
			return
		case t := <-c:
			// Always run
			switch t.OnParallel {
			case Run:
				go t.Do(ctx)
			case Skip:
				ctx, cancel := context.WithCancel(ctx)
				swapped := t.concurrent.CompareAndSwap(nil, &cancel)
				if swapped {
					go func() {
						defer t.concurrent.Store(nil)
						defer cancel()
						t.Do(ctx)
					}()
				}
			case Cancel:
				pcancel := t.concurrent.Load()
				if pcancel != nil {
					(*pcancel)()
				}
				ctx, cancel := context.WithCancel(ctx)
				t.concurrent.Store(&cancel)
				go func() {
					defer t.concurrent.Store(nil)
					defer cancel()
					t.Do(ctx)
				}()
			}
		}
	}
}
