package main

import (
	"fmt"
	"log/slog"
	"os"
	"strings"
)

func main() {
	err := run()
	if err != nil {
		slog.Error("run", "err", err)
		os.Exit(1)
	}
}

func run() error {
	var rows []string
	for i := range 128 {
		rows = append(rows, fmt.Sprintf("% 3d\t%0.2X\t%6q\t%s", i, i, i, names[i]))
	}
	var longest int
	for _, row := range rows {
		longest = max(longest, len(row))
		fmt.Println(len(row))
	}
	for i := range 64 {
		fmt.Print(rows[i], strings.Repeat(" ", longest-len(rows[i])), " |  ", rows[i+64], "\n")
	}

	return nil
}

var names = map[int]string{
	0:   "Null",
	1:   "Start of Heading",
	2:   "Start of Text",
	3:   "End of Text",
	4:   "End of Transmission",
	5:   "Enquiry",
	6:   "Acknowledgement",
	7:   "Bell (Alert)",
	8:   "Backspace",
	9:   "Horizontal Tab",
	10:  "Line Feed",
	11:  "Vertical Tab",
	12:  "Form Feed",
	13:  "Carriage Return",
	14:  "Shift Out",
	15:  "Shift In",
	16:  "Data Link Escape",
	17:  "Device Control 1 (often XON)",
	18:  "Device Control 2",
	19:  "Device Control 3 (often XOFF)",
	20:  "Device Control 4",
	21:  "Negative Acknowledgement",
	22:  "Synchronous Idle",
	23:  "End of Transmission Block",
	24:  "Cancel",
	25:  "End of Medium",
	26:  "Substitute",
	27:  "Escape",
	28:  "File Separator",
	29:  "Group Separator",
	30:  "Record Separator",
	31:  "Unit Separator",
	127: "Delete",
}
