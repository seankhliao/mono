# kubebuilder applyconfiguration

## how to configure kubebuilder to generate the new apply types

### _kubebuilder_ applyconfigurations

If you work with the k8s client-go sdk,
you might have seen their new [applyconfigurations](https://pkg.go.dev/k8s.io/client-go/applyconfigurations)
to be used with Server Side Apply.

If you're working with [kubebuilder](https://github.com/kubernetes-sigs/kubebuilder)
for your own types/controller,
you might wonder how to generate the new applyconfigurations.

Update the `Makefile` to include the `applyconfiguration` generator for `controller-gen`:

Old:

```make
.PHONY: generate
generate: controller-gen
  "$(CONTROLLER_GEN)" object paths="./..."
```

New:

```make
.PHONY: generate
generate: controller-gen
  "$(CONTROLLER_GEN)" applyconfiguration object paths="./..."
```

In your `api/` subdirectory,
mark that you want to generate applyconfigurations,
and the output dir (if left unset, it's nested deep in `api/`)

Old:

```go
// groupversion_info.go

// +kubebuilder:object:generate=true
// +groupName=example.com
package v1
```

New:

```go
// groupversion_info.go

// +kubebuilder:ac:generate=true
// +kubebuilder:ac:package=../../applyconfiguration
// +kubebuilder:object:generate=true
// +groupName=example.com
package v1
```

Finally, for each CRD type,
you'll also need to mark that you want applyconfigurations for it:

```go
// mycrd_types.go

package v1

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status

type MyCRD struct{}
```

```go
// mycrd_types.go

package v1

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:ac:generate:true

type MyCRD struct{}
```
