package deploy

cainjector_rbac: #Rbac & {
	#args: {
		name:      "cert-manager-cainjector"
		namespace: "cert-manager"

		clusterRules: [{
			apiGroups: ["cert-manager.io"]
			resources: ["certificates"]
			verbs: ["get", "list", "watch"]
		}, {
			apiGroups: [""]
			resources: ["secrets"]
			verbs: ["get", "list", "watch"]
		}, {
			apiGroups: [""]
			resources: ["events"]
			verbs: ["get", "create", "update", "patch"]
		}, {
			apiGroups: ["admissionregistration.k8s.io"]
			resources: ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"]
			verbs: ["get", "list", "watch", "update", "patch"]
		}, {
			apiGroups: ["apiregistration.k8s.io"]
			resources: ["apiservices"]
			verbs: ["get", "list", "watch", "update", "patch"]
		}, {
			apiGroups: ["apiextensions.k8s.io"]
			resources: ["customresourcedefinitions"]
			verbs: ["get", "list", "watch", "update", "patch"]
		}]

		namespaceRules: "cert-manager": [{
			// Used for leader election by the controller
			// cert-manager-cainjector-leader-election is used by the CertificateBased injector controller
			//   see cmd/cainjector/start.go#L113
			// cert-manager-cainjector-leader-election-core is used by the SecretBased injector controller
			//   see cmd/cainjector/start.go#L137
			apiGroups: ["coordination.k8s.io"]
			resources: ["leases"]
			resourceNames: ["cert-manager-cainjector-leader-election", "cert-manager-cainjector-leader-election-core"]
			verbs: ["get", "update", "patch"]
		}, {
			apiGroups: ["coordination.k8s.io"]
			resources: ["leases"]
			verbs: ["create"]
		}]

	}
}

k8s: cainjector_rbac.out
