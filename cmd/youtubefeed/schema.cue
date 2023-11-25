import "time"

#Config: {
	maxAge:  int64 & >time.ParseDuration("1h") // duration in ns
	refresh: int64 & >time.ParseDuration("1m") // duration in ns
	feeds: [string]: #Feed
}

#Feed: {
	description: string
	channels: [string]: #Channel // username: channel
	exclude: [string]:  string   // name: regexp
}

#Channel: {
	title:      string
	channel_id: string
	uploads_id: string
}

config: #Config
