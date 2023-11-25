package main

import (
	"context"
	"errors"
	"fmt"

	"cuelang.org/go/cue/cuecontext"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

func (a *App) lookupFromConfig(ctx context.Context) (string, error) {
	results, err := a.runLookup(ctx, a.startupConfig.lookup)
	if err != nil {
		return "", err
	}

	// TODO: merge results into new config

	cuectx := cuecontext.New()
	return fmt.Sprintf("%v\n", cuectx.Encode(results)), nil
}

func (a *App) runLookup(ctx context.Context, usernames []string) (map[string]ConfigChannel, error) {
	ctx, span := a.o.T.Start(ctx, "run lookup")
	defer span.End()

	results := make(map[string]ConfigChannel)
	var errs []error

	for _, username := range usernames {
		username, channel, err := a.lookupUser(ctx, username)
		if err != nil {
			errs = append(errs, err)
			continue
		}
		results[username] = channel
	}

	if len(errs) > 0 {
		return nil, errors.Join(errs...)
	}
	return results, nil
}

func (a *App) lookupUser(ctx context.Context, username string) (string, ConfigChannel, error) {
	ctx, span := a.o.T.Start(ctx, "lookup user",
		trace.WithAttributes(attribute.String("username", username)),
	)
	defer span.End()

	// lookup channel id
	res, err := a.yt.Search.
		List([]string{"id", "snippet"}).
		Q(username).
		Type("channel").
		Context(ctx).
		Do()
	if err != nil {
		return "", ConfigChannel{}, LookupError{"search for", username, err}
	} else if len(res.Items) == 0 {
		return "", ConfigChannel{}, LookupError{"results for", username, ErrNoResults}
	}

	result := res.Items[0]
	channels, err := a.yt.Channels.
		List([]string{"snippet", "contentDetails"}).
		Id(result.Id.ChannelId).
		Context(ctx).
		Do()
	if err != nil {
		return "", ConfigChannel{}, LookupError{"channel detailts for", username, err}
	} else if len(channels.Items) == 0 {
		return "", ConfigChannel{}, LookupError{"no channels for", username, ErrNoResults}
	}

	channel := channels.Items[0]

	return channel.Snippet.CustomUrl, ConfigChannel{
		Title:     channel.Snippet.Title,
		ChannelID: channel.Id,
		UploadsID: channel.ContentDetails.RelatedPlaylists.Uploads,
	}, nil
}

var ErrNoResults = errors.New("no results found")

type LookupError struct {
	Operation string
	Username  string
	base      error
}

func (err LookupError) Error() string {
	return fmt.Sprintf("%s %s: %v", err.Operation, err.Username, err.base)
}

func (err LookupError) Unwrap() error {
	return err.base
}
