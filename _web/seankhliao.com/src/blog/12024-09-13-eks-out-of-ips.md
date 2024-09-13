# EKS out of IPs

## but we have so many free addresses

### _EKS_ running out of IPs

One of our on callers was recently paged for networking issues in one of our clusters.
It appears the cluster had multiple cascading failures,
but I'm here to talk about a specific one:
pods were failing to start because the CNI couldn't assign an IP address to it.

```
Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "29cc27a011aab71e2ed75ce44f42ad86415b3c3faffe84c4dbd543e91fb52210": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
```

Some background info:
these are EKS clusters using [amazon-vpc-cni-k8s](https://github.com/aws/amazon-vpc-cni-k8s)
in pretty much the default configuration.
Each zone has a `/20` IPv4 subnet.

The next day, when we started digging in,
we saw the subnets each had around 1300 free addresses.
No way we had 4000 extra pods when the incident happened.

Digging around, there wasn't a lot of information on why it failed to allocate an IP address.
I couldn't even find a metric for how much of the VPC address space was in use.
That was until after reading through a few github issues for the CNI that I saw mentions of the `ipamd.log`.
This can be found at `/var/log/aws-routed-eni/ipamd.log` on the host,
I got in via AWS EC2 Instance Connect, a pod with a host volume would have worked equally well.

```json
{"level":"debug","ts":"2024-09-11T20:39:00.478Z","caller":"rpc/rpc.pb.go:863","msg":"AddNetworkRequest: K8S_POD_NAME:\"my-app-28768119-xvn9r\" K8S_POD_NAMESPACE:\"default\" K8S_POD_INFRA_CONTAINER_ID:\"98f16b278707cf18fbae5f190fe83d010e88648d2bd89ecd28fb1c9a2fe42adc\" ContainerID:\"98f16b278707cf18fbae5f190fe83d010e88648d2bd89ecd28fb1c9a2fe42adc\" IfName:\"eth0\" NetworkName:\"aws-cni\" Netns:\"/var/run/netns/cni-eaea82d6-9e67-9aaf-89b2-9a6256510820\""}
{"level":"debug","ts":"2024-09-11T20:39:00.478Z","caller":"datastore/data_store.go:607","msg":"AssignPodIPv4Address: IP address pool stats: total 29, assigned 9"}
{"level":"debug","ts":"2024-09-11T20:39:00.478Z","caller":"datastore/data_store.go:687","msg":"Get free IP from prefix failed no free IP available in the prefix - 10.4.128.241/ffffffff"}
{"level":"debug","ts":"2024-09-11T20:39:00.478Z","caller":"datastore/data_store.go:607","msg":"Unable to get IP address from CIDR: no free IP available in the prefix - 10.4.128.241/ffffffff"}
{"level":"debug","ts":"2024-09-11T20:39:00.478Z","caller":"datastore/data_store.go:687","msg":"Get free IP from prefix failed no free IP available in the prefix - 10.4.130.94/ffffffff"}
{"level":"debug","ts":"2024-09-11T20:39:00.478Z","caller":"datastore/data_store.go:607","msg":"Unable to get IP address from CIDR: no free IP available in the prefix - 10.4.130.94/ffffffff"}
{"level":"debug","ts":"2024-09-11T20:39:00.478Z","caller":"datastore/data_store.go:1286","msg":"Found a free IP not in DB - 10.4.128.118"}
{"level":"debug","ts":"2024-09-11T20:39:00.478Z","caller":"datastore/data_store.go:687","msg":"Returning Free IP 10.4.128.118"}
{"level":"debug","ts":"2024-09-11T20:39:00.478Z","caller":"datastore/data_store.go:607","msg":"New IP from CIDR pool- 10.4.128.118"}
{"level":"info","ts":"2024-09-11T20:39:00.478Z","caller":"datastore/data_store.go:714","msg":"assignPodIPAddressUnsafe: Assign IP 10.4.128.118 to sandbox aws-cni/98f16b278707cf18fbae5f190fe83d010e88648d2bd89ecd28fb1c9a2fe42adc/eth0"}
{"level":"debug","ts":"2024-09-11T20:39:00.479Z","caller":"rpc/rpc.pb.go:863","msg":"VPC CIDR 10.4.128.0/18"}
{"level":"info","ts":"2024-09-11T20:39:00.479Z","caller":"rpc/rpc.pb.go:863","msg":"Send AddNetworkReply: IPv4Addr: 10.4.128.118, IPv6Addr: , DeviceNumber: 0, err: <nil>"}
{"level":"debug","ts":"2024-09-11T20:39:04.052Z","caller":"ipamd/ipamd.go:673","msg":"IP pool is too low: available (19) < ENI target (1) * addrsPerENI (29)"}
{"level":"debug","ts":"2024-09-11T20:39:04.052Z","caller":"ipamd/ipamd.go:2171","msg":"IP pool stats: Total IPs/Prefixes = 29/0, AssignedIPs/CooldownIPs: 10/0, c.maxIPsPerENI = 29"}
{"level":"debug","ts":"2024-09-11T20:39:04.052Z","caller":"ipamd/ipamd.go:660","msg":"IP stats - total IPs: 29, assigned IPs: 10, cooldown IPs: 0"}
{"level":"debug","ts":"2024-09-11T20:39:04.052Z","caller":"ipamd/ipamd.go:678","msg":"Starting to increase pool size"}
{"level":"debug","ts":"2024-09-11T20:39:04.052Z","caller":"ipamd/ipamd.go:798","msg":"Node found \"ip-10-4-129-144.eu-central-1.compute.internal\" - no of taints - 0"}
{"level":"debug","ts":"2024-09-11T20:39:04.052Z","caller":"ipamd/ipamd.go:678","msg":"Recently we had InsufficientCidr error hence will wait for 2m0s before retrying"}
```

This log appears to contain IP assignment for the entire cluster / subnet,
and not just for the host it was running on,
which was great because the hosts we had issues on had all cycled out.

This log told me 2 things:
we really did run out of free IP addresses,
and addresses are batch allocated upfront to ENIs.
This led to a more careful reading of the amazon-vpc-cni-k8s README
and finding [`pkg/vpc/vpc_ip_resource_limit.go`](https://github.com/aws/amazon-vpc-cni-k8s/blob/27ce1362636567592f006b987f3820c6b0fef55e/pkg/vpc/vpc_ip_resource_limit.go)
mapping instance types to the number of ENIs and IPs it would allocate.

Turns out that each VM will start with 1 ENI with X number of IPs attached to it,
and by default, the `amazon-vpc-cni-k8s` daemonset will add at least 1 more ENI.
This reserves a significant chunk of IP address space up front for the pods that might run on the node,
and `amazon-vpc-cni-k8s` will add more ENIs if necessary.

This was a problem for us,
because a service with large resource requests had scaled up poorly,
creating `m6a.32xlarge` nodes, each reserving 98 IPs, but only running a single pod of that application.

So, turns out that EKS with the `amazon-vpc-cni-k8s` CNI has similar behaviour to GKE,
where IP address space is allocated to nodes up front in batches,
but nobody who planned the network knew about it...
Oops.

#### _GCP_ GKE

[GKE documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips#range_management) 
calls out that by default each node will grab a `/24`,
or less if you lowered the max pods on a node,
and you should plan your subnet according to the number of nodes you need to run.
For this reason, we had given much larger subnets to our GKE clusters,
and don't expect to run into the issue anytime soon.

