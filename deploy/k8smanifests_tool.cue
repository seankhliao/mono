package deploy

import (
	"encoding/yaml"
	"tool/file"
	"tool/os"
)

command: k8smanifests: {
	env: os.Getenv & {
		SKAFFOLD_IMAGE?: string
	}

	output: file.Create & {
		filename: "kubernetes.yaml"
		contents: yaml.MarshalStream([for obj in k8slist {
			obj & {
				#config: {
					image: env.SKAFFOLD_IMAGE
				}
			}
		}])
	}
}
