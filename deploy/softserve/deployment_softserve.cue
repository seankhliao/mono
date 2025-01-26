package deploy

k8s: apps: v1: Deployment: "softserve": {
	"softserve": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/name": "softserve"
		}
	}).out
	"softserve": {
		spec: revisionHistoryLimit: 1
		spec: strategy: type: "Recreate"
		spec: template: spec: {
			containers: [{
				image: "ghcr.io/charmbracelet/soft-serve:v0.8.2"
				name:  "softserve"
				ports: [{
					containerPort: 9418
					name:          "git"
				}, {
					containerPort: 23231
					hostPort:      23231
					name:          "git-ssh"
				}, {
					containerPort: 23232
					name:          "git-http"
				}, {
					containerPort: 23233
					name:          "stats"
				}]
				volumeMounts: [{
					mountPath: "/soft-serve"
					name:      "data"
				}]
			}]
			volumes: [{
				hostPath: path: "/opt/volumes/softserve"
				name: "data"
			}]
		}
	}
}
