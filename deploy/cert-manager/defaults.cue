package deploy

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [knamespace=string]: [kname=string]: {
	metadata: annotations: {
		"config.kubernetes.io/origin": """
				mono/deploy/cert-manager/*.cue
			"""
	}
	metadata: labels: {
		"app.kubernetes.io/part-of": "cert-manager"
		"app.kubernetes.io/name":    string | *"cert-manager"
	}
}

namespace: (#Namespace & {#args: name: "cert-manager"})

k8s: namespace.out
