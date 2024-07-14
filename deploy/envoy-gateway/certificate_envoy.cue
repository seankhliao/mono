package deploy

k8s: "cert-manager.io": "v1": "Certificate": "envoy-gateway-system": "envoy": spec: {
	commonName: "*"
	dnsNames: ["*.envoy-gateway-system"]
	issuerRef: {
		kind: "Issuer"
		name: "envoy-gateway"
	}
	usages: [
		"digital signature",
		"data encipherment",
		"key encipherment",
		"content commitment",
	]
	secretName: "envoy"
}
