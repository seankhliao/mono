package deploy

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
	metadata: annotations: {
		"config.kubernetes.io/origin": """
				mono/deploy/cilium/*.cue
			"""
	}
	metadata: labels: {
		"app.kubernetes.io/part-of": "cilium"
	}
}
