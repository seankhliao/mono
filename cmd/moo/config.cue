package config

import (
	"time"
)

// TODO: merge with secrets?
App: {
	BaseDomain: string | *"liao.dev"
	Auth: {
		Host:         string | *"auth.\(BaseDomain)"
		CookieDomain: string | *"\(BaseDomain)"
		CookieName:   string | *"__moo_auth"
	}
	Earbug: {
		Host:       string | *"earbug.\(BaseDomain)"
		Key:        string | *"earbug.pb.zstd"
		UpdateFreq: time.ParseDuration("5m")
	}
	GHDefaults: {
		Host:          "ghdefaults.\(BaseDomain)"
		AppID:         int
		PrivateKey:    string
		WebhookSecret: string
	}
	Homepage: {
		Host: "justia.\(BaseDomain)"
	}
	ReqLog: {
		Host: "reqlog.\(BaseDomain)"
	}
}
