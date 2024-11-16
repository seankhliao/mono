package deploy

k8s: "": "v1": "Service": "softserve": "softserve": "spec": {
	type: "ClusterIP"
	ports: [{
		name:        "http"
		port:        80
		protocol:    "TCP"
		appProtocol: "http"
		targetPort:  "git-http"
	}]
	selector: {
		"app.kubernetes.io/name": "softserve"
	}
}
