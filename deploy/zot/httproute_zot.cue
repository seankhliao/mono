package deploy

k8s: "gateway.networking.k8s.io": "v1": "HTTPRoute": "zot": "zot": "spec": {
	hostnames: ["registry.liao.dev"]
	parentRefs: [{
		name:      "http-gateway"
		namespace: "envoy-gateway-system"
	}]
	rules: [{
		backendRefs: [{
			name: "zot"
			port: 80
		}]
	}]
}
