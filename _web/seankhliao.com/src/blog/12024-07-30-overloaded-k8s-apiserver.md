# overloaded api server

## locked out of your own cluster

### _overloaded_ api server

We had a fun incident today where we saw performance of one of our kubernetes clusters
gradually degrade until it started timing out all requests.
We couldn't log in to the cluster to find out what was going on.
It being a GCP GKE cluster, 
we could see some but not all metrics.
The workload tab was broken most of the time,
indicating the api server really was overloaded.

We had our usual suspects,
and quickly checking through them,
we found a namespace with 60k Jobs...
well that wasn't going to end well.
Weighing our options,
it seemed like applying a ResourceQuota was our best bet:
it would limit the number of pods / jobs the cluster would create,
bringing down overall load,
and allowing us to clean up.

So we ran `kubernetes apply -f quota.yaml` in a loop
until it succeeded.
