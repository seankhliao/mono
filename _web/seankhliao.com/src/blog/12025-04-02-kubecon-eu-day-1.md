# kubecon eu day 1

## kubecon begins

### _kubecon_ eu 2025 day 1

#### _keynotes_

##### [o11y in the age of llms](https://kccnceu2025.sched.com/event/1txBR/keynote-into-the-black-box-observability-in-the-age-of-llms-christine-yen-ceo-and-cofounder-honeycomb)

LLMs are fuzzy, we need better, 
more high cardinality observability that can track inputs / outputs properly.

##### [more scheduling](https://kccnceu2025.sched.com/event/1txBU/sponsored-keynote-the-cloud-and-your-is-not-infinite-dynamic-scheduling-at-every-layer-corentin-debains-software-engineer-google-laura-lorenz-software-engineer-google)

Better schedulers can look for capacity across clouds and place workloads appropriately.

##### [ai observability explaineres](https://kccnceu2025.sched.com/event/1txBX/keynote-ai-enabled-observability-explainers-we-actually-did-something-with-ai-vijay-samuel-principal-mts-architect-ebay)

Build useful ai agents by breaking down task to simpler building blocks
that do one thing, and compose them.

##### [evolving k8s ux](https://kccnceu2025.sched.com/event/1txBv/sponsored-keynote-evolving-the-kubernetes-user-experience-andrew-randall-principal-product-manager-microsoft)

We need a ui for more adoption.
[headlamp](https://github.com/kubernetes-sigs/headlamp)
is the current project for dashboard / management ui.

##### [rust in the linux kernel](https://kccnceu2025.sched.com/event/1xBJR/keynote-rust-in-the-linux-kernel-a-new-era-for-cloud-native-performance-and-security-greg-kroah-hartman-linux-kernel-maintainer-fellow-the-linux-foundation)

Greg Kroah-Hartman is generally positive about the movement,
framing it as freeing up maintainer time to not have to catch bugs manually.

#### _breakouts_

##### [kueue vs volcano vs yunikorn](https://kccnceu2025.sched.com/event/1txHR/a-comparative-analysis-of-kueue-volcano-and-yunikorn-wei-huang-apple-shiming-zhang-daocloud)

[Yunikorn](https://yunikorn.apache.org/) is a batch based k8s scheduler.
[Kueue](https://github.com/kubernetes-sigs/kueue) is a job admission gate
[volcano](https://volcano.sh/en/) is both.

kueue is the most kubernetes native, and composable with k8s extensions / crds.
(but does need to work around some failures by not having full control).

##### [mistakes writing controllers](https://kccnceu2025.sched.com/event/1tx7B/dont-write-controllers-like-charlie-dont-does-avoiding-common-kubernetes-controller-mistakes-nick-young-isovalent-at-cisco)

The base apis create too much load (uncached) or go out of sync (informers).
Use frameworks like [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime), 
[StateDB](https://github.com/cilium/statedb), 
or [krt](https://github.com/istio/istio/blob/master/pkg/kube/krt/README.md).

controller-runtime: check predicates properly, especially for associated resources.

##### [gRPC project updates](https://kccnceu2025.sched.com/event/1tcy8/whats-new-in-grpc-kevin-nilson-google)

Proxyless Service mesh. Native Otel telemetry, sessions affinity, dual stack, and xDS global rate limting.

##### [gateway api panel](https://kccnceu2025.sched.com/event/1txAr/taming-the-traffic-selecting-the-perfect-gateway-implementation-for-you-spencer-hance-google-arko-dasgupta-tetrate-christine-kim-isovalent-at-cisco-kate-osborn-nginxf5-mike-morris-microsoft)

Less vendor lock in on the standard parts,
differentiate on extensions.
CRD management is a pain.
End users should drive features they desire.

##### [csi block changed tracking](https://kccnceu2025.sched.com/event/1txF7/kubernetes-backup-legitimized-csi-changed-block-tracking-has-arrived-mark-lavi-carl-braganza-prasad-ghangal-veeam-xing-yang-vmware-by-broadcom)

Get an auth token from the api-server,
and make a direct gRPC call to the csi driver for expanded apis.
It generates extra SnapshotMetadata that can more easily be diffed to show blocks changed between snapshots.

##### [daemonset autoscaling](https://kccnceu2025.sched.com/event/1tx8F/the-next-generation-of-daemonset-autoscaling-adam-bernot-google-cloud-bryan-boreham-grafana-labs)

node scope vertical pod autoscaler tracking,
allowing daemonsets pods to scale according to load on the node.

##### [service mesh bugs](https://kccnceu2025.sched.com/event/1txHj/museum-of-weird-bugs-our-favorites-from-8-years-of-service-mesh-debugging-alex-leong-buoyant)

Mismatched code bindings vs in cluster CRD leads to continuous reconciles.

#### hallway track


