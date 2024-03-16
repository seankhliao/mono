package ghdefaults

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/bradleyfalzon/ghinstallation/v2"
	"github.com/google/go-github/v60/github"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/spanerr"
	"golang.org/x/oauth2"
)

type Config struct {
	WebhookSecret string `flag:",shared secret with github to validate webhook payloads"`
	AppID         int64  `flag:",registered github app id"`
	PrivateKey    string `flag:",private key used to auth to github as the app"`

	t         trace.Tracer
	ctrError  metric.Int64Counter
	ctrEvents metric.Int64Counter
}

func Register(c Config, mux *http.ServeMux) {
	c.WebhookSecret = strings.TrimSpace(c.WebhookSecret)
	c.PrivateKey = c.PrivateKey + "\n"

	c.t = otel.Tracer("go.seankhliao.com/mono/cmd/mono/ghdefaults")

	mux.HandleFunc("POST /ghdefaults/webhook", HandleWebhook(c))
}

func HandleWebhook(c Config) http.HandlerFunc {
	mt := otel.Meter("go.seankhliao.com/mono/cmd/mono/ghdefaults")
	c.ctrError, _ = mt.Int64Counter("errors")
	c.ctrEvents, _ = mt.Int64Counter("ghdefaults.webhook.events")

	return func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := c.t.Start(r.Context(), "handle webhook")
		defer span.End()

		event, eventType, err := getPayload(ctx, c, r)
		if err != nil {
			c.ctrError.Add(ctx, 1)
			spanerr.Error(span, "failed to get payload", err)
			http.Error(rw, "bad request", http.StatusBadRequest)
			return
		}

		var handler func(ctx context.Context, c Config, event any) error

		switch event.(type) {
		case *github.InstallationEvent:
			handler = installEvent
		case *github.RepositoryEvent:
			handler = repoEvent
		default:
			eventType = "other"
		}

		c.ctrEvents.Add(ctx, 1, metric.WithAttributes(attribute.String("event.type", eventType)))

		if eventType == "other" {
			io.WriteString(rw, "skipping")
			return
		}

		err = handler(ctx, c, event)
		if err != nil {
			c.ctrError.Add(ctx, 1)
			spanerr.Error(span, "error processing event", err)
			http.Error(rw, "internal error", http.StatusInternalServerError)
			return
		}

		io.WriteString(rw, "ok")
	}
}

func getPayload(ctx context.Context, c Config, r *http.Request) (any, string, error) {
	_, span := c.t.Start(ctx, "get webhook payload")
	defer span.End()

	payload, err := github.ValidatePayload(r, []byte(c.WebhookSecret))
	if err != nil {
		return nil, "", fmt.Errorf("validate webhook payload: %w", err)
	}
	eventType := github.WebHookType(r)
	event, err := github.ParseWebHook(eventType, payload)
	if err != nil {
		return nil, "", fmt.Errorf("parse webhook payload: %w", err)
	}

	return event, eventType, nil
}

func installEvent(ctx context.Context, c Config, evt any) error {
	event := evt.(*github.InstallationEvent)
	owner := *event.Installation.Account.Login
	installID := *event.Installation.ID

	ctx, span := c.t.Start(ctx, "handle install event", trace.WithAttributes(
		attribute.Int64("install.id", installID),
		attribute.String("owner", owner),
		attribute.String("action", *event.Action),
	))
	defer span.End()

	var errs []error
	switch *event.Action {
	case "created":
		if _, ok := defaultConfig[owner]; !ok {
			return nil
		}

		for _, repo := range event.Repositories {
			err := setDefaults(ctx, c, installID, owner, *repo.Name, *repo.Fork)
			if err != nil {
				errs = append(errs, err)
				continue
			}
		}
	}

	if len(errs) > 0 {
		err := errors.Join(errs...)
		return spanerr.Error(span, "error setting default", err)
	}

	return nil
}

func repoEvent(ctx context.Context, c Config, evt any) error {
	event := evt.(*github.RepositoryEvent)
	installID := *event.Installation.ID
	owner := *event.Repo.Owner.Login
	repo := *event.Repo.Name
	action := *event.Action

	ctx, span := c.t.Start(ctx, "handle repo event", trace.WithAttributes(
		attribute.Int64("install.id", installID),
		attribute.String("owner", owner),
		attribute.String("repo", repo),
		attribute.String("action", action),
	))
	defer span.End()

	switch action {
	case "created", "transferred":
		if _, ok := defaultConfig[owner]; !ok {
			return nil
		}
		err := setDefaults(ctx, c, installID, owner, repo, *event.Repo.Fork)
		if err != nil {
			return spanerr.Error(span, "error setting defaults", err)
		}
	}
	return nil
}

func setDefaults(ctx context.Context, c Config, installID int64, owner, repo string, fork bool) error {
	ctx, span := c.t.Start(ctx, "set defaults for repo", trace.WithAttributes(
		attribute.String("owner", owner),
		attribute.String("repo", repo),
		attribute.Bool("fork", fork),
	))
	defer span.End()

	tr := http.DefaultTransport
	tr, err := ghinstallation.NewAppsTransport(tr, c.AppID, []byte(c.PrivateKey))
	if err != nil {
		return spanerr.Error(span, "create ghinstallation transport", err)
	}

	client := github.NewClient(&http.Client{Transport: otelhttp.NewTransport(tr)})
	installToken, _, err := client.Apps.CreateInstallationToken(ctx, installID, nil)
	if err != nil {
		return spanerr.Error(span, "create installation token", err)
	}

	client = github.NewClient(&http.Client{
		Transport: otelhttp.NewTransport(&oauth2.Transport{
			Source: oauth2.StaticTokenSource(&oauth2.Token{AccessToken: *installToken.Token}),
		}),
	})

	config := defaultConfig[owner]
	_, _, err = client.Repositories.Edit(ctx, owner, repo, &config)
	if err != nil {
		return spanerr.Error(span, "update repo settings", err)
	}

	if fork {
		_, _, err = client.Repositories.EditActionsPermissions(ctx, owner, repo,
			github.ActionsPermissionsRepository{
				Enabled: github.Bool(false),
			},
		)
		if err != nil {
			return spanerr.Error(span, "disable github actions on fork", err)
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
