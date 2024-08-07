package deploy

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [knamespace=string]: [kname=string]: {
	metadata: annotations: {
		"config.kubernetes.io/origin": """
				mono/deploy/cilium/*.cue
			"""
	}
	metadata: labels: {
		"app.kubernetes.io/part-of": "cilium"
		"app.kubernetes.io/name":    string | *"cilium"
	}
}
