package Events

import "time"

Title:    string
Subtitle: string

PageTitle:   string
Description: string

Events: [...#Event]

#Event: {
	_date:     string
	date:      time.Parse(time.RFC3339Date, _date)
	headline?: string
	support?: [...string]
	name:  string | *headline
	text?: string
}

Links: #Link

#Link: {
	_ignore: [...string]
	ignore: {for l in _ignore {"\(l)": {}}}
	known: [string]: string
}
