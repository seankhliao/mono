# upgrades, manifests, operators

## too much config for its own good

### _upgrades_ and manifests

Recently, I've been faced with having to upgrade a bunch of things running in kubernetes.
The day 2 operations that are glossed over in those getting started guides,
bet end up becoming the day job of many people.

First off is the easy stuff,
these barely interact with kubernetes in any meaningful way,
maybe a few RBAC rules but otherwise it's self contained and version bumps are straightforward.

Then comes the applications which have an extensive config file,
hopefully they'll have chosen some sane defaults for any new config they added,
and you can mostly ignore changes.

Now comes the hard stuff:
components that integrate deeply into Kubernetes.
They aren't just a Deployment whose image you can bump to a new reference,
they're things like istio and cilium, where the upgrade steps aren't straightforward,
and the software itself is almost inseparable from the manifests required to run them.

About those manifests, 
many projects have (unfortunately) ended up with Helm charts as their single source of truth.
This is okay if you've also landed on helm as part of your deployment tooling,
since you could pull in the upstream chart as a dependency,
but in all likeliness, you'll want some kind of customization not exposed by the chart authors,
and you're stuck vendoring / forking the chart...
For everyone else not on helm,
sure you could render out the manifests, 
diff that against the previsou version and work out what new config values you might need,
but it certainly feels like doing the work twice,
not to mention needing to keep around the helm config anyway.

While I usually dislike operators that are little more than:
apply some embedded manifests,
i think this can usually be done better from a dedicated gitops stylre reconciler,
complex upgrade steps is when I really want an operator.
