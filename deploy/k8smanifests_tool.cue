package deploy

import (
	"encoding/yaml"
	"tool/file"
	"tool/os"
)

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
}

objs: [for _group, versions in k8s {
	{for version, kinds in versions {
		{for kind, namespaces in kinds {
			{for namespace, names in namespaces {
				{for name, obj in names {
					obj
				}}
			}}
		}}
	}}
}]

command: k8smanifests: {
	env: os.Getenv & {
		SKAFFOLD_IMAGE?: string
	}

	output: file.Create & {
		filename: "kubernetes.yaml"
		contents: yaml.MarshalStream([for obj in objs {
			obj & {
				#config: {
					image: env.SKAFFOLD_IMAGE
				}
			}
		}])
	}
}
