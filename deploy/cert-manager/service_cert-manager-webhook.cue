package deploy

import (
	corev1 "k8s.io/api/core/v1"
)

k8s: "": v1: Service: "cert-manager": "cert-manager-webhook": corev1.#Service & {
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "https"
			port:       443
			protocol:   "TCP"
			targetPort: "https"
		}]
		selector: {
			"app.kubernetes.io/name":      "cert-manager-webhook"
			"app.kubernetes.io/component": "webhook"
		}
	}
}

k8s: "admissionregistration.k8s.io": v1: MutatingWebhookConfiguration: "": "cert-manager": {
	metadata: annotations: "cert-manager.io/inject-ca-from-secret": "cert-manager/cert-manager-webhook-ca"
	webhooks: [{
		name: "webhook.cert-manager.io"
		rules: [{
			apiGroups: [
				"cert-manager.io",
				"acme.cert-manager.io",
			]
			apiVersions: ["v1"]
			operations: [
				"CREATE",
				"UPDATE",
			]
			resources: ["*/*"]
		}]
		admissionReviewVersions: ["v1"]
		// This webhook only accepts v1 cert-manager resources.
		// Equivalent matchPolicy ensures that non-v1 resource requests are sent to
		// this webhook (after the resources have been converted to v1).
		matchPolicy:    "Equivalent"
		timeoutSeconds: 10
		failurePolicy:  "Fail"
		// Only include 'sideEffects' field in Kubernetes 1.12+
		sideEffects: "None"
		clientConfig: service: {
			name:      "cert-manager-webhook"
			namespace: "cert-manager"
			path:      "/mutate"
		}
	}]
}

k8s: "admissionregistration.k8s.io": v1: ValidatingWebhookConfiguration: "": "cert-manager": {
	metadata: annotations: "cert-manager.io/inject-ca-from-secret": "cert-manager/cert-manager-webhook-ca"
	webhooks: [{
		name: "webhook.cert-manager.io"
		namespaceSelector: matchExpressions: [{
			key:      "cert-manager.io/disable-validation"
			operator: "NotIn"
			values: ["true"]
		}]
		rules: [{
			apiGroups: [
				"cert-manager.io",
				"acme.cert-manager.io",
			]
			apiVersions: ["v1"]
			operations: [
				"CREATE",
				"UPDATE",
			]
			resources: ["*/*"]
		}]
		admissionReviewVersions: ["v1"]
		// This webhook only accepts v1 cert-manager resources.
		// Equivalent matchPolicy ensures that non-v1 resource requests are sent to
		// this webhook (after the resources have been converted to v1).
		matchPolicy:    "Equivalent"
		timeoutSeconds: 10
		failurePolicy:  "Fail"
		sideEffects:    "None"
		clientConfig: service: {
			name:      "cert-manager-webhook"
			namespace: "cert-manager"
			path:      "/validate"
		}
	}]
}
