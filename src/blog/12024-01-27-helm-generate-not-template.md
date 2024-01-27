# helm: generate not template

## banish whitespace errors?

### _generating_ yaml with helm

[Helm](https://helm.sh/), a very popular way of writing kubernetes charts,
but why oh why are we templating yaml,
whitespace sensitive language?

While the better way of doing it is to generate manifests with a sane language,
it might not always be an option,
and we're stuck with Helm for the time being.
So maybe we can make our lives a little bit easier?

#### _typical_ helm chart

This is what you see in the wild.
Fragments of yaml in `define` blocks,
partial yaml that you want to write out,
littered with `include .... | nindent` to include fragments at the right indent level.

```helm
{{- define "app.name" -}}
my-app
{{- end }}

{{- define "app.labels" }}
{{ include "app.selectorLabels" . }}
example.com/owner: me
{{- end }}

{{- define "app.selectorLabels" }}
app.kubernetes.io/name: my-app
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "app.name" . }}
  labels:
    {{- include "app.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "app.labels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ include "app.name" . }}
          image: {{ .Values.image.respository }}:{{ .Values.image.tag }}
```

Say you want to provide a helper to generate a sidecar,
you might write soemthing like:

```helm
{{- define "sidecar" }}
name: "my-sidecar"
image: "example.com/sidecar:latest"
{{- end }}
```

Your instructions to users would be something like:

> add `- {{- include "sidecar" . | nindent 10 }}` after deployment spec.containers

But of course this will fail when people use different list indent styles:

```txt
list1:
- item1
- item2
list2:
  - item1
  - item2
```

Which may result in errors like:
 
> Error: YAML parse error on my-app/templates/deployment-old.yaml: error converting YAML to JSON: yaml: line 28: found character that cannot start any token

and you can't run the templates through a formatter to make them consistent.

#### _generating_ yaml

What if instead of templating out yaml,
we create a native object instead, 
and at the end, we marshal it into a yaml document?

```helm
{{ $appName := "my-app" }}
{{ $appSelectorLabels := dict
  "app.kubernetes.io/name" "my-app"
  "app.kubernetes.io/instance" .Release.Name
}}
{{ $appLabels := merge (dict
    "example.com" "me"
  )
  $appSelectorLabels
}}
---
{{ $deploy := dict
  "apiVersion" "apps/v1"
  "kind" "Deployment"
  "metadata" (dict
    "name" $appName
    "labels"  $appLabels
  )
  "spec" (dict
    "selector" (dict
      "matchLabels" $appSelectorLabels
    )
    "template" (dict
      "metadata" (dict
        "labels" $appLabels
      )
      "spec" (dict
        "containers" (list
          (dict
            "name" $appName
            "image" (printf "%s:%s" .Values.image.repository .Values.image.tag)
          )
        )
      )
    )
  )
}}
{{- toYaml $deploy -}}
```

Now when we want to have a helper that adds a sidecar,
we can instead write a function like the following
(Note that maps/dicts in Go/Helm templates passed by reference and modified in place):

```helm
{{ define "add-sidecar" }}
{{ $sidecar := dict 
  "name" "my-sidecar"
  "image" "example.com/my-sidecar:latest"
}}
{{ $containers := concat (list $sidecar) .spec.template.spec.containers }}
{{ $_ := set .spec.template.spec "containers" $containers }}
{{- end }}
```

And usage instructions can be:

> add `{{ include "add-sidecar $deploy }}` before `{{ toYaml $deploy }}`

Now there's no possibility of whitespace errors.

As a bonus, if you have values you want to pass in,
you can do `{{ mergeOverrite $deploy .Values.deploymentOverrides }}`
