package deploy

k8s: "cert-manager.io": "v1": "ClusterIssuer": "": "letsencrypt-staging": {
	spec: acme: {
		email:  "acme+letsencrypt@liao.dev"
		server: "https://acme-staging-v02.api.letsencrypt.org/directory"
		privateKeySecretRef: name: "letsencrypt-staging-account"
		solvers: [{
			dns01: cloudDNS: project: "com-seankhliao"
		}]
	}
}
