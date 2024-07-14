package deploy

k8s: "cert-manager.io": "v1": "ClusterIssuer": "": "letsencrypt-production": spec: acme: {
	email:  "acme+letsencrypt@liao.dev"
	server: "https://acme-v02.api.letsencrypt.org/directory"
	privateKeySecretRef: name: "letsencrypt-production-account"
	solvers: [{
		dns01: cloudDNS: {
			project: "com-seankhliao"
		}
	}]
}
