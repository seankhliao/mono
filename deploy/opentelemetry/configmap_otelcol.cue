package deploy

import "encoding/yaml"

k8s: "": "v1": "ConfigMap": "opentelemetry": "otelcol": "data": {
	"config.yaml": yaml.Marshal({
		receivers: {
			otlp: protocols: {
				grpc: endpoint: "0.0.0.0:4317"
				http: endpoint: "0.0.0.0:4318"
			}
		}

		processors: {
			transform: {
				error_mode: "ignore"
				trace_statements: [{
					context: "resource"
					statements: [
						#"set(attributes["k8s.cluster.name"], "justia")"#,
						#"set(attributes["deployment.environment"], "production")"#,
					]
				}]
				metric_statements: trace_statements
				log_statements:    trace_statements
			}
		}

		exporters: {
			googlecloud: project: "com-seankhliao"
			nop: {}
		}

		extensions: {
			health_check: {
				endpoint: "0.0.0.0:13133"
			}
			pprof: {
				endpoint: "0.0.0.0:1777"
			}
			zpages: {
				endpoint: "0.0.0.0:55679"
			}
		}

		service: extensions: ["health_check", "pprof", "zpages"]
		service: pipelines: logs: {
			receivers: ["otlp"]
			processors: ["transform"]
			exporters: ["nop"]
		}
		service: pipelines: metrics: {
			receivers: ["otlp"]
			processors: ["transform"]
			exporters: ["nop"]
		}
		service: pipelines: traces: {
			receivers: ["otlp"]
			processors: ["transform"]
			exporters: ["googlecloud"]
		}
	})
}
