# kubecon eu colocated events

## all the mini cons

### _kubecon_ eu colocated events

It's [CloudNativeCon Europe 2025](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/),
more specifically, the day for
[Co-located Events](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/cncf-hosted-co-located-schedule/).

#### CiliumCon

##### [Cilium with MCS-API](https://colocatedeventseu2025.sched.com/event/1u5fH/simplifying-multi-cluster-networking-with-cilium-and-mcs-api-a-technical-deep-dive-arthur-outhenin-chalandre-ledger-marco-iorio-isovalent-at-cisco)

So there's now a standardized [K8s Multicluster Services API](https://multicluster.sigs.k8s.io/concepts/multicluster-services-api/)
and [Cilium](https://github.com/cilium/cilium) supports it.
Goes a bit into syncing the underlying EndpointSlices,
so other controllers should also work properly.
Also syncs labels and annotations, so other controllers can look at those.
It does require a coredns recompile, because of out of tree plugins.

##### [HA Egress Gateway](https://colocatedeventseu2025.sched.com/event/1u5fQ/cl-lightning-talk-high-availability-for-cilium-egress-gateway-angelo-conforti-corner-banca-sa)

Something about using [kube-vip](https://kube-vip.io/)
to give nodes IPs for egress.

#### EnvoyCon

##### [Spotify Rate Limiter](https://colocatedeventseu2025.sched.com/event/1u5hY/adventures-in-rate-limiting-spotifys-journey-writing-a-scalable-envoy-rate-limiter-in-golang-oliver-soell-peter-marsh-spotify)

Spotify wrote a rate limiter, 
with the observation that it only needs to be accurate enough, 
not 100%. 
Much deliberation over choices later,
they chose Go, implemented it,
but found the exposed API lacking,
so they're doing a C++ rewrite.

##### [Envoy memory management](https://colocatedeventseu2025.sched.com/event/1u5hn/cl-lightning-talk-understanding-memory-allocation-management-in-envoy-current-and-future-kateryna-nezdolii-docker)

Use [tcmalloc](https://github.com/google/tcmalloc)
and/or [gperftools](https://github.com/gperftools/gperftools)
to debug envoy memory allocation / fragmentation issues.

##### [ORCA load balancing](https://colocatedeventseu2025.sched.com/event/1u5hk/cl-lightning-talk-introducing-orca-load-balancing-with-endpoint-provided-load-data-misha-efimov-google)

[Open Request Cost Aggregation](https://github.com/envoyproxy/envoy/issues/6614)
Bringing a gRPC implemented feature into Envoy,
where the backends can report cost to the proxy for local calculations
of load balancing.
Brings better utilization, especially in heteregenous environments.

##### [Dynamic Modules](https://colocatedeventseu2025.sched.com/event/1u5hh/cl-lightning-talk-dynamic-modules-a-new-era-of-high-performance-envoy-extensions-takeshi-yoneda-tetrate)

Envoy gets shared libraries.

#### ArgoCon

##### [SLOs for ArgoCD](https://colocatedeventseu2025.sched.com/event/1u5d6/defining-slos-and-slis-for-argocd-a-metrics-driven-approach-to-observability-serhiy-martynenko-the-new-york-times)

Raw metrics are too much.
Be careful and merge / thin down metrics to a few core ones your devs may care about.

##### [Scaling ArgoCD](https://colocatedeventseu2025.sched.com/event/1u5dg/scaling-argo-cd-from-symptoms-to-solution-alexandre-gaudreault-intuit)

High CPU: ArgoCD is doing too much work,
usually reconciliations,
and you can get it to do less with resource exclusions, 
not tracking orphans, not tracking status, filtering manifest-generate-paths,
and applying jitter.

High memory: shard argocd,
maybe manually.
There's an argocd agent in the works.

ArgoCD is slow...
look at the reconciliation and operations queues,
adjust the number of processors,
watch out for cpu throttling.
Check K8s api requests and adjust client settings.

##### [ArgoCD at Scale](https://colocatedeventseu2025.sched.com/event/1u5dy/argo-at-scale-navigating-complex-multi-dimensional-deployments-across-hundreds-of-clusters-carlos-santana-aws-mike-tougeron-adobe)

Group clusters together within Appsets.

You can pull Custom Resource fields into Prometheus metrics using kube-state-metrics.
Then with some advanced recording rules and combinations,
create alerts for thhings like an app being stuck syncing,
but only within its sync window.

##### [Promotion via Commit Status](https://colocatedeventseu2025.sched.com/event/1u5e7/no-more-pipelines-reconciling-environment-promotion-via-commit-statuses-with-argo-cd-michael-crenshaw-zach-aller-intuit)

A different approach to promotion of a change through environments.
Background: prefer hydrated sources, with an automated branch per env,
approvals managed through PRs.
Use github/gitlab status checks and a corresponding `CommitSratus` CRD to manage preflight check status.

#### Observability Day

##### [OTTL playground](https://colocatedeventseu2025.sched.com/event/1u5kt/cl-lightning-talk-empowering-opentelemetry-users-with-the-ottl-playground-simplified-data-transformation-and-testing-edmo-vamerlatti-costa-elastic)

[ottl.run](https://ottl.run) is available to debug your ottl filters online with sample data.
Runs wasm, so all the same code.

#### Other

I had a nice long chat with Damien Mathieu, Felix Geisendörfer, Florian Lehner
on profiling, eBPF, OpenTelemetry, and some random other topics.
