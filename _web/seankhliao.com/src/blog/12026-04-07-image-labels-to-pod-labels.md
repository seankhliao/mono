# image labels to pod labels

## metadata all over the place

### _image_ to pod labels

I wanted to copy some metadata from deployment artifacts
into the actual deployment.

#### _image_ labels and annotations

OCI / docker container images can contain metadata like labels and annotations.
The [image index](https://github.com/opencontainers/image-spec/blob/main/image-index.md)
(top level reference to each architecture)
can contain annotations,
the [image manifest](https://github.com/opencontainers/image-spec/blob/main/manifest.md)
(per architecture root)
can also contain annotations,
while the [config](https://github.com/opencontainers/image-spec/blob/main/config.md)
for the manifest can contain labels.

Labels can be added on the command line

```sh
docker build --label foo=bar
```

dockerfile

```dockerfile
LABEL foo=bar
```

or in a buildx bake file:

```hcl
target "default" {
  labels = {
    "foo" = "bar"
  }
}
```

Annotations can only be added via command line

```sh
docker build --annotation foo=bar
```

or in a buildx bake file.
It's not really clear why they went with a single string for a key-value pair:

```hcl
target "default" {
  annotations = [
    "foo=bar"
  ]
}
```

The nice thing about being added on the command line
is that they can contain data about the commit that generated it.
While there are [rules](https://github.com/opencontainers/image-spec/blob/main/annotations.md#rules)
about how annotation / labels should look like,
there doesn't appear to be too many enforced constraints.

#### _k8s_ pod labels and annotations

Kubernetes labels are quite restrictive in the
[allowed format](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#syntax-and-character-set):
single slash in key, 63 characters in value.

Annotations are [similar](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/#syntax-and-character-set),
but don't constrain their values.

#### _kyverno_

[kyverno](https://kyverno.io/) is a policy controller that can implement mutation policies.
Importantly for us, it can access image metadata through its `imageRegistry` context / data source.

So we can write a policy like the below,
which on pod creation will pull the image,
extract and copy over some labels onto the pod annotations.

We read from image labels because they're easier to set,
while writing to pod annotations because of the wider allowed character set.
In theory, reading from annotations is possible as well.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
spec:
  rules:
    - name: copy-labels
      match:
        - resources:
            kinds:
              - Pod
            operations:
              - CREATE
      preconditions:
        all:
          - key: >-
              {{ request.object.metadata.annotations."kubectl.kubernetes.io/default-container" || '' }}
            operator: NotEquals
            value: ""
      context:
        - name: image
          variable:
            jmesPath: >-
              request.object.spec.containers[?name == '{{ request.object.metadata.annotations."kubectl.kubernetes.io/default-container" }}']
        - name: labels
          imageRegistry:
            reference: "{{ image }}"
            jmesPath: >-
              configData.config.Labels || `{}`
      mutate:
        foreach:
          - list: >-
              keys(labels) | [?starts_with(@, "example.com")]
            context:
              - name: value
                variable:
                  jmesPath: >-
                    labels."{{ element }}"
            patchesJson6902:
              - op: add
                path: /metadata/annotations/{{ element | replace_all(@, '/', '~1') }}
                value: "{{ value }}"
```

Aside, kyverno started deprecating their ClusterPolicy which was a mashup of yaml and json patches
with new more specific policy types driven by [CEL](https://github.com/google/cel-spec).
Unfortunately, when I tried to do this with MutatingPolicy,
[it couldn't access private registries](https://github.com/kyverno/kyverno/issues/15776).

```yaml
apiVersion: policies.kyverno.io/v1alpha1
kind: MutatingPolicy
spec:
  failurePolicy: Ignore
  matchConstraints:
    resourceRules:
      - apiGroups: [""]
        apiVersions: ["v1"]
        operations: ["CREATE"]
        resources: ["pods"]
  matchConditions:
    - name: has-default-container
      expression: >-
        has(object.metadata.annotations) && "kubectl.kubernetes.io/default-container" in object.metadata.annotations
  variables:
    - name: defaultContainerName
      expression: >-
        object.metadata.annotations["kubectl.kubernetes.io/default-container"]
    - name: defaultContainer
      expression: >-
        object.spec.containers.filter(e, e.name == variables.defaultContainerName)
    - name: containerMetadata
      expression: >-
        image.GetMetadata(variables.defaultContainer[0].image)
    - name: allContainerLabels
      expression: >-
        has(variables.containerMetadata.config.config.Labels) ? variables.containerMetadata.config.config.Labels : {}
    - name: wantKeys
      expression: >-
        variables.allContainerLabels.map(k, k.startsWith(""), {"key": k})
    - name: wantVals
      expression: >-
        variables.wantKeys.map(k, {"val": variables.allContainerLabels[k.key]})
    - name: wantLabels
      expression: >-
        listObjToMap(variables.wantKeys, variables.wantVals, "key", "val")
  mutations:
    - patchType: ApplyConfiguration
      applyConfiguration:
        expression: >-
          Object{
            metadata: Object.metadata{
              annotations: variables.wantLabels,
            }
          }
```
