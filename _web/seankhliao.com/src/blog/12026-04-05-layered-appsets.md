# layered appsets

## reworking how applications are defined

### _layered_ appsets

At $job, I had the chance to rework how our team's applications were deployed to Kubernetes.
Our starting point was [Helm](https://helm.sh/)
wrapped in [Terraform](https://developer.hashicorp.com/terraform)
via the [Helm Terraform Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs).
Our end goal was [ArgoCD](https://argo-cd.readthedocs.io/en/stable/)
with an eye on making deployments more declarative.
Our other services used a [Github Actions](https://docs.github.com/en/actions) workflow
to run `argocd app set` and `argocd app sync` in order.
but that scales poorly when you try to deploy to multiple clusters
and [Github's uptime, especially actions](https://mrshu.github.io/github-statuses/)
is... poor.

Our existing services used the [Argocd Terraform Provider](https://registry.terraform.io/providers/argoproj-labs/argocd/latest/docs)
to define their [`Application`](https://argo-cd.readthedocs.io/en/latest/user-guide/application-specification/)s.
While some of our infrastrcture used [ApplicationSet](https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/)s
driven from files in a single repo.

Since our application definitions were sufficiently different from regular services,
plus the fact that we needed some extra manifests [for promotion](/blog/12026-04-06-gitops-promoter/)
I started from scratch.

My goal: just label a repo,
add in a manifest file,
and my app should automagically be deployed everywhere.

![appset hierarchy](/static/appset-hierarchy.excalidraw.png)

#### _application_ hierarchy

##### _bootstrap_ Application

We deploy argocd itself as a helm chart in terraform....
but the helm chart does come with a way to define some sbasic applications
so we define one to render a bootstrap application in our general infra repo.

The bootstrap application contains an appset with the [git directories generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Git/#git-generator-directories)
that iterates over the other directories
of the repo, which map to `$cluster/$application_instance` directory trees,
generating an Application each.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
spec:
  generators:
    - git:
        files:
          - "clusters/**/kustomization.yaml"
        repoURL: https://github.com/my/repo
        revision: main
        values:
          account: "{{path[1]}}"
          region: "{{path[2]}}"
          cluster: "{{path[3]}}"
          app: "{{path[4]}}"
```

##### _mgmt1-argocd-kustomize_ Application

Targeting the management cluster where argocd lives is an application for extra argocd configs.
This contains an appset with the
[matrix generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Matrix/)
configured with the
[scm generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-SCM-Provider/)
to find labeled repos with the manifest file, and the
[git files generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Git/#git-generator-files)
to read some data out of the file.

While in theory the labels aren't strictly necessary,
with over a thousand repos in the org,
performance degrades quickly, so labels exist as a first layer filter.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
spec:
  generators:
    - matrix:
        - generators:
            - scmProvider:
                github:
                  organization: my-org
                  appSecretName: ...
                filters:
                  - labelMatch: "^argo-apps$"
                    pathExists:
                      - argo-apps.yaml
            - git:
                repoURL: https://github.com/{{ .organization }}/{{ .repository }}
                revision: "{{ .branch }}"
                files:
                  - path: argo-apps.yaml
```

##### _repo1-apps_ Application

The manifest file declares the applications in the repo,
and the environments they target.
It's used as a remote values file for a shared helm chart
using argocd's [multi source support](https://argo-cd.readthedocs.io/en/latest/user-guide/multiple_sources/#helm-value-files-from-external-git-repository).

This application contains an appset per application (repos can have multiple),
using multiple instances of the
[cluster generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/)
to map to specific clusters for each environment.

This is possible as our clusters are generally dedicated to one environment each
and we labeled them appropriately.
Labels go on the [Secret containing cluster credentials for argocd](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#clusters).

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
spec:
  generators:
    # this is actually helm chart for loop over the defined environments
    - clusters:
        selector:
          matchExpressions:
            ...
      values:
        envName: stg
        ...
    - clusters:
        selector:
          matchExpressions:
            ...
      values:
        envName: prod
        ...
    ...
```

##### _repo1-app1-cluster1_ Application

At the very end of our hierarchy is the application for the actual service.
this reads a helm chart in the application repo,
selecting values file applicable to the instance.
