package deploy

webhook_rbac: #Rbac & {
	#args: {
		name:      "cert-manager-webhook"
		namespace: "cert-manager"

		clusterRules: [{
			apiGroups: ["authorization.k8s.io"]
			resources: ["subjectaccessreviews"]
			verbs: ["create"]
		}]

		namespaceRules: "cert-manager": [{
			apiGroups: [""]
			resources: ["secrets"]
			resourceNames: ["cert-manager-webhook-ca"]
			verbs: ["get", "list", "watch", "update"]
		}, {
			// It's not possible to grant CREATE permission on a single resourceName.
			apiGroups: [""]
			resources: ["secrets"]
			verbs: ["create"]
		}]
	}
}

k8s: webhook_rbac.out
