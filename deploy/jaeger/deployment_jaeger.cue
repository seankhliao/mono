package deploy

import (
	"encoding/yaml"
	"encoding/json"
)

k8s: "": v1: "Service": "jaeger": "jaeger": spec: {
	ports: [{
		name:       "http"
		port:       80
		targetPort: k8s.apps.v1.Deployment.jaeger.jaeger.spec.template.spec.containers[0].ports[1].name
	}, {
		name:       "otlp"
		port:       4317
		targetPort: k8s.apps.v1.Deployment.jaeger.jaeger.spec.template.spec.containers[0].ports[0].name
	}]
	selector: k8s.apps.v1.Deployment.jaeger.jaeger.spec.selector.matchLabels
}

k8s: "apps": v1: "Deployment": "jaeger": {
	"jaeger": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/name": "jaeger"
		}
	}).out
	"jaeger": {
		spec: revisionHistoryLimit: 1
		spec: strategy: type: "Recreate"
		spec: template: spec: {
			let config_dir = "/etc/jaeger"
			let storage_dir = "/var/lib/jaeger"
			let http_port = 16686
			containers: [{
				image: "quay.io/jaegertracing/jaeger:2.0.0"
				name:  "jaeger"
				args: [
					"--config=file:\(config_dir)/jaeger.yaml",
				]
				ports: [{
					containerPort: 4317
					name:          "otlp"
				}, {
					containerPort: http_port
					name:          "http"
				}]
				volumeMounts: [{
					mountPath: storage_dir
					name:      "data"
				}, {
					mountPath: config_dir
					name:      "config"
				}]
			}]
			volumes: [{
				hostPath: path: "/opt/volumes/jaeger"
				name: "data"
			}, {
				name: "config"
				configMap: name: "jaeger"
			}]
		}
	}
}

k8s: "": v1: ConfigMap: "jaeger": "jaeger": data: {
	"ui.json": json.Marshal({
		dependencies: menuEnabled: true
		monitor: menuEnabled:      true
	})
	"jaeger.yaml": yaml.Marshal({
		service: {
			extensions: [
				"jaeger_storage",
				"jaeger_query",
				"healthcheckv2",
			]
			pipelines: traces: {
				receivers: ["otlp"]
				processors: ["batch"]
				exporters: ["jaeger_storage_exporter"]
			}
			telemetry: {
				resource: "service.name": "jaeger"
				metrics: {
					level:   "detailed"
					address: "0.0.0.0:8888"
				}
				logs: level: "info"
			}
		}
		extensions: {
			healthcheckv2: {
				use_v2: true
				http: {}
			}

			jaeger_query: {
				storage: {
					traces:  "localstore"
					metrics: "promstore"
				}
				ui: config_file: "/etc/jaeger/ui.json"
				http: endpoint:  "0.0.0.0:16686"
			}

			jaeger_storage: {
				backends: localstore: badger: {
					directories: {
						keys:   "/var/lib/jaeger/keys"
						values: "/var/lib/jaeger/values"
					}
					ephemeral: false
					ttl: spans: "\(24*7)h"
				}
				metric_backends: promstore: prometheus: {
					endpoint:           "http://prometheus.prometheus.svc"
					normalize_calls:    true
					normalize_duration: true
				}
			}
		}

		receivers: otlp: protocols: grpc: endpoint: "0.0.0.0:4317"

		processors: batch: {}

		exporters: jaeger_storage_exporter: trace_storage: "localstore"
	})
}
