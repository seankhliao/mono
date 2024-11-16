package deploy

k8s: "gateway.networking.k8s.io": "v1": "HTTPRoute": "softserve": "softserve": "spec": {
	hostnames: ["softserve.liao.dev"]
	parentRefs: [{
		name:      "http-gateway"
		namespace: "envoy-gateway-system"
	}]
	rules: [{
		backendRefs: [{
			name: "softserve"
			port: 80
		}]
	}]
}
