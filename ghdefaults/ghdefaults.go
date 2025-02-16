package ghdefaults

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/bradleyfalzon/ghinstallation/v2"
	"github.com/google/go-github/v60/github"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/yo11y"
	"golang.org/x/oauth2"
)

func Register(a *App, r yhttp.Registrar) {
	r.Pattern("GET", a.Host, "/robots.txt", a.robots)
	r.Pattern("POST", a.Host, "/webhook", a.ServeHTTP)
}

type Config struct {
	AppID         int64  `env:"GITHUB_APP_ID"`
	PrivateKey    string `env:"GITHUB_APP_PRIVATE_KEY"`
	WebhookSecret string `env:"GITHUB_APP_WEBHOOK_SECRET"`
	Host          string
}

type App struct {
	Config

	o      yo11y.O11y
	mOwner metric.Int64Counter
}

func New(ctx context.Context, c Config, o yo11y.O11y) (*App, error) {
	a := &App{
		Config: c,

		o: o.Sub("ghdefaults"),
	}

	a.mOwner, _ = a.o.M.Int64Counter("mono.ghdefaults.repo_updated", metric.WithUnit("repository"))
	return a, nil
}

var defaultConfig = map[string]github.Repository{
	"erred": {
		AllowMergeCommit:    ptr(false),
		AllowUpdateBranch:   ptr(true),
		AllowAutoMerge:      ptr(true),
		AllowSquashMerge:    ptr(true),
		AllowRebaseMerge:    ptr(false),
		DeleteBranchOnMerge: ptr(true),
		HasIssues:           ptr(false),
		HasWiki:             ptr(false),
		HasPages:            ptr(false),
		HasProjects:         ptr(false),
		HasDownloads:        ptr(false),
		HasDiscussions:      ptr(false),
		IsTemplate:          ptr(false),
		Archived:            ptr(true),
	},
	"seankhliao": {
		AllowMergeCommit:    ptr(false),
		AllowUpdateBranch:   ptr(true),
		AllowAutoMerge:      ptr(true),
		AllowSquashMerge:    ptr(true),
		AllowRebaseMerge:    ptr(false),
		DeleteBranchOnMerge: ptr(true),
		HasIssues:           ptr(false),
		HasWiki:             ptr(false),
		HasPages:            ptr(false),
		HasProjects:         ptr(false),
		HasDownloads:        ptr(false),
		HasDiscussions:      ptr(false),
		IsTemplate:          ptr(false),
	},
}

func ptr[T any](t T) *T {
	return &t
}

var (
	ErrIgnore      = errors.New("ignoring")
	ErrSetDefaults = errors.New("errors setting repo defaults")
)

func (a *App) ServeHTTP(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "handle webhook")
	defer span.End()

	event, eventType, err := a.getPayload(ctx, r)
	if err != nil {
		a.o.HTTPErr(ctx, "invalid payload", err, rw, http.StatusBadRequest)
		return
	}

	err = ErrIgnore
	switch event := event.(type) {
	case *github.InstallationEvent:
		err = a.installEvent(ctx, event)
	case *github.RepositoryEvent:
		err = a.repoEvent(ctx, event)
	}

	lvl := slog.LevelInfo
	if ignore := errors.Is(err, ErrIgnore); err != nil && !ignore {
		a.o.HTTPErr(ctx, "process event", err, rw, http.StatusInternalServerError)
		return
	} else if ignore {
		lvl = slog.LevelDebug
	}
	a.o.L.LogAttrs(ctx, lvl, "processed event",
		slog.String("eventType", eventType),
	)
	rw.Write([]byte("ok"))
}

func (a *App) getPayload(ctx context.Context, r *http.Request) (any, string, error) {
	_, span := a.o.T.Start(ctx, "getPayload")
	defer span.End()

	payload, err := github.ValidatePayload(r, []byte(a.WebhookSecret))
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

func (a *App) installEvent(ctx context.Context, event *github.InstallationEvent) error {
	ctx, span := a.o.T.Start(ctx, "installEvent")
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
			return a.o.Err(ctx, "ignoring owner", errors.New("unknown owner"))
		}

		for _, repo := range event.Repositories {
			err := a.setDefaults(ctx, installID, owner, *repo.Name, *repo.Fork)
			if err != nil {
				a.o.Err(ctx, "set defaults", err)
				errs = ErrSetDefaults
				continue
			}
		}
	default:
		a.o.L.LogAttrs(ctx, slog.LevelDebug, "ignoring action",
			slog.String("action", *event.Action),
		)
	}

	return errs
}

func (a *App) repoEvent(ctx context.Context, event *github.RepositoryEvent) error {
	ctx, span := a.o.T.Start(ctx, "repoEvent")
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
		err := a.setDefaults(ctx, installID, owner, repo, *event.Repo.Fork)
		if err != nil {
			return ErrSetDefaults
		}
	default:
		a.o.L.LogAttrs(ctx, slog.LevelDebug, "ignoring action",
			slog.String("action", *event.Action),
		)
	}
	return nil
}

func (a *App) setDefaults(ctx context.Context, installID int64, owner, repo string, fork bool) error {
	ctx, span := a.o.T.Start(ctx, "setDefaults", trace.WithAttributes(
		attribute.String("owner", owner),
		attribute.String("repo", repo),
		attribute.Bool("fork", fork),
	))
	defer span.End()

	config := defaultConfig[owner]
	tr := http.DefaultTransport
	tr, err := ghinstallation.NewAppsTransport(tr, a.AppID, []byte(a.PrivateKey))
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
			Enabled: ptr(false),
		})
		if err != nil {
			return fmt.Errorf("disable actions: %w", err)
		}
	}

	a.mOwner.Add(ctx, 1, metric.WithAttributes(attribute.String("owner", owner)))
	return nil
}

const robotsTxt = `
User-agent: *
Disallow: /
`

func (a *App) robots(rw http.ResponseWriter, r *http.Request) {
	fmt.Fprint(rw, robotsTxt)
}
