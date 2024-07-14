package deploy

import "encoding/json"

k8s: "": "v1": "ConfigMap": "opentelemetry": "gcp": {
	data: "creds.json": json.Marshal({
		"universe_domain":    "googleapis.com"
		"type":               "external_account"
		"audience":           "//iam.googleapis.com/projects/330311169810/locations/global/workloadIdentityPools/kubernetes/providers/justia-asami"
		"subject_token_type": "urn:ietf:params:oauth:token-type:jwt"
		"token_url":          "https://sts.googleapis.com/v1/token"
		"credential_source": {
			"file": "/var/run/service-account/token"
			"format": {
				"type": "text"
			}
		}
		"token_info_url": "https://sts.googleapis.com/v1/introspect"
	})
}
