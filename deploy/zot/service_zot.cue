package deploy

k8s: "": "v1": "Service": "zot": "zot": "spec": {
	type: "ClusterIP"
	ports: [{
		name:        "http"
		port:        80
		protocol:    "TCP"
		appProtocol: "http"
		targetPort:  "http"
	}]
	selector: {
		"app.kubernetes.io/name": "zot"
	}
}
