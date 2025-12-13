# kubectl get all categories

## virtual groups

### _kubectl_ categories

Have you ever wondered what types get added to the output of
`kubectl get all`?

Example:

```sh
$ kubectl get all
NAME                          READY   STATUS    RESTARTS   AGE
pod/my-app-5dc75f4f9f-fj4bx   1/1     Running   0          10s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   2m20s
service/my-svc       ClusterIP   10.96.252.176   <none>        80/TCP    42s

NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-app   1/1     1            1           10s

NAME                                DESIRED   CURRENT   READY   AGE
replicaset.apps/my-app-5dc75f4f9f   1         1         1       10s
```

Turns out _all_ is a category.
You can see which categories a resource is in with the following,
looking at the CATEGORIES column:

```sh
$ kubectl api-resources -o wide
...
serviceaccounts                     sa           v1                                true         ServiceAccount                     create,delete,deletecollection,get,list,patch,update,watch
services                            svc          v1                                true         Service                            create,delete,deletecollection,get,list,patch,update,watch   all
mutatingwebhookconfigurations                    admissionregistration.k8s.io/v1   false        MutatingWebhookConfiguration       create,delete,deletecollection,get,list,patch,update,watch   api-extensions
...
```

CustomResourceDefinitions (CRDs) can declare which categories they belong to
using the `spec.names.categories` field.

Example CRD added to _all_:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: things.example.com
spec:
  group: example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                x:
                  type: string
  scope: Namespaced
  names:
    plural: things
    singular: thing
    kind: Thing
    categories:
      - all
---
apiVersion: example.com/v1
kind: Thing
metadata:
  name: my-thing
spec:
  x: hello world
```

And getting it
(you may need to clear the local kubectl cache):

```sh
$ kubectl get all
NAME                          READY   STATUS    RESTARTS   AGE
pod/my-app-5dc75f4f9f-fj4bx   1/1     Running   0          9m29s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   11m
service/my-svc       ClusterIP   10.96.252.176   <none>        80/TCP    10m

NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-app   1/1     1            1           9m29s

NAME                                DESIRED   CURRENT   READY   AGE
replicaset.apps/my-app-5dc75f4f9f   1         1         1       9m29s

NAME                         AGE
thing.example.com/my-thing   27s
```

[kubebuilder](https://book.kubebuilder.io/)
also supports categories in its
[CRD generatoon](https://book.kubebuilder.io/reference/markers/crd.html?highlight=annotations#crd-generation):

```go
// +kubebuilder:resource:categories="all"
```
