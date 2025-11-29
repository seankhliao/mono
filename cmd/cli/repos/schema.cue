#SyncConfig: {
	Parallel: int & >0 | *5

	Upstream: string
	Origin:   string

	ExcludeRegexes: [...string] | *[]
}
