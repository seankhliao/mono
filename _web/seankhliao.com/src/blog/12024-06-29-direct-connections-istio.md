# direct connections in istio

## bypass the mesh routing

### _direct_ pod to pod requests in istio

This is about what happens when you make direct (HTTP) calls between pods using their IP address,
when istio is active in your kubernetes cluster.
Some cases when this is used:
prometheus which needs to contact every pod for scrapes,
or something like etcd, redis, or kafka connect where the pods need to be aware of each other
for gossip and consistent routing of requests/data.

#### _k8s_ networking

Each `Pod` in K8s gets its own IP address.
As pods are more or less ephemeral,
they come and go on a regular basis.
Without `NetworkPolicy`, there are no restrictions on incoming network connections,
the `ports` field of containers is merely informational.

Usually you expose them with a `Service` with a `ClusterIP`,
a DNS name and a stable, virtual IP address.
In "default" configuration with `kube-proxy`,
this IP address is resolved to a `Pod` address with round-robin per (source) node.
Once the layer 4 (TCP) connection is established, everything inside of it is opaque to K8s.

#### _istio_ networking

Istio is primarily used for its layer 7 (HTTP(s)) capabilities,
implemented through Envoy proxies.

For a HTTP request between pods,
it's intercepted and processed at 2 points: the source and destination.
At the source, it's routed per HTTP request based on least requests load balancing, and wrapped in TLS.
At the destination, it's unwrapped from TLS, matched against declared routes, and passed to the container.

###### _source_ processing

By shifting the load balancing from layer 4 (TCP) to layer 7 (HTTP),
applications can no longer open a single TCP connection and send multiple requests,
expecting them to end up at the same destination pod.
This is only really an "issue" if you send requests to a `ClusterIP` `Service`,
if you want to target a specific pod, 
it is addressable via its IP address or the extended hostname under a headless `Service`
(see next section for caveats).

##### _destination_ processing

In `STRICT` mode, all requests must come with mTLS,
either implemented by the application or more commonly by the envoy sidecar proxy.
Istio enforces the contract that `Pod`s can only be accessed through their declared `Service`s,
and only on the declared ports.

Istio takes all the declared `Service`, and `VirtualService` declared in a cluster,
expands them to their possible hostnames 
(`my-svc`, `my-svc.my-namespace`, `my-svc.my-namespace.svc`, `my-svc.my-namespace.svc.cluster.local`)
and constructs a routing tree passed to the envoy sidecar.
This means only requests with matching HTTP `Host` headers are allowed through.

If you sent a request like `http://10.1.2.3/hello` using a `Pod` IP address, 
it wouldn't match any declared rule and would just get dropped.
This is where _headless_ `Service`s come in, they provide 2 things:
a per pod hostname that will be accepted by istio,
and a default allow rule for backwards compatibility.

##### _headless_ service

In nornmal K8s, a headless `Service` does away with the virtual IP address,
exposing the Pod IP addresses directly, 
leaving it to the application to keep up to date with membership changes.
It also provides an extra set of DNS names like under the service name:
`my-pod.my-svc.my-namespace.svc.cluster.local`.

In istio, these per pod hostnames will be accepted by the envoy sidecars,
and will obviously all go to the same pod.
Additionally, because the common usecase of headless services has been to expose the pod directly,
istio adds a fallback route in its routing tree,
accepting requests destined for any host (match `*`) as long as it arrives on the appropriate port.

##### _appProtocol_

To normal K8s, the `Service.spec.ports[].appProtocol` field is merely informational.
To istio, it is used to inform the processing of requests.
Defaulting to `http`, requests are parsed, wrapped, and load balanced.
But you could also declare it as `tcp`, making it an opaque TCP stream,
still wrapped in TLS, but not load balanced at layer 7.


