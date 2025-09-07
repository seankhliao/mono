# datadog notify by

## alert aggregation

### _datadog_ notify by

So you might have Datadog Monitors (alerts) that are per thing
(host, pod, other fine grained dimension).
If they're correlated (all pods of a deployment),
and you get paged for them,
you'll soon learn what it's like to get flooded with pages.
(I'm not sure how my coworkers tolerated this.)

```
max(last_15m):max:kubernetes_state.container.status_report.count.waiting{reason:imagepullbackoff} by {kube_cluster,kube_namespace,kube_container_name,pod_name} > 0.5
```

Datadog has an underused (in the places I've seen) feature of
[Alert Aggregation](https://docs.datadoghq.com/monitors/guide/alert_aggregation/).
In the API / terraform, this is `notify_by`.
So you only get a notification per higher level grouping.

```
"notify_by": ["kube_cluster", "kube_namespace", "kube_container_name"]
```
