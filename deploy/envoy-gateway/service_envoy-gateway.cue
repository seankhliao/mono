package deploy

k8s: "": "v1": "Service": "envoy-gateway-system": "envoy-gateway": {
	spec: {
		selector: {
			"app.kubernetes.io/name": "envoy-gateway"
		}
		ports: [{
			name:       "grpc"
			port:       18000
			targetPort: 18000
		}, {
			name:       "ratelimit"
			port:       18001
			targetPort: 18001
		}, {
			name:       "wasm"
			port:       18002
			targetPort: 18002
		}, {
			name:       "metrics"
			port:       19001
			targetPort: 19001
		}]
	}
}
