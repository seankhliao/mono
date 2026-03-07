import "time"

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

		price?:     number
		price_jpy?: number
		price_usd?: number
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
