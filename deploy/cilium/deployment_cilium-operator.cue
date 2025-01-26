package deploy

import (
	"strings"
)

k8s: apps: v1: Deployment: "kube-system": {
	"cilium-operator": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/name":      "cilium-operator"
			"app.kubernetes.io/part-of":   "cilium"
			"app.kubernetes.io/component": "operator"
		}
	}).out
	"cilium-operator": {
		metadata: annotations: "config.kubernetes.io/depends-on": strings.Join([
			for ref in cilium_operator_rbac.depends {ref},
			"/namespaces/kube-system/ConfigMap/cilium-config",
		], ",")
		spec: strategy: rollingUpdate: maxUnavailable: "100%"
		spec: template: spec: {
			containers: [{
				name:            "cilium-operator"
				image:           "quay.io/cilium/operator:v1.16.6@sha256:09ab2878e103fa32a00fd1fe4469f7042cfb053627b44c82fa03a04a820c0b46"
				imagePullPolicy: "IfNotPresent"
				command: ["cilium-operator"]
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
