package goproxyaudit

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"runtime"
	"slices"
	"strings"
	"time"

	"github.com/go-json-experiment/json"
	"github.com/go-json-experiment/json/jsontext"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	goproxyauditv1 "go.seankhliao.com/mono/goproxyaudit/v1"
	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/ystore"
	"gocloud.dev/blob"
	"golang.org/x/mod/semver"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func Register(a *App, r yhttp.Registrar) {
	// r.Handle("GET /data", http.StripPrefix("/data", (http.FileServerFS(a.bkt))))
	r.Pattern("GET", "", "/view/{mod...}", a.viewModule)
	r.Pattern("GET", "", "/stats", a.stats)
}

func Background(a *App) []func(context.Context) error {
	return []func(context.Context) error{
		a.watchIndex,
	}
}

func Shutdown(a *App) []func(context.Context) error {
	return []func(context.Context) error{
		func(ctx context.Context) error {
			a.store.Sync(ctx, true)
			return nil
		},
	}
}

type Config struct {
	Host string
}

type App struct {
	http *http.Client
	o    yo11y.O11y

	store *ystore.Store[*goproxyauditv1.Store]
}

func New(ctx context.Context, c Config, bkt *blob.Bucket, o yo11y.O11y) (*App, error) {
	var a App

	a.http = &http.Client{
		Transport: &yhttp.UserAgent{
			Next: otelhttp.NewTransport(http.DefaultTransport),
		},
	}

	a.o = o.Sub("goproxyaudit")

	var err error
	a.store, err = ystore.New(ctx, bkt, "goproxyaudit.pb.zstd", func() *goproxyauditv1.Store {
		return goproxyauditv1.Store_builder{
			Root: make(map[string]*goproxyauditv1.ModuleSegment),
		}.Build()
	})
	if err != nil {
		return nil, fmt.Errorf("init store: %w", err)
	}

	return &a, nil
}

const indexURL = "https://index.golang.org/index?since="

func (a *App) watchIndex(ctx context.Context) error {
	for {
		since, err := a.updateFromIndex(ctx)
		if err != nil {
			sleep := time.Minute
			a.o.Err(ctx, "error updating from index.golang.org", err,
				slog.Time("since", since),
				slog.Duration("retry.after", sleep),
			)
			time.Sleep(sleep)
			continue
		}

		sinceLastSeen := time.Since(since)
		sleep := 5*time.Minute - sinceLastSeen
		if sleep < 0 {
			continue
		}
		a.o.L.LogAttrs(ctx, slog.LevelDebug, "sleeping",
			slog.Duration("duration", sleep),
		)
		time.Sleep(sleep)
	}
}

func (a *App) updateFromIndex(ctx context.Context) (time.Time, error) {
	defer runtime.GC()

	var since time.Time
	a.store.RDo(ctx, func(s *goproxyauditv1.Store) {
		since = s.GetGolangOrgLastIndex().AsTime()
	})
	uri := indexURL + since.Format(time.RFC3339)
	req, err := http.NewRequestWithContext(ctx, "GET", uri, http.NoBody)
	if err != nil {
		return since, fmt.Errorf("prepare request: %w", err)
	}
	res, err := a.http.Do(req)
	if err != nil {
		return since, fmt.Errorf("get from index: %w", err)
	}
	defer res.Body.Close()

	jtdec := jsontext.NewDecoder(res.Body)

	var processed, added int
	a.store.Do(ctx, func(s *goproxyauditv1.Store) {
		for {
			var rec IndexRecord
			err = json.UnmarshalDecode(jtdec, &rec)
			if errors.Is(err, io.EOF) {
				break
			} else if err != nil {
				err = fmt.Errorf("decode record: %w", err)
				break
			}

			processed++

			segment := findSegment(s, rec.Path)
			module := segment.GetModule()

			if module == nil {
				module = goproxyauditv1.Module_builder{
					ModuleName: &rec.Path,
				}.Build()
				segment.SetModule(module)
			}

			moduleVersions := module.GetVersions()
			idx, found := slices.BinarySearchFunc(moduleVersions, rec.Version, func(e *goproxyauditv1.ModuleVersion, t string) int {
				return semver.Compare(e.GetVersion(), t)
			})
			if !found {
				moduleVersions = slices.Insert(moduleVersions, idx, goproxyauditv1.ModuleVersion_builder{
					Version:          &rec.Version,
					GolangOrgIndexed: timestamppb.New(rec.Timestamp),
				}.Build())
				added++
			} else {
				a.o.L.LogAttrs(ctx, slog.LevelDebug, "duplicate module in index",
					slog.String("path", rec.Path),
					slog.Group("old",
						slog.String("version", moduleVersions[idx].GetVersion()),
						slog.Time("ts", moduleVersions[idx].GetGolangOrgIndexed().AsTime()),
					),
					slog.Group("new",
						slog.String("version", rec.Version),
						slog.Time("ts", rec.Timestamp),
					),
				)
			}

			module.SetVersions(moduleVersions)
			module.SetLatest(moduleVersions[len(moduleVersions)-1].GetVersion())

			since = rec.Timestamp
		}

		s.SetGolangOrgLastIndex(timestamppb.New(since))
	})

	a.o.L.LogAttrs(ctx, slog.LevelInfo, "updated from index.golang.org",
		slog.Int("processed", processed),
		slog.Int("added", added),
		slog.Time("last", since),
	)

	return since, nil
}

type IndexRecord struct {
	Path      string
	Version   string
	Timestamp time.Time
}

func (a *App) viewModule(rw http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	moduleName := r.PathValue("mod")

	var module *goproxyauditv1.Module
	a.store.RDo(ctx, func(s *goproxyauditv1.Store) {
		segment := findSegment(s, moduleName)
		module = segment.GetModule()
	})

	encoder := protojson.MarshalOptions{Multiline: true}
	b, err := encoder.Marshal(module)
	if err != nil {
		a.o.HTTPErr(ctx, "marshal module", err, rw, http.StatusInternalServerError,
			slog.String("module.path", moduleName),
		)
		return
	}

	rw.Write(b)
}

func findSegment(s *goproxyauditv1.Store, moduleName string) *goproxyauditv1.ModuleSegment {
	modsegs := strings.Split(moduleName, "/")
	hostname := modsegs[0]
	root := s.GetRoot()
	if len(root) == 0 {
		root = make(map[string]*goproxyauditv1.ModuleSegment)
		s.SetRoot(root)
	}
	segment, ok := root[hostname]
	if !ok {
		segment = goproxyauditv1.ModuleSegment_builder{
			Children: make(map[string]*goproxyauditv1.ModuleSegment),
		}.Build()
		root[hostname] = segment
	}
	modsegs = modsegs[1:]

	for _, modseg := range modsegs {
		children := segment.GetChildren()
		if len(children) == 0 {
			children = make(map[string]*goproxyauditv1.ModuleSegment)
			segment.SetChildren(children)
		}
		var ok bool
		segment, ok = children[modseg]
		if !ok {
			segment = goproxyauditv1.ModuleSegment_builder{
				Children: make(map[string]*goproxyauditv1.ModuleSegment),
			}.Build()
			children[modseg] = segment
		}
	}

	return segment
}
