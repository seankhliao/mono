package deploy

k8s: "": v1: Service: "": "hubble-peer": {
	metadata: {
		labels: {
			"app.kubernetes.io/part-of": "cilium"
			"app.kubernetes.io/name":    "hubble-peer"
		}
	}
	spec: {
		selector: "k8s-app": "cilium"
		ports: [{
			name:       "peer-service"
			port:       443
			protocol:   "TCP"
			targetPort: 4244
		}]
		internalTrafficPolicy: "Local"
	}
}
