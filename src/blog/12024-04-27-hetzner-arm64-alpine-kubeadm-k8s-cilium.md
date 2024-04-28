# cilium in k8s with kubeadm, on hetzner arm64 alpine

## is this some sort of unique combination?

### _cilium_ on my alpine hosted k8s

One of the servers I use is an arm64 virtual machine from hetzner cloud.
Previously I had it running [Fedora](https://fedoraproject.org/),
but I got bored with it and thought why not switch it up and go with [Alpine](https://www.alpinelinux.org/)?
After all, it has been my preferred base for container images when I can't use scratch/distroless,
surely it can work as the host too.
(I would have considered google's [Container Optimized OS](https://cloud.google.com/container-optimized-os/docs)
if it was any easier to run,
and I couldn't be bothered to do a custom install of [Talos](https://www.talos.dev/) this time round).
So I mash some answers through their guided installer,
through hetzner's web serial console because it doesn't boot with networking,
and I have a system up and running.

#### _secure_ access

Practically, this means running `ssh` and `tailscale`.

##### _ssh_

I use plain ssh for day to day use
(tailscale seems to be too power hungry to run constantly for laptops / phones).
I change the port to cut down on brute force login noise,
and sign the host keys with:
`ssh-keygen -s ~/.ssh/ssh/5c -I justia -h ssh_host_ed25519_key.pub`
to keep my local `known_hosts` relatively clean.

```sshdconfig
Port 22222
HostCertificate /etc/ssh/ssh_host_ed25519_key.pub.5c.cert
HostCertificate /etc/ssh/ssh_host_ed25519_key.pub.5r.cert
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519
PermitRootLogin no
```

##### _tailscale_

[tailscale](https://tailscale.com/) comes from Alpine's community repo,
so uncomment that in `/etc/apk/repositories`.
A quick refresher on [OpenRC](https://github.com/OpenRC/openrc)
(the init system used on Alpine):
`rc-update add <service> <runlevel>` to enable to service,
`rc-update <service> start` to run it now.
Run `tailscale up [flags]` to authorize the machine,
and that's it.

#### _kubernetes_

I've been using [k3s](https://k3s.io/) for a while,
it's easy enough to setup,
but this time I wanted to go plain `kubeadm`.

##### _os_ setup

First disable swap in `/etc/fstab`.
Next, some sysctl and modules:

```
echo "br_netfilter" > /etc/modules-load.d/k8s.conf

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/k8s.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/k8s.conf
```

Not sure if this was necessary but I did it: `uuidgen > /etc/machine-id`.

Finally, we install the actual k8s components.

```sh
apk add cni-plugins kubelet kubeadm kubectl containerd containerd-ctr linux-virt linux-virt-dev
```

Note that we're running in a VM so we using `linux-virt`,
we also need `linux-virt-dev` to get the linux kernel module configs available,
otherwise `kubeadm` fails in its preflight checks.

```
[ERROR SystemVerification]: failed to parse kernel config: unable to load kernel module: "configs", output: "modprobe: FATAL: Module configs not found in directory /lib/modules/6.6.28-0-virt\n", err: exit status 1
```

Enable `contaienrd` and `kubelet`, and reboot to make sure everything takes effect.

We also need to fix some mounting options for cilium later:
Put this in a script, e.g. `/etc/local.d/k8s-mounts.start` (and `chmod +x k8s-mounts.start`),
and enable the `local` service in openrc: `rc-update add local`:

```sh
#!/bin/sh

# for cilium
mount bpffs -t bpf /sys/fs/bpf
mount --make-shared /sys/fs/bpf
mkdir -p /run/cilium/cgroupv2
mount -t cgroup2 none /run/cilium/cgroupv2
mount --make-shared /run/cilium/cgroupv2/
```

Failing to do so may result in:

```
cilium-jghtg   0/1     Init:CreateContainerError   0          16s

       message: 'failed to generate container "5e3808b8e265b94aac306daa4ebe892e0f747698a90ebf2f394d65e538aa2af5"
          spec: failed to generate spec: path "/sys/fs/bpf" is mounted on "/sys" but
          it is not a shared mount'
```


##### _kubeadm_ init

I went with using a config file for `kubeadm` because editing a long list of fiags wasn't fun.
`kubeadm config print init-defaults` will get you a starting point from which to modify.
The full config types/options can be found in the
[source code docs](https://pkg.go.dev/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta3#InitConfiguration).

I used the config below, and just run `kubeadm init --config kubeadm.yaml`.
Since I plan to use Cilium with its kube-proxy replacement,
`skipPhases: [addon/kube-proxy]` was an important flag to add now.

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 10.0.0.2
  bindPort: 6443
skipPhases:
  - addon/kube-proxy
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
etcd:
  local:
    dataDir: /var/lib/etcd
networking:
  dnsDomain: asami.liao.dev
  serviceSubnet: 10.96.0.0/12
kubernetesVersion: 1.28.4
controlPlaneEndpoint: justia.liao.dev
apiServer:
  certSANs:
    - justia
    - justia.liao.dev
    - justia.badger-altered.ts.net
    - 10.0.0.2
    - 49.12.245.99
clusterName: asami
```

The cluster more or less cam up fine.
I did restart `kubelet` once, 
though I think it may have been unnecessary and it was just pulling images(?).

To make life easier,
create a kubeconfig for yourself that isn't `system:masters`:
`kubeadm kubeconfig user --client-name user`,
and apply a rolebinding to it:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: user-cluster-admin
subjects:
- kind: User
  name: user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```

##### _cilium_

The cluster that just came up lacks networking,
and I choose [cilium](https://cilium.io/) because it's cool
(and also what's used under the hood at clouds).

First, make sure we can run workloads:

```sh
kubectl taint node --all node-role.kubernetes.io/control-plane-
```

And install cilium,
the `k8sServiceHost` and `k8sServicePort` are the host/port pair from outside the cluster
(because the in-cluster networking won't be running when it starts without kube-proxy).
`cni.binPath` needs to be set, because when installed from alpine repos, 
they go in `/usr/libexec/cni` instead of the more traditional `/opt/cni/bin`.
And a single replica of the operator because I only run a single node.

```sh
helm upgrade cilium cilium/cilium --version 1.15.4 \
    --namespace kube-system \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=justia.liao.dev \
    --set k8sServicePort=6443 \
    --set cni.binPath=/usr/libexec/cni \
    --set operator.replicas=1
```

This should run successfully,
and we can test with `cilium connectivity test`,
which all passes for me.
