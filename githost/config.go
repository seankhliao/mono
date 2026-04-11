package githost

type (
	RepoID string
	UserID string

	AuthToken string
)

var UserAnonymous UserID = "anonymous"

type Config struct {
	Repos []ConfigRepo `json:"repos"`
	Users []ConfigUser `json:"users"`
}
type ConfigRepo struct {
	ID    RepoID   `json:"id"`
	Read  []UserID `json:"read"`
	Write []UserID `json:"write"`
}

type ConfigUser struct {
	ID         UserID `json:"id"`
	Argon2ID   string `json:"argon2id"`
	cgitrcPath string
}
