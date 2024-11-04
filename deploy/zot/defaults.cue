package deploy

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [knamespace=string]: [kname=string]: {
	metadata: annotations: {
		"config.kubernetes.io/origin": """
				mono/deploy/zot/*.cue
			"""
	}
	metadata: labels: {
		"app.kubernetes.io/part-of": "zot"
		"app.kubernetes.io/name":    string | *"zot"
	}
}

namespace: (#Namespace & {#args: name: "zot"})

k8s: namespace.out
