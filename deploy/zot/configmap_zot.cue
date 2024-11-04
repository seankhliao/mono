package deploy

import "encoding/json"

k8s: "": "v1": "ConfigMap": "zot": "zot": "data": {
	"config.json": json.Marshal({
		storage: {
			rootDirectory: "/data"
			dedupe:        true
			gc:            true
		}
		http: {
			address: "0.0.0.0"
			port:    "5000"
			auth: htpasswd: path: "/var/run/secrets/zot/htpasswd"
		}
	})
}
