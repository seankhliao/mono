package deploy

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [knamespace=string]: [kname=string]: {
	metadata: annotations: {
		"config.kubernetes.io/origin": """
				mono/deploy/opentelemetry/*.cue
			"""
	}
	metadata: labels: {
		"app.kubernetes.io/part-of": "opentelemetry"
		"app.kubernetes.io/name":    string | *"opentelemetry"
	}
}

namespace: (#Namespace & {#args: name: "opentelemetry"})

k8s: namespace.out
