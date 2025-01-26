package deploy

import "encoding/yaml"

k8s: "": "v1": "ConfigMap": "envoy-gateway-system": "envoy-gateway": {
	data: "envoy-gateway.yaml": yaml.Marshal({
		apiVersion: "gateway.envoyproxy.io/v1alpha1"
		kind:       "EnvoyGateway"
		gateway: controllerName: "gateway.envoyproxy.io/gatewayclass-controller"
		logging: level: default: "info"
		provider: {
			type: "Kubernetes"
			kubernetes: envoyService: type: "ClusterIP"
			kubernetes: rateLimitDeployment: {
				container: image: "docker.io/envoyproxy/ratelimit:49af5cca"
				patch: type:      "StrategicMerge"
				patch: value: spec: template: spec: containers: [{
					imagePullPolicy: "IfNotPresent"
					name:            "envoy-ratelimit"
				}]
			}
			kubernetes: shutdownManager: image: "docker.io/envoyproxy/gateway:v1.2.6"
		}
	})
}
