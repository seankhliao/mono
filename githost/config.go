package githost

type (
	RepoID string
	UserID string

	AuthToken string
)

var UserAnonymous UserID = "anonymous"

type Config struct {
	Repos []ConfigRepo
	Users []ConfigUser
}
type ConfigRepo struct {
	ID    RepoID
	Name  string
	Read  []UserID
	Write []UserID
}

type ConfigUser struct {
	ID         UserID
	Argon2ID   string
	cgitrcPath string
}
