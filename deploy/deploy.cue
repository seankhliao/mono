package deploy

import (
	"encoding/json"
	"list"
	"strings"

	admissionregistrationv1 "k8s.io/api/admissionregistration/v1"
	apiextensionsv1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
	appsv1 "k8s.io/api/apps/v1"
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	batchv1 "k8s.io/api/batch/v1"
	certmanagerv1 "github.com/cert-manager/cert-manager/pkg/apis/certmanager/v1"
	corev1 "k8s.io/api/core/v1"
	gatewayv1 "sigs.k8s.io/gateway-api/apis/v1"
	gatewayv1alpha2 "sigs.k8s.io/gateway-api/apis/v1alpha2"
	gatewayv1beta1 "sigs.k8s.io/gateway-api/apis/v1beta1"
	networkingv1 "k8s.io/api/networking/v1"
	policyv1 "k8s.io/api/policy/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	schedulingv1 "k8s.io/api/scheduling/v1"
	storagev1 "k8s.io/api/storage/v1"
)

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [kns=string]: [kn=string]: {
	if kgroup == "" {
		apiVersion: kversion
	}
	if kgroup != "" {
		apiVersion: kgroup + "/" + kversion
	}
	kind: kkind
	metadata: name: kn
	if kns != "" {
		metadata: namespace: kns
	}
}

k8s: {
	"": v1: {
		ConfigMap: [kns=string]: [kn=string]:             corev1.#ConfigMap
		LimitRange: [kns=string]: [kn=string]:            corev1.#LimitRange
		PersistentVolumeClaim: [kns=string]: [kn=string]: corev1.#PersistentVolumeClaim
		Pod: [kns=string]: [kn=string]:                   corev1.#Pod
		Secret: [kns=string]: [kn=string]:                corev1.#Secret
		Secret: [kns=string]: [kn=string]:                corev1.#Service
		ServiceAccount: [kns=string]: [kn=string]:        corev1.#ServiceAccount

		Namespace: [kns=""]: [kn=string]: corev1.#Namespace
	}
	"admissionregistration.k8s.io": v1: {
		MutatingWebhookConfiguration: [kns=""]: [kn=string]:   admissionregistrationv1.#MutatingWebhookConfiguration
		ValidatingAdmissionPolicy: [kns=""]: [kn=string]:      admissionregistrationv1.#ValidatingAdmissionPolicy
		ValidatingWebhookConfiguration: [kns=""]: [kn=string]: admissionregistrationv1.#ValidatingWebhookConfiguration
	}
	"apiextensions.k8s.io": v1: {
		CustomResourceDefinition: [kns=""]: [kn=string]: apiextensionsv1.#CustomResourceDefinition
	}
	apps: v1: {
		DaemonSet: [kns=string]: [kn=string]: appsv1.#DaemonSet
		Deployment: [kns=string]: [kn=string]: appsv1.#Deployment & {
			spec: template: spec: enableServiceLinks: bool | *false
			spec: revisionHistoryLimit: 1
		}
		StatefulSet: [kns=string]: [kn=string]: appsv1.#StatefulSet
	}
	autoscaling: v2: {
		HorizontalPodAutoscaler: [kns=string]: [kn=string]: autoscalingv2.#HorizontalPodAutoscaler
	}
	batch: v1: {
		CronJob: [kns=string]: [kn=string]: batchv1.#CronJob
		Job: [kns=string]: [kn=string]:     batchv1.#Job
	}
	"cert-manager.io": v1: {
		Certificate: [kns=string]: [kn=string]: certmanagerv1.#Certificate
		Issuer: [kns=string]: [kn=string]:      certmanagerv1.#Issuer

		ClusterIssuer: [kns=""]: [kn=string]: certmanagerv1.#ClusterIssuer
	}
	"gateway.networking.k8s.io": {
		v1alpha2: {
			BackendTLSPolicy: [kns=string]: [kn=string]: gatewayv1alpha2.#BackendTLSPolicy
			GRPCRoute: [kns=string]: [kn=string]:        gatewayv1alpha2.#GRPCRoute
			TCPRoute: [kns=string]: [kn=string]:         gatewayv1alpha2.#TCPRoute
			TLSRoute: [kns=string]: [kn=string]:         gatewayv1alpha2.#TLSRoute
			UDPRoute: [kns=string]: [kn=string]:         gatewayv1alpha2.#UDPRoute
		}
		v1beta1: {
			ReferenceGrant: [kns=string]: [kn=string]: gatewayv1beta1.#ReferenceGrant
		}
		v1: {
			Gateway: [kns=string]: [kn=string]:   gatewayv1.#Gateway
			HTTPRoute: [kns=string]: [kn=string]: gatewayv1.#HTTPRoute

			GatewayClass: [kns=""]: [kn=string]: gatewayv1.#GatewayClass
		}
	}
	"networking.k8s.io": v1: {
		Ingress: [kns=string]: [kn=string]: networkingv1.#Ingress
	}
	policy: v1: {
		PodDisruptionBudget: [kns=string]: [kn=string]: policyv1.#PodDisruptionBudget
	}
	"rbac.authorization.k8s.io": v1: {
		RoleBinding: [kns=string]: [kn=string]: rbacv1.#RoleBinding
		Role: [kns=string]: [kn=string]:        rbacv1.#Role

		ClusterRoleBinding: [kns=""]: [kn=string]: rbacv1.#ClusterRoleBinding
		ClusterRole: [kns=""]: [kn=string]:        rbacv1.#ClusterRole
	}
	"scheduling.k8s.io": v1: {
		PriorityClass: [kns=""]: [kn=string]: schedulingv1.#PriorityClass
	}
	"storage.k8s.io": v1: {
		StorageClass: [kns=""]: [kn=string]: storagev1.#StorageClass
	}
}

k8slist: list.FlattenN([for _group, versions in k8s {
	[for version, kinds in versions {
		[for kind, namespaces in kinds {
			[for namespace, names in namespaces {
				[for name, obj in names {
					obj & {
						metadata: labels: "app.kubernetes.io/managed-by": "kpt"
					}
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

#Namespace: {
	#args: {
		name: string
	}

	gcpEnv: {
		name:  "GOOGLE_APPLICATION_CREDENTIALS"
		value: "/var/run/service-account/creds.json"
	}
	gcpVolumeMount: {
		name:      "token"
		mountPath: "/var/run/service-account"
		readOnly:  true
	}
	gcpVolume: {
		name: "token"
		projected: sources: [{
			serviceAccountToken: {
				audience:          "https://iam.googleapis.com/projects/330311169810/locations/global/workloadIdentityPools/kubernetes/providers/justia-asami"
				expirationSeconds: 3600
				path:              "token"
			}
		}, {
			configMap: name: "gcp"
		}]
	}

	out: {
		"": v1: "ConfigMap": "\(#args.name)": "gcp": "data": {
			"creds.json": json.Marshal({
				"universe_domain":    "googleapis.com"
				"type":               "external_account"
				"audience":           "//iam.googleapis.com/projects/330311169810/locations/global/workloadIdentityPools/kubernetes/providers/justia-asami"
				"subject_token_type": "urn:ietf:params:oauth:token-type:jwt"
				"token_url":          "https://sts.googleapis.com/v1/token"
				"credential_source": {
					"file": "/var/run/service-account/token"
					"format": {
						"type": "text"
					}
				}
				"token_info_url": "https://sts.googleapis.com/v1/introspect"
			})
		}
		"": v1: "Namespace": "": "\(#args.name)": {}
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
