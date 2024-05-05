package deploy

objs: "clusterissuer_letsencrypt-staging": {
	apiVersion: "cert-manager.io/v1"
	kind:       "ClusterIssuer"
	metadata: name: "letsencrypt-staging"
	spec: acme: {
		email:  "acme+letsencrypt@liao.dev"
		server: "https://acme-staging-v02.api.letsencrypt.org/directory"
		privateKeySecretRef: name: "letsencrypt-staging-account"
		solvers: [{
			dns01: cloudDNS: {
				project: "com-seankhliao"
				serviceAccountSecretRef: {
					name: "gcp-cert-manager-sa"
					key:  "key.json"
				}
			}
		}]
	}
}
