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
			image: "ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib:0.104.0"
			args: ["--config=file:/etc/otelcol/config.yaml"]
			env: [{
				name:  "GOOGLE_APPLICATION_CREDENTIALS"
				value: "/etc/workload-identity/creds.json"
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
			volumeMounts: [{
				name:      "token"
				mountPath: "/var/run/service-account"
				readOnly:  true
			}, {
				name:      "gcp-creds"
				mountPath: "/etc/workload-identity"
				readOnly:  true
			}, {
				name:      "config"
				mountPath: "/etc/otelcol"
			}]
		}]
		volumes: [{
			name: "token"
			projected: sources: [{
				serviceAccountToken: {
					audience:          "https://iam.googleapis.com/projects/330311169810/locations/global/workloadIdentityPools/kubernetes/providers/justia-asami"
					expirationSeconds: 3600
					path:              "token"
				}
			}]
		}, {
			name: "gcp-creds"
			configMap: name: "gcp"
		}, {
			name: "config"
			configMap: name: "otelcol"
		}]

	}
}
