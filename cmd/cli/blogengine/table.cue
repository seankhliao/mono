package Table

import "time"

Title:    string
Subtitle: string

PageTitle:   string
Description: string

Tables: [...#Table]

#Table: {
	Heading:     string
	Description: string
	LinkFormat:  string
	Rows: [...#TableRow]
}

#TableRow: {
	Date?:  time.Format(time.RFC3339)
	Rating: int & >=0 & <=10
	ID:     int
	Title: [...string]
	Note?: string
}
