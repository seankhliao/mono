package deploy

import (
	"strings"
)

k8s: apps: v1: Deployment: "kube-system": "cilium-operator": {
	metadata: {
		labels: {
			"io.cilium/app":             "operator"
			name:                        "cilium-operator"
			"app.kubernetes.io/part-of": "cilium"
			"app.kubernetes.io/name":    "cilium-operator"
		}
		annotations: {
			"config.kubernetes.io/depends-on": strings.Join([
				"/namespaces/kube-system/ServiceAccount/cilium-operator",
				"rbac.authorization.k8s.io/ClusterRoleBinding/cilium-operator",
				"rbac.authorization.k8s.io/namespaces/cilium-secrets/RoleBinding/cilium-operator-gateway-secrets",
				"/namespaces/kube-system/ConfigMap/cilium-config",
			], ",")
		}
	}
	spec: {
		// See docs on ServerCapabilities.LeasesResourceLock in file pkg/k8s/version/version.go
		// for more details.
		replicas: 1
		selector: matchLabels: {
			"io.cilium/app": "operator"
			name:            "cilium-operator"
		}
		// ensure operator update on single node k8s clusters, by using rolling update with maxUnavailable=100% in case
		// of one replica and no user configured Recreate strategy.
		// otherwise an update might get stuck due to the default maxUnavailable=50% in combination with the
		// podAntiAffinity which prevents deployments of multiple operator replicas on the same node.
		strategy: {
			rollingUpdate: {
				maxSurge:       "25%"
				maxUnavailable: "100%"
			}
			type: "RollingUpdate"
		}
		template: {
			metadata: {
				annotations: {
					"prometheus.io/port":   "9963"
					"prometheus.io/scrape": "true"
				}
				labels: {
					"io.cilium/app":             "operator"
					name:                        "cilium-operator"
					"app.kubernetes.io/part-of": "cilium"
					"app.kubernetes.io/name":    "cilium-operator"
				}
			}
			spec: {
				containers: [{
					name:            "cilium-operator"
					image:           "quay.io/cilium/operator-generic:v1.15.4@sha256:404890a83cca3f28829eb7e54c1564bb6904708cdb7be04ebe69c2b60f164e9a"
					imagePullPolicy: "IfNotPresent"
					command: ["cilium-operator-generic"]
					args: [
						"--config-dir=/tmp/cilium/config-map",
						"--debug=$(CILIUM_DEBUG)",
					]
					env: [{
						name: "K8S_NODE_NAME"
						valueFrom: fieldRef: {
							apiVersion: "v1"
							fieldPath:  "spec.nodeName"
						}
					}, {
						name: "CILIUM_K8S_NAMESPACE"
						valueFrom: fieldRef: {
							apiVersion: "v1"
							fieldPath:  "metadata.namespace"
						}
					}, {
						name: "CILIUM_DEBUG"
						valueFrom: configMapKeyRef: {
							key:      "debug"
							name:     "cilium-config"
							optional: true
						}
					}, {
						name:  "KUBERNETES_SERVICE_HOST"
						value: "justia.liao.dev"
					}, {
						name:  "KUBERNETES_SERVICE_PORT"
						value: "6443"
					}]
					ports: [{
						name:          "prometheus"
						containerPort: 9963
						hostPort:      9963
						protocol:      "TCP"
					}]
					livenessProbe: {
						httpGet: {
							host:   "127.0.0.1"
							path:   "/healthz"
							port:   9234
							scheme: "HTTP"
						}
						initialDelaySeconds: 60
						periodSeconds:       10
						timeoutSeconds:      3
					}
					readinessProbe: {
						httpGet: {
							host:   "127.0.0.1"
							path:   "/healthz"
							port:   9234
							scheme: "HTTP"
						}
						initialDelaySeconds: 0
						periodSeconds:       5
						timeoutSeconds:      3
						failureThreshold:    5
					}
					volumeMounts: [{
						name:      "cilium-config-path"
						mountPath: "/tmp/cilium/config-map"
						readOnly:  true
					}]
					terminationMessagePolicy: "FallbackToLogsOnError"
				}]
				hostNetwork:                  true
				restartPolicy:                "Always"
				priorityClassName:            "system-cluster-critical"
				serviceAccount:               "cilium-operator"
				serviceAccountName:           "cilium-operator"
				automountServiceAccountToken: true
				// In HA mode, cilium-operator pods must not be scheduled on the same
				// node as they will clash with each other.
				affinity: {
					podAntiAffinity: requiredDuringSchedulingIgnoredDuringExecution: [{
						labelSelector: matchLabels: "io.cilium/app": "operator"
						topologyKey: "kubernetes.io/hostname"
					}]
				}
				nodeSelector: "kubernetes.io/os": "linux"
				tolerations: [{
					operator: "Exists"
				}]
				volumes: [{
					// To read the configuration from the config map
					name: "cilium-config-path"
					configMap: name: "cilium-config"
				}]
			}
		}
	}
}
