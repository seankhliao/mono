// Sample Go code for user authorization

package main

import (
	_ "embed"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"log/slog"
	"os"

	"cuelang.org/go/cue/cuecontext"
	"go.seankhliao.com/mono/jsonlog"
	"golang.org/x/net/context"
	"google.golang.org/api/option"
	"google.golang.org/api/youtube/v3"
)

func main() {
	lh := jsonlog.New(slog.LevelDebug, os.Stderr)
	lg := slog.New(lh)
	ctx := context.Background()

	err := run(ctx, lg, os.Args)
	if err != nil {
		slog.LogAttrs(ctx, slog.LevelError, "run", slog.String("error", err.Error()))
		os.Exit(1)
	}
}

func run(ctx context.Context, lg *slog.Logger, args []string) error {
	var lookup bool
	var configFile string
	fset := flag.NewFlagSet("youtubefeed", flag.ExitOnError)
	fset.BoolVar(&lookup, "lookup", false, "lookup usernames and output config")
	fset.StringVar(&configFile, "config", "config.cue", "path to config file")
	fset.Parse(args[1:])

	conf, err := newConfig(ctx, lg, configFile)
	if err != nil {
		return err
	}

	yt, err := youtube.NewService(ctx, option.WithAPIKey(os.Getenv("GCP_APIKEY")), option.WithScopes(youtube.YoutubeReadonlyScope))
	if err != nil {
		log.Fatalln(err)
	}

	if lookup {
		return runLookup(ctx, lg, yt, conf)
	}

	return nil
}

func runLookup(ctx context.Context, lg *slog.Logger, yt *youtube.Service, config Config) error {
	results := make(map[string]ConfigChannel)

	for _, username := range config.Lookup {
		lg := lg.With(slog.String("username", username))

		// lookup channel id
		res, err := yt.Search.
			List([]string{"id", "snippet"}).
			Q(username).
			Type("channel").
			Do()
		if err != nil {
			lg.LogAttrs(ctx, slog.LevelError, "lookup channel id from username",
				slog.String("error", err.Error()),
			)
			continue
		} else if len(res.Items) == 0 {
			lg.LogAttrs(ctx, slog.LevelError, "no channel found for username")
			continue
		}

		result := res.Items[0]
		lg = lg.With(
			slog.String("channel_id", result.Id.ChannelId),
			slog.String("channel_title", result.Snippet.Title),
		)

		channels, err := yt.Channels.
			List([]string{"snippet", "contentDetails"}).
			Id(res.Items[0].Id.ChannelId).
			Do()
		if err != nil {
			lg.LogAttrs(ctx, slog.LevelError, "get channel info",
				slog.String("error", err.Error()),
			)
			continue
		} else if len(channels.Items) != 1 {
			lg.LogAttrs(ctx, slog.LevelError, "unexpected number of channels",
				slog.Int("channel items", len(channels.Items)),
			)
		}

		channel := channels.Items[0]

		results[channel.Snippet.CustomUrl] = ConfigChannel{
			Title:     channel.Snippet.Title,
			ChannelID: channel.Id,
			UploadsID: channel.ContentDetails.RelatedPlaylists.Uploads,
		}
	}

	b, err := json.MarshalIndent(results, "", "  ")
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "marshal results", slog.String("error", err.Error()))
		return err
	}

	fmt.Println(string(b))
	return nil
}

//go:embed schema.cue
var configSchema string

func newConfig(ctx context.Context, lg *slog.Logger, configFile string) (Config, error) {
	var conf Config
	cuectx := cuecontext.New()
	confUnified := cuectx.CompileString(configSchema)

	lg.LogAttrs(ctx, slog.LevelDebug, "read config", slog.String("file", configFile))
	configGiven, err := os.ReadFile(configFile)
	if err != nil {
		return Config{}, fmt.Errorf("read %s: %w", configFile, err)
	}

	confGiven := cuectx.CompileBytes(configGiven)
	confUnified = confUnified.Unify(confGiven)
	err = confUnified.Decode(&conf)
	if err != nil {
		return Config{}, fmt.Errorf("decode unified config: %w", err)
	}

	return conf, nil
}

type Config struct {
	Lookup []string              `json:"lookup"`
	Feeds  map[string]ConfigFeed `json:"feeds"`
}

type ConfigFeed struct {
	Name        string                   `json:"name"`
	Description string                   `json:"description"`
	Exclude     map[string]string        `json:"exclude"`
	Channels    map[string]ConfigChannel `json:"channels"`
}
type ConfigChannel struct {
	Title     string
	ChannelID string `json:"channel_id"`
	UploadsID string `json:"uploads_id"`
}

// func getsvcs() {
// 	service, err := youtube.NewService(ctx, option.WithAPIKey(os.Getenv("GCP_APIKEY")), option.WithScopes(youtube.YoutubeReadonlyScope))
// 	if err != nil {
// 		log.Fatalln(err)
// 	}
//
// 	videosForChannels(service, "AlinaGingertail", "PricklyAlpaca")
// }
//
// func videosForChannels(service *youtube.Service, usernames ...string) {
// 	var videos []*youtube.PlaylistItem
// 	for _, username := range usernames {
// 		log.Println("username", username)
// 		search, err := service.Search.List([]string{"id", "snippet"}).Q(username).Type("channel").Do()
// 		if err != nil {
// 			log.Fatalln(err)
// 		}
// 		fmt.Println(search.Items[0].Snippet.Title, search.Items[0].Snippet)
// 		res, err := service.Channels.List([]string{"snippet", "contentDetails"}).Id(search.Items[0].Id.ChannelId).Do()
// 		if err != nil {
// 			log.Fatalln(err)
// 		}
// 		for _, channel := range res.Items {
// 			log.Println("username", username, "channel", channel.Snippet.Title)
// 			res, err := service.PlaylistItems.List([]string{"id", "snippet"}).PlaylistId(channel.ContentDetails.RelatedPlaylists.Uploads).Do()
// 			if err != nil {
// 				log.Fatalln(err)
// 			}
// 			videos = append(videos, res.Items...)
// 		}
// 	}
// 	slices.SortFunc(videos, func(a, b *youtube.PlaylistItem) int {
// 		if aa, bb := a.Snippet.PublishedAt, b.Snippet.PublishedAt; aa < bb {
// 			return -1
// 		} else if aa == bb {
// 			return 0
// 		}
// 		return 1
// 	})
// 	for _, video := range videos {
// 		fmt.Println(video.Snippet.PublishedAt, video.Snippet.ChannelTitle, video.Snippet.Title)
// 	}
// }
