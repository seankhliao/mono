package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strconv"
	"strings"

	"github.com/bradleyfalzon/ghinstallation/v2"
	"github.com/google/go-github/v56/github"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/observability"
	"golang.org/x/oauth2"
)

func main() {
	conf := &Config{}
	framework.Run(framework.Config{
		RegisterFlags: conf.SetFlags,
		Start: func(ctx context.Context, o *observability.O, m *http.ServeMux) (func(), error) {
			app := New(ctx, o, *conf)
			app.Register(m)
			return nil, nil
		},
	})
}

type Config struct {
	webhookSecret string
	appID         int64
	privateKey    string
}

func (c *Config) SetFlags(fset *flag.FlagSet) {
	t := &http.Transport{}
	t.RegisterProtocol("file", http.NewFileTransport(http.Dir("/")))
	t.RegisterProtocol("data", dataTransport{})
	client := &http.Client{Transport: t}

	fset.Func("gh.app.id", "file: or data: to github app id", func(s string) error {
		val, err := getBody(client, s)
		if err != nil {
			return err
		}
		c.appID, err = strconv.ParseInt(val, 10, 64)
		return err
	})
	fset.Func("gh.app.private-key", "file: or data: uri to private key", func(s string) (err error) {
		c.privateKey, err = getBody(client, s)
		return
	})
	fset.Func("gh.webhook.secret", "file: or data: uri to webhook secret", func(s string) (err error) {
		c.webhookSecret, err = getBody(client, s)
		return
	})
}

type Server struct {
	o             *observability.O
	webhookSecret string
	privateKey    string
	appID         int64
}

func New(ctx context.Context, o *observability.O, c Config) *Server {
	return &Server{
		o:             o,
		webhookSecret: strings.TrimSpace(c.webhookSecret),
		privateKey:    c.privateKey + "\n",
		appID:         c.appID,
	}
}

func (s *Server) Register(mux *http.ServeMux) {
	mux.Handle("/webhook", otelhttp.NewHandler(http.HandlerFunc(s.hWebhook), "hWebhook"))
}

var defaultConfig = map[string]github.Repository{
	"erred": {
		AllowMergeCommit:    github.Bool(false),
		AllowUpdateBranch:   github.Bool(true),
		AllowAutoMerge:      github.Bool(true),
		AllowSquashMerge:    github.Bool(true),
		AllowRebaseMerge:    github.Bool(false),
		DeleteBranchOnMerge: github.Bool(true),
		HasIssues:           github.Bool(false),
		HasWiki:             github.Bool(false),
		HasPages:            github.Bool(false),
		HasProjects:         github.Bool(false),
		HasDownloads:        github.Bool(false),
		HasDiscussions:      github.Bool(false),
		IsTemplate:          github.Bool(false),
		Archived:            github.Bool(true),
	},
	"seankhliao": {
		AllowMergeCommit:    github.Bool(false),
		AllowUpdateBranch:   github.Bool(true),
		AllowAutoMerge:      github.Bool(true),
		AllowSquashMerge:    github.Bool(true),
		AllowRebaseMerge:    github.Bool(false),
		DeleteBranchOnMerge: github.Bool(true),
		HasIssues:           github.Bool(false),
		HasWiki:             github.Bool(false),
		HasPages:            github.Bool(false),
		HasProjects:         github.Bool(false),
		HasDownloads:        github.Bool(false),
		HasDiscussions:      github.Bool(false),
		IsTemplate:          github.Bool(false),
	},
}

var (
	ErrIgnore      = errors.New("ignoring")
	ErrSetDefaults = errors.New("errors setting repo defaults")
)

func (s *Server) hWebhook(rw http.ResponseWriter, r *http.Request) {
	ctx, span := s.o.T.Start(r.Context(), "hWebhook")
	defer span.End()

	event, eventType, err := s.getPayload(ctx, r)
	if err != nil {
		s.o.HTTPErr(ctx, "invalid payload", err, rw, http.StatusBadRequest)
		return
	}

	err = ErrIgnore
	switch event := event.(type) {
	case *github.InstallationEvent:
		err = s.installEvent(ctx, event)
	case *github.RepositoryEvent:
		err = s.repoEvent(ctx, event)
	}

	lvl := slog.LevelInfo
	if ig := errors.Is(err, ErrIgnore); err != nil && !ig {
		s.o.HTTPErr(ctx, "process event", err, rw, http.StatusInternalServerError)
		return
	} else if ig {
		lvl = slog.LevelDebug
	}
	s.o.L.LogAttrs(ctx, lvl, "processed event",
		slog.String("eventType", eventType),
	)
	rw.Write([]byte("ok"))
}

func (s *Server) getPayload(ctx context.Context, r *http.Request) (any, string, error) {
	_, span := s.o.T.Start(ctx, "getPayload")
	defer span.End()

	payload, err := github.ValidatePayload(r, []byte(s.webhookSecret))
	if err != nil {
		return nil, "", fmt.Errorf("validate: %w", err)
	}
	eventType := github.WebHookType(r)
	event, err := github.ParseWebHook(eventType, payload)
	if err != nil {
		return nil, "", fmt.Errorf("parse: %w", err)
	}

	return event, eventType, nil
}

func (s *Server) installEvent(ctx context.Context, event *github.InstallationEvent) error {
	ctx, span := s.o.T.Start(ctx, "installEvent")
	defer span.End()

	owner := *event.Installation.Account.Login
	installID := *event.Installation.ID

	span.SetAttributes(
		attribute.String("owner", owner),
		attribute.String("action", *event.Action),
	)

	var errs error
	switch *event.Action {
	case "created":
		if _, ok := defaultConfig[owner]; !ok {
			return s.o.Err(ctx, "ignoring owner", errors.New("unknown owner"))
		}

		for _, repo := range event.Repositories {
			err := s.setDefaults(ctx, installID, owner, *repo.Name, *repo.Fork)
			if err != nil {
				s.o.Err(ctx, "set defaults", err)
				errs = ErrSetDefaults
				continue
			}
		}
	default:
		s.o.L.LogAttrs(ctx, slog.LevelDebug, "ignoring action",
			slog.String("action", *event.Action),
		)
	}

	return errs
}

func (s *Server) repoEvent(ctx context.Context, event *github.RepositoryEvent) error {
	ctx, span := s.o.T.Start(ctx, "repoEvent")
	defer span.End()

	installID := *event.Installation.ID
	owner := *event.Repo.Owner.Login
	repo := *event.Repo.Name

	span.SetAttributes(
		attribute.String("owner", owner),
		attribute.String("repo", repo),
		attribute.String("action", *event.Action),
	)

	switch *event.Action {
	case "created", "transferred":
		if _, ok := defaultConfig[owner]; !ok {
			return nil
		}
		err := s.setDefaults(ctx, installID, owner, repo, *event.Repo.Fork)
		if err != nil {
			return ErrSetDefaults
		}
	default:
		s.o.L.LogAttrs(ctx, slog.LevelDebug, "ignoring action",
			slog.String("action", *event.Action),
		)
	}
	return nil
}

func (s *Server) setDefaults(ctx context.Context, installID int64, owner, repo string, fork bool) error {
	ctx, span := s.o.T.Start(ctx, "setDefaults", trace.WithAttributes(
		attribute.String("owner", owner),
		attribute.String("repo", repo),
		attribute.Bool("fork", fork),
	))
	defer span.End()

	config := defaultConfig[owner]
	tr := http.DefaultTransport
	tr, err := ghinstallation.NewAppsTransport(tr, s.appID, []byte(s.privateKey))
	if err != nil {
		return fmt.Errorf("create ghinstallation transport: %w", err)
	}
	client := github.NewClient(&http.Client{Transport: otelhttp.NewTransport(tr)})
	installToken, _, err := client.Apps.CreateInstallationToken(ctx, installID, nil)
	if err != nil {
		return fmt.Errorf("create installation token: %w", err)
	}

	client = github.NewClient(&http.Client{
		Transport: otelhttp.NewTransport(&oauth2.Transport{
			Source: oauth2.StaticTokenSource(&oauth2.Token{AccessToken: *installToken.Token}),
		}),
	})

	_, _, err = client.Repositories.Edit(ctx, owner, repo, &config)
	if err != nil {
		return fmt.Errorf("update repo settings: %w", err)
	}
	if fork {
		_, _, err = client.Repositories.EditActionsPermissions(ctx, owner, repo, github.ActionsPermissionsRepository{
			Enabled: github.Bool(false),
		})
		if err != nil {
			return fmt.Errorf("disable actions: %w", err)
		}
	}

	return nil
}

type dataTransport struct{}

func (dataTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	return &http.Response{
		Body: io.NopCloser(strings.NewReader(req.URL.Opaque)),
	}, nil
}

func getBody(client *http.Client, uri string) (string, error) {
	res, err := client.Get(uri)
	if err != nil {
		return "", fmt.Errorf("get %q: %w", uri, err)
	}
	defer res.Body.Close()
	b, err := io.ReadAll(res.Body)
	if err != nil {
		return "", fmt.Errorf("read %q: %w", uri, err)
	}
	return string(b), nil
}
