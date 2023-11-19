// Sample Go code for user authorization

package main

import (
	"fmt"
	"log"
	"os"
	"slices"

	"golang.org/x/net/context"
	"google.golang.org/api/option"
	"google.golang.org/api/youtube/v3"
)

func main() {
	ctx := context.Background()

	service, err := youtube.NewService(ctx, option.WithAPIKey(os.Getenv("GCP_APIKEY")), option.WithScopes(youtube.YoutubeReadonlyScope))
	if err != nil {
		log.Fatalln(err)
	}

	videosForChannels(service, "AlinaGingertail", "PricklyAlpaca")
}

func videosForChannels(service *youtube.Service, usernames ...string) {
	var videos []*youtube.PlaylistItem
	for _, username := range usernames {
		log.Println("username", username)
		search, err := service.Search.List([]string{"id", "snippet"}).Q(username).Type("channel").Do()
		if err != nil {
			log.Fatalln(err)
		}
		fmt.Println(search.Items[0].Snippet.Title, search.Items[0].Snippet)
		res, err := service.Channels.List([]string{"snippet", "contentDetails"}).Id(search.Items[0].Id.ChannelId).Do()
		if err != nil {
			log.Fatalln(err)
		}
		for _, channel := range res.Items {
			log.Println("username", username, "channel", channel.Snippet.Title)
			res, err := service.PlaylistItems.List([]string{"id", "snippet"}).PlaylistId(channel.ContentDetails.RelatedPlaylists.Uploads).Do()
			if err != nil {
				log.Fatalln(err)
			}
			videos = append(videos, res.Items...)
		}
	}
	slices.SortFunc(videos, func(a, b *youtube.PlaylistItem) int {
		if aa, bb := a.Snippet.PublishedAt, b.Snippet.PublishedAt; aa < bb {
			return -1
		} else if aa == bb {
			return 0
		}
		return 1
	})
	for _, video := range videos {
		fmt.Println(video.Snippet.PublishedAt, video.Snippet.ChannelTitle, video.Snippet.Title)
	}
}
