package deploy

import (
	"strings"

	appsv1 "k8s.io/api/apps/v1"
)

k8s: apps: v1: Deployment: "cert-manager": {
	"cert-manager-webhook": appsv1.#Deployment
	"cert-manager-webhook": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/part-of":   "cert-manager"
			"app.kubernetes.io/name":      "cert-manager-webhook"
			"app.kubernetes.io/component": "webhook"
		}
	}).out
	"cert-manager-webhook": {
		metadata: annotations: "config.kubernetes.io/depends-on": strings.Join([
			for ref in webhook_rbac.depends {ref},
		], ",")
		spec: template: spec: {
			serviceAccountName: "cert-manager-webhook"
			enableServiceLinks: false
			securityContext: {
				runAsNonRoot: true
				seccompProfile: type: "RuntimeDefault"
			}
			containers: [{
				name:            "cert-manager-webhook"
				image:           "quay.io/jetstack/cert-manager-webhook:v1.13.2"
				imagePullPolicy: "IfNotPresent"
				args: [
					"--v=2",
					"--secure-port=10250",
					"--dynamic-serving-ca-secret-namespace=$(POD_NAMESPACE)",
					"--dynamic-serving-ca-secret-name=cert-manager-webhook-ca",
					"--dynamic-serving-dns-names=cert-manager-webhook",
					"--dynamic-serving-dns-names=cert-manager-webhook.$(POD_NAMESPACE)",
					"--dynamic-serving-dns-names=cert-manager-webhook.$(POD_NAMESPACE).svc",
				]
				ports: [{
					name:          "https"
					protocol:      "TCP"
					containerPort: 10250
				}, {
					name:          "healthcheck"
					protocol:      "TCP"
					containerPort: 6080
				}]
				livenessProbe: {
					httpGet: {
						path:   "/livez"
						port:   6080
						scheme: "HTTP"
					}
					initialDelaySeconds: 60
					periodSeconds:       10
					timeoutSeconds:      1
					successThreshold:    1
					failureThreshold:    3
				}
				readinessProbe: {
					httpGet: {
						path:   "/healthz"
						port:   6080
						scheme: "HTTP"
					}
					initialDelaySeconds: 5
					periodSeconds:       5
					timeoutSeconds:      1
					successThreshold:    1
					failureThreshold:    3
				}
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
