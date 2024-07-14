package deploy

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [knamespace=string]: [kname=string]: {
	metadata: annotations: {
		"config.kubernetes.io/origin": """
				mono/deploy/softserve/*.cue
			"""
	}
	metadata: labels: {
		"app.kubernetes.io/part-of": "softserve"
		"app.kubernetes.io/name":    string | *"softserve"
	}
}

namespace: (#Namespace & {#args: name: "softserve"})

k8s: namespace.out
