config: #Config

#Config: {
	Parallel: int & >0 | *5
	Archived: bool | *false
	Worktree: bool | *true

	Users: [...string] | *[]
	Orgs: [...string] | *[]

	// total: int & >0
	// total: len(Users) + len(Orgs)

	ExcludeRegexes: [...string] | *[]
}
