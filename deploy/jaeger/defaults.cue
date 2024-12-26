package deploy

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [knamespace=string]: [kname=string]: {
	metadata: annotations: {
		"config.kubernetes.io/origin": """
				mono/deploy/jaeger/*.cue
			"""
	}
	metadata: labels: {
		"app.kubernetes.io/part-of": "jaeger"
		"app.kubernetes.io/name":    string | *"jaeger"
	}
}

namespace: (#Namespace & {#args: name: "jaeger"})

k8s: namespace.out
