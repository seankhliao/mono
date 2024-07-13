package deploy

import (
	"strings"
)

k8s: apps: v1: Deployment: "cert-manager": {
	"cert-manager-controller": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/part-of":   "cert-manager"
			"app.kubernetes.io/name":      "cert-manager-controller"
			"app.kubernetes.io/component": "controller"
		}
	}).out
	"cert-manager-controller": {
		metadata: annotations: "config.kubernetes.io/depends-on": strings.Join([
			for ref in controller_rbac.depends {ref},
		], ",")
		spec: template: spec: {
			serviceAccountName: "cert-manager-controller"
			securityContext: {
				runAsNonRoot: true
				seccompProfile: type: "RuntimeDefault"
			}
			containers: [{
				name:            "cert-manager-controller"
				image:           "quay.io/jetstack/cert-manager-controller:v1.13.2"
				imagePullPolicy: "IfNotPresent"
				args: [
					"--v=2",
					"--cluster-resource-namespace=$(POD_NAMESPACE)",
					"--leader-election-namespace=cert-manager",
					"--acme-http01-solver-image=quay.io/jetstack/cert-manager-acmesolver:v1.13.2",
					"--max-concurrent-challenges=60",
				]
				ports: [{
					containerPort: 9402
					name:          "http-metrics"
					protocol:      "TCP"
				}, {
					containerPort: 9403
					name:          "http-healthz"
					protocol:      "TCP"
				}]
				securityContext: {
					allowPrivilegeEscalation: false
					capabilities: drop: ["ALL"]
				}
				env: [{
					name: "POD_NAMESPACE"
					valueFrom: fieldRef: fieldPath: "metadata.namespace"
				}]
			}]
		}
	}
}
