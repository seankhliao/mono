package deploy

import "encoding/yaml"

k8s: "": "v1": "ConfigMap": "opentelemetry": "otelcol": "data": {
	"config.yaml": yaml.Marshal({
		receivers: otlp: protocols: {
			grpc: endpoint: "0.0.0.0:4317"
			http: endpoint: "0.0.0.0:4318"
		}

		exporters: googlecloud: project: "com-seankhliao"
		exporters: nop: {}

		extensions: {
			health_check: {}
			pprof: {}
			zpages: {}
		}

		service: extensions: ["health_check", "pprof", "zpages"]
		service: pipelines: metrics: {
			receivers: ["otlp"]
			exporters: ["nop"]
		}
		service: pipelines: traces: {
			receivers: ["otlp"]
			exporters: ["googlecloud"]
		}
	})
}
