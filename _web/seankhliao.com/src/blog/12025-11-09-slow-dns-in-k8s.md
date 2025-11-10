# slow dns in k8s

## but why

### _dns_ is slow in kubernetes

Recently I was pulled in to investigate an incident
where one of our node.js application was slow.
It was making a lot of http requests (in hindsight too many),
but one of the things that stood out were traces that showed
dns resolution taking 10s (the timeout we set for requests).

If you do some research,
you might find there are multiple problems here:

- nodejs & threads
- K8s default ndots
- K8s dns servers

#### _nodejs_ and threads

So apparently, while `dns.lookup` is async in js code,
under the hood,
it's a blocking sync call the the underlying threadpool executor.
And by default, the thread pool size is 4.
So you're limited to 4 concurrent dns resolutions at a time
and blocking everything else in the process.

This can be adjusted with the environment variable `UV_THREADPOOL_SIZE`.

Expected improvement: linear throughput increase up to the number of available cores,
depending on other load on the system.

#### _nxdomain_ requests and ndots

If you look in the `/etc/resolv.conf`,
you'll see a line of search domains
and an ndots options.
You might have even more in the search, e.g. `ec2.internal`.

```resolv
search mynamespace.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

ndots controls the order DNS requests are issued in when there are search domains.
For example, with ndots:5,
any domain with less than 5 dots will be subject to search first,
before being tried as an absolute domain.

E.g. with `ndots:5` a query for `www.example.com` will result in queries in the following order:

- `www.example.com.mynamespace.svc.cluster.local`: NXDOMAIN
- `www.example.com.svc.cluster.local`: NXDOMAIN
- `www.example.com.cluster.local`: NXDOMAIN
- `www.example.com`: found

With `ndots:2` it would instead be:

- `www.example.com`: found

Linux systems generally default ndots:1,
but Kubernetes wants to make short names for in cluster services work
so the default is pretty high.

Your options to fix this are:

- always use absolute domain `example.com.` (trailing dot),
  not subject to search,
  but the servers might not expect / accept it.
- set `dnsConfig` in every pod.
  there's no global setting,
  so you're stuck configuring it manually or using a MutatingAdmissionPolicy
  or webhook.

Setting ndots, you have to choose a reasonable value.
The existing dns names you could use are:

- `$service`
- `$service.$namespace`
- `$service.$namespace.svc`
- `$service.$namespace.svc.cluster.local`

Setting ndots:1 would result in `$service.$namespace` queries being tried as an absolute query first.
I think this is unsafe, as `$namespace` can clash with exist gTLDs,
So if you had a `dev` namespace, `foo.dev` would go to that absolute domain rather than `foo.dev.svc.cluster.local`.

ndots:2 seems to be the lowest reasonable value
if you have any existing workloads.
If you have the discipline to never use short names,
then you can go lower with ndots:1.

Expected improvement: 4-5x improvement in speed and DNS volume.

#### dns server location

By default,
dns in a k8s cluster is served by the `kube-dns` Service in the `kube-system` namespace.
Modern deployments will use CoreDNS
but some will use the old kube-dns server.

The more important part is that this is a dns server(s) per cluster,
not per node.
So your dns request from a pod may need to go to a different node to get resolved
or in the worst case, cross an AZ.
This is quite unlike systems where there's always a local resolver / cache like `systemd-resolved`.

The common solution for this is to run a per node dns cache:
[nodelocaldns](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns/nodelocaldns).
This is another CoreDNS DaemonSet that caches responses on each node.
Note, Cilium users will want to follow their instructions to use
[Local Redirect Policy](https://docs.cilium.io/en/stable/network/kubernetes/local-redirect-policy/)

Expected improvement: 2-4x speed depending on node/pod placement and networking.

#### references

- [DNS performance issues in Kubernetes cluster](https://adambrodziak.pl/dns-performance-issues-in-kubernetes-cluster)
- [https://adambrodziak.pl/dns-performance-issues-in-kubernetes-cluster](https://medium.com/@amirilovic/how-to-fix-node-dns-issues-5d4ec2e12e95)
- [resolv.conf ndots:5 is causing throttling issues with cloud provider DNS #14051](https://github.com/kubernetes/kubernetes/issues/14051)
- [resolv.conf(5) ndots](https://man.archlinux.org/man/resolv.conf.5.en#ndots:)
- [K8s default ndots MutatingAdmissionPolicy](https://github.com/kubernetes/kubernetes/issues/127137#issuecomment-2603247342)
