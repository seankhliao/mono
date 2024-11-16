package deploy

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [knamespace=string]: [kname=string]: {
	metadata: annotations: {
		"config.kubernetes.io/origin": """
				mono/deploy/gerrit/*.cue
			"""
	}
	metadata: labels: {
		"app.kubernetes.io/part-of": "gerrit"
		"app.kubernetes.io/name":    string | *"gerrit"
	}
}

namespace: (#Namespace & {#args: name: "gerrit"})

k8s: namespace.out
