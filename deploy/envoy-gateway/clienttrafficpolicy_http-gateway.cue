package deploy

k8s: "gateway.envoyproxy.io": "v1alpha1": "ClientTrafficPolicy": "envoy-gateway-system": "http-gateway": {
	spec: {
		http3: {}
		path: {
			// required by gerrit
			escapedSlashesAction: "KeepUnchanged"
			disableMergeSlashes:  true
		}
		targetRefs: [{
			group: "gateway.networking.k8s.io"
			kind:  "Gateway"
			name:  "http-gateway"
		}]
	}
}
