package deploy

controller_rbac: #Rbac & {
	#args: {
		name:      "cert-manager-controller"
		namespace: "cert-manager"

		clusterRules: [{
			apiGroups: [""]
			resources: ["secrets"]
			verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]
		}, {
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		}, {
			apiGroups: ["certificates.k8s.io"]
			resources: ["certificatesigningrequests", "certificatesigningrequests/status"]
			verbs: ["get", "list", "watch", "update", "patch"]
		}, {
			apiGroups: ["certificates.k8s.io"]
			resources: ["signers"]
			resourceNames: ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"]
			verbs: ["sign"]
		}, {
			apiGroups: ["authorization.k8s.io"]
			resources: ["subjectaccessreviews"]
			verbs: ["create"]
		}, {
			apiGroups: ["cert-manager.io"]
			resources: ["*"]
			verbs: ["*"]
		}, {
			apiGroups: ["acme.cert-manager.io"]
			resources: ["*"]
			verbs: ["*"]
		}]

		namespaceRules: "cert-manager": [{
			apiGroups: ["coordination.k8s.io"]
			resources: ["leases"]
			resourceNames: ["cert-manager-controller"]
			verbs: ["get", "update", "patch"]
		}, {
			apiGroups: ["coordination.k8s.io"]
			resources: ["leases"]
			verbs: ["create"]
		}]
	}
}

k8s: controller_rbac.out
