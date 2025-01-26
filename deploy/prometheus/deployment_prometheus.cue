package deploy

import (
	"encoding/yaml"
)

k8s: "": v1: Service: "prometheus": "prometheus": spec: {
	ports: [{
		name:       "http"
		port:       80
		targetPort: k8s.apps.v1.Deployment.prometheus.prometheus.spec.template.spec.containers[0].ports[0].name
	}]

	selector: k8s.apps.v1.Deployment.prometheus.prometheus.spec.selector.matchLabels
}

k8s: apps: v1: Deployment: "prometheus": {
	"prometheus": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/name": "prometheus"
		}
	}).out
	"prometheus": {
		spec: revisionHistoryLimit: 1
		spec: strategy: type: "Recreate"
		spec: template: spec: {
			let config_dir = "/etc/prometheus"
			let storage_dir = "/var/lib/prometheus"
			let http_port = 9090
			containers: [{
				image: "quay.io/prometheus/prometheus:v3.1.0"
				name:  "prometheus"
				args: [
					"--config.file=\(config_dir)/prometheus.yaml",
					"--web.listen-address=0.0.0.0:\(http_port)",
					"--web.enable-otlp-receiver",
					"--storage.tsdb.path=\(storage_dir)",
					"--storage.tsdb.retention.time=30d",
					"--enable-feature=exemplar-storage,native-histograms",
				]
				ports: [{
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
				hostPath: path: "/opt/volumes/prometheus"
				name: "data"
			}, {
				name: "config"
				configMap: name: "prometheus"
			}]
		}
	}
}

k8s: "": v1: ConfigMap: "prometheus": "prometheus": data: "prometheus.yaml": yaml.Marshal({
	storage: tsdb: out_of_order_time_window: "30m"
})
