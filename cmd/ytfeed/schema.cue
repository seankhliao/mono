import "time"

#Config: {
	maxAge:  >time.ParseDuration("1h") // duration in ns
	refresh: >time.ParseDuration("1m") // duration in ns
	feeds: [string]: #Feed
}

#Feed: {
	name:        string
	description: string | *""
	channels: [string]: #Channel // username: channel
	exclude: [string]:  string   // name: regexp
}

#Channel: {
	title:      string
	channel_id: string
	uploads_id: string
}

config: #Config
