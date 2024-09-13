# istio high interzone traffic

## push all the config changes everywhere

### _istio_ high interzone traffic

You've installed [istio](https://istio.io/)
into your [kubernetes](https://kubernetes.io/) cluster,
thinking you'd get some free network goodness like
standardized logs, traces, metrics and mTLS.
But a few weeks later, 
someone notices your AWS bill has gone up quite a bit,
turns out it wasn't totally free.

What do you do?
For us, this is an AWS EKS regional cluster,
so we start with logging in to the AWS console,
and heading over to Cost Explorer.
By Service, you see most of the increase attributed to _EC2-Other_.
By API operation, it's an even split between _InterZone-In_ and _InterZone-Out_.
This tells us it's traffic between the different availability zones,
traffic is charged twice, once to exit a zone and once to enter another zone.

We know it's interzone traffic,
now to attribute it to a service.
We have metrics integrations with datadog,
but not network performance monitoring.
A bit of poking around later,
`kubernetes.network.tx_bytes` and `kubernetes.network.rx_bytes`
summed by `kube_namespace` ,  `kube_ownerref_name` , and `availability-zone`
appears to be the most useful metrics for this.
We can see which services were transmitting and receiving traffic,
but not the exact flows across zone boundaries.
For our purposes, it's good enough, 
the absolute volume produced by _istiod_ stands out enough (5x background traffic).

We know it's _istiod_, but now what?
First, a theory on why _istiod_ produces so much traffic.
Istio injects sidecars into pods, 
and those sidecars start up with a minimal bootstrap config,
connecting back to istiod to receive the dynamic config 
that represents the current state of the cluster,
and any updates afterwards.
Unlike traditional k8s networking 
where service discovery is performed on demand via DNS resolution,
in istio's service mesh implementation,
the service discovery info is proactively pushed out to every sidecar.
This means every time a pod spins up or down, and the endpoints backing a Service change,
that information is pushed to all the sidecars so they have updated routing config.

Time to look into logs...
we had previously set istiod to log at warn or above,
and I didn't quite want to turn on info/debug for all the istiods...
Time to leverage a new feature `kubectl debug`.
The `--copy-to` flag allows us to copy a pod,
and modify some parameters,
in this case, the flag `--log_output_level=all:info`.
Note that the args passed to `kubectl debug [flags] -- args to container`
need to include the entrypoint command.
For me this was:

```sh
kubectl debug \
  istiod-5b6799667d-h8lr7 \
  -c discovery \
  --copy-to istiod-sean-debug \
  -- \
  /usr/local/bin/pilot-discovery \
    discovery \
    --monitoringAddr=:15014 \
    --log_output_level=all:info \
    --log_as_json \
    --domain=cluster.local \
    --keepaliveMaxServerConnectionAge=30m
```

I didn't use any fancy log analysis tools here,
just `kubectl logs -f istiod-sean-debug`
and watch for patterns.
For us, we saw something similar to the following line being repeated a lot.
This was most likely the trigger for all the config changes.

```json
{
  "level": "info",
  "time": "2024-09-12T10:21:47.168538Z",
  "scope": "ads",
  "msg": "Push debounce stable[154] 4 for config ServiceEntry/my-app/arangodb-cluster-int.my-app.svc.cluster.local and 1 more configs: 100.234648ms since last change, 100.248093ms since last push, full=true"
}
```

Next to verify.
We can get the Service object, but it won't change much.
What we want to watch is the changes to the endpoints that back the service.

```sh
kubectl get service -n my-app -o yaml arangodb-cluster-int
kubectl get endpoints -n my-app -w arangodb-cluster-int
```

Watching it reveals that it is constantly updated.
We can also look at pods which serve the actual endpoints,
selecting pods using the same label selectors as the Service.

```sh
kubectl get pod -n my-app -w -l arango_deployment=arangodb-cluster,arango_exporter=yes
```

Watching that shows pods getting created, 
failing to start,
and being removed once every few seconds.

Finally, we can verify that this service's endpoint membership changes
are the source of the istiod traffic.
Istio is smart enough to only push changes relevant to the sidecar,
and since we do namespace per application, 
if we limit a service to its own namespace, it's effectibely unavailable to the rest of the mesh.
For this we have the [`networking.istio.io/exportTo`](https://istio.io/latest/docs/reference/config/annotations/#NetworkingExportTo)
annotation we can put on the service.

```sh
kubectl annotate service arangodb-cluster-exporter networking.istio.io/exportTo=.
```

The change is reflected fairly quickly,
and the volume of traffic istiod pushes out drops like a rock.

#### _zonal_ routing

Before doing the full investigation,
I had thought to mitigate the issue.
Because our costs come from traffic crossing a zone boundary,
if we can keep traffic within a zone,
then we don't get charged.

Kubernetes has [Topology Aware Routing](https://kubernetes.io/docs/concepts/services-networking/topology-aware-routing/)
these days:
annotate a service with `service.kubernetes.io/topology-mode: Auto`
and if the backing pods are spread across the zones (use `topologySpreadConstraints`),
then it will prefer to route traffic to pods in the same zone.
This works for istiod because while the majority of the volume is from istiod to sidecars,
the connection is established from sidecars to istiod, so it goes through the istiod service.

This appeared to only reduce our interzone traffic costs by a third.
