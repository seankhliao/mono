#GithostConfig: {
	Dir: string
	Repos: [string]: #RepoConfig
	Users: [string]: #UserConfig
}

#RepoConfig: {
	ID:   string
	Name: string | *ID
	Actions: [string]: [...string]
}

#UserConfig: {
	ID:       string
	Name:     string
	Argon2ID: string
}
