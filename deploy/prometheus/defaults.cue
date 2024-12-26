package deploy

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [knamespace=string]: [kname=string]: {
	metadata: annotations: {
		"config.kubernetes.io/origin": """
				mono/deploy/prometheus/*.cue
			"""
	}
	metadata: labels: {
		"app.kubernetes.io/part-of": "prometheus"
		"app.kubernetes.io/name":    string | *"prometheus"
	}
}

namespace: (#Namespace & {#args: name: "prometheus"})

k8s: namespace.out
