# talos linux on hetzner dedicated

## bare metal without ssh

### talos linux on hetzner dedicated

For reasons (git),
I need to host some workloads with persistent disk storage.
Shopping around,
[Hetzner dedicated root servers (bare metal)](https://www.hetzner.com/dedicated-rootserver)
seemed like the best balance of reliability and price.
So I got myself an [EX44](https://www.hetzner.com/dedicated-rootserver/ex44/).

Now, what base OS do you put on it?
Previously I used [Arch Linux](https://archlinux.org/)
in [2020](/blog/12020-10-04-hetzner-arch-k8s/),
[2021-04](/blog/12021-04-24-hetzner-arch-k8s-cilium/),
and [2021-11](/blog/12021-11-16-manual-hetzner-arch-linux/),
[Fedora Linux](https://www.fedoraproject.org/) sometime in 2024,
and [Alpine Linux](https://www.alpinelinux.org/)
in [2024](12024-04-27-hetzner-arm64-alpine-kubeadm-k8s-cilium/).

Most of the later ones, I ended putting [Kubernetes](https://kubernetes.io/)
on them to handle downloading packages (containers),
and running workloads.

This time I'm trying out [Talos Linux](https://www.talos.dev/),
a purpose built distribution for Kubernetes.
You don't even get SSH access,
almost everything is done through K8s and remotely applying config manifests.

#### _preparing_ the machine

I'm only planning to run a single machine.
So it's a one node k8s cluster.

Hetzner booted up the server in its rescue system,
a minimal install for you to install your own OS.
Looking at the disks attached, they don't even have partitions / filesystems on them.

```sh
$ lsblk
NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0     7:0    0   3.8G  1 loop
nvme1n1 259:0    0 476.9G  0 disk
nvme0n1 259:1    0 476.9G  0 disk
```

To install Talos, we need a raw disk image.
Most of the docs online are for Hetzner's cloud (VM) offerings,
not what we have.

Instead start with
[Talos Linux Image Factory](https://factory.talos.dev/)
and select the applicable options.
I ended up with:

```
Schematic Ready
Your image schematic ID is:
be09ac2f119f94a17780dddc69afc17405ff658f2a7201bfa1fb9f72629ff555

customization:
    systemExtensions:
        officialExtensions:
            - siderolabs/ctr
            - siderolabs/gvisor
            - siderolabs/tailscale
    bootloader: dual-boot
```

Below were several links, the important ones are:

> Disk Image (raw)
> https://factory.talos.dev/image/be09ac2f119f94a17780dddc69afc17405ff658f2a7201bfa1fb9f72629ff555/v1.12.4/metal-amd64.raw.zst

and:

> Initial Installation
> For the initial installation of Talos Linux (not applicable for disk image boot), add the following installer image to the machine configuration:
> factory.talos.dev/metal-installer/be09ac2f119f94a17780dddc69afc17405ff658f2a7201bfa1fb9f72629ff555:v1.12.4

Back to the server,
download the resulting raw disk image:

```sh
$ wget -O /tmp/talos.zst https://factory.talos.dev/image/be09ac2f119f94a17780dddc69afc17405ff658f2a7201bfa1fb9f72629ff555/v1.12.4/metal-amd64.raw.zst
--2026-02-28 12:39:20--  https://factory.talos.dev/image/be09ac2f119f94a17780dddc69afc17405ff658f2a7201bfa1fb9f72629ff555/v1.12.4/metal-amd64.raw.zst
Resolving factory.talos.dev (factory.talos.dev)... 131.153.154.51
Connecting to factory.talos.dev (factory.talos.dev)|131.153.154.51|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://assets.factory.talos.dev/assets/3c5ca81b7de2aa5d8764519e7bd2bef2663f0726ee54451ca1c5c8f5fc214031?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=4cb9c5618e2681ac12b61dd0303523b2%2F20260228%2FENAM%2Fs3%2Faws4_request&X-Amz-Date=20260228T114000Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&response-content-disposition=attachment%3B%20filename%3D%22metal-amd64.raw.zst%22&X-Amz-Signature=f41fb901f9c21894bd6cabd99e588328c64845b86ab8f8d8f673ff9c00a144a5 [following]
--2026-02-28 12:40:00--  https://assets.factory.talos.dev/assets/3c5ca81b7de2aa5d8764519e7bd2bef2663f0726ee54451ca1c5c8f5fc214031?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=4cb9c5618e2681ac12b61dd0303523b2%2F20260228%2FENAM%2Fs3%2Faws4_request&X-Amz-Date=20260228T114000Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&response-content-disposition=attachment%3B%20filename%3D%22metal-amd64.raw.zst%22&X-Amz-Signature=f41fb901f9c21894bd6cabd99e588328c64845b86ab8f8d8f673ff9c00a144a5
Resolving assets.factory.talos.dev (assets.factory.talos.dev)... 2606:4700:10::6814:2384, 2606:4700:10::ac42:946e, 172.66.148.110, ...
Connecting to assets.factory.talos.dev (assets.factory.talos.dev)|2606:4700:10::6814:2384|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 350991845 (335M) [application/octet-stream]
Saving to: ‘/tmp/talos.zst’

/tmp/talos.zst                 100%[====================================================>] 334.73M  78.6MB/s    in 4.6s

2026-02-28 12:40:05 (72.4 MB/s) - ‘/tmp/talos.zst’ saved [350991845/350991845]
```

and extract / write it directly on to the first disk.
This writes out some small partitions.

```sh
$ zstd -c -d /tmp/talos.zst | dd of=/dev/nvme0n1
8697856+0 records in
8697856+0 records out
4453302272 bytes (4.5 GB, 4.1 GiB) copied, 16.7773 s, 265 MB/s
```

Reboot the server.
It should start up in to talos,
and be responsive on port 6443.

```sh
$ reboot
```

#### _tallos_ config

The machine booted,
but it's not doing much.
It needs to be told how to form its own cluster.

One thing to decide really early on is the networking layer.
I'm going to use [Cilium]
in kube proxy replacement mode.

With a patch.yaml file:

```yaml
machine:
  # allow sche
  nodeLabels: {}
  # for gvisor
  sysctls:
    user.max_user_namespaces: "11255"
cluster:
  network:
    cni:
      name: none
  proxy:
    disabled: true
  allowSchedulingOnControlPlanes: true
---
apiVersion: v1alpha1
kind: HostnameConfig
auto: off
hostname: nerys.liao.dev
---
apiVersion: v1alpha1
kind: ExtensionServiceConfig
name: tailscale
environment:
  - TS_AUTHKEY=...
  - TS_ROUTES=10.96.0.0/12
```

Generate the config files:

```sh
$ talosctl gen secrets -o secrets.yaml

$ talosctl gen config nerys https://95.217.61.27:6443 \
  --additional-sans nerys.liao.dev,2a01:4f9:4a:152a::2 \
  --dns-domain k8s.nerys.liao.dev \
  --install-disk /dev/nvme0n1 \
  --install-image factory.talos.dev/metal-installer/be09ac2f119f94a17780dddc69afc17405ff658f2a7201bfa1fb9f72629ff555:v1.12.4 \
  --with-secrets secrets.yaml \
  --config-patch @patch.yaml
```

This nets us 3 files:
a `talosconfig` for connecting via `talosctl`,
a `controlplane.yaml` for control plane nodes,
and a `worker.yaml` for workers.
As I only have a single node,
the `worker.yaml` can be ignored.

Next is to apply the config to the machine.
First store the generated talosconfig (`~/.talos/config`),
and set the endpoint (how to connect)
and node (machine to control):

```sh
$ talosctl config merge ./talosconfig
$ talosctl config endpoint 95.217.61.27
$ talosctl config node 95.217.61.27
```

Next, apply the config:

```sh
$ talosctl apply-config -f controlplane.yaml -n 95.217.61.27 -e 95.217.61.27
Applied configuration without a reboot
```

Use dashboard to look at logs,
it should complain about etcd waiting to joing a cluster.

```sh
$ talosctl dashboard
```

Start up our cluster:

```sh
$ talosctl bootstrap --talosconfig=./talosconfig
```

And save the kubeconfig:

```sh
$ talosctl kubeconfig
# goes into ~/.kube/config
```

Since I chose ciliumm,
I also need to install cilium myself:

```sh
$ cilium install \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445
```

And finally a sanity check that everything is working:

```sh
$ talosctl health
discovered nodes: ["95.217.61.27"]
waiting for etcd to be healthy: ...
waiting for etcd to be healthy: OK
waiting for etcd members to be consistent across nodes: ...
waiting for etcd members to be consistent across nodes: OK
waiting for etcd members to be control plane nodes: ...
waiting for etcd members to be control plane nodes: OK
waiting for apid to be ready: ...
waiting for apid to be ready: OK
waiting for all nodes memory sizes: ...
waiting for all nodes memory sizes: OK
waiting for all nodes disk sizes: ...
waiting for all nodes disk sizes: OK
waiting for no diagnostics: ...
waiting for no diagnostics: OK
waiting for kubelet to be healthy: ...
waiting for kubelet to be healthy: OK
waiting for all nodes to finish boot sequence: ...
waiting for all nodes to finish boot sequence: OK
waiting for all k8s nodes to report: ...
waiting for all k8s nodes to report: OK
waiting for all control plane static pods to be running: ...
waiting for all control plane static pods to be running: OK
waiting for all control plane components to be ready: ...
waiting for all control plane components to be ready: OK
waiting for all k8s nodes to report ready: ...
waiting for all k8s nodes to report ready: OK
waiting for kube-proxy to report ready: ...
waiting for kube-proxy to report ready: SKIP
waiting for coredns to report ready: ...
waiting for coredns to report ready: OK
waiting for all k8s nodes to report schedulable: ...
waiting for all k8s nodes to report schedulable: OK

$ kubectl apply -f https://raw.githubusercontent.com/siderolabs/example-workload/refs/heads/main/deploy/example-svc-nodeport.yaml
```
