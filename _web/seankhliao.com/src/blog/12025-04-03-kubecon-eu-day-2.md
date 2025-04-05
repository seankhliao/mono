# kubecon eu day 2

## kubecon continues

### _kubecon_ eu 2025 day 2

#### keynotes

##### [PaaS for the Norwegian government](https://kccnceu2025.sched.com/event/1txBy/keynote-adventures-of-building-a-platform-as-a-service-for-the-government-hans-kristian-flaatten-lead-platform-engineer-nav-audun-fauchald-strand-principal-software-engineer-nav)

Grassroots? started in a queue for kubecon.
Government red tape...
Full platform distribution: [Nais](https://nais.io/).

#### talks

##### [designing a standard query language](https://kccnceu2025.sched.com/event/1tcyx/from-the-observability-tag-designing-a-common-query-language-for-observability-data-alolita-sharma-apple-pereira-braga-google-chris-larsen-netflix)

Query language syntax isn't that tied to backing store.
Most data is relational, and data anaylytics is coming round back to SQL from NoSQL.
There's a focus on semantics for now, standardizing on SQL.
Users really like piped SQL, [ZetaSQL](https://github.com/google/zetasql) from Google.

##### [scaling controllers horizontally](https://kccnceu2025.sched.com/event/1txFG/beyond-the-limits-scaling-kubernetes-controllers-horizontally-tim-ebert-stackit)

Consistent hash ring to distribute load between controller instances.

##### [network and identities](https://kccnceu2025.sched.com/event/1txER/encryption-identities-and-everything-in-between-building-secure-kubernetes-networks-lior-lieberman-google-igor-velichkovich-stealth-startup)

Security breaks from lack of segmentation.
NetworkPolucy / AdminNetworkPolicy / Cilium... / Istio...
extensions are better, and provide baselines.
Should be careful to have admission control to limit changes to labels used in policies.

IP addresses are still weak identities, they are reused between different pods.
Better is identities attached to service accounts.
[KEP-4317](https://github.com/kubernetes/enhancements/issues/4317)
for standardizing pod certificates.

##### [hot takes](https://kccnceu2025.sched.com/event/1txH0/hot-takes-kubernetes-paintainers-bring-the-heat-ian-coldwater-docker-marly-salazar-integral-ad-science-jeffrey-sica-cloud-native-computing-foundation-kat-cosgrove-xander-grzywinski-independent)

Maintainers eat spicy wings.

##### [perses](https://kccnceu2025.sched.com/event/1txHy/limitless-possibilities-consistent-design-crafting-dashboards-with-perses-dac-nicolas-takashi-coralogix-antoine-thebaud-amadeus)

Finally have maintainable dashboards as code, in Go or Cue.
Full toolchain for edit / review / apply workflow.

#### hallway

##### [datafy](https://www.datafy.io/)

Shrink AWS EBS volumes.

##### [terramate](https://terramate.io/docs/)

Better management of lots of tf workspaces

##### [crossplane](https://www.crossplane.io/)

Crossplane 2.0: more generic, less sharp edges.
Crossplane has a render cli.

Upbound has simulations coming.

##### [atlantis](https://www.runatlantis.io/)

Could work with maintainers to get a design on horizontal scaling.


##### [kedify](https://kedify.io/)

[Keda](https://keda.sh/) with enterprise support and more frequent CVE patch releases.


