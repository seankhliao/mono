package deploy

k8s: "cert-manager.io": "v1": "Certificate": "envoy-gateway-system": "envoy-gateway-ca": {
	spec: {
		isCA:       true
		commonName: "envoy-gateway"
		secretName: "envoy-gateway-ca"
		privateKey: {
			algorithm: "ECDSA"
			size:      256
		}
		issuerRef: {
			name:  "selfsigned"
			kind:  "ClusterIssuer"
			group: "cert-manager.io"
		}
	}
}
