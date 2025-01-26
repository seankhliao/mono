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
			initContainers: [{
				image: "index.docker.io/gerritcodereview/gerrit:3.11.1-ubuntu24"
				name:  "gerrit-init"
				command: [
					"sh",
					"-c",
					"""
						if [ ! -d /var/gerrit/git/All-Projects.git ]
						then
						  echo "Initializing Gerrit site ..."
						  java $JAVA_OPTS -jar /var/gerrit/bin/gerrit.war init --batch --install-all-plugins -d /var/gerrit
						  java $JAVA_OPTS -jar /var/gerrit/bin/gerrit.war reindex -d /var/gerrit
						  git config -f /var/gerrit/etc/gerrit.config --add container.javaOptions "-Djava.security.egd=file:/dev/./urandom"
						  git config -f /var/gerrit/etc/gerrit.config --add container.javaOptions "--add-opens java.base/java.net=ALL-UNNAMED"
						  git config -f /var/gerrit/etc/gerrit.config --add container.javaOptions "--add-opens java.base/java.lang.invoke=ALL-UNNAMED"
						fi
						""",
				]
				env: [{
					name:  "JAVA_OPTS"
					value: "--add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/java.lang.invoke=ALL-UNNAMED"
				}]
				volumeMounts: [{
					mountPath: "/var/gerrit/cache"
					subPath:   "cache"
					name:      "data"
				}, {
					mountPath: "/var/gerrit/data"
					subPath:   "data"
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
				}, {
					mountPath: "/var/gerrit/logs"
					subPath:   "logs"
					name:      "data"
				}]
			}]
			containers: [{
				image: "index.docker.io/gerritcodereview/gerrit:3.11.1-ubuntu24"
				name:  "gerrit"
				command: [
					"/var/gerrit/bin/gerrit.sh",
					"run",
				]
				env: [{
					name:  "JAVA_OPTS"
					value: "--add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/java.lang.invoke=ALL-UNNAMED"
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
					mountPath: "/var/gerrit/data"
					subPath:   "data"
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
				}, {
					mountPath: "/var/gerrit/logs"
					subPath:   "logs"
					name:      "data"
				}, {
					mountPath: "/var/gerrit/plugins"
					subPath:   "plugins"
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
