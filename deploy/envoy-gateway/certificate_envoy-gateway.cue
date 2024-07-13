package deploy

k8s: "cert-manager.io": "v1": "Certificate": "envoy-gateway-system": "envoy-gateway": {
	spec: {
		commonName: "envoy-gateway"
		dnsNames: [
			"envoy-gateway",
			"envoy-gateway.envoy-gateway-system",
			"envoy-gateway.envoy-gateway-system.svc",
			"envoy-gateway.envoy-gateway-system.svc.cluster.local",
		]
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
		secretName: "envoy-gateway"
	}
}
