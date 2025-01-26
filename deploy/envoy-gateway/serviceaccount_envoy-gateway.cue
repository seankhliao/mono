package deploy

k8s: (#Rbac & {
	#args: {
		name:      "envoy-gateway"
		namespace: "envoy-gateway-system"

		clusterRules: [{
			apiGroups: [""]
			resources: ["nodes", "namespaces"]
			verbs: ["get", "list", "watch"]
		}, {
			apiGroups: ["gateway.networking.k8s.io"]
			resources: ["gatewayclasses"]
			verbs: ["get", "list", "patch", "update", "watch"]
		}, {
			apiGroups: ["gateway.networking.k8s.io"]
			resources: ["gatewayclasses/status"]
			verbs: ["update"]
		}, {
			apiGroups: ["multicluster.x-k8s.io"]
			resources: ["serviceimports"]
			verbs: ["get", "list", "watch"]
		}, {
			apiGroups: [""]
			resources: ["configmaps", "secrets", "services"]
			verbs: ["get", "list", "watch"]
		}, {
			apiGroups: ["apps"]
			resources: ["deployments", "daemonsets"]
			verbs: ["get", "list", "watch"]
		}, {
			apiGroups: ["discovery.k8s.io"]
			resources: ["endpointslices"]
			verbs: ["get", "list", "watch"]
		}, {
			apiGroups: ["gateway.envoyproxy.io"]
			resources: ["envoyproxies", "envoypatchpolicies", "clienttrafficpolicies", "backendtrafficpolicies", "securitypolicies", "envoyextensionpolicies", "backends", "httproutefilters"]
			verbs: ["get", "list", "watch"]
		}, {
			apiGroups: ["gateway.envoyproxy.io"]
			resources: ["envoypatchpolicies/status", "clienttrafficpolicies/status", "backendtrafficpolicies/status", "securitypolicies/status", "envoyextensionpolicies/status", "backends/status", "httproutefilters/status"]
			verbs: ["update"]
		}, {
			apiGroups: ["gateway.networking.k8s.io"]
			resources: ["gateways", "grpcroutes", "httproutes", "referencegrants", "tcproutes", "tlsroutes", "udproutes", "backendtlspolicies"]
			verbs: ["get", "list", "watch"]
		}, {
			apiGroups: ["gateway.networking.k8s.io"]
			resources: ["gateways/status", "grpcroutes/status", "httproutes/status", "tcproutes/status", "tlsroutes/status", "udproutes/status", "backendtlspolicies/status"]
			verbs: ["update"]
		}]

		namespaceRules: "envoy-gateway-system": [{
			apiGroups: [""]
			resources: ["serviceaccounts", "services"]
			verbs: ["create", "get", "delete", "patch"]
		}, {
			apiGroups: ["apps"]
			resources: ["deployments", "daemonsets"]
			verbs: ["create", "get", "delete", "patch"]
		}, {
			apiGroups: ["autoscaling"]
			resources: ["horizontalpodautoscalers"]
			verbs: ["create", "get", "delete", "patch"]
		}, {
			apiGroups: ["policy"]
			resources: ["poddisruptionbudgets"]
			verbs: ["create", "get", "delete", "patch"]
		}, {
			apiGroups: [""]
			resources: ["configmaps"]
			verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
		}, {
			apiGroups: ["coordination.k8s.io"]
			resources: ["leases"]
			verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
		}, {
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		}]
	}
}).out
