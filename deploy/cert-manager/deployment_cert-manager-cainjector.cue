package deploy

import (
	"strings"
)

k8s: apps: v1: Deployment: "cert-manager": {
	"cert-manager-cainjector": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/part-of":   "cert-manager"
			"app.kubernetes.io/name":      "cert-manager-cainjector"
			"app.kubernetes.io/component": "cainjector"
		}
	}).out
	"cert-manager-cainjector": {
		metadata: annotations: "config.kubernetes.io/depends-on": strings.Join([
			for ref in cainjector_rbac.depends {ref},
		], ",")
		spec: template: spec: {
			serviceAccountName: "cert-manager-cainjector"
			securityContext: {
				runAsNonRoot: true
				seccompProfile: type: "RuntimeDefault"
			}
			containers: [{
				name:            "cert-manager-cainjector"
				image:           "quay.io/jetstack/cert-manager-cainjector:v1.16.0"
				imagePullPolicy: "IfNotPresent"
				args: [
					"--v=2",
					"--leader-election-namespace=cert-manager",
				]
				env: [{
					name: "POD_NAMESPACE"
					valueFrom: fieldRef: fieldPath: "metadata.namespace"
				}]
				securityContext: {
					allowPrivilegeEscalation: false
					capabilities: drop: ["ALL"]
				}
			}]
		}
	}
}
