# Deploy

This directory tree contains `cue`, `kpt`, and `skaffold` based tooling to deploy k8s manifests.

## Updating an application

The `.cue` files are the source of truth.

1. Modify the cue manifests to the desired state.
2. `cue cmd k8smanifests` to render the manifests into `kubernetes.yaml`
3. `kpt live apply --server-side --output table` to apply to the cluster

## Adding a new application

1. Run `cue cmd --inject name=application-name skaffold`
2. (Optional) remove `skaffold.yaml` if it's not a custom application
3. `kpt live init` to register the resource group in the cluster
4. `kpt live apply --server-side --output table` to apply to the cluster
