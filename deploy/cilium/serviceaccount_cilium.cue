package deploy

import (
	"strings"

	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

k8s: "": v1: ServiceAccount: "kube-system": "cilium": corev1.#ServiceAccount & {
	metadata: {
		annotations: {
			"config.kubernetes.io/depends-on": strings.Join([
				"rbac.authorization.k8s.io/ClusterRole/cilium",
				"rbac.authorization.k8s.io/namespaces/kube-system/Role/cilium-config-agent",
				"rbac.authorization.k8s.io/namespaces/cilium-secrets/Role/cilium-gateway-secrets",
			], ",")
		}
	}
}

k8s: "rbac.authorization.k8s.io": v1: ClusterRoleBinding: "": "cilium": rbacv1.#ClusterRoleBinding & {
	metadata: namespace: _
	metadata: {
		labels: "app.kubernetes.io/part-of": "cilium"
		annotations: {
			"config.kubernetes.io/depends-on": strings.Join([
				"/namespaces/kube-system/ServiceAccount/cilium",
				"rbac.authorization.k8s.io/ClusterRole/cilium",
			], ",")
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     "cilium"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      "cilium"
		namespace: "kube-system"
	}]
}

k8s: "rbac.authorization.k8s.io": v1: RoleBinding: "kube-system": "cilium-config-agent": rbacv1.#RoleBinding & {
	metadata: {
		labels: "app.kubernetes.io/part-of": "cilium"
		annotations: {
			"config.kubernetes.io/depends-on": strings.Join([
				"/namespaces/kube-system/ServiceAccount/cilium",
				"rbac.authorization.k8s.io/namespaces/kube-system/Role/cilium-config-agent",
			], ",")
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "cilium-config-agent"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      "cilium"
		namespace: "kube-system"
	}]
}

k8s: "rbac.authorization.k8s.io": v1: RoleBinding: "cilium-secrets": "cilium-gateway-secrets": rbacv1.#RoleBinding & {
	metadata: {
		labels: "app.kubernetes.io/part-of": "cilium"
		annotations: {
			"config.kubernetes.io/depends-on": strings.Join([
				"/namespaces/kube-system/ServiceAccount/cilium",
				"rbac.authorization.k8s.io/namespaces/cilium-secrets/Role/cilium-gateway-secrets",
			], ",")
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "cilium-gateway-secrets"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      "cilium"
		namespace: "kube-system"
	}]
}

k8s: "rbac.authorization.k8s.io": v1: ClusterRole: "": "cilium": rbacv1.#ClusterRole & {
	metadata: {
		labels: "app.kubernetes.io/part-of": "cilium"
	}
	rules: [{
		apiGroups: ["networking.k8s.io"]
		resources: ["networkpolicies"]
		verbs: [
			"get",
			"list",
			"watch",
		]
	}, {
		apiGroups: ["discovery.k8s.io"]
		resources: ["endpointslices"]
		verbs: [
			"get",
			"list",
			"watch",
		]
	}, {
		apiGroups: [""]
		resources: [
			"namespaces",
			"services",
			"pods",
			"endpoints",
			"nodes",
		]
		verbs: [
			"get",
			"list",
			"watch",
		]
	}, {
		apiGroups: ["apiextensions.k8s.io"]
		resources: ["customresourcedefinitions"]
		verbs: [
			"list",
			"watch",
			"get",
		]
	}, {

		apiGroups: ["cilium.io"]
		resources: [
			"ciliumloadbalancerippools",
			"ciliumbgppeeringpolicies",
			"ciliumbgpnodeconfigs",
			"ciliumbgpadvertisements",
			"ciliumbgppeerconfigs",
			"ciliumclusterwideenvoyconfigs",
			"ciliumclusterwidenetworkpolicies",
			"ciliumegressgatewaypolicies",
			"ciliumendpoints",
			"ciliumendpointslices",
			"ciliumenvoyconfigs",
			"ciliumidentities",
			"ciliumlocalredirectpolicies",
			"ciliumnetworkpolicies",
			"ciliumnodes",
			"ciliumnodeconfigs",
			"ciliumcidrgroups",
			"ciliuml2announcementpolicies",
			"ciliumpodippools",
		]
		verbs: [
			"list",
			"watch",
		]
		// This is used when validating policies in preflight. This will need to stay
		// until we figure out how to avoid "get" inside the preflight, and then
		// should be removed ideally.
	}, {
		apiGroups: ["cilium.io"]
		resources: [
			"ciliumidentities",
			"ciliumendpoints",
			"ciliumnodes",
		]
		verbs: ["create"]
	}, {
		apiGroups: ["cilium.io"]
		// To synchronize garbage collection of such resources
		resources: ["ciliumidentities"]
		verbs: ["update"]
	}, {
		apiGroups: ["cilium.io"]
		resources: ["ciliumendpoints"]
		verbs: [
			"delete",
			"get",
		]
	}, {
		apiGroups: ["cilium.io"]
		resources: [
			"ciliumnodes",
			"ciliumnodes/status",
		]
		verbs: [
			"get",
			"update",
		]
	}, {
		apiGroups: ["cilium.io"]
		resources: [
			"ciliumnetworkpolicies/status",
			"ciliumclusterwidenetworkpolicies/status",
			"ciliumendpoints/status",
			"ciliumendpoints",
			"ciliuml2announcementpolicies/status",
			"ciliumbgpnodeconfigs/status",
		]
		verbs: ["patch"]
	}]
}

k8s: "rbac.authorization.k8s.io": v1: Role: "kube-system": "cilium-config-agent": rbacv1.#Role & {
	metadata: {
		labels: "app.kubernetes.io/part-of": "cilium"
	}
	rules: [{
		apiGroups: [""]
		resources: ["configmaps"]
		verbs: [
			"get",
			"list",
			"watch",
		]
	}]
}

k8s: "rbac.authorization.k8s.io": v1: Role: "cilium-secrets": "cilium-gateway-secrets": rbacv1.#Role & {
	metadata: {
		labels: "app.kubernetes.io/part-of": "cilium"
	}
	rules: [{
		apiGroups: [""]
		resources: ["secrets"]
		verbs: [
			"get",
			"list",
			"watch",
		]
	}]
}
