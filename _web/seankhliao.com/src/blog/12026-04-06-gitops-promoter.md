# gitops-promoter

## declarative deployments

### _gitops-promoter_

In [layered appsets](/blog/12026-04-05-layered-appsets/),
I built out tiers of Applications / ApplicationSets.
Besides the fact that I wanted an easy way to onboard new repos,
I also wanted to have a good place to place and orchestrate the resources
needed for [Gitops Promoter](https://gitops-promoter.readthedocs.io/en/latest/)
our chosen tool to do declarative continuous deployments.
Like our applicationset, it too needs to know the list of environments
in order to drive promotions.

![promoter resources](/static/promoter-resources.excalidraw.png)

#### _promoter_ resources

Specifically, the promoter needs a repo level
[GitRepository](https://gitops-promoter.readthedocs.io/en/latest/crd-specs/#gitrepository),
and a per application cross environment [PromotionStrategy](https://gitops-promoter.readthedocs.io/en/latest/crd-specs/#promotionstrategy)
and optional config for the various [CommitStatus controllers](https://gitops-promoter.readthedocs.io/en/latest/gating-promotions/).

We render these via a shared helm chart,
the input looks something like the below.

```yaml
applications:
  - name: app1
    helm:
      dir: path/in/repo
    promotion:
      gate-type:
        extra: config
    environments:
      - name: dev
        clusterExpressions:
          - key: environment
            operator: In
            values:
              - dev
          - key: account
            operator: In
            values:
              - foo
      - name: stg
        clusterExpressions:
          - key: environment
            operator: In
            values:
              - stg
          - key: account
            operator: In
            values:
              - foo
```

![promoter single environment](/static/promoter-1env.excalidraw.png)

#### _per_ environment

The arrows look complicated but most of it is on the argocd side.
[Source Hydrator](https://argo-cd.readthedocs.io/en/latest/user-guide/source-hydrator/)
is used to commit rendered kubernetes manifests back to a staging branch.
The main branch only ever contains DRY source files,
while each environment is represented by a pair of branches:
the live branch and the staging (`-next`) branch.

The promoter creates PRs when new commits land on the staging branch,
waits for required checks to pass (both on github and in k8s),
and merges the PR into the live branch.

As the PRs are merged into the live branch,
argocd syncs those into Kubernetes.

The result is a declarative control loop,
with the desired live state represented as the various git branches
(which should be protected).
Failures in the deployment process can be recovered from gracefully
as it will just re-evaluate / retry the reconciliation.

![promoter multi environment](/static/promoter-xenv.excalidraw.png)

#### _cross_ environment

The promoter comes with 2 kinds of checks.
**proposed commit statuses** report on the proposed changes to an environment,
whiel **active commit statuses** report on the current state of the environment.

While the reconciliation loops run continuously,
their results feed in at 2 points:
proposed statuses directly gate a deployment,
while active statuses are rolled up and gate the deployment of the next environment.

#### _custom_ gates

To make things smoother,
we implemented a few custom gates.

##### _image_ exists

As the deployment process kicks off once a change lands in main,
it introduces a race between CI (run code tests, build image) and CD (deploy the image).
Most of the time,
this will naturally be resolved by Kubernetes ImagePullBackoff
but we'd like to avoid that where possible.

So we have a custom controller that scans the rendered manifests for any image references
and checks if they are resolvable.

##### _image_ updated

For most applications, we build the application code (if any) on every commit,
tag it with the sha it was built on, and in our Application helm source, set:
`--set image.tag=$ARGOCD_APP_REVISION`.
This allows the rendered manifest to contain the commit it was rendered from.

Some of our code can be quite slow to build and test **cough, rust, cough**,
with 1hr+ CI times.
For these, we choose to batch up changes to the container image,
and tag / deploy them with [release-please](https://github.com/googleapis/release-please).
We make use of its [extra-files](https://github.com/googleapis/release-please/blob/main/docs/customizing.md#updating-arbitrary-files)
setting to update the dry manifests with the tag.

If files that are inputs to the image build process are touched,
our image updated gate blocks further deployments until the image tag changes.
This ensures that incompatible config changes don't roll out before
the code that understands it is deployed.

##### _kubeconform_

We run our manifests through the [kubeconform](https://github.com/yannh/kubeconform)
validator as a sanity check.

##### _load_ tests

We have a custom gate that runs post deploy,
waiting for the application sync to be healthy to trigger a load test.

While [Argo Rollouts](https://argo-rollouts.readthedocs.io/en/stable/) might have been preferable,
the specific case it was built for deployed multiple apps per environment,
waiting for it all to sync before starting the test.
