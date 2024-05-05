package deploy

import (
	"list"
	"strings"

	rbacv1 "k8s.io/api/rbac/v1"
)

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [knamespace=string]: [kname=string]: {
	if kgroup == "" {
		apiVersion: kversion
	}
	if kgroup != "" {
		apiVersion: kgroup + "/" + kversion
	}
	kind: kkind
	metadata: name: kname
	if knamespace != "" {
		metadata: namespace: knamespace
	}
}

k8slist: list.FlattenN([for _group, versions in k8s {
	[for version, kinds in versions {
		[for kind, namespaces in kinds {
			[for namespace, names in namespaces {
				[for name, obj in names {
					obj
				}]
			}]
		}]
	}]
}], -1)

#LabelSelector: {
	#args: {
		labels: [string]: string
	}

	out: {
		metadata: labels: #args.labels
		spec: selector: matchLabels: #args.labels
		spec: template: metadata: labels: #args.labels
	}
}

#Rbac: {
	#args: {
		name:      string
		namespace: string
		clusterRules?: [...rbacv1.#PolicyRule]
		namespaceRules?: [string]: [...rbacv1.#PolicyRule]
	}
	out: {
		"": v1: ServiceAccount: "\(#args.namespace)": "\(#args.name)": {}

		"rbac.authorization.k8s.io": v1: {
			if #args.clusterRules != _|_ {
				ClusterRoleBinding: "": "\(#args.name)": rbacv1.#ClusterRoleBinding & {
					metadata: annotations: "config.kubernetes.io/depends-on": strings.Join([
						"/namespaces/\(#args.namespace)/ServiceAccount/\(#args.name)",
						"rbac.authorization.k8s.io/ClusterRole/\(#args.name)",
					], ",")
					roleRef: {
						apiGroup: "rbac.authorization.k8s.io"
						kind:     "ClusterRole"
						name:     #args.name
					}
					subjects: [{
						kind:      "ServiceAccount"
						name:      #args.name
						namespace: #args.namespace
					}]
				}
				ClusterRole: "": "\(#args.name)": rbacv1.#ClusterRole & {
					rules: #args.clusterRules
				}
			}

			RoleBinding: {for ns, rules in #args.namespaceRules {
				"\(ns)": "\(#args.name)": {
					metadata: annotations: "config.kubernetes.io/depends-on": strings.Join([
						"/namespaces/\(#args.namespace)/ServiceAccount/\(#args.name)",
						"rbac.authorization.k8s.io/namespaces/\(#args.namespaces)/Role/\(#args.name)",
					], ",")
					roleRef: {
						apiGroup: "rbac.authorization.k8s.io"
						kind:     "Role"
						name:     #args.name
					}
					subjects: [{
						kind:      "ServiceAccount"
						name:      #args.name
						namespace: #args.namespace
					}]
				}
			}}

			Role: {for ns, rules in #args.namespaceRules {
				"\(ns)": "\(#args.name)": {
					"rules": rules
				}
			}}
		}
	}

	depends: [
		if #args.clusterRules != _|_ {
			"rbac.authorization.k8s.io/ClusterRoleBinding/\(#args.name)"
		},
		for ns, rules in #args.namespaceRules {
			"rbac.authorization.k8s.io/namespaces/\(ns)/RoleBinding/\(#args.name)"
		},
	]
}
