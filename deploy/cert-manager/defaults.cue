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

// k8s: controller.k8s
// k8s: cainjector.k8s
// k8s: webhook.k8s
