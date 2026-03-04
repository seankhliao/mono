# argocd helm dependencies in oci

## fickle helm auth...

### _argocd_ oci helm dependencies

I had quite the headache trying to get ArgoCD to render out a helm chart
which hade a private OCI dependency hosted in ECR.

#### dependency

First we start with the dependency.
We have a helm library chart.
Here is the `Chart.yaml` file,
nothing special.

```yaml
# Chart.yaml
apiVersion: v2
name: my-dep
version: 1.0.0
type: library
```

And it's pushed as an OCI artifact
using helm's native support
into AWS Amazon Elastic Container Registry (ECR).
Note that the push destination exclude the final part which has to match the chart name.
[docs for helm push in oci](https://helm.sh/docs/topics/registries/#the-push-subcommand).

```sh
$ helm package ./my-dep
$ helm push my-dep-1.0.0.tgz  oci://12345678910.dkr.ecr.us-east-1.amazonaws.com/helm/charts
```

We can look at the artifact versions using the full artifact path:

```sh
$ crane ls 12345678910.dkr.ecr.us-east-1.amazonaws.com/helm/charts/my-dep
0.1.0
1.0.0
...
```

#### application chart

Now to use that library chart,
we have an application chart.
It sits somewhere in an application repo.
Note that like the `helm push` command,
the repository definition here doesn't include the chart name.

```yaml
# deploy/my-charts/my-app/Chart.yaml
apiVersion: v2
name: my-app
version: 2.0.0
type: application
dependencies:
  - name: my-dep
    repository: oci://12345678910.dkr.ecr.us-east-1.amazonaws.com/helm/charts
    version: 1.0.0
```

We use that in an ArgoCD application.
The application chart is read from a checkout of the git repository,
while the library chart is pulled in via helm as an oci artifact.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app-1
spec:
  source:
    repoURL: https://github.com/example/my-app-repo.git
    targetRevision: HEAD
    path: deploy/my-charts/my-app
    helm:
      valueFiles:
        - values.yaml
```

Here's the authentication setup to make it work.
It relies on External Secrets Operator (ESO)
since ECR expires the authorization tokens frequently.
[docs for ESO ECRAuthorizationToken](https://external-secrets.io/latest/api/generator/ecr/).

Note that the base path in the url for the credential secret
must match the base bath used in the other contexts above.
[note by commenter in github issue](https://github.com/argoproj/argo-cd/issues/11717#issuecomment-1660797847)

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-ecr
  annotations:
    # you'll need to set up IRSA on the AWS role
    # with the right permissions for ECR access.
    eks.amazonaws.com/role-arn: "arn:aws:iam::12345678910:role/argocd-ecr"
---
apiVersion: generators.external-secrets.io/v1alpha1
kind: ECRAuthorizationToken
metadata:
  name: argocd-ecr
spec:
  region: us-east-1
  auth:
    jwt:
      serviceAccountRef:
        name: argocd-ecr
---
apiVersion: v1
kind: ExternalSecret
metadata:
  name: argocd-ecr
spec:
  dataFrom:
    - sourceRef:
        generatorRef:
          apiVersion: generators.external-secrets.io/v1alpha1
          kind: ECRAuthorizationToken
          name: argocd-ecr
  refreshInterval: "1h"
  target:
    name:
    template:
      metadata:
        labels:
          argocd.argoproj.io/secret-type: repo-creds
      data:
        # has to helm + oci here
        type: helm
        enableOCI: "true"
        # username will be "AWS"
        username: "{{ .username }}"
        # will be a very long base64 encoded json blob
        password: "{{ .password }}"
        # the raw .proxy_endpoint value is an https://12345678910.dkr....
        # url, but argocd expects it to have no scheme.
        # note that this will also need to have the path components matching
        # the earlier definitions.
        url: '{{ trimPrefix "https://" .proxy_endpoint }}/helm/charts'
```
