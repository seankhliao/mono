package deploy

k8s: "apps": "v1": "Deployment": "envoy-gateway-system": {
	"envoy-gateway": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/name": "envoy-gateway"
		}
	}).out
	"envoy-gateway": {
		spec: revisionHistoryLimit: 1
		spec: template: spec: {
			containers: [{
				name:  "envoy-gateway"
				image: "docker.io/envoyproxy/gateway:v1.0.2"
				args: [
					"server",
					"--config-path=/config/envoy-gateway.yaml",
				]
				env: [{
					name: "ENVOY_GATEWAY_NAMESPACE"
					valueFrom: fieldRef: {
						apiVersion: "v1"
						fieldPath:  "metadata.namespace"
					}
				}, {
					name:  "KUBERNETES_CLUSTER_DOMAIN"
					value: "cluster.local"
				}]
				ports: [{
					containerPort: 18000
					name:          "grpc"
				}, {
					containerPort: 18001
					name:          "ratelimit"
				}, {
					containerPort: 19001
					name:          "http-metrics"
				}]
				livenessProbe: {
					httpGet: {
						path: "/healthz"
						port: 8081
					}
					initialDelaySeconds: 15
					periodSeconds:       20
				}
				readinessProbe: {
					httpGet: {
						path: "/readyz"
						port: 8081
					}
					initialDelaySeconds: 5
					periodSeconds:       10
				}
				resources: {
					requests: {
						cpu:    "100m"
						memory: "256Mi"
					}
				}
				securityContext: allowPrivilegeEscalation: false
				volumeMounts: [{
					mountPath: "/config"
					name:      "envoy-gateway-config"
					readOnly:  true
				}, {
					mountPath: "/certs"
					name:      "certs"
					readOnly:  true
				}]
			}]
			securityContext: runAsNonRoot: true
			serviceAccountName:            "envoy-gateway"
			terminationGracePeriodSeconds: 10
			volumes: [{
				configMap: {
					defaultMode: 420
					name:        "envoy-gateway"
				}
				name: "envoy-gateway-config"
			}, {
				name: "certs"
				secret: secretName: "envoy-gateway"
			}]

		}
	}
}
