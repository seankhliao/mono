go: {
	bootstrap: string

	pre:      bool | *true
	releases: int | *2

	tip: {
		update: bool | *true
	}
}

tools: {
	update: bool | *true
	overrides: [string]: #override
}

#override: {
	version: string | *"latest"
	cgo:     bool | *false
}
