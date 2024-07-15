package deploy

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [knamespace=string]: [kname=string]: {
	metadata: annotations: {
		"config.kubernetes.io/origin": """
				mono/deploy/envoy-gateway/*.cue
			"""
	}
	metadata: labels: {
		"app.kubernetes.io/part-of": "envoy-gateway"
		"app.kubernetes.io/name":    string | *"envoy-gateway"
	}
}

namespace: (#Namespace & {#args: name: "envoy-gateway-system"})

k8s: namespace.out
