package deploy

k8s: "gateway.networking.k8s.io": "v1": "GatewayClass": "": "http-gateway": spec: {
	controllerName: "gateway.envoyproxy.io/gatewayclass-controller"
	parametersRef: {
		group:     "gateway.envoyproxy.io"
		kind:      "EnvoyProxy"
		namespace: "envoy-gateway-system"
		name:      "http-gateway"
	}
}
