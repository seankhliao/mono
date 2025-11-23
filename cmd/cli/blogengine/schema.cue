import "time"

#BlogengineConfig: {
	render: {
		baseUrl: string
		dst?:    string | *""
		gtm?:    string
		src:     string | *"src"
		style:   "compact" | *"full"
	}

	firebase?: {
		site: string
		redirects?: [...{
			glob:     string
			location: string
			code:     int
		}]
		headers?: [...{
			glob: string
			headers: [string]: string
		}]
	}
}

#EventPage: {
	Title:    string
	Subtitle: string

	PageTitle:   string
	Description: string
	Events: [...{
		_date:     string
		date:      time.Parse(time.RFC3339Date, _date)
		headline?: string
		support?: [...string]
		name:  string | *headline
		text?: string
	}]
	Links: {
		_ignore: [...string]
		ignore: {for l in _ignore {"\(l)": {}}}
		known: [string]: string
	}
}

#TablePage: {
	Title:    string
	Subtitle: string

	PageTitle:   string
	Description: string

	Tables: [...{
		Heading:     string
		Description: string
		LinkFormat:  string
		Rows: [...{
			Date?:  time.Format(time.RFC3339)
			Rating: int & >=0 & <=10
			ID:     int
			Title: [...string]
			Note?: string
		}]
	}]
}
