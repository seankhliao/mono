package deploy

k8s: "apps": "v1": "Deployment": "opentelemetry": {
	"otelcol": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/name": "otelcol"
		}
	}).out
	"otelcol": spec: template: spec: {
		automountServiceAccountToken: true
		containers: [{
			name:  "otelcol"
			image: "ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib:0.112.0"
			args: ["--config=file:/etc/otelcol/config.yaml"]
			env: [namespace.gcpEnv]
			envFrom: [{
				secretRef: name: "api-keys" // manually managed
			}]
			ports: [{
				name:          "otlp-grpc"
				containerPort: 4317
			}, {
				name:          "otlp-http"
				containerPort: 4318
			}, {
				name:          "healthcheck"
				containerPort: 13133
			}, {
				name:          "zpages"
				containerPort: 55679
			}]
			volumeMounts: [namespace.gcpVolumeMount, {
				name:      "config"
				mountPath: "/etc/otelcol"
			}]
		}]
		volumes: [namespace.gcpVolume, {
			name: "config"
			configMap: name: "otelcol"
		}]
	}
}
