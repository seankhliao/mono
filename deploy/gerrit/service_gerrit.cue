package deploy

k8s: "": "v1": "Service": "gerrit": "gerrit": "spec": {
	type: "ClusterIP"
	ports: [{
		name:        "http"
		port:        80
		protocol:    "TCP"
		appProtocol: "http"
		targetPort:  "http"
	}]
	selector: {
		"app.kubernetes.io/name": "gerrit"
	}
}
