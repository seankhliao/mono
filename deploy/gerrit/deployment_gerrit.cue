package deploy

k8s: apps: v1: Deployment: "gerrit": {
	"gerrit": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/name": "gerrit"
		}
	}).out
	"gerrit": {
		spec: revisionHistoryLimit: 1
		spec: strategy: type: "Recreate"
		spec: template: spec: {
			containers: [{
				image: "index.docker.io/gerritcodereview/gerrit:3.11.0-rc3-ubuntu24"
				name:  "gerrit"
				env: [{
					name:  "CANONICAL_WEB_URL"
					value: "https://gerrit.liao.dev/"
				}]
				ports: [{
					containerPort: 29418
					name:          "git-ssh"
				}, {
					containerPort: 8080
					name:          "http"
				}]
				volumeMounts: [{
					mountPath: "/var/gerrit/cache"
					subPath:   "cache"
					name:      "data"
				}, {
					mountPath: "/var/gerrit/db"
					subPath:   "db"
					name:      "data"
				}, {
					mountPath: "/var/gerrit/etc"
					subPath:   "etc"
					name:      "data"
				}, {
					mountPath: "/var/gerrit/git"
					subPath:   "git"
					name:      "data"
				}, {
					mountPath: "/var/gerrit/index"
					subPath:   "index"
					name:      "data"
				}]
			}]
			volumes: [{
				hostPath: path: "/opt/volumes/gerrit"
				name: "data"
			}]
		}
	}
}
