# single node envoy gateway

## https traffic plz

### _envoy-gateway_ on a single node

I run a single node k8s cluster for experiments,
and I need some way to route HTTP(S) traffic to different pods.
These days, it's something that implements Gateway API,
and [Envoy Gateway](https://gateway.envoyproxy.io/) doesn't look too bad,
i.e. locks features behind paywall like most open core software
or is too complex to run like Istio.

If you follow through their instructions,
you'll end up with a `Gateway` like this:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: http-gateway
  namespace: envoy-gateway-system
spec:
  gatewayClassName: http-gateway
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: http-gateway
      allowedRoutes:
        namespaces:
          from: All
```

But how do you get traffic into the `Gateway`?
By default it creates a `Service` of type `LoadBalancer` and I don't have that.
So I also have the `GatewayClass` point to a custom `EnvoyProxy` config
that marks the ports as `hostPort`.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: http-gateway
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
  parametersRef:
    group: gateway.envoyproxy.io
    kind: EnvoyProxy
    namespace: envoy-gateway-system
    name: http-gateway
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyProxy
metadata:
  name: http-gateway
  namespace: envoy-gateway-system
spec:
  provider:
    type: Kubernetes
    kubernetes:
      envoyService:
        type: ClusterIP
      envoyDeployment:
        strategy:
          type: Recreate
        patch:
          type: StrategicMerge
          value:
            spec:
              template:
                spec:
                  containers:
                    - name: envoy
                      ports:
                        - containerPort: 10080
                          hostPort: 80
                        - containerPort: 10443
                          protocol: TCP
                          hostPort: 443
```

There is a limitation of this though:
when I tried to enable HTTP3 (QUIC),
I realized that the ports are keyed only on `containerPort` 
which isn't unique when you have both `TCP` and `UDP` as protocols.
The output after patchhing is only one of the ports will remain.
