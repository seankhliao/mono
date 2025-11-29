SyncGithub: #SyncGithubConfig

#SyncGithubConfig: {
	Parallel: int & >0 | *5
	Archived: bool | *false
	Worktree: bool | *true
	JJ:       bool | *true

	Users: [...string] | *[]
	Orgs: [...string] | *[]

	ExcludeRegexes: [...string] | *[]
}
