package deploy

k8s: "gateway.networking.k8s.io": v1: GatewayClass: "": cilium: {
	spec: controllerName: "io.cilium/gateway-controller"
}
