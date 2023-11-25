package main

import (
	"context"
	"errors"
	"fmt"

	"cuelang.org/go/cue/cuecontext"
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
	results := make(map[string]ConfigChannel)
	var errs []error

	for _, username := range usernames {
		// lg := a.o.L.With(slog.String("username", username))

		// lookup channel id
		res, err := a.yt.Search.
			List([]string{"id", "snippet"}).
			Q(username).
			Type("channel").
			Do()
		if err != nil {
			errs = append(errs, LookupError{"search for", username, err})
			continue
		} else if len(res.Items) == 0 {
			errs = append(errs, LookupError{"results for", username, ErrNoResults})
			continue
		}

		result := res.Items[0]
		// lg = lg.With(
		// 	slog.String("channel_id", result.Id.ChannelId),
		// 	slog.String("channel_title", result.Snippet.Title),
		// )

		channels, err := a.yt.Channels.
			List([]string{"snippet", "contentDetails"}).
			Id(result.Id.ChannelId).
			Do()
		if err != nil {
			errs = append(errs, LookupError{"channel detailts for", username, err})
			continue
		} else if len(channels.Items) == 0 {
			errs = append(errs, LookupError{"no channels for", username, ErrNoResults})
			continue
		}

		channel := channels.Items[0]

		results[channel.Snippet.CustomUrl] = ConfigChannel{
			Title:     channel.Snippet.Title,
			ChannelID: channel.Id,
			UploadsID: channel.ContentDetails.RelatedPlaylists.Uploads,
		}
	}

	if len(errs) > 0 {
		return nil, errors.Join(errs...)
	}
	return results, nil
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
