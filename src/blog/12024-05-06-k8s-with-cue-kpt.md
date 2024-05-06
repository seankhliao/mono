# k8s with cue and kpt

## no more text templates

### _k8s_ with cue and kpt

I recently reset my k8s cluster,
with that, wiping away my previous experiment of deploying things to it.

Previously, I wanted to do gitops at home,
but I didn't want to run [argo cd](https://argo-cd.readthedocs.io/en/stable/)
which I already do for work,
and I didn't really want [flux](https://fluxcd.io/) either,
which is how I ended up using the open source version of
[Config Sync](https://github.com/GoogleContainerTools/kpt-config-sync).
It was fine,
but also really strict 
(a validating webhook prevented any modification outside of the giops flow),
and somewhat hard to recover from errors
(at least without any ui).
I also used it with plain yaml manifests,
not liking any of the templating / modification tools at the time.

Looking around this time,
I wanted something smarter than kubectl especially for pruning
(the [applyset KEP](https://github.com/kubernetes/enhancements/tree/master/keps/sig-cli/3659-kubectl-apply-prune) 
seems to be in limbo atm).
Having a strong dislike for Helm, it and Timoni were out of the picture.
From the applyset KEP,
the other listed options were [Carvel kapp](https://carvel.dev/kapp/)
and [kpt](https://kpt.dev/).
I liked kpt's approach better,
so that's what I chose to move forward with.

While I like the concept of how kpt and config as data passed through a pipeline of KRM functions work,
I wasn't all that enthused about how they were implemented in practice (docker containers),
so I decided I needed something to generaye manifests,
and use kpt as just as smarter applier.

I briefly entertained the idea of defining manifests in Go code,
and just bundling all the functionality from kpt,
but decided it probably wasn't quite worth the effort.
The next best thing appears to be generating the manifests from [cue](https://cuelang.org/),
at least there's some level of type checking and reuse,
even if it is somewhat clunky to have to run 2 commands every time you change something.

#### _cue_

We finally get to using cue:
initially I started with a model similar to how timoni is set up,
but decided that was too much flexibility for too little help in structuring things.
Instead, I landed with a structured tree for how everything would be laid out.
Instead of repeating the keys `apiVersion` / `kind` for every object,
they would become required fields along with namespace and name,
a bit like function args or terraform resources.
With a fixed structure,
I could fill in typemeta and partial objectmeta for every object,
while ensuring that objects are validated against specs.

```cue
package deploy

import (
	"list"
	"strings"

	corev1 "k8s.io/api/core/v1"
)

k8s: [kgroup=string]: [kversion=string]: [kkind=string]: [kns=string]: [kn=string]: {
	if kgroup == "" {
		apiVersion: kversion
	}
	if kgroup != "" {
		apiVersion: kgroup + "/" + kversion
	}
	kind: kkind
	metadata: name: kn
	if kns != "" {
		metadata: namespace: kns
	}
}

k8s: {
	"": v1: {
		ConfigMap: [kns=string]: [kn=string]:             corev1.#ConfigMap
		LimitRange: [kns=string]: [kn=string]:            corev1.#LimitRange
		PersistentVolumeClaim: [kns=string]: [kn=string]: corev1.#PersistentVolumeClaim
		Pod: [kns=string]: [kn=string]:                   corev1.#Pod
		Secret: [kns=string]: [kn=string]:                corev1.#Secret
		Secret: [kns=string]: [kn=string]:                corev1.#Service
		ServiceAccount: [kns=string]: [kn=string]:        corev1.#ServiceAccount

		Namespace: [kns=""]: [kn=string]: corev1.#Namespace
	}
  
  // other apigroups
}
```

Generating the manifests for kpt becomes a matter of flattening the list,
and sending that to `yaml.MarshalStream`.
By defining these at the root directory,
and creating apps in subdirectories while still sharing the same package name,
the resulting command can be called with `cue cmd k8smanifests` in each subdirectory.


```cue
package deploy

k8slist: list.FlattenN([for _group, versions in k8s {
	[for version, kinds in versions {
		[for kind, namespaces in kinds {
			[for namespace, names in namespaces {
				[for name, obj in names {
					obj
				}]
			}]
		}]
	}]
}], -1)

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
```

The pattern I've found to create "functions" looks like the below,
where `out` is unified with where I want it to be used.

```cue
#LabelSelector: {
	#args: {
		labels: [string]: string
	}

	out: {
		metadata: labels: #args.labels
		spec: selector: matchLabels: #args.labels
		spec: template: metadata: labels: #args.labels
	}
}
```

As an example:

```cue
package deploy

k8s: apps: v1: Deployment: "kube-system": {
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
				image: "ghcr.io/charmbracelet/soft-serve:v0.7.4"
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
			enableServiceLinks: false
			volumes: [{
				hostPath: path: "/opt/volumes/softserve"
				name: "data"
			}]
		}
	}
}
```
