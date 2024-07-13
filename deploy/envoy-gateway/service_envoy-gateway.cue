package deploy

k8s: "": "v1": "Service": "envoy-gateway": {
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
		}]
	}
}
