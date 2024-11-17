# personal use gerrit, part 1

## a code review server as a git host.

### _gerrit_ as a personal git host

I don't really like how everything and everyone is on Github,
so I want to do something about it.
It srarts small with hosting your own git stuff elsewhere.

For a while, I had been using [charmbracelet/soft-serve](https://github.com/charmbracelet/soft-serve)
as my git host.
But it's just a git host,
you can host a repo, and do some ci with webhooks,
but there' no review integration, and it's very much ssh first.

I thought I'd try out [gerrit](https://www.gerritcodereview.com/) again,
this one is review-first rather than host first.
Now, I don't really review my own code,
after all I just wrote it...,
but I could maybe make it work.

#### _gerrit_ in kubernetes

Right, to spin up a gerrit server.
My server runs kubernetes, so gerrit will run inside kubernetes too.

Gerrit have published prebuilt containers at
[`index.docker.io/gerritcodereview/gerrit`](https://hub.docker.com/r/gerritcodereview/gerrit),
which is great, I don't want to figure out how to build java services.

Annoyingly, almost all gerrit data and config is mixed together in `/var/gerrit`,
which is also its `$HOME` directory.
You'll have to mount the individual `cache`, `data`, `db`, `etc`, `git`, `index`, `logs`, `plugins`
directories as volumes.
I'm not quite sure if it's gerrit or its init process,
but it does write to the config files as well,
you'll need some way of managing that.
This is also the reason I don't use the embedded entrypoint script,
TBD if I should skip the gerrit run script too.

The first user to log in become admin,
you can later promote other users if you want.

#### _auth_ = HTTP

As a single user instance,
and not having an openid instance idp around,
I opted for using HTTP Basic Auth.
Gerrit has 2 parts that need authentication, and they don't really speak to each other.
The web ui does basic auth by offloading it to whatever reverse proxy you have,
while the git http daemon requires credentials generated from the web ui...
In effect, this means you should:

- create a temporary password, add that to your reverse proxy's basic auth filter
- log in once, to get your account created
- generate http credentials from the gerrit web ui account settings
- update your password in the reverse proxy config to be the same as the newly generated one
- use the same password for web ui and git submission

Side note,
running in K8s, I'm using the new Gateway API,
specifically [Envoy Gateway](https://gateway.envoyproxy.io/).
I kept getting 500 internal server errors until I read the instructions more carefully,
and realized it only supports `SHA` as the password hash method for `.htpasswd`.

#### _http_ passing encoded slashes

Everything seemed to work,
until I clicked on a diff and it came back with a cryptic:

> ```
> An error occurred
> You might have not enough privileges.
>
> Error 404: Not found: envoy-gateway
>
> Endpoint: /changes/*~*/revisions/*/files/*/reviewed
> ```

Poking around a bit, for a diff affecting a path in a directory like `deploy/envoy-gateway/kubernetes.yaml`,
the gerrit web ui sent a request for `https://gerrit.liao.dev/c/mono/+/21/2/deploy%2Fenvoy-gateway%2Fkubernetes.yaml`,
note the slashes encoded as `%2F`.
My reverse proxy was canonicalizing requests to
`https://gerrit.liao.dev/c/mono/+/21/2/deploy/envoy-gateway/kubernetes.yaml`,
which then gerrit failed to match.
Gerrit has this documented as `AllowEncodedSlashes On` and `nocanon` for apache httpd.
For envoy gateway, this meant modifying my `ClientTrafficPolicy`
with `path.escapedSlashesAction: KeepUnchanged`

```yaml
kind: ClientTrafficPolicy
spec:
  http3: {}
  path:
    escapedSlashesAction: KeepUnchanged
    disableMergeSlashes: true
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: http-gateway
metadata:
  name: http-gateway
  namespace: envoy-gateway-system
  labels:
    app.kubernetes.io/part-of: envoy-gateway
    app.kubernetes.io/managed-by: kpt
    app.kubernetes.io/name: envoy-gateway
  annotations:
    config.kubernetes.io/origin: "\tmono/deploy/envoy-gateway/*.cue"
apiVersion: gateway.envoyproxy.io/v1alpha1
```

#### _gerrit_ config file

gerrit config options are [documented online](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html)
but lets go over some of the settings.
The config file format is the same as git config, `#` are comments.

```gitconfig
# This is a plugin for auto submit when all requriements are met
[automerge]
    botEmail = gerrit@liao.dev

# basic auth handled by gateway
[auth]
    type = HTTP
    gitBasicAuthPolicy = HTTP
    # gerrit wants emails for users,
    # this maps the username to a fixed domain part
    emailFormat = {0}@liao.dev

[cache]
    directory = cache

[gerrit]
    # directory within /var/gerrit to store bare git repos
    basePath = git
    defaultBranch = refs/heads/main
    canonicalWebUrl = https://gerrit.liao.dev/
    serverId = e536212b-9667-4845-8848-736bb2f4a5f0

[httpd]
    listenUrl = proxy-http://*:8080

[index]
    type = lucene

# allow managing plugins from web interface,
# seems it may sometime still be necessary to install them by hand though...
[plugins]
    allowRemoteAdmin = true

[receive]
    enableSignedPush = false

# gerrit really wants to send email,
# but I don't have a SMTP server to give it yet
[sendemail]
    enable = false

[sshd]
    listenAddress = *:29418
```

#### _gitiles_ config 

Gerrit runs a built in gitiles server for the web git view,
I couldn't quite figure out how to make it run on its own hostname.

#### _gerrit_ deployment manifests

A snapshot of what I currently use to deploy gerrit

```yaml
kind: Namespace
metadata:
  name: gerrit
  labels:
    app.kubernetes.io/part-of: gerrit
    app.kubernetes.io/managed-by: kpt
    app.kubernetes.io/name: gerrit
  annotations:
    config.kubernetes.io/origin: "\tmono/deploy/gerrit/*.cue"
apiVersion: v1
---
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 80
      protocol: TCP
      appProtocol: http
      targetPort: http
  selector:
    app.kubernetes.io/name: gerrit
kind: Service
apiVersion: v1
metadata:
  name: gerrit
  namespace: gerrit
  annotations:
    config.kubernetes.io/origin: "\tmono/deploy/gerrit/*.cue"
  labels:
    app.kubernetes.io/part-of: gerrit
    app.kubernetes.io/managed-by: kpt
    app.kubernetes.io/name: gerrit
---
kind: Deployment
metadata:
  name: gerrit
  namespace: gerrit
  labels:
    app.kubernetes.io/part-of: gerrit
    app.kubernetes.io/managed-by: kpt
    app.kubernetes.io/name: gerrit
  annotations:
    config.kubernetes.io/origin: "\tmono/deploy/gerrit/*.cue"
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: gerrit
  template:
    metadata:
      labels:
        app.kubernetes.io/name: gerrit
    spec:
      initContainers:
        - image: index.docker.io/gerritcodereview/gerrit:3.11.0-rc3-ubuntu24
          name: gerrit-init
          command:
            - sh
            - -c
            - |-
              if [ ! -d /var/gerrit/git/All-Projects.git ]
              then
                echo "Initializing Gerrit site ..."
                java $JAVA_OPTS -jar /var/gerrit/bin/gerrit.war init --batch --install-all-plugins -d /var/gerrit
                java $JAVA_OPTS -jar /var/gerrit/bin/gerrit.war reindex -d /var/gerrit
                git config -f /var/gerrit/etc/gerrit.config --add container.javaOptions "-Djava.security.egd=file:/dev/./urandom"
                git config -f /var/gerrit/etc/gerrit.config --add container.javaOptions "--add-opens java.base/java.net=ALL-UNNAMED"
                git config -f /var/gerrit/etc/gerrit.config --add container.javaOptions "--add-opens java.base/java.lang.invoke=ALL-UNNAMED"
              fi
          env:
            - name: JAVA_OPTS
              value: --add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/java.lang.invoke=ALL-UNNAMED
          volumeMounts:
            - mountPath: /var/gerrit/cache
              subPath: cache
              name: data
            - mountPath: /var/gerrit/data
              subPath: data
              name: data
            - mountPath: /var/gerrit/db
              subPath: db
              name: data
            - mountPath: /var/gerrit/etc
              subPath: etc
              name: data
            - mountPath: /var/gerrit/git
              subPath: git
              name: data
            - mountPath: /var/gerrit/index
              subPath: index
              name: data
            - mountPath: /var/gerrit/logs
              subPath: logs
              name: data
      containers:
        - image: index.docker.io/gerritcodereview/gerrit:3.11.0-rc3-ubuntu24
          name: gerrit
          command:
            - /var/gerrit/bin/gerrit.sh
            - run
          env:
            - name: JAVA_OPTS
              value: --add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/java.lang.invoke=ALL-UNNAMED
          ports:
            - containerPort: 29418
              name: git-ssh
            - containerPort: 8080
              name: http
          volumeMounts:
            - mountPath: /var/gerrit/cache
              subPath: cache
              name: data
            - mountPath: /var/gerrit/data
              subPath: data
              name: data
            - mountPath: /var/gerrit/db
              subPath: db
              name: data
            - mountPath: /var/gerrit/etc
              subPath: etc
              name: data
            - mountPath: /var/gerrit/git
              subPath: git
              name: data
            - mountPath: /var/gerrit/index
              subPath: index
              name: data
            - mountPath: /var/gerrit/logs
              subPath: logs
              name: data
            - mountPath: /var/gerrit/plugins
              subPath: plugins
              name: data
      volumes:
        - hostPath:
            path: /opt/volumes/gerrit
          name: data
      enableServiceLinks: false
  strategy:
    type: Recreate
  revisionHistoryLimit: 1
apiVersion: apps/v1
---
kind: SecurityPolicy
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: gerrit
  basicAuth:
    users:
      name: basic-auth
metadata:
  name: gerrit
  namespace: gerrit
  labels:
    app.kubernetes.io/part-of: gerrit
    app.kubernetes.io/managed-by: kpt
    app.kubernetes.io/name: gerrit
  annotations:
    config.kubernetes.io/origin: "\tmono/deploy/gerrit/*.cue"
apiVersion: gateway.envoyproxy.io/v1alpha1
---
kind: HTTPRoute
spec:
  hostnames:
    - gerrit.liao.dev
  parentRefs:
    - name: http-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: gerrit
          port: 80
metadata:
  name: gerrit
  namespace: gerrit
  labels:
    app.kubernetes.io/part-of: gerrit
    app.kubernetes.io/managed-by: kpt
    app.kubernetes.io/name: gerrit
  annotations:
    config.kubernetes.io/origin: "\tmono/deploy/gerrit/*.cue"
apiVersion: gateway.networking.k8s.io/v1
```
