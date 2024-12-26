package deploy

k8s: apps: v1: Deployment: "zot": {
	"zot": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/name": "zot"
		}
	}).out
	"zot": {
		spec: revisionHistoryLimit: 1
		spec: strategy: type: "Recreate"
		spec: template: spec: {
			containers: [{
				image: "ghcr.io/project-zot/zot:v2.1.1"
				name:  "zot"
				ports: [{
					containerPort: 5000
					name:          "http"
				}]
				volumeMounts: [{
					mountPath: "/data"
					name:      "data"
				}, {
					mountPath: "/etc/zot"
					name:      "config"
				}, {
					mountPath: "/var/run/secrets/zot"
					name:      "secrets"
				}]
			}]
			volumes: [{
				hostPath: path: "/opt/volumes/zot"
				name: "data"
			}, {
				configMap: name: "zot"
				name: "config"
			}, {
				secret: secretName: "zot"
				name: "secrets"
			}]
		}
	}
}
