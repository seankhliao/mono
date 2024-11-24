package deploy

import (
	"encoding/yaml"
	"path"
	"tool/file"
)

#args: {
	name:     string @tag(name)
	baserepo: "ghcr.io/seankhliao"
}

#DefaultsCue: #"""
	package deploy

	k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [knamespace=string]: [kname=string]: {
		metadata: annotations: {
			"config.kubernetes.io/origin": """
					mono/deploy/\#(#args.name)/*.cue
				"""
		}
		metadata: labels: {
			"app.kubernetes.io/part-of": "\#(#args.name)"
			"app.kubernetes.io/name":    string | *"\#(#args.name)"
		}
	}

	namespace: (#Namespace & {#args: name: "\#(#args.name)"})

	k8s: namespace.out
	"""#

#Kptfile: {
	apiVersion: "kpt.dev/v1"
	kind:       "Kptfile"
	metadata: name: #args.name
	metadata: annotations: "config.kubernetes.io/local-config": "true"
	info: description: "generated Kptfile for \(#args.name)"
}

#Skaffold: {
	apiVersion: "skaffold/v4beta10"
	kind:       "Config"
	metadata: name: #args.name
	build: artifacts: [{
		image: "\(#args.baserepo)/\(#args.name):latest"
		ko: {
			fromImage: "gcr.io/distroless/static-debian12:nonroot"
			env: ["CGO_ENABLED=0"]
			flags: ["-trimpath"]
			ldflags: ["-s", "-w"]
		}
	}]
	build: tagPolicy: inputDigest: {}
	build: platforms: ["linux/arm64", "linux/amd64"]
	build: local: concurrency: 0
	manifests: kpt: ["./"]
	manifests: hooks: before: [{host: {command: ["cue", "cmd", "k8smanifests"]}}]
	deploy: kpt: applyFlags: ["--server-side"]
	deploy: statusCheck: true
	deploy: kubeContext: "user@asami"
}

// usage:
//    cue cmd --inject "name=foo" skaffold
command: skaffold: {
	dir: file.MkdirAll & {
		path: #args.name
	}

	kptfile: file.Create & {
		filename: path.Join([dir.path, "Kptfile"], "unix")
		contents: yaml.Marshal(#Kptfile)
		$after: [dir]
	}

	defaultscue: file.Create & {
		filename: path.Join([dir.path, "defaults.cue"], "unix")
		contents: #DefaultsCue
		$after: [dir]
	}

	skaffold: file.Create & {
		filename: path.Join([dir.path, "skaffold.yaml"], "unix")
		contents: yaml.Marshal(#Skaffold)
		$after: [dir]
	}
}
