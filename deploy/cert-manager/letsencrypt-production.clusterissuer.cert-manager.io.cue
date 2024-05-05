package deploy

objs: "clusterissuer_letsencrypt-production": {
	apiVersion: "cert-manager.io/v1"
	kind:       "ClusterIssuer"
	metadata: name: "letsencrypt-production"
	spec: acme: {
		email:  "acme+letsencrypt@liao.dev"
		server: "https://acme-v02.api.letsencrypt.org/directory"
		privateKeySecretRef: name: "letsencrypt-production-account"
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
