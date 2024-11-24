GRPC: {
	Address: string | *":8000"
}
HTTP: {
	Address: string | *":8080"
	K8s: {
		Enable: bool | *false

		GatewayNamespace: string | *"envoy-gateway-system"
		GatewayName:      string | *"http-gateway"
	}
}
Debug: {
	Address: string | *":8081"
}
