package deploy

import "encoding/yaml"

k8s: "": "v1": "ConfigMap": "envoy-gateway-system": "envoy-gateway": {
	data: "envoy-gateway.yaml": yaml.Marshal({
		apiVersion: "gateway.envoyproxy.io/v1alpha1"
		kind:       "EnvoyGateway"
		gateway: controllerName: "gateway.envoyproxy.io/gatewayclass-controller"
		logging: level: default: "info"
		provider: type: "Kubernetes"
	})
}
