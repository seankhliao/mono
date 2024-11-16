package deploy

k8s: "gateway.networking.k8s.io": "v1": "HTTPRoute": "gerrit": "gerrit": "spec": {
	hostnames: [
		"gerrit.liao.dev",
	]
	parentRefs: [{
		name:      "http-gateway"
		namespace: "envoy-gateway-system"
	}]
	rules: [{
		backendRefs: [{
			name: "gerrit"
			port: 80
		}]
	},
		// filters: [{
		// 	type: "ResponseHeaderModifier"
		// 	responseHeaderModifier: add: [{
		// 		name:  "WWW-Authenticate"
		// 		value: "Basic realm=gerrit"
		// 	}]
		// }]
	]
}

k8s: "gateway.envoyproxy.io": "v1alpha1": "SecurityPolicy": "gerrit": "gerrit": spec: {
	targetRefs: [{
		group: "gateway.networking.k8s.io"
		kind:  "HTTPRoute"
		name:  "gerrit"
	}]
	basicAuth: users: name: "basic-auth" // name of secret
}
