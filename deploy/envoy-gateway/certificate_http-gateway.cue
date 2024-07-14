package deploy

k8s: "cert-manager.io": "v1": "Certificate": "envoy-gateway-system": "http-gateway": "spec": {
	secretName: "http-gateway"
	privateKey: {
		algorithm: "ECDSA"
		size:      256
	}
	duration:    "\(24*90)h"
	renewBefore: "\(24*30)h"
	isCA:        false
	usages: ["server auth", "client auth"]
	subject: organizations: ["liao.dev"]
	dnsNames: ["*.liao.dev", "*.justia.liao.dev"]
	issuerRef: {
		name:  "letsencrypt-production"
		kind:  "ClusterIssuer"
		group: "cert-manager.io"
	}
}
