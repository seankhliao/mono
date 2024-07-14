package deploy

k8s: "": "v1": "Service": "opentelemetry": "otelcol": "spec": {
	type: "ClusterIP"
	ports: [{
		name:        "otlp-grpc"
		port:        4317
		protocol:    "TCP"
		appProtocol: "grpc"
		targetPort:  "otlp-grpc"
	}, {
		name:        "otlp-http"
		port:        4318
		protocol:    "TCP"
		appProtocol: "http"
		targetPort:  "otlp-http"
	}]
	selector: {
		"app.kubernetes.io/name": "otelcol"
	}
}
