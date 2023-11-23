#Config: {
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
