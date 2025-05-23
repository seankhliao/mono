package deploy

import (
	"strings"
)

k8s: apps: v1: DaemonSet: "kube-system": {
	"cilium-agent": (#LabelSelector & {
		#args: labels: {
			"app.kubernetes.io/name":      "cilium-agent"
			"app.kubernetes.io/part-of":   "cilium"
			"app.kubernetes.io/component": "agent"
		}
	}).out
	"cilium-agent": {
		metadata: annotations: "config.kubernetes.io/depends-on": strings.Join([
			for ref in cilium_operator_rbac.depends {ref},
			"/namespaces/kube-system/ConfigMap/cilium-config",
		], ",")
		spec: {
			template: {
				metadata: {
					annotations: {
						// Set app AppArmor's profile to "unconfined". The value of this annotation
						// can be modified as long users know which profiles they have available
						// in AppArmor.
						"container.apparmor.security.beta.kubernetes.io/cilium-agent":            "unconfined"
						"container.apparmor.security.beta.kubernetes.io/clean-cilium-state":      "unconfined"
						"container.apparmor.security.beta.kubernetes.io/mount-cgroup":            "unconfined"
						"container.apparmor.security.beta.kubernetes.io/apply-sysctl-overwrites": "unconfined"
					}
				}
				spec: {
					containers: [{
						name:            "cilium-agent"
						image:           "quay.io/cilium/cilium:v1.16.6@sha256:1e0896b1c4c188b4812c7e0bed7ec3f5631388ca88325c1391a0ef9172c448da"
						imagePullPolicy: "IfNotPresent"
						command: ["cilium-agent"]
						args: ["--config-dir=/tmp/cilium/config-map"]
						startupProbe: {
							httpGet: {
								host:   "127.0.0.1"
								path:   "/healthz"
								port:   9879
								scheme: "HTTP"
								httpHeaders: [{
									name:  "brief"
									value: "true"
								}]
							}
							failureThreshold:    105
							periodSeconds:       2
							successThreshold:    1
							initialDelaySeconds: 5
						}
						livenessProbe: {
							httpGet: {
								host:   "127.0.0.1"
								path:   "/healthz"
								port:   9879
								scheme: "HTTP"
								httpHeaders: [{
									name:  "brief"
									value: "true"
								}]
							}
							periodSeconds:    30
							successThreshold: 1
							failureThreshold: 10
							timeoutSeconds:   5
						}
						readinessProbe: {
							httpGet: {
								host:   "127.0.0.1"
								path:   "/healthz"
								port:   9879
								scheme: "HTTP"
								httpHeaders: [{
									name:  "brief"
									value: "true"
								}]
							}
							periodSeconds:    30
							successThreshold: 1
							failureThreshold: 3
							timeoutSeconds:   5
						}
						env: [{
							name: "K8S_NODE_NAME"
							valueFrom: fieldRef: {
								apiVersion: "v1"
								fieldPath:  "spec.nodeName"
							}
						}, {
							name: "CILIUM_K8S_NAMESPACE"
							valueFrom: fieldRef: {
								apiVersion: "v1"
								fieldPath:  "metadata.namespace"
							}
						}, {
							name:  "CILIUM_CLUSTERMESH_CONFIG"
							value: "/var/lib/cilium/clustermesh/"
						}, {
							name: "GOMEMLIMIT"
							valueFrom: resourceFieldRef: {
								resource: "limits.memory"
								divisor:  "1"
							}
						}, {
							name:  "KUBERNETES_SERVICE_HOST"
							value: "justia.liao.dev"
						}, {
							name:  "KUBERNETES_SERVICE_PORT"
							value: "6443"
						}]
						lifecycle: {
							postStart: exec: command: [
								"bash",
								"-c",
								"""
		set -o errexit
		set -o pipefail
		set -o nounset

		# When running in AWS ENI mode, it's likely that 'aws-node' has
		# had a chance to install SNAT iptables rules. These can result
		# in dropped traffic, so we should attempt to remove them.
		# We do it using a 'postStart' hook since this may need to run
		# for nodes which might have already been init'ed but may still
		# have dangling rules. This is safe because there are no
		# dependencies on anything that is part of the startup script
		# itself, and can be safely run multiple times per node (e.g. in
		# case of a restart).
		if [[ \"$(iptables-save | grep -E -c 'AWS-SNAT-CHAIN|AWS-CONNMARK-CHAIN')\" != \"0\" ]];
		then
		    echo 'Deleting iptables rules created by the AWS CNI VPC plugin'
		    iptables-save | grep -E -v 'AWS-SNAT-CHAIN|AWS-CONNMARK-CHAIN' | iptables-restore
		fi
		echo 'Done!'

		""",
							]

							preStop: exec: command: ["/cni-uninstall.sh"]
						}
						securityContext: {
							seLinuxOptions: {
								level: "s0"
								type:  "spc_t"
							}
							capabilities: {
								add: [
									"CHOWN",
									"KILL",
									"NET_ADMIN",
									"NET_RAW",
									"IPC_LOCK",
									"SYS_MODULE",
									"SYS_ADMIN",
									"SYS_RESOURCE",
									"DAC_OVERRIDE",
									"FOWNER",
									"SETGID",
									"SETUID",
									"NET_BIND_SERVICE",
								]
								drop: ["ALL"]
							}
						}
						terminationMessagePolicy: "FallbackToLogsOnError"
						volumeMounts: [{
							// Unprivileged containers need to mount /proc/sys/net from the host
							// to have write access
							mountPath: "/host/proc/sys/net"
							name:      "host-proc-sys-net"
						}, {
							// Unprivileged containers need to mount /proc/sys/kernel from the host
							// to have write access
							mountPath: "/host/proc/sys/kernel"
							name:      "host-proc-sys-kernel"
						}, {
							name:      "bpf-maps"
							mountPath: "/sys/fs/bpf"
							// Unprivileged containers can't set mount propagation to bidirectional
							// in this case we will mount the bpf fs from an init container that
							// is privileged and set the mount propagation from host to container
							// in Cilium.
							mountPropagation: "HostToContainer"
						}, {
							name:      "cilium-run"
							mountPath: "/var/run/cilium"
						}, {
							name:      "etc-cni-netd"
							mountPath: "/host/etc/cni/net.d"
						}, {
							name:      "clustermesh-secrets"
							mountPath: "/var/lib/cilium/clustermesh"
							readOnly:  true
						}, {
							// Needed to be able to load kernel modules
							name:      "lib-modules"
							mountPath: "/lib/modules"
							readOnly:  true
						}, {
							name:      "xtables-lock"
							mountPath: "/run/xtables.lock"
						}, {
							name:      "tmp"
							mountPath: "/tmp"
						}]
					}]
					initContainers: [{
						name:            "config"
						image:           "quay.io/cilium/cilium:v1.16.6@sha256:1e0896b1c4c188b4812c7e0bed7ec3f5631388ca88325c1391a0ef9172c448da"
						imagePullPolicy: "IfNotPresent"
						command: [
							"cilium-dbg",
							"build-config",
						]
						env: [{
							name: "K8S_NODE_NAME"
							valueFrom: fieldRef: {
								apiVersion: "v1"
								fieldPath:  "spec.nodeName"
							}
						}, {
							name: "CILIUM_K8S_NAMESPACE"
							valueFrom: fieldRef: {
								apiVersion: "v1"
								fieldPath:  "metadata.namespace"
							}
						}, {
							name:  "KUBERNETES_SERVICE_HOST"
							value: "justia.liao.dev"
						}, {
							name:  "KUBERNETES_SERVICE_PORT"
							value: "6443"
						}]
						volumeMounts: [{
							name:      "tmp"
							mountPath: "/tmp"
						}]
						terminationMessagePolicy: "FallbackToLogsOnError"
					}, {
						// Required to mount cgroup2 filesystem on the underlying Kubernetes node.
						// We use nsenter command with host's cgroup and mount namespaces enabled.
						name:            "mount-cgroup"
						image:           "quay.io/cilium/cilium:v1.16.6@sha256:1e0896b1c4c188b4812c7e0bed7ec3f5631388ca88325c1391a0ef9172c448da"
						imagePullPolicy: "IfNotPresent"
						env: [{
							name:  "CGROUP_ROOT"
							value: "/run/cilium/cgroupv2"
						}, {
							name:  "BIN_PATH"
							value: "/usr/libexec/cni"
						}]
						command: [
							"sh",
							"-ec",
							"""
		cp /usr/bin/cilium-mount /hostbin/cilium-mount;
		nsenter --cgroup=/hostproc/1/ns/cgroup --mount=/hostproc/1/ns/mnt \"${BIN_PATH}/cilium-mount\" $CGROUP_ROOT;
		rm /hostbin/cilium-mount

		""",
						]
						// The statically linked Go program binary is invoked to avoid any
						// dependency on utilities like sh and mount that can be missing on certain
						// distros installed on the underlying host. Copy the binary to the
						// same directory where we install cilium cni plugin so that exec permissions
						// are available.

						volumeMounts: [{
							name:      "hostproc"
							mountPath: "/hostproc"
						}, {
							name:      "cni-path"
							mountPath: "/hostbin"
						}]
						terminationMessagePolicy: "FallbackToLogsOnError"
						securityContext: {
							seLinuxOptions: {
								level: "s0"
								type:  "spc_t"
							}
							capabilities: {
								add: [
									"SYS_ADMIN",
									"SYS_CHROOT",
									"SYS_PTRACE",
								]
								drop: ["ALL"]
							}
						}
					}, {
						name:            "apply-sysctl-overwrites"
						image:           "quay.io/cilium/cilium:v1.16.6@sha256:1e0896b1c4c188b4812c7e0bed7ec3f5631388ca88325c1391a0ef9172c448da"
						imagePullPolicy: "IfNotPresent"
						env: [{
							name:  "BIN_PATH"
							value: "/usr/libexec/cni"
						}]
						command: [
							"sh",
							"-ec",
							"""
		cp /usr/bin/cilium-sysctlfix /hostbin/cilium-sysctlfix;
		nsenter --mount=/hostproc/1/ns/mnt \"${BIN_PATH}/cilium-sysctlfix\";
		rm /hostbin/cilium-sysctlfix

		""",
						]
						// The statically linked Go program binary is invoked to avoid any
						// dependency on utilities like sh that can be missing on certain
						// distros installed on the underlying host. Copy the binary to the
						// same directory where we install cilium cni plugin so that exec permissions
						// are available.

						volumeMounts: [{
							name:      "hostproc"
							mountPath: "/hostproc"
						}, {
							name:      "cni-path"
							mountPath: "/hostbin"
						}]
						terminationMessagePolicy: "FallbackToLogsOnError"
						securityContext: {
							seLinuxOptions: {
								level: "s0"
								type:  "spc_t"
							}
							capabilities: {
								add: [
									"SYS_ADMIN",
									"SYS_CHROOT",
									"SYS_PTRACE",
								]
								drop: ["ALL"]
							}
						}
					}, {
						// Mount the bpf fs if it is not mounted. We will perform this task
						// from a privileged container because the mount propagation bidirectional
						// only works from privileged containers.
						name:            "mount-bpf-fs"
						image:           "quay.io/cilium/cilium:v1.16.6@sha256:1e0896b1c4c188b4812c7e0bed7ec3f5631388ca88325c1391a0ef9172c448da"
						imagePullPolicy: "IfNotPresent"
						args: ["mount | grep \"/sys/fs/bpf type bpf\" || mount -t bpf bpf /sys/fs/bpf"]
						command: [
							"/bin/bash",
							"-c",
							"--",
						]
						terminationMessagePolicy: "FallbackToLogsOnError"
						securityContext: privileged: true
						volumeMounts: [{
							name:             "bpf-maps"
							mountPath:        "/sys/fs/bpf"
							mountPropagation: "Bidirectional"
						}]
					}, {
						name:            "clean-cilium-state"
						image:           "quay.io/cilium/cilium:v1.16.6@sha256:1e0896b1c4c188b4812c7e0bed7ec3f5631388ca88325c1391a0ef9172c448da"
						imagePullPolicy: "IfNotPresent"
						command: ["/init-container.sh"]
						env: [{
							name: "CILIUM_ALL_STATE"
							valueFrom: configMapKeyRef: {
								name:     "cilium-config"
								key:      "clean-cilium-state"
								optional: true
							}
						}, {
							name: "CILIUM_BPF_STATE"
							valueFrom: configMapKeyRef: {
								name:     "cilium-config"
								key:      "clean-cilium-bpf-state"
								optional: true
							}
						}, {
							name: "WRITE_CNI_CONF_WHEN_READY"
							valueFrom: configMapKeyRef: {
								name:     "cilium-config"
								key:      "write-cni-conf-when-ready"
								optional: true
							}
						}, {
							name:  "KUBERNETES_SERVICE_HOST"
							value: "justia.liao.dev"
						}, {
							name:  "KUBERNETES_SERVICE_PORT"
							value: "6443"
						}]
						terminationMessagePolicy: "FallbackToLogsOnError"
						securityContext: {
							seLinuxOptions: {
								level: "s0"
								type:  "spc_t"
							}
							capabilities: {
								add: [
									"NET_ADMIN",
									"SYS_MODULE",
									"SYS_ADMIN",
									"SYS_RESOURCE",
								]
								drop: ["ALL"]
							}
						}
						volumeMounts: [{
							name:      "bpf-maps"
							mountPath: "/sys/fs/bpf"
						}, {
							// Required to mount cgroup filesystem from the host to cilium agent pod
							name:             "cilium-cgroup"
							mountPath:        "/run/cilium/cgroupv2"
							mountPropagation: "HostToContainer"
						}, {
							name:      "cilium-run"
							mountPath: "/var/run/cilium"
						}]
					}, {
						// wait-for-kube-proxy
						// Install the CNI binaries in an InitContainer so we don't have a writable host mount in the agent
						name:            "install-cni-binaries"
						image:           "quay.io/cilium/cilium:v1.16.6@sha256:1e0896b1c4c188b4812c7e0bed7ec3f5631388ca88325c1391a0ef9172c448da"
						imagePullPolicy: "IfNotPresent"
						command: ["/install-plugin.sh"]
						resources: requests: {
							cpu:    "100m"
							memory: "10Mi"
						}
						securityContext: {
							seLinuxOptions: {
								level: "s0"
								type:  "spc_t"
							}
							capabilities: drop: ["ALL"]
						}
						terminationMessagePolicy: "FallbackToLogsOnError"
						volumeMounts: [{
							name:      "cni-path"
							mountPath: "/host/opt/cni/bin"
						}]
					}]                             // .Values.cni.install
					restartPolicy:                 "Always"
					priorityClassName:             "system-node-critical"
					serviceAccountName:            "cilium-agent"
					automountServiceAccountToken:  true
					terminationGracePeriodSeconds: 1
					hostNetwork:                   true
					affinity: podAntiAffinity: requiredDuringSchedulingIgnoredDuringExecution: [{
						labelSelector: matchLabels: "k8s-app": "cilium"
						topologyKey: "kubernetes.io/hostname"
					}]
					nodeSelector: "kubernetes.io/os": "linux"
					tolerations: [{
						operator: "Exists"
					}]
					volumes: [{
						// For sharing configuration between the "config" initContainer and the agent
						name: "tmp"
						emptyDir: {}
					}, {
						// To keep state between restarts / upgrades
						name: "cilium-run"
						hostPath: {
							path: "/var/run/cilium"
							type: "DirectoryOrCreate"
						}
					}, {
						// To keep state between restarts / upgrades for bpf maps
						name: "bpf-maps"
						hostPath: {
							path: "/sys/fs/bpf"
							type: "DirectoryOrCreate"
						}
					}, {
						// To mount cgroup2 filesystem on the host
						name: "hostproc"
						hostPath: {
							path: "/proc"
							type: "Directory"
						}
					}, {
						// To keep state between restarts / upgrades for cgroup2 filesystem
						name: "cilium-cgroup"
						hostPath: {
							path: "/run/cilium/cgroupv2"
							type: "DirectoryOrCreate"
						}
					}, {
						// To install cilium cni plugin in the host
						name: "cni-path"
						hostPath: {
							path: "/usr/libexec/cni"
							type: "DirectoryOrCreate"
						}
					}, {
						// To install cilium cni configuration in the host
						name: "etc-cni-netd"
						hostPath: {
							path: "/etc/cni/net.d"
							type: "DirectoryOrCreate"
						}
					}, {
						// To be able to load kernel modules
						name: "lib-modules"
						hostPath: path: "/lib/modules"
					}, {
						// To access iptables concurrently with other processes (e.g. kube-proxy)
						name: "xtables-lock"
						hostPath: {
							path: "/run/xtables.lock"
							type: "FileOrCreate"
						}
					}, {
						// To read the clustermesh configuration
						name: "clustermesh-secrets"
						projected: {
							// note: the leading zero means this number is in octal representation: do not remove it
							defaultMode: 0o400
							sources: [{
								secret: {
									name:     "cilium-clustermesh"
									optional: true
								}
							}, {
								// note: items are not explicitly listed here, since the entries of this secret
								// depend on the peers configured, and that would cause a restart of all agents
								// at every addition/removal. Leaving the field empty makes each secret entry
								// to be automatically projected into the volume as a file whose name is the key.
								secret: {
									name:     "clustermesh-apiserver-remote-cert"
									optional: true
									items: [{
										key:  "tls.key"
										path: "common-etcd-client.key"
									}, {
										key:  "tls.crt"
										path: "common-etcd-client.crt"
									}, {
										key:  "ca.crt"
										path: "common-etcd-client-ca.crt"
									}]
								}
							}]
						}
					}, {
						name: "host-proc-sys-net"
						hostPath: {
							path: "/proc/sys/net"
							type: "Directory"
						}
					}, {
						name: "host-proc-sys-kernel"
						hostPath: {
							path: "/proc/sys/kernel"
							type: "Directory"
						}
					}]
				}
			}
		}
	}
}
