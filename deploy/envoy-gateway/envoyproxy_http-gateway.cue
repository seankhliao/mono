package deploy

k8s: "gateway.envoyproxy.io": "v1alpha1": "EnvoyProxy": "envoy-gateway-system": "http-gateway": {
	spec: provider: {
		type: "Kubernetes"
		kubernetes: {
			envoyService: type: "ClusterIP"
			envoyDeployment: {
				strategy: type: "Recreate"
				patch: {
					type: "StrategicMerge"
					value: {
						spec: template: spec: containers: [{
							name: "envoy"
							ports: [{
								containerPort: 10080
								hostPort:      80
							}, {
								containerPort: 10443
								protocol:      "TCP"
								hostPort:      443
							}]
						}]
					}
				}
			}
		}
	}
}
