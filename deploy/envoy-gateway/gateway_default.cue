package deploy

k8s: "gateway.networking.k8s.io": "v1": "Gateway": "envoy-gateway-system": "http-gateway": "spec": {
	gatewayClassName: "http-gateway"
	listeners: [{
		name:     "http"
		protocol: "HTTP"
		port:     80
		allowedRoutes: namespaces: from: "All"
	}]
}
