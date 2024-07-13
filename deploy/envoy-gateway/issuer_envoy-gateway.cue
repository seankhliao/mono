package deploy

k8s: "cert-manager.io": "v1": "Issuer": "envoy-gateway-system": "envoy-gateway": {
	spec: ca: secretName: "envoy-gateway-ca"
}
