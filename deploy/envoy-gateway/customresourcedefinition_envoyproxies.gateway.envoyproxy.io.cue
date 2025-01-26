package deploy

k8s: "apiextensions.k8s.io": v1: CustomResourceDefinition: "": "envoyproxies.gateway.envoyproxy.io": {
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: {
		annotations: "controller-gen.kubebuilder.io/version": "v0.16.1"
		name: "envoyproxies.gateway.envoyproxy.io"
	}
	spec: {
		group: "gateway.envoyproxy.io"
		names: {
			categories: ["envoy-gateway"]
			kind:     "EnvoyProxy"
			listKind: "EnvoyProxyList"
			plural:   "envoyproxies"
			shortNames: ["eproxy"]
			singular: "envoyproxy"
		}
		scope: "Namespaced"
		versions: [{
			name: "v1alpha1"
			schema: openAPIV3Schema: {
				description: "EnvoyProxy is the schema for the envoyproxies API."
				properties: {
					apiVersion: {
						description: """
	APIVersion defines the versioned schema of this representation of an object.
	Servers should convert recognized schemas to the latest internal value, and
	may reject unrecognized values.
	More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
	"""
						type: "string"
					}
					kind: {
						description: """
	Kind is a string value representing the REST resource this object represents.
	Servers may infer this from the endpoint the client submits requests to.
	Cannot be updated.
	In CamelCase.
	More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
	"""
						type: "string"
					}
					metadata: type: "object"
					spec: {
						description: "EnvoyProxySpec defines the desired state of EnvoyProxy."
						properties: {
							backendTLS: {
								description: """
	BackendTLS is the TLS configuration for the Envoy proxy to use when connecting to backends.
	These settings are applied on backends for which TLS policies are specified.
	"""
								properties: {
									alpnProtocols: {
										description: """
	ALPNProtocols supplies the list of ALPN protocols that should be
	exposed by the listener. By default h2 and http/1.1 are enabled.
	Supported values are:
	- http/1.0
	- http/1.1
	- h2
	"""
										items: {
											description: "ALPNProtocol specifies the protocol to be negotiated using ALPN"
											enum: [
												"http/1.0",
												"http/1.1",
												"h2",
											]
											type: "string"
										}
										type: "array"
									}
									ciphers: {
										description: """
	Ciphers specifies the set of cipher suites supported when
	negotiating TLS 1.0 - 1.2. This setting has no effect for TLS 1.3.
	In non-FIPS Envoy Proxy builds the default cipher list is:
	- [ECDHE-ECDSA-AES128-GCM-SHA256|ECDHE-ECDSA-CHACHA20-POLY1305]
	- [ECDHE-RSA-AES128-GCM-SHA256|ECDHE-RSA-CHACHA20-POLY1305]
	- ECDHE-ECDSA-AES256-GCM-SHA384
	- ECDHE-RSA-AES256-GCM-SHA384
	In builds using BoringSSL FIPS the default cipher list is:
	- ECDHE-ECDSA-AES128-GCM-SHA256
	- ECDHE-RSA-AES128-GCM-SHA256
	- ECDHE-ECDSA-AES256-GCM-SHA384
	- ECDHE-RSA-AES256-GCM-SHA384
	"""
										items: type: "string"
										type: "array"
									}
									clientCertificateRef: {
										description: """
	ClientCertificateRef defines the reference to a Kubernetes Secret that contains
	the client certificate and private key for Envoy to use when connecting to
	backend services and external services, such as ExtAuth, ALS, OpenTelemetry, etc.
	This secret should be located within the same namespace as the Envoy proxy resource that references it.
	"""
										properties: {
											group: {
												default: ""
												description: """
	Group is the group of the referent. For example, "gateway.networking.k8s.io".
	When unspecified or empty string, core API group is inferred.
	"""
												maxLength: 253
												pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
												type:      "string"
											}
											kind: {
												default:     "Secret"
												description: "Kind is kind of the referent. For example \"Secret\"."
												maxLength:   63
												minLength:   1
												pattern:     "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
												type:        "string"
											}
											name: {
												description: "Name is the name of the referent."
												maxLength:   253
												minLength:   1
												type:        "string"
											}
											namespace: {
												description: """
	Namespace is the namespace of the referenced object. When unspecified, the local
	namespace is inferred.

	Note that when a namespace different than the local namespace is specified,
	a ReferenceGrant object is required in the referent namespace to allow that
	namespace's owner to accept the reference. See the ReferenceGrant
	documentation for details.

	Support: Core
	"""
												maxLength: 63
												minLength: 1
												pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
												type:      "string"
											}
										}
										required: ["name"]
										type: "object"
									}
									ecdhCurves: {
										description: """
	ECDHCurves specifies the set of supported ECDH curves.
	In non-FIPS Envoy Proxy builds the default curves are:
	- X25519
	- P-256
	In builds using BoringSSL FIPS the default curve is:
	- P-256
	"""
										items: type: "string"
										type: "array"
									}
									maxVersion: {
										description: """
	Max specifies the maximal TLS protocol version to allow
	The default is TLS 1.3 if this is not specified.
	"""
										enum: [
											"Auto",
											"1.0",
											"1.1",
											"1.2",
											"1.3",
										]
										type: "string"
									}
									minVersion: {
										description: """
	Min specifies the minimal TLS protocol version to allow.
	The default is TLS 1.2 if this is not specified.
	"""
										enum: [
											"Auto",
											"1.0",
											"1.1",
											"1.2",
											"1.3",
										]
										type: "string"
									}
									signatureAlgorithms: {
										description: """
	SignatureAlgorithms specifies which signature algorithms the listener should
	support.
	"""
										items: type: "string"
										type: "array"
									}
								}
								type: "object"
								"x-kubernetes-validations": [{
									message: "setting ciphers has no effect if the minimum possible TLS version is 1.3"
									rule:    "has(self.minVersion) && self.minVersion == '1.3' ? !has(self.ciphers) : true"
								}, {
									message: "minVersion must be smaller or equal to maxVersion"
									rule:    "has(self.minVersion) && has(self.maxVersion) ? {\"Auto\":0,\"1.0\":1,\"1.1\":2,\"1.2\":3,\"1.3\":4}[self.minVersion] <= {\"1.0\":1,\"1.1\":2,\"1.2\":3,\"1.3\":4,\"Auto\":5}[self.maxVersion] : !has(self.minVersion) && has(self.maxVersion) ? 3 <= {\"1.0\":1,\"1.1\":2,\"1.2\":3,\"1.3\":4,\"Auto\":5}[self.maxVersion] : true"
								}]
							}
							bootstrap: {
								description: """
	Bootstrap defines the Envoy Bootstrap as a YAML string.
	Visit https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/bootstrap/v3/bootstrap.proto#envoy-v3-api-msg-config-bootstrap-v3-bootstrap
	to learn more about the syntax.
	If set, this is the Bootstrap configuration used for the managed Envoy Proxy fleet instead of the default Bootstrap configuration
	set by Envoy Gateway.
	Some fields within the Bootstrap that are required to communicate with the xDS Server (Envoy Gateway) and receive xDS resources
	from it are not configurable and will result in the `EnvoyProxy` resource being rejected.
	Backward compatibility across minor versions is not guaranteed.
	We strongly recommend using `egctl x translate` to generate a `EnvoyProxy` resource with the `Bootstrap` field set to the default
	Bootstrap configuration used. You can edit this configuration, and rerun `egctl x translate` to ensure there are no validation errors.
	"""
								properties: {
									jsonPatches: {
										description: """
	JSONPatches is an array of JSONPatches to be applied to the default bootstrap. Patches are
	applied in the order in which they are defined.
	"""
										items: {
											description: """
	JSONPatchOperation defines the JSON Patch Operation as defined in
	https://datatracker.ietf.org/doc/html/rfc6902
	"""
											properties: {
												from: {
													description: """
	From is the source location of the value to be copied or moved. Only valid
	for move or copy operations
	Refer to https://datatracker.ietf.org/doc/html/rfc6901 for more details.
	"""
													type: "string"
												}
												jsonPath: {
													description: """
	JSONPath is a JSONPath expression. Refer to https://datatracker.ietf.org/doc/rfc9535/ for more details.
	It produces one or more JSONPointer expressions based on the given JSON document.
	If no JSONPointer is found, it will result in an error.
	If the 'Path' property is also set, it will be appended to the resulting JSONPointer expressions from the JSONPath evaluation.
	This is useful when creating a property that does not yet exist in the JSON document.
	The final JSONPointer expressions specifies the locations in the target document/field where the operation will be applied.
	"""
													type: "string"
												}
												op: {
													description: "Op is the type of operation to perform"
													enum: [
														"add",
														"remove",
														"replace",
														"move",
														"copy",
														"test",
													]
													type: "string"
												}
												path: {
													description: """
	Path is a JSONPointer expression. Refer to https://datatracker.ietf.org/doc/html/rfc6901 for more details.
	It specifies the location of the target document/field where the operation will be performed
	"""
													type: "string"
												}
												value: {
													description: """
	Value is the new value of the path location. The value is only used by
	the `add` and `replace` operations.
	"""
													"x-kubernetes-preserve-unknown-fields": true
												}
											}
											required: ["op"]
											type: "object"
										}
										type: "array"
									}
									type: {
										default: "Replace"
										description: """
	Type is the type of the bootstrap configuration, it should be either Replace,  Merge, or JSONPatch.
	If unspecified, it defaults to Replace.
	"""
										enum: [
											"Merge",
											"Replace",
											"JSONPatch",
										]
										type: "string"
									}
									value: {
										description: "Value is a YAML string of the bootstrap."
										type:        "string"
									}
								}
								type: "object"
								"x-kubernetes-validations": [{
									message: "provided bootstrap patch doesn't match the configured patch type"
									rule:    "self.type == 'JSONPatch' ? self.jsonPatches.size() > 0 : has(self.value)"
								}]
							}
							concurrency: {
								description: """
	Concurrency defines the number of worker threads to run. If unset, it defaults to
	the number of cpuset threads on the platform.
	"""
								format: "int32"
								type:   "integer"
							}
							extraArgs: {
								description: """
	ExtraArgs defines additional command line options that are provided to Envoy.
	More info: https://www.envoyproxy.io/docs/envoy/latest/operations/cli#command-line-options
	Note: some command line options are used internally(e.g. --log-level) so they cannot be provided here.
	"""
								items: type: "string"
								type: "array"
							}
							filterOrder: {
								description: """
	FilterOrder defines the order of filters in the Envoy proxy's HTTP filter chain.
	The FilterPosition in the list will be applied in the order they are defined.
	If unspecified, the default filter order is applied.
	Default filter order is:

	- envoy.filters.http.health_check

	- envoy.filters.http.fault

	- envoy.filters.http.cors

	- envoy.filters.http.ext_authz

	- envoy.filters.http.basic_auth

	- envoy.filters.http.oauth2

	- envoy.filters.http.jwt_authn

	- envoy.filters.http.stateful_session

	- envoy.filters.http.ext_proc

	- envoy.filters.http.wasm

	- envoy.filters.http.rbac

	- envoy.filters.http.local_ratelimit

	- envoy.filters.http.ratelimit

	- envoy.filters.http.custom_response

	- envoy.filters.http.router

	Note: "envoy.filters.http.router" cannot be reordered, it's always the last filter in the chain.
	"""
								items: {
									description: "FilterPosition defines the position of an Envoy HTTP filter in the filter chain."
									properties: {
										after: {
											description: """
	After defines the filter that should come after the filter.
	Only one of Before or After must be set.
	"""
											enum: [
												"envoy.filters.http.health_check",
												"envoy.filters.http.fault",
												"envoy.filters.http.cors",
												"envoy.filters.http.ext_authz",
												"envoy.filters.http.basic_auth",
												"envoy.filters.http.oauth2",
												"envoy.filters.http.jwt_authn",
												"envoy.filters.http.stateful_session",
												"envoy.filters.http.ext_proc",
												"envoy.filters.http.wasm",
												"envoy.filters.http.rbac",
												"envoy.filters.http.local_ratelimit",
												"envoy.filters.http.ratelimit",
												"envoy.filters.http.custom_response",
											]
											type: "string"
										}
										before: {
											description: """
	Before defines the filter that should come before the filter.
	Only one of Before or After must be set.
	"""
											enum: [
												"envoy.filters.http.health_check",
												"envoy.filters.http.fault",
												"envoy.filters.http.cors",
												"envoy.filters.http.ext_authz",
												"envoy.filters.http.basic_auth",
												"envoy.filters.http.oauth2",
												"envoy.filters.http.jwt_authn",
												"envoy.filters.http.stateful_session",
												"envoy.filters.http.ext_proc",
												"envoy.filters.http.wasm",
												"envoy.filters.http.rbac",
												"envoy.filters.http.local_ratelimit",
												"envoy.filters.http.ratelimit",
												"envoy.filters.http.custom_response",
											]
											type: "string"
										}
										name: {
											description: "Name of the filter."
											enum: [
												"envoy.filters.http.health_check",
												"envoy.filters.http.fault",
												"envoy.filters.http.cors",
												"envoy.filters.http.ext_authz",
												"envoy.filters.http.basic_auth",
												"envoy.filters.http.oauth2",
												"envoy.filters.http.jwt_authn",
												"envoy.filters.http.stateful_session",
												"envoy.filters.http.ext_proc",
												"envoy.filters.http.wasm",
												"envoy.filters.http.rbac",
												"envoy.filters.http.local_ratelimit",
												"envoy.filters.http.ratelimit",
												"envoy.filters.http.custom_response",
											]
											type: "string"
										}
									}
									required: ["name"]
									type: "object"
									"x-kubernetes-validations": [{
										message: "one of before or after must be specified"
										rule:    "(has(self.before) || has(self.after))"
									}, {
										message: "only one of before or after can be specified"
										rule:    "(has(self.before) && !has(self.after)) || (!has(self.before) && has(self.after))"
									}]
								}
								type: "array"
							}
							ipFamily: {
								description: """
	IPFamily specifies the IP family for the EnvoyProxy fleet.
	This setting only affects the Gateway listener port and does not impact
	other aspects of the Envoy proxy configuration.
	If not specified, the system will operate as follows:
	- It defaults to IPv4 only.
	- IPv6 and dual-stack environments are not supported in this default configuration.
	Note: To enable IPv6 or dual-stack functionality, explicit configuration is required.
	"""
								enum: [
									"IPv4",
									"IPv6",
									"DualStack",
								]
								type: "string"
							}
							logging: {
								default: level: default: "warn"
								description: "Logging defines logging parameters for managed proxies."
								properties: level: {
									additionalProperties: {
										description: "LogLevel defines a log level for Envoy Gateway and EnvoyProxy system logs."
										enum: [
											"debug",
											"info",
											"error",
											"warn",
										]
										type: "string"
									}
									default: default: "warn"
									description: """
	Level is a map of logging level per component, where the component is the key
	and the log level is the value. If unspecified, defaults to "default: warn".
	"""
									type: "object"
								}
								type: "object"
							}
							mergeGateways: {
								description: """
	MergeGateways defines if Gateway resources should be merged onto the same Envoy Proxy Infrastructure.
	Setting this field to true would merge all Gateway Listeners under the parent Gateway Class.
	This means that the port, protocol and hostname tuple must be unique for every listener.
	If a duplicate listener is detected, the newer listener (based on timestamp) will be rejected and its status will be updated with a "Accepted=False" condition.
	"""
								type: "boolean"
							}
							provider: {
								description: """
	Provider defines the desired resource provider and provider-specific configuration.
	If unspecified, the "Kubernetes" resource provider is used with default configuration
	parameters.
	"""
								properties: {
									kubernetes: {
										description: """
	Kubernetes defines the desired state of the Kubernetes resource provider.
	Kubernetes provides infrastructure resources for running the data plane,
	e.g. Envoy proxy. If unspecified and type is "Kubernetes", default settings
	for managed Kubernetes resources are applied.
	"""
										properties: {
											envoyDaemonSet: {
												description: """
	EnvoyDaemonSet defines the desired state of the Envoy daemonset resource.
	Disabled by default, a deployment resource is used instead to provision the Envoy Proxy fleet
	"""
												properties: {
													container: {
														description: "Container defines the desired specification of main container."
														properties: {
															env: {
																description: "List of environment variables to set in the container."
																items: {
																	description: "EnvVar represents an environment variable present in a Container."
																	properties: {
																		name: {
																			description: "Name of the environment variable. Must be a C_IDENTIFIER."
																			type:        "string"
																		}
																		value: {
																			description: """
	Variable references $(VAR_NAME) are expanded
	using the previously defined environment variables in the container and
	any service environment variables. If a variable cannot be resolved,
	the reference in the input string will be unchanged. Double $$ are reduced
	to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e.
	"$$(VAR_NAME)" will produce the string literal "$(VAR_NAME)".
	Escaped references will never be expanded, regardless of whether the variable
	exists or not.
	Defaults to "".
	"""
																			type: "string"
																		}
																		valueFrom: {
																			description: "Source for the environment variable's value. Cannot be used if value is not empty."
																			properties: {
																				configMapKeyRef: {
																					description: "Selects a key of a ConfigMap."
																					properties: {
																						key: {
																							description: "The key to select."
																							type:        "string"
																						}
																						name: {
																							default: ""
																							description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																							type: "string"
																						}
																						optional: {
																							description: "Specify whether the ConfigMap or its key must be defined"
																							type:        "boolean"
																						}
																					}
																					required: ["key"]
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				fieldRef: {
																					description: """
	Selects a field of the pod: supports metadata.name, metadata.namespace, `metadata.labels['<KEY>']`, `metadata.annotations['<KEY>']`,
	spec.nodeName, spec.serviceAccountName, status.hostIP, status.podIP, status.podIPs.
	"""
																					properties: {
																						apiVersion: {
																							description: "Version of the schema the FieldPath is written in terms of, defaults to \"v1\"."
																							type:        "string"
																						}
																						fieldPath: {
																							description: "Path of the field to select in the specified API version."
																							type:        "string"
																						}
																					}
																					required: ["fieldPath"]
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				resourceFieldRef: {
																					description: """
	Selects a resource of the container: only resources limits and requests
	(limits.cpu, limits.memory, limits.ephemeral-storage, requests.cpu, requests.memory and requests.ephemeral-storage) are currently supported.
	"""
																					properties: {
																						containerName: {
																							description: "Container name: required for volumes, optional for env vars"
																							type:        "string"
																						}
																						divisor: {
																							anyOf: [{
																								type: "integer"
																							}, {
																								type: "string"
																							}]
																							description:                  "Specifies the output format of the exposed resources, defaults to \"1\""
																							pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																							"x-kubernetes-int-or-string": true
																						}
																						resource: {
																							description: "Required: resource to select"
																							type:        "string"
																						}
																					}
																					required: ["resource"]
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				secretKeyRef: {
																					description: "Selects a key of a secret in the pod's namespace"
																					properties: {
																						key: {
																							description: "The key of the secret to select from.  Must be a valid secret key."
																							type:        "string"
																						}
																						name: {
																							default: ""
																							description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																							type: "string"
																						}
																						optional: {
																							description: "Specify whether the Secret or its key must be defined"
																							type:        "boolean"
																						}
																					}
																					required: ["key"]
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																			}
																			type: "object"
																		}
																	}
																	required: ["name"]
																	type: "object"
																}
																type: "array"
															}
															image: {
																description: "Image specifies the EnvoyProxy container image to be used, instead of the default image."
																type:        "string"
															}
															resources: {
																description: """
	Resources required by this container.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																properties: {
																	claims: {
																		description: """
	Claims lists the names of resources, defined in spec.resourceClaims,
	that are used by this container.

	This is an alpha field and requires enabling the
	DynamicResourceAllocation feature gate.

	This field is immutable. It can only be set for containers.
	"""
																		items: {
																			description: "ResourceClaim references one entry in PodSpec.ResourceClaims."
																			properties: {
																				name: {
																					description: """
	Name must match the name of one entry in pod.spec.resourceClaims of
	the Pod where this field is used. It makes that resource available
	inside a container.
	"""
																					type: "string"
																				}
																				request: {
																					description: """
	Request is the name chosen for a request in the referenced claim.
	If empty, everything from the claim is made available, otherwise
	only the result of this request.
	"""
																					type: "string"
																				}
																			}
																			required: ["name"]
																			type: "object"
																		}
																		type: "array"
																		"x-kubernetes-list-map-keys": ["name"]
																		"x-kubernetes-list-type": "map"
																	}
																	limits: {
																		additionalProperties: {
																			anyOf: [{
																				type: "integer"
																			}, {
																				type: "string"
																			}]
																			pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																			"x-kubernetes-int-or-string": true
																		}
																		description: """
	Limits describes the maximum amount of compute resources allowed.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																		type: "object"
																	}
																	requests: {
																		additionalProperties: {
																			anyOf: [{
																				type: "integer"
																			}, {
																				type: "string"
																			}]
																			pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																			"x-kubernetes-int-or-string": true
																		}
																		description: """
	Requests describes the minimum amount of compute resources required.
	If Requests is omitted for a container, it defaults to Limits if that is explicitly specified,
	otherwise to an implementation-defined value. Requests cannot exceed Limits.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																		type: "object"
																	}
																}
																type: "object"
															}
															securityContext: {
																description: """
	SecurityContext defines the security options the container should be run with.
	If set, the fields of SecurityContext override the equivalent fields of PodSecurityContext.
	More info: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
	"""
																properties: {
																	allowPrivilegeEscalation: {
																		description: """
	AllowPrivilegeEscalation controls whether a process can gain more
	privileges than its parent process. This bool directly controls if
	the no_new_privs flag will be set on the container process.
	AllowPrivilegeEscalation is true always when the container is:
	1) run as Privileged
	2) has CAP_SYS_ADMIN
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "boolean"
																	}
																	appArmorProfile: {
																		description: """
	appArmorProfile is the AppArmor options to use by this container. If set, this profile
	overrides the pod's appArmorProfile.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			localhostProfile: {
																				description: """
	localhostProfile indicates a profile loaded on the node that should be used.
	The profile must be preconfigured on the node to work.
	Must match the loaded name of the profile.
	Must be set if and only if type is "Localhost".
	"""
																				type: "string"
																			}
																			type: {
																				description: """
	type indicates which kind of AppArmor profile will be applied.
	Valid options are:
	  Localhost - a profile pre-loaded on the node.
	  RuntimeDefault - the container runtime's default profile.
	  Unconfined - no AppArmor enforcement.
	"""
																				type: "string"
																			}
																		}
																		required: ["type"]
																		type: "object"
																	}
																	capabilities: {
																		description: """
	The capabilities to add/drop when running containers.
	Defaults to the default set of capabilities granted by the container runtime.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			add: {
																				description: "Added capabilities"
																				items: {
																					description: "Capability represent POSIX capabilities type"
																					type:        "string"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																			drop: {
																				description: "Removed capabilities"
																				items: {
																					description: "Capability represent POSIX capabilities type"
																					type:        "string"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																		}
																		type: "object"
																	}
																	privileged: {
																		description: """
	Run container in privileged mode.
	Processes in privileged containers are essentially equivalent to root on the host.
	Defaults to false.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "boolean"
																	}
																	procMount: {
																		description: """
	procMount denotes the type of proc mount to use for the containers.
	The default value is Default which uses the container runtime defaults for
	readonly paths and masked paths.
	This requires the ProcMountType feature flag to be enabled.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "string"
																	}
																	readOnlyRootFilesystem: {
																		description: """
	Whether this container has a read-only root filesystem.
	Default is false.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "boolean"
																	}
																	runAsGroup: {
																		description: """
	The GID to run the entrypoint of the container process.
	Uses runtime default if unset.
	May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		format: "int64"
																		type:   "integer"
																	}
																	runAsNonRoot: {
																		description: """
	Indicates that the container must run as a non-root user.
	If true, the Kubelet will validate the image at runtime to ensure that it
	does not run as UID 0 (root) and fail to start the container if it does.
	If unset or false, no such validation will be performed.
	May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	"""
																		type: "boolean"
																	}
																	runAsUser: {
																		description: """
	The UID to run the entrypoint of the container process.
	Defaults to user specified in image metadata if unspecified.
	May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		format: "int64"
																		type:   "integer"
																	}
																	seLinuxOptions: {
																		description: """
	The SELinux context to be applied to the container.
	If unspecified, the container runtime will allocate a random SELinux context for each
	container.  May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			level: {
																				description: "Level is SELinux level label that applies to the container."
																				type:        "string"
																			}
																			role: {
																				description: "Role is a SELinux role label that applies to the container."
																				type:        "string"
																			}
																			type: {
																				description: "Type is a SELinux type label that applies to the container."
																				type:        "string"
																			}
																			user: {
																				description: "User is a SELinux user label that applies to the container."
																				type:        "string"
																			}
																		}
																		type: "object"
																	}
																	seccompProfile: {
																		description: """
	The seccomp options to use by this container. If seccomp options are
	provided at both the pod & container level, the container options
	override the pod options.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			localhostProfile: {
																				description: """
	localhostProfile indicates a profile defined in a file on the node should be used.
	The profile must be preconfigured on the node to work.
	Must be a descending path, relative to the kubelet's configured seccomp profile location.
	Must be set if type is "Localhost". Must NOT be set for any other type.
	"""
																				type: "string"
																			}
																			type: {
																				description: """
	type indicates which kind of seccomp profile will be applied.
	Valid options are:

	Localhost - a profile defined in a file on the node should be used.
	RuntimeDefault - the container runtime default profile should be used.
	Unconfined - no profile should be applied.
	"""
																				type: "string"
																			}
																		}
																		required: ["type"]
																		type: "object"
																	}
																	windowsOptions: {
																		description: """
	The Windows specific settings applied to all containers.
	If unspecified, the options from the PodSecurityContext will be used.
	If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is linux.
	"""
																		properties: {
																			gmsaCredentialSpec: {
																				description: """
	GMSACredentialSpec is where the GMSA admission webhook
	(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the
	GMSA credential spec named by the GMSACredentialSpecName field.
	"""
																				type: "string"
																			}
																			gmsaCredentialSpecName: {
																				description: "GMSACredentialSpecName is the name of the GMSA credential spec to use."
																				type:        "string"
																			}
																			hostProcess: {
																				description: """
	HostProcess determines if a container should be run as a 'Host Process' container.
	All of a Pod's containers must have the same effective HostProcess value
	(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).
	In addition, if HostProcess is true then HostNetwork must also be set to true.
	"""
																				type: "boolean"
																			}
																			runAsUserName: {
																				description: """
	The UserName in Windows to run the entrypoint of the container process.
	Defaults to the user specified in image metadata if unspecified.
	May also be set in PodSecurityContext. If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	"""
																				type: "string"
																			}
																		}
																		type: "object"
																	}
																}
																type: "object"
															}
															volumeMounts: {
																description: """
	VolumeMounts are volumes to mount into the container's filesystem.
	Cannot be updated.
	"""
																items: {
																	description: "VolumeMount describes a mounting of a Volume within a container."
																	properties: {
																		mountPath: {
																			description: """
	Path within the container at which the volume should be mounted.  Must
	not contain ':'.
	"""
																			type: "string"
																		}
																		mountPropagation: {
																			description: """
	mountPropagation determines how mounts are propagated from the host
	to container and the other way around.
	When not set, MountPropagationNone is used.
	This field is beta in 1.10.
	When RecursiveReadOnly is set to IfPossible or to Enabled, MountPropagation must be None or unspecified
	(which defaults to None).
	"""
																			type: "string"
																		}
																		name: {
																			description: "This must match the Name of a Volume."
																			type:        "string"
																		}
																		readOnly: {
																			description: """
	Mounted read-only if true, read-write otherwise (false or unspecified).
	Defaults to false.
	"""
																			type: "boolean"
																		}
																		recursiveReadOnly: {
																			description: """
	RecursiveReadOnly specifies whether read-only mounts should be handled
	recursively.

	If ReadOnly is false, this field has no meaning and must be unspecified.

	If ReadOnly is true, and this field is set to Disabled, the mount is not made
	recursively read-only.  If this field is set to IfPossible, the mount is made
	recursively read-only, if it is supported by the container runtime.  If this
	field is set to Enabled, the mount is made recursively read-only if it is
	supported by the container runtime, otherwise the pod will not be started and
	an error will be generated to indicate the reason.

	If this field is set to IfPossible or Enabled, MountPropagation must be set to
	None (or be unspecified, which defaults to None).

	If this field is not specified, it is treated as an equivalent of Disabled.
	"""
																			type: "string"
																		}
																		subPath: {
																			description: """
	Path within the volume from which the container's volume should be mounted.
	Defaults to "" (volume's root).
	"""
																			type: "string"
																		}
																		subPathExpr: {
																			description: """
	Expanded path within the volume from which the container's volume should be mounted.
	Behaves similarly to SubPath but environment variable references $(VAR_NAME) are expanded using the container's environment.
	Defaults to "" (volume's root).
	SubPathExpr and SubPath are mutually exclusive.
	"""
																			type: "string"
																		}
																	}
																	required: [
																		"mountPath",
																		"name",
																	]
																	type: "object"
																}
																type: "array"
															}
														}
														type: "object"
													}
													name: {
														description: """
	Name of the daemonSet.
	When unset, this defaults to an autogenerated name.
	"""
														type: "string"
													}
													patch: {
														description: "Patch defines how to perform the patch operation to daemonset"
														properties: {
															type: {
																description: """
	Type is the type of merge operation to perform

	By default, StrategicMerge is used as the patch type.
	"""
																type: "string"
															}
															value: {
																description:                            "Object contains the raw configuration for merged object"
																"x-kubernetes-preserve-unknown-fields": true
															}
														}
														required: ["value"]
														type: "object"
													}
													pod: {
														description: "Pod defines the desired specification of pod."
														properties: {
															affinity: {
																description: "If specified, the pod's scheduling constraints."
																properties: {
																	nodeAffinity: {
																		description: "Describes node affinity scheduling rules for the pod."
																		properties: {
																			preferredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	The scheduler will prefer to schedule pods to nodes that satisfy
	the affinity expressions specified by this field, but it may choose
	a node that violates one or more of the expressions. The node that is
	most preferred is the one with the greatest sum of weights, i.e.
	for each node that meets all of the scheduling requirements (resource
	request, requiredDuringScheduling affinity expressions, etc.),
	compute a sum by iterating through the elements of this field and adding
	"weight" to the sum if the node matches the corresponding matchExpressions; the
	node(s) with the highest sum are the most preferred.
	"""
																				items: {
																					description: """
	An empty preferred scheduling term matches all objects with implicit weight 0
	(i.e. it's a no-op). A null preferred scheduling term matches no objects (i.e. is also a no-op).
	"""
																					properties: {
																						preference: {
																							description: "A node selector term, associated with the corresponding weight."
																							properties: {
																								matchExpressions: {
																									description: "A list of node selector requirements by node's labels."
																									items: {
																										description: """
	A node selector requirement is a selector that contains values, a key, and an operator
	that relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "The label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	Represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	An array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. If the operator is Gt or Lt, the values
	array must have a single element, which will be interpreted as an integer.
	This array is replaced during a strategic merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								matchFields: {
																									description: "A list of node selector requirements by node's fields."
																									items: {
																										description: """
	A node selector requirement is a selector that contains values, a key, and an operator
	that relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "The label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	Represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	An array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. If the operator is Gt or Lt, the values
	array must have a single element, which will be interpreted as an integer.
	This array is replaced during a strategic merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						weight: {
																							description: "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100."
																							format:      "int32"
																							type:        "integer"
																						}
																					}
																					required: [
																						"preference",
																						"weight",
																					]
																					type: "object"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																			requiredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	If the affinity requirements specified by this field are not met at
	scheduling time, the pod will not be scheduled onto the node.
	If the affinity requirements specified by this field cease to be met
	at some point during pod execution (e.g. due to an update), the system
	may or may not try to eventually evict the pod from its node.
	"""
																				properties: nodeSelectorTerms: {
																					description: "Required. A list of node selector terms. The terms are ORed."
																					items: {
																						description: """
	A null or empty node selector term matches no objects. The requirements of
	them are ANDed.
	The TopologySelectorTerm type implements a subset of the NodeSelectorTerm.
	"""
																						properties: {
																							matchExpressions: {
																								description: "A list of node selector requirements by node's labels."
																								items: {
																									description: """
	A node selector requirement is a selector that contains values, a key, and an operator
	that relates the key and values.
	"""
																									properties: {
																										key: {
																											description: "The label key that the selector applies to."
																											type:        "string"
																										}
																										operator: {
																											description: """
	Represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
	"""
																											type: "string"
																										}
																										values: {
																											description: """
	An array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. If the operator is Gt or Lt, the values
	array must have a single element, which will be interpreted as an integer.
	This array is replaced during a strategic merge patch.
	"""
																											items: type: "string"
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																									}
																									required: [
																										"key",
																										"operator",
																									]
																									type: "object"
																								}
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																							matchFields: {
																								description: "A list of node selector requirements by node's fields."
																								items: {
																									description: """
	A node selector requirement is a selector that contains values, a key, and an operator
	that relates the key and values.
	"""
																									properties: {
																										key: {
																											description: "The label key that the selector applies to."
																											type:        "string"
																										}
																										operator: {
																											description: """
	Represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
	"""
																											type: "string"
																										}
																										values: {
																											description: """
	An array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. If the operator is Gt or Lt, the values
	array must have a single element, which will be interpreted as an integer.
	This array is replaced during a strategic merge patch.
	"""
																											items: type: "string"
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																									}
																									required: [
																										"key",
																										"operator",
																									]
																									type: "object"
																								}
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																						}
																						type:                    "object"
																						"x-kubernetes-map-type": "atomic"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				required: ["nodeSelectorTerms"]
																				type:                    "object"
																				"x-kubernetes-map-type": "atomic"
																			}
																		}
																		type: "object"
																	}
																	podAffinity: {
																		description: "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s))."
																		properties: {
																			preferredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	The scheduler will prefer to schedule pods to nodes that satisfy
	the affinity expressions specified by this field, but it may choose
	a node that violates one or more of the expressions. The node that is
	most preferred is the one with the greatest sum of weights, i.e.
	for each node that meets all of the scheduling requirements (resource
	request, requiredDuringScheduling affinity expressions, etc.),
	compute a sum by iterating through the elements of this field and adding
	"weight" to the sum if the node has pods which matches the corresponding podAffinityTerm; the
	node(s) with the highest sum are the most preferred.
	"""
																				items: {
																					description: "The weights of all of the matched WeightedPodAffinityTerm fields are added per-node to find the most preferred node(s)"
																					properties: {
																						podAffinityTerm: {
																							description: "Required. A pod affinity term, associated with the corresponding weight."
																							properties: {
																								labelSelector: {
																									description: """
	A label query over a set of resources, in this case pods.
	If it's null, this PodAffinityTerm matches with no Pods.
	"""
																									properties: {
																										matchExpressions: {
																											description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																											items: {
																												description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																												properties: {
																													key: {
																														description: "key is the label key that the selector applies to."
																														type:        "string"
																													}
																													operator: {
																														description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																														type: "string"
																													}
																													values: {
																														description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																														items: type: "string"
																														type:                     "array"
																														"x-kubernetes-list-type": "atomic"
																													}
																												}
																												required: [
																													"key",
																													"operator",
																												]
																												type: "object"
																											}
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																										matchLabels: {
																											additionalProperties: type: "string"
																											description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																											type: "object"
																										}
																									}
																									type:                    "object"
																									"x-kubernetes-map-type": "atomic"
																								}
																								matchLabelKeys: {
																									description: """
	MatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both matchLabelKeys and labelSelector.
	Also, matchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								mismatchLabelKeys: {
																									description: """
	MismatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both mismatchLabelKeys and labelSelector.
	Also, mismatchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								namespaceSelector: {
																									description: """
	A label query over the set of namespaces that the term applies to.
	The term is applied to the union of the namespaces selected by this field
	and the ones listed in the namespaces field.
	null selector and null or empty namespaces list means "this pod's namespace".
	An empty selector ({}) matches all namespaces.
	"""
																									properties: {
																										matchExpressions: {
																											description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																											items: {
																												description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																												properties: {
																													key: {
																														description: "key is the label key that the selector applies to."
																														type:        "string"
																													}
																													operator: {
																														description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																														type: "string"
																													}
																													values: {
																														description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																														items: type: "string"
																														type:                     "array"
																														"x-kubernetes-list-type": "atomic"
																													}
																												}
																												required: [
																													"key",
																													"operator",
																												]
																												type: "object"
																											}
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																										matchLabels: {
																											additionalProperties: type: "string"
																											description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																											type: "object"
																										}
																									}
																									type:                    "object"
																									"x-kubernetes-map-type": "atomic"
																								}
																								namespaces: {
																									description: """
	namespaces specifies a static list of namespace names that the term applies to.
	The term is applied to the union of the namespaces listed in this field
	and the ones selected by namespaceSelector.
	null or empty namespaces list and null namespaceSelector means "this pod's namespace".
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								topologyKey: {
																									description: """
	This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching
	the labelSelector in the specified namespaces, where co-located is defined as running on a node
	whose value of the label with key topologyKey matches that of any node on which any of the
	selected pods is running.
	Empty topologyKey is not allowed.
	"""
																									type: "string"
																								}
																							}
																							required: ["topologyKey"]
																							type: "object"
																						}
																						weight: {
																							description: """
	weight associated with matching the corresponding podAffinityTerm,
	in the range 1-100.
	"""
																							format: "int32"
																							type:   "integer"
																						}
																					}
																					required: [
																						"podAffinityTerm",
																						"weight",
																					]
																					type: "object"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																			requiredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	If the affinity requirements specified by this field are not met at
	scheduling time, the pod will not be scheduled onto the node.
	If the affinity requirements specified by this field cease to be met
	at some point during pod execution (e.g. due to a pod label update), the
	system may or may not try to eventually evict the pod from its node.
	When there are multiple elements, the lists of nodes corresponding to each
	podAffinityTerm are intersected, i.e. all terms must be satisfied.
	"""
																				items: {
																					description: """
	Defines a set of pods (namely those matching the labelSelector
	relative to the given namespace(s)) that this pod should be
	co-located (affinity) or not co-located (anti-affinity) with,
	where co-located is defined as running on a node whose value of
	the label with key <topologyKey> matches that of any node on which
	a pod of the set of pods is running
	"""
																					properties: {
																						labelSelector: {
																							description: """
	A label query over a set of resources, in this case pods.
	If it's null, this PodAffinityTerm matches with no Pods.
	"""
																							properties: {
																								matchExpressions: {
																									description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																									items: {
																										description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "key is the label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								matchLabels: {
																									additionalProperties: type: "string"
																									description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																									type: "object"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						matchLabelKeys: {
																							description: """
	MatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both matchLabelKeys and labelSelector.
	Also, matchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						mismatchLabelKeys: {
																							description: """
	MismatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both mismatchLabelKeys and labelSelector.
	Also, mismatchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						namespaceSelector: {
																							description: """
	A label query over the set of namespaces that the term applies to.
	The term is applied to the union of the namespaces selected by this field
	and the ones listed in the namespaces field.
	null selector and null or empty namespaces list means "this pod's namespace".
	An empty selector ({}) matches all namespaces.
	"""
																							properties: {
																								matchExpressions: {
																									description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																									items: {
																										description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "key is the label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								matchLabels: {
																									additionalProperties: type: "string"
																									description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																									type: "object"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						namespaces: {
																							description: """
	namespaces specifies a static list of namespace names that the term applies to.
	The term is applied to the union of the namespaces listed in this field
	and the ones selected by namespaceSelector.
	null or empty namespaces list and null namespaceSelector means "this pod's namespace".
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						topologyKey: {
																							description: """
	This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching
	the labelSelector in the specified namespaces, where co-located is defined as running on a node
	whose value of the label with key topologyKey matches that of any node on which any of the
	selected pods is running.
	Empty topologyKey is not allowed.
	"""
																							type: "string"
																						}
																					}
																					required: ["topologyKey"]
																					type: "object"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																		}
																		type: "object"
																	}
																	podAntiAffinity: {
																		description: "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s))."
																		properties: {
																			preferredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	The scheduler will prefer to schedule pods to nodes that satisfy
	the anti-affinity expressions specified by this field, but it may choose
	a node that violates one or more of the expressions. The node that is
	most preferred is the one with the greatest sum of weights, i.e.
	for each node that meets all of the scheduling requirements (resource
	request, requiredDuringScheduling anti-affinity expressions, etc.),
	compute a sum by iterating through the elements of this field and adding
	"weight" to the sum if the node has pods which matches the corresponding podAffinityTerm; the
	node(s) with the highest sum are the most preferred.
	"""
																				items: {
																					description: "The weights of all of the matched WeightedPodAffinityTerm fields are added per-node to find the most preferred node(s)"
																					properties: {
																						podAffinityTerm: {
																							description: "Required. A pod affinity term, associated with the corresponding weight."
																							properties: {
																								labelSelector: {
																									description: """
	A label query over a set of resources, in this case pods.
	If it's null, this PodAffinityTerm matches with no Pods.
	"""
																									properties: {
																										matchExpressions: {
																											description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																											items: {
																												description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																												properties: {
																													key: {
																														description: "key is the label key that the selector applies to."
																														type:        "string"
																													}
																													operator: {
																														description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																														type: "string"
																													}
																													values: {
																														description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																														items: type: "string"
																														type:                     "array"
																														"x-kubernetes-list-type": "atomic"
																													}
																												}
																												required: [
																													"key",
																													"operator",
																												]
																												type: "object"
																											}
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																										matchLabels: {
																											additionalProperties: type: "string"
																											description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																											type: "object"
																										}
																									}
																									type:                    "object"
																									"x-kubernetes-map-type": "atomic"
																								}
																								matchLabelKeys: {
																									description: """
	MatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both matchLabelKeys and labelSelector.
	Also, matchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								mismatchLabelKeys: {
																									description: """
	MismatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both mismatchLabelKeys and labelSelector.
	Also, mismatchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								namespaceSelector: {
																									description: """
	A label query over the set of namespaces that the term applies to.
	The term is applied to the union of the namespaces selected by this field
	and the ones listed in the namespaces field.
	null selector and null or empty namespaces list means "this pod's namespace".
	An empty selector ({}) matches all namespaces.
	"""
																									properties: {
																										matchExpressions: {
																											description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																											items: {
																												description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																												properties: {
																													key: {
																														description: "key is the label key that the selector applies to."
																														type:        "string"
																													}
																													operator: {
																														description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																														type: "string"
																													}
																													values: {
																														description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																														items: type: "string"
																														type:                     "array"
																														"x-kubernetes-list-type": "atomic"
																													}
																												}
																												required: [
																													"key",
																													"operator",
																												]
																												type: "object"
																											}
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																										matchLabels: {
																											additionalProperties: type: "string"
																											description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																											type: "object"
																										}
																									}
																									type:                    "object"
																									"x-kubernetes-map-type": "atomic"
																								}
																								namespaces: {
																									description: """
	namespaces specifies a static list of namespace names that the term applies to.
	The term is applied to the union of the namespaces listed in this field
	and the ones selected by namespaceSelector.
	null or empty namespaces list and null namespaceSelector means "this pod's namespace".
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								topologyKey: {
																									description: """
	This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching
	the labelSelector in the specified namespaces, where co-located is defined as running on a node
	whose value of the label with key topologyKey matches that of any node on which any of the
	selected pods is running.
	Empty topologyKey is not allowed.
	"""
																									type: "string"
																								}
																							}
																							required: ["topologyKey"]
																							type: "object"
																						}
																						weight: {
																							description: """
	weight associated with matching the corresponding podAffinityTerm,
	in the range 1-100.
	"""
																							format: "int32"
																							type:   "integer"
																						}
																					}
																					required: [
																						"podAffinityTerm",
																						"weight",
																					]
																					type: "object"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																			requiredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	If the anti-affinity requirements specified by this field are not met at
	scheduling time, the pod will not be scheduled onto the node.
	If the anti-affinity requirements specified by this field cease to be met
	at some point during pod execution (e.g. due to a pod label update), the
	system may or may not try to eventually evict the pod from its node.
	When there are multiple elements, the lists of nodes corresponding to each
	podAffinityTerm are intersected, i.e. all terms must be satisfied.
	"""
																				items: {
																					description: """
	Defines a set of pods (namely those matching the labelSelector
	relative to the given namespace(s)) that this pod should be
	co-located (affinity) or not co-located (anti-affinity) with,
	where co-located is defined as running on a node whose value of
	the label with key <topologyKey> matches that of any node on which
	a pod of the set of pods is running
	"""
																					properties: {
																						labelSelector: {
																							description: """
	A label query over a set of resources, in this case pods.
	If it's null, this PodAffinityTerm matches with no Pods.
	"""
																							properties: {
																								matchExpressions: {
																									description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																									items: {
																										description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "key is the label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								matchLabels: {
																									additionalProperties: type: "string"
																									description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																									type: "object"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						matchLabelKeys: {
																							description: """
	MatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both matchLabelKeys and labelSelector.
	Also, matchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						mismatchLabelKeys: {
																							description: """
	MismatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both mismatchLabelKeys and labelSelector.
	Also, mismatchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						namespaceSelector: {
																							description: """
	A label query over the set of namespaces that the term applies to.
	The term is applied to the union of the namespaces selected by this field
	and the ones listed in the namespaces field.
	null selector and null or empty namespaces list means "this pod's namespace".
	An empty selector ({}) matches all namespaces.
	"""
																							properties: {
																								matchExpressions: {
																									description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																									items: {
																										description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "key is the label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								matchLabels: {
																									additionalProperties: type: "string"
																									description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																									type: "object"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						namespaces: {
																							description: """
	namespaces specifies a static list of namespace names that the term applies to.
	The term is applied to the union of the namespaces listed in this field
	and the ones selected by namespaceSelector.
	null or empty namespaces list and null namespaceSelector means "this pod's namespace".
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						topologyKey: {
																							description: """
	This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching
	the labelSelector in the specified namespaces, where co-located is defined as running on a node
	whose value of the label with key topologyKey matches that of any node on which any of the
	selected pods is running.
	Empty topologyKey is not allowed.
	"""
																							type: "string"
																						}
																					}
																					required: ["topologyKey"]
																					type: "object"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																		}
																		type: "object"
																	}
																}
																type: "object"
															}
															annotations: {
																additionalProperties: type: "string"
																description: """
	Annotations are the annotations that should be appended to the pods.
	By default, no pod annotations are appended.
	"""
																type: "object"
															}
															imagePullSecrets: {
																description: """
	ImagePullSecrets is an optional list of references to secrets
	in the same namespace to use for pulling any of the images used by this PodSpec.
	If specified, these secrets will be passed to individual puller implementations for them to use.
	More info: https://kubernetes.io/docs/concepts/containers/images#specifying-imagepullsecrets-on-a-pod
	"""
																items: {
																	description: """
	LocalObjectReference contains enough information to let you locate the
	referenced object inside the same namespace.
	"""
																	properties: name: {
																		default: ""
																		description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																		type: "string"
																	}
																	type:                    "object"
																	"x-kubernetes-map-type": "atomic"
																}
																type: "array"
															}
															labels: {
																additionalProperties: type: "string"
																description: """
	Labels are the additional labels that should be tagged to the pods.
	By default, no additional pod labels are tagged.
	"""
																type: "object"
															}
															nodeSelector: {
																additionalProperties: type: "string"
																description: """
	NodeSelector is a selector which must be true for the pod to fit on a node.
	Selector which must match a node's labels for the pod to be scheduled on that node.
	More info: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
	"""
																type: "object"
															}
															securityContext: {
																description: """
	SecurityContext holds pod-level security attributes and common container settings.
	Optional: Defaults to empty.  See type description for default values of each field.
	"""
																properties: {
																	appArmorProfile: {
																		description: """
	appArmorProfile is the AppArmor options to use by the containers in this pod.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			localhostProfile: {
																				description: """
	localhostProfile indicates a profile loaded on the node that should be used.
	The profile must be preconfigured on the node to work.
	Must match the loaded name of the profile.
	Must be set if and only if type is "Localhost".
	"""
																				type: "string"
																			}
																			type: {
																				description: """
	type indicates which kind of AppArmor profile will be applied.
	Valid options are:
	  Localhost - a profile pre-loaded on the node.
	  RuntimeDefault - the container runtime's default profile.
	  Unconfined - no AppArmor enforcement.
	"""
																				type: "string"
																			}
																		}
																		required: ["type"]
																		type: "object"
																	}
																	fsGroup: {
																		description: """
	A special supplemental group that applies to all containers in a pod.
	Some volume types allow the Kubelet to change the ownership of that volume
	to be owned by the pod:

	1. The owning GID will be the FSGroup
	2. The setgid bit is set (new files created in the volume will be owned by FSGroup)
	3. The permission bits are OR'd with rw-rw----

	If unset, the Kubelet will not modify the ownership and permissions of any volume.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		format: "int64"
																		type:   "integer"
																	}
																	fsGroupChangePolicy: {
																		description: """
	fsGroupChangePolicy defines behavior of changing ownership and permission of the volume
	before being exposed inside Pod. This field will only apply to
	volume types which support fsGroup based ownership(and permissions).
	It will have no effect on ephemeral volume types such as: secret, configmaps
	and emptydir.
	Valid values are "OnRootMismatch" and "Always". If not specified, "Always" is used.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "string"
																	}
																	runAsGroup: {
																		description: """
	The GID to run the entrypoint of the container process.
	Uses runtime default if unset.
	May also be set in SecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence
	for that container.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		format: "int64"
																		type:   "integer"
																	}
																	runAsNonRoot: {
																		description: """
	Indicates that the container must run as a non-root user.
	If true, the Kubelet will validate the image at runtime to ensure that it
	does not run as UID 0 (root) and fail to start the container if it does.
	If unset or false, no such validation will be performed.
	May also be set in SecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	"""
																		type: "boolean"
																	}
																	runAsUser: {
																		description: """
	The UID to run the entrypoint of the container process.
	Defaults to user specified in image metadata if unspecified.
	May also be set in SecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence
	for that container.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		format: "int64"
																		type:   "integer"
																	}
																	seLinuxOptions: {
																		description: """
	The SELinux context to be applied to all containers.
	If unspecified, the container runtime will allocate a random SELinux context for each
	container.  May also be set in SecurityContext.  If set in
	both SecurityContext and PodSecurityContext, the value specified in SecurityContext
	takes precedence for that container.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			level: {
																				description: "Level is SELinux level label that applies to the container."
																				type:        "string"
																			}
																			role: {
																				description: "Role is a SELinux role label that applies to the container."
																				type:        "string"
																			}
																			type: {
																				description: "Type is a SELinux type label that applies to the container."
																				type:        "string"
																			}
																			user: {
																				description: "User is a SELinux user label that applies to the container."
																				type:        "string"
																			}
																		}
																		type: "object"
																	}
																	seccompProfile: {
																		description: """
	The seccomp options to use by the containers in this pod.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			localhostProfile: {
																				description: """
	localhostProfile indicates a profile defined in a file on the node should be used.
	The profile must be preconfigured on the node to work.
	Must be a descending path, relative to the kubelet's configured seccomp profile location.
	Must be set if type is "Localhost". Must NOT be set for any other type.
	"""
																				type: "string"
																			}
																			type: {
																				description: """
	type indicates which kind of seccomp profile will be applied.
	Valid options are:

	Localhost - a profile defined in a file on the node should be used.
	RuntimeDefault - the container runtime default profile should be used.
	Unconfined - no profile should be applied.
	"""
																				type: "string"
																			}
																		}
																		required: ["type"]
																		type: "object"
																	}
																	supplementalGroups: {
																		description: """
	A list of groups applied to the first process run in each container, in
	addition to the container's primary GID and fsGroup (if specified).  If
	the SupplementalGroupsPolicy feature is enabled, the
	supplementalGroupsPolicy field determines whether these are in addition
	to or instead of any group memberships defined in the container image.
	If unspecified, no additional groups are added, though group memberships
	defined in the container image may still be used, depending on the
	supplementalGroupsPolicy field.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		items: {
																			format: "int64"
																			type:   "integer"
																		}
																		type:                     "array"
																		"x-kubernetes-list-type": "atomic"
																	}
																	supplementalGroupsPolicy: {
																		description: """
	Defines how supplemental groups of the first container processes are calculated.
	Valid values are "Merge" and "Strict". If not specified, "Merge" is used.
	(Alpha) Using the field requires the SupplementalGroupsPolicy feature gate to be enabled
	and the container runtime must implement support for this feature.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "string"
																	}
																	sysctls: {
																		description: """
	Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported
	sysctls (by the container runtime) might fail to launch.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		items: {
																			description: "Sysctl defines a kernel parameter to be set"
																			properties: {
																				name: {
																					description: "Name of a property to set"
																					type:        "string"
																				}
																				value: {
																					description: "Value of a property to set"
																					type:        "string"
																				}
																			}
																			required: [
																				"name",
																				"value",
																			]
																			type: "object"
																		}
																		type:                     "array"
																		"x-kubernetes-list-type": "atomic"
																	}
																	windowsOptions: {
																		description: """
	The Windows specific settings applied to all containers.
	If unspecified, the options within a container's SecurityContext will be used.
	If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is linux.
	"""
																		properties: {
																			gmsaCredentialSpec: {
																				description: """
	GMSACredentialSpec is where the GMSA admission webhook
	(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the
	GMSA credential spec named by the GMSACredentialSpecName field.
	"""
																				type: "string"
																			}
																			gmsaCredentialSpecName: {
																				description: "GMSACredentialSpecName is the name of the GMSA credential spec to use."
																				type:        "string"
																			}
																			hostProcess: {
																				description: """
	HostProcess determines if a container should be run as a 'Host Process' container.
	All of a Pod's containers must have the same effective HostProcess value
	(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).
	In addition, if HostProcess is true then HostNetwork must also be set to true.
	"""
																				type: "boolean"
																			}
																			runAsUserName: {
																				description: """
	The UserName in Windows to run the entrypoint of the container process.
	Defaults to the user specified in image metadata if unspecified.
	May also be set in PodSecurityContext. If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	"""
																				type: "string"
																			}
																		}
																		type: "object"
																	}
																}
																type: "object"
															}
															tolerations: {
																description: "If specified, the pod's tolerations."
																items: {
																	description: """
	The pod this Toleration is attached to tolerates any taint that matches
	the triple <key,value,effect> using the matching operator <operator>.
	"""
																	properties: {
																		effect: {
																			description: """
	Effect indicates the taint effect to match. Empty means match all taint effects.
	When specified, allowed values are NoSchedule, PreferNoSchedule and NoExecute.
	"""
																			type: "string"
																		}
																		key: {
																			description: """
	Key is the taint key that the toleration applies to. Empty means match all taint keys.
	If the key is empty, operator must be Exists; this combination means to match all values and all keys.
	"""
																			type: "string"
																		}
																		operator: {
																			description: """
	Operator represents a key's relationship to the value.
	Valid operators are Exists and Equal. Defaults to Equal.
	Exists is equivalent to wildcard for value, so that a pod can
	tolerate all taints of a particular category.
	"""
																			type: "string"
																		}
																		tolerationSeconds: {
																			description: """
	TolerationSeconds represents the period of time the toleration (which must be
	of effect NoExecute, otherwise this field is ignored) tolerates the taint. By default,
	it is not set, which means tolerate the taint forever (do not evict). Zero and
	negative values will be treated as 0 (evict immediately) by the system.
	"""
																			format: "int64"
																			type:   "integer"
																		}
																		value: {
																			description: """
	Value is the taint value the toleration matches to.
	If the operator is Exists, the value should be empty, otherwise just a regular string.
	"""
																			type: "string"
																		}
																	}
																	type: "object"
																}
																type: "array"
															}
															topologySpreadConstraints: {
																description: """
	TopologySpreadConstraints describes how a group of pods ought to spread across topology
	domains. Scheduler will schedule pods in a way which abides by the constraints.
	All topologySpreadConstraints are ANDed.
	"""
																items: {
																	description: "TopologySpreadConstraint specifies how to spread matching pods among the given topology."
																	properties: {
																		labelSelector: {
																			description: """
	LabelSelector is used to find matching pods.
	Pods that match this label selector are counted to determine the number of pods
	in their corresponding topology domain.
	"""
																			properties: {
																				matchExpressions: {
																					description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																					items: {
																						description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																						properties: {
																							key: {
																								description: "key is the label key that the selector applies to."
																								type:        "string"
																							}
																							operator: {
																								description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																								type: "string"
																							}
																							values: {
																								description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																								items: type: "string"
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																						}
																						required: [
																							"key",
																							"operator",
																						]
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				matchLabels: {
																					additionalProperties: type: "string"
																					description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																					type: "object"
																				}
																			}
																			type:                    "object"
																			"x-kubernetes-map-type": "atomic"
																		}
																		matchLabelKeys: {
																			description: """
	MatchLabelKeys is a set of pod label keys to select the pods over which
	spreading will be calculated. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are ANDed with labelSelector
	to select the group of existing pods over which spreading will be calculated
	for the incoming pod. The same key is forbidden to exist in both MatchLabelKeys and LabelSelector.
	MatchLabelKeys cannot be set when LabelSelector isn't set.
	Keys that don't exist in the incoming pod labels will
	be ignored. A null or empty list means only match against labelSelector.

	This is a beta field and requires the MatchLabelKeysInPodTopologySpread feature gate to be enabled (enabled by default).
	"""
																			items: type: "string"
																			type:                     "array"
																			"x-kubernetes-list-type": "atomic"
																		}
																		maxSkew: {
																			description: """
	MaxSkew describes the degree to which pods may be unevenly distributed.
	When `whenUnsatisfiable=DoNotSchedule`, it is the maximum permitted difference
	between the number of matching pods in the target topology and the global minimum.
	The global minimum is the minimum number of matching pods in an eligible domain
	or zero if the number of eligible domains is less than MinDomains.
	For example, in a 3-zone cluster, MaxSkew is set to 1, and pods with the same
	labelSelector spread as 2/2/1:
	In this case, the global minimum is 1.
	| zone1 | zone2 | zone3 |
	|  P P  |  P P  |   P   |
	- if MaxSkew is 1, incoming pod can only be scheduled to zone3 to become 2/2/2;
	scheduling it onto zone1(zone2) would make the ActualSkew(3-1) on zone1(zone2)
	violate MaxSkew(1).
	- if MaxSkew is 2, incoming pod can be scheduled onto any zone.
	When `whenUnsatisfiable=ScheduleAnyway`, it is used to give higher precedence
	to topologies that satisfy it.
	It's a required field. Default value is 1 and 0 is not allowed.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		minDomains: {
																			description: """
	MinDomains indicates a minimum number of eligible domains.
	When the number of eligible domains with matching topology keys is less than minDomains,
	Pod Topology Spread treats "global minimum" as 0, and then the calculation of Skew is performed.
	And when the number of eligible domains with matching topology keys equals or greater than minDomains,
	this value has no effect on scheduling.
	As a result, when the number of eligible domains is less than minDomains,
	scheduler won't schedule more than maxSkew Pods to those domains.
	If value is nil, the constraint behaves as if MinDomains is equal to 1.
	Valid values are integers greater than 0.
	When value is not nil, WhenUnsatisfiable must be DoNotSchedule.

	For example, in a 3-zone cluster, MaxSkew is set to 2, MinDomains is set to 5 and pods with the same
	labelSelector spread as 2/2/2:
	| zone1 | zone2 | zone3 |
	|  P P  |  P P  |  P P  |
	The number of domains is less than 5(MinDomains), so "global minimum" is treated as 0.
	In this situation, new pod with the same labelSelector cannot be scheduled,
	because computed skew will be 3(3 - 0) if new Pod is scheduled to any of the three zones,
	it will violate MaxSkew.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		nodeAffinityPolicy: {
																			description: """
	NodeAffinityPolicy indicates how we will treat Pod's nodeAffinity/nodeSelector
	when calculating pod topology spread skew. Options are:
	- Honor: only nodes matching nodeAffinity/nodeSelector are included in the calculations.
	- Ignore: nodeAffinity/nodeSelector are ignored. All nodes are included in the calculations.

	If this value is nil, the behavior is equivalent to the Honor policy.
	This is a beta-level feature default enabled by the NodeInclusionPolicyInPodTopologySpread feature flag.
	"""
																			type: "string"
																		}
																		nodeTaintsPolicy: {
																			description: """
	NodeTaintsPolicy indicates how we will treat node taints when calculating
	pod topology spread skew. Options are:
	- Honor: nodes without taints, along with tainted nodes for which the incoming pod
	has a toleration, are included.
	- Ignore: node taints are ignored. All nodes are included.

	If this value is nil, the behavior is equivalent to the Ignore policy.
	This is a beta-level feature default enabled by the NodeInclusionPolicyInPodTopologySpread feature flag.
	"""
																			type: "string"
																		}
																		topologyKey: {
																			description: """
	TopologyKey is the key of node labels. Nodes that have a label with this key
	and identical values are considered to be in the same topology.
	We consider each <key, value> as a "bucket", and try to put balanced number
	of pods into each bucket.
	We define a domain as a particular instance of a topology.
	Also, we define an eligible domain as a domain whose nodes meet the requirements of
	nodeAffinityPolicy and nodeTaintsPolicy.
	e.g. If TopologyKey is "kubernetes.io/hostname", each Node is a domain of that topology.
	And, if TopologyKey is "topology.kubernetes.io/zone", each zone is a domain of that topology.
	It's a required field.
	"""
																			type: "string"
																		}
																		whenUnsatisfiable: {
																			description: """
	WhenUnsatisfiable indicates how to deal with a pod if it doesn't satisfy
	the spread constraint.
	- DoNotSchedule (default) tells the scheduler not to schedule it.
	- ScheduleAnyway tells the scheduler to schedule the pod in any location,
	  but giving higher precedence to topologies that would help reduce the
	  skew.
	A constraint is considered "Unsatisfiable" for an incoming pod
	if and only if every possible node assignment for that pod would violate
	"MaxSkew" on some topology.
	For example, in a 3-zone cluster, MaxSkew is set to 1, and pods with the same
	labelSelector spread as 3/1/1:
	| zone1 | zone2 | zone3 |
	| P P P |   P   |   P   |
	If WhenUnsatisfiable is set to DoNotSchedule, incoming pod can only be scheduled
	to zone2(zone3) to become 3/2/1(3/1/2) as ActualSkew(2-1) on zone2(zone3) satisfies
	MaxSkew(1). In other words, the cluster can still be imbalanced, but scheduler
	won't make it *more* imbalanced.
	It's a required field.
	"""
																			type: "string"
																		}
																	}
																	required: [
																		"maxSkew",
																		"topologyKey",
																		"whenUnsatisfiable",
																	]
																	type: "object"
																}
																type: "array"
															}
															volumes: {
																description: """
	Volumes that can be mounted by containers belonging to the pod.
	More info: https://kubernetes.io/docs/concepts/storage/volumes
	"""
																items: {
																	description: "Volume represents a named volume in a pod that may be accessed by any container in the pod."
																	properties: {
																		awsElasticBlockStore: {
																			description: """
	awsElasticBlockStore represents an AWS Disk resource that is attached to a
	kubelet's host machine and then exposed to the pod.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore
	"""
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type of the volume that you want to mount.
	Tip: Ensure that the filesystem type is supported by the host operating system.
	Examples: "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore
	"""
																					type: "string"
																				}
																				partition: {
																					description: """
	partition is the partition in the volume that you want to mount.
	If omitted, the default is to mount by volume name.
	Examples: For volume /dev/sda1, you specify the partition as "1".
	Similarly, the volume partition for /dev/sda is "0" (or you can leave the property empty).
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				readOnly: {
																					description: """
	readOnly value true will force the readOnly setting in VolumeMounts.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore
	"""
																					type: "boolean"
																				}
																				volumeID: {
																					description: """
	volumeID is unique ID of the persistent disk resource in AWS (Amazon EBS volume).
	More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore
	"""
																					type: "string"
																				}
																			}
																			required: ["volumeID"]
																			type: "object"
																		}
																		azureDisk: {
																			description: "azureDisk represents an Azure Data Disk mount on the host and bind mount to the pod."
																			properties: {
																				cachingMode: {
																					description: "cachingMode is the Host Caching mode: None, Read Only, Read Write."
																					type:        "string"
																				}
																				diskName: {
																					description: "diskName is the Name of the data disk in the blob storage"
																					type:        "string"
																				}
																				diskURI: {
																					description: "diskURI is the URI of data disk in the blob storage"
																					type:        "string"
																				}
																				fsType: {
																					default: "ext4"
																					description: """
	fsType is Filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				kind: {
																					description: "kind expected values are Shared: multiple blob disks per storage account  Dedicated: single blob disk per storage account  Managed: azure managed data disk (only in managed availability set). defaults to shared"
																					type:        "string"
																				}
																				readOnly: {
																					default: false
																					description: """
	readOnly Defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																			}
																			required: [
																				"diskName",
																				"diskURI",
																			]
																			type: "object"
																		}
																		azureFile: {
																			description: "azureFile represents an Azure File Service mount on the host and bind mount to the pod."
																			properties: {
																				readOnly: {
																					description: """
	readOnly defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				secretName: {
																					description: "secretName is the  name of secret that contains Azure Storage Account Name and Key"
																					type:        "string"
																				}
																				shareName: {
																					description: "shareName is the azure share Name"
																					type:        "string"
																				}
																			}
																			required: [
																				"secretName",
																				"shareName",
																			]
																			type: "object"
																		}
																		cephfs: {
																			description: "cephFS represents a Ceph FS mount on the host that shares a pod's lifetime"
																			properties: {
																				monitors: {
																					description: """
	monitors is Required: Monitors is a collection of Ceph monitors
	More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it
	"""
																					items: type: "string"
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				path: {
																					description: "path is Optional: Used as the mounted root, rather than the full Ceph tree, default is /"
																					type:        "string"
																				}
																				readOnly: {
																					description: """
	readOnly is Optional: Defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it
	"""
																					type: "boolean"
																				}
																				secretFile: {
																					description: """
	secretFile is Optional: SecretFile is the path to key ring for User, default is /etc/ceph/user.secret
	More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																				secretRef: {
																					description: """
	secretRef is Optional: SecretRef is reference to the authentication secret for User, default is empty.
	More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				user: {
																					description: """
	user is optional: User is the rados user name, default is admin
	More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																			}
																			required: ["monitors"]
																			type: "object"
																		}
																		cinder: {
																			description: """
	cinder represents a cinder volume attached and mounted on kubelets host machine.
	More info: https://examples.k8s.io/mysql-cinder-pd/README.md
	"""
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Examples: "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	More info: https://examples.k8s.io/mysql-cinder-pd/README.md
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	More info: https://examples.k8s.io/mysql-cinder-pd/README.md
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: """
	secretRef is optional: points to a secret object containing parameters used to connect
	to OpenStack.
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				volumeID: {
																					description: """
	volumeID used to identify the volume in cinder.
	More info: https://examples.k8s.io/mysql-cinder-pd/README.md
	"""
																					type: "string"
																				}
																			}
																			required: ["volumeID"]
																			type: "object"
																		}
																		configMap: {
																			description: "configMap represents a configMap that should populate this volume"
																			properties: {
																				defaultMode: {
																					description: """
	defaultMode is optional: mode bits used to set permissions on created files by default.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	Defaults to 0644.
	Directories within the path are not affected by this setting.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				items: {
																					description: """
	items if unspecified, each key-value pair in the Data field of the referenced
	ConfigMap will be projected into the volume as a file whose name is the
	key and content is the value. If specified, the listed keys will be
	projected into the specified paths, and unlisted keys will not be
	present. If a key is specified which is not present in the ConfigMap,
	the volume setup will error unless it is marked optional. Paths must be
	relative and may not contain the '..' path or start with '..'.
	"""
																					items: {
																						description: "Maps a string key to a path within a volume."
																						properties: {
																							key: {
																								description: "key is the key to project."
																								type:        "string"
																							}
																							mode: {
																								description: """
	mode is Optional: mode bits used to set permissions on this file.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																								format: "int32"
																								type:   "integer"
																							}
																							path: {
																								description: """
	path is the relative path of the file to map the key to.
	May not be an absolute path.
	May not contain the path element '..'.
	May not start with the string '..'.
	"""
																								type: "string"
																							}
																						}
																						required: [
																							"key",
																							"path",
																						]
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				name: {
																					default: ""
																					description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																					type: "string"
																				}
																				optional: {
																					description: "optional specify whether the ConfigMap or its keys must be defined"
																					type:        "boolean"
																				}
																			}
																			type:                    "object"
																			"x-kubernetes-map-type": "atomic"
																		}
																		csi: {
																			description: "csi (Container Storage Interface) represents ephemeral storage that is handled by certain external CSI drivers (Beta feature)."
																			properties: {
																				driver: {
																					description: """
	driver is the name of the CSI driver that handles this volume.
	Consult with your admin for the correct name as registered in the cluster.
	"""
																					type: "string"
																				}
																				fsType: {
																					description: """
	fsType to mount. Ex. "ext4", "xfs", "ntfs".
	If not provided, the empty value is passed to the associated CSI driver
	which will determine the default filesystem to apply.
	"""
																					type: "string"
																				}
																				nodePublishSecretRef: {
																					description: """
	nodePublishSecretRef is a reference to the secret object containing
	sensitive information to pass to the CSI driver to complete the CSI
	NodePublishVolume and NodeUnpublishVolume calls.
	This field is optional, and  may be empty if no secret is required. If the
	secret object contains more than one secret, all secret references are passed.
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				readOnly: {
																					description: """
	readOnly specifies a read-only configuration for the volume.
	Defaults to false (read/write).
	"""
																					type: "boolean"
																				}
																				volumeAttributes: {
																					additionalProperties: type: "string"
																					description: """
	volumeAttributes stores driver-specific properties that are passed to the CSI
	driver. Consult your driver's documentation for supported values.
	"""
																					type: "object"
																				}
																			}
																			required: ["driver"]
																			type: "object"
																		}
																		downwardAPI: {
																			description: "downwardAPI represents downward API about the pod that should populate this volume"
																			properties: {
																				defaultMode: {
																					description: """
	Optional: mode bits to use on created files by default. Must be a
	Optional: mode bits used to set permissions on created files by default.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	Defaults to 0644.
	Directories within the path are not affected by this setting.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				items: {
																					description: "Items is a list of downward API volume file"
																					items: {
																						description: "DownwardAPIVolumeFile represents information to create the file containing the pod field"
																						properties: {
																							fieldRef: {
																								description: "Required: Selects a field of the pod: only annotations, labels, name, namespace and uid are supported."
																								properties: {
																									apiVersion: {
																										description: "Version of the schema the FieldPath is written in terms of, defaults to \"v1\"."
																										type:        "string"
																									}
																									fieldPath: {
																										description: "Path of the field to select in the specified API version."
																										type:        "string"
																									}
																								}
																								required: ["fieldPath"]
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																							mode: {
																								description: """
	Optional: mode bits used to set permissions on this file, must be an octal value
	between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																								format: "int32"
																								type:   "integer"
																							}
																							path: {
																								description: "Required: Path is  the relative path name of the file to be created. Must not be absolute or contain the '..' path. Must be utf-8 encoded. The first item of the relative path must not start with '..'"
																								type:        "string"
																							}
																							resourceFieldRef: {
																								description: """
	Selects a resource of the container: only resources limits and requests
	(limits.cpu, limits.memory, requests.cpu and requests.memory) are currently supported.
	"""
																								properties: {
																									containerName: {
																										description: "Container name: required for volumes, optional for env vars"
																										type:        "string"
																									}
																									divisor: {
																										anyOf: [{
																											type: "integer"
																										}, {
																											type: "string"
																										}]
																										description:                  "Specifies the output format of the exposed resources, defaults to \"1\""
																										pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																										"x-kubernetes-int-or-string": true
																									}
																									resource: {
																										description: "Required: resource to select"
																										type:        "string"
																									}
																								}
																								required: ["resource"]
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																						}
																						required: ["path"]
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																			}
																			type: "object"
																		}
																		emptyDir: {
																			description: """
	emptyDir represents a temporary directory that shares a pod's lifetime.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir
	"""
																			properties: {
																				medium: {
																					description: """
	medium represents what type of storage medium should back this directory.
	The default is "" which means to use the node's default medium.
	Must be an empty string (default) or Memory.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir
	"""
																					type: "string"
																				}
																				sizeLimit: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	sizeLimit is the total amount of local storage required for this EmptyDir volume.
	The size limit is also applicable for memory medium.
	The maximum usage on memory medium EmptyDir would be the minimum value between
	the SizeLimit specified here and the sum of memory limits of all containers in a pod.
	The default is nil which means that the limit is undefined.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir
	"""
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																			}
																			type: "object"
																		}
																		ephemeral: {
																			description: """
	ephemeral represents a volume that is handled by a cluster storage driver.
	The volume's lifecycle is tied to the pod that defines it - it will be created before the pod starts,
	and deleted when the pod is removed.

	Use this if:
	a) the volume is only needed while the pod runs,
	b) features of normal volumes like restoring from snapshot or capacity
	   tracking are needed,
	c) the storage driver is specified through a storage class, and
	d) the storage driver supports dynamic volume provisioning through
	   a PersistentVolumeClaim (see EphemeralVolumeSource for more
	   information on the connection between this volume type
	   and PersistentVolumeClaim).

	Use PersistentVolumeClaim or one of the vendor-specific
	APIs for volumes that persist for longer than the lifecycle
	of an individual pod.

	Use CSI for light-weight local ephemeral volumes if the CSI driver is meant to
	be used that way - see the documentation of the driver for
	more information.

	A pod can use both types of ephemeral volumes and
	persistent volumes at the same time.
	"""
																			properties: volumeClaimTemplate: {
																				description: """
	Will be used to create a stand-alone PVC to provision the volume.
	The pod in which this EphemeralVolumeSource is embedded will be the
	owner of the PVC, i.e. the PVC will be deleted together with the
	pod.  The name of the PVC will be `<pod name>-<volume name>` where
	`<volume name>` is the name from the `PodSpec.Volumes` array
	entry. Pod validation will reject the pod if the concatenated name
	is not valid for a PVC (for example, too long).

	An existing PVC with that name that is not owned by the pod
	will *not* be used for the pod to avoid using an unrelated
	volume by mistake. Starting the pod is then blocked until
	the unrelated PVC is removed. If such a pre-created PVC is
	meant to be used by the pod, the PVC has to updated with an
	owner reference to the pod once the pod exists. Normally
	this should not be necessary, but it may be useful when
	manually reconstructing a broken cluster.

	This field is read-only and no changes will be made by Kubernetes
	to the PVC after it has been created.

	Required, must not be nil.
	"""
																				properties: {
																					metadata: {
																						description: """
	May contain labels and annotations that will be copied into the PVC
	when creating it. No other fields are allowed and will be rejected during
	validation.
	"""
																						type: "object"
																					}
																					spec: {
																						description: """
	The specification for the PersistentVolumeClaim. The entire content is
	copied unchanged into the PVC that gets created from this
	template. The same fields as in a PersistentVolumeClaim
	are also valid here.
	"""
																						properties: {
																							accessModes: {
																								description: """
	accessModes contains the desired access modes the volume should have.
	More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes-1
	"""
																								items: type: "string"
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																							dataSource: {
																								description: """
	dataSource field can be used to specify either:
	* An existing VolumeSnapshot object (snapshot.storage.k8s.io/VolumeSnapshot)
	* An existing PVC (PersistentVolumeClaim)
	If the provisioner or an external controller can support the specified data source,
	it will create a new volume based on the contents of the specified data source.
	When the AnyVolumeDataSource feature gate is enabled, dataSource contents will be copied to dataSourceRef,
	and dataSourceRef contents will be copied to dataSource when dataSourceRef.namespace is not specified.
	If the namespace is specified, then dataSourceRef will not be copied to dataSource.
	"""
																								properties: {
																									apiGroup: {
																										description: """
	APIGroup is the group for the resource being referenced.
	If APIGroup is not specified, the specified Kind must be in the core API group.
	For any other third-party types, APIGroup is required.
	"""
																										type: "string"
																									}
																									kind: {
																										description: "Kind is the type of resource being referenced"
																										type:        "string"
																									}
																									name: {
																										description: "Name is the name of resource being referenced"
																										type:        "string"
																									}
																								}
																								required: [
																									"kind",
																									"name",
																								]
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																							dataSourceRef: {
																								description: """
	dataSourceRef specifies the object from which to populate the volume with data, if a non-empty
	volume is desired. This may be any object from a non-empty API group (non
	core object) or a PersistentVolumeClaim object.
	When this field is specified, volume binding will only succeed if the type of
	the specified object matches some installed volume populator or dynamic
	provisioner.
	This field will replace the functionality of the dataSource field and as such
	if both fields are non-empty, they must have the same value. For backwards
	compatibility, when namespace isn't specified in dataSourceRef,
	both fields (dataSource and dataSourceRef) will be set to the same
	value automatically if one of them is empty and the other is non-empty.
	When namespace is specified in dataSourceRef,
	dataSource isn't set to the same value and must be empty.
	There are three important differences between dataSource and dataSourceRef:
	* While dataSource only allows two specific types of objects, dataSourceRef
	  allows any non-core object, as well as PersistentVolumeClaim objects.
	* While dataSource ignores disallowed values (dropping them), dataSourceRef
	  preserves all values, and generates an error if a disallowed value is
	  specified.
	* While dataSource only allows local objects, dataSourceRef allows objects
	  in any namespaces.
	(Beta) Using this field requires the AnyVolumeDataSource feature gate to be enabled.
	(Alpha) Using the namespace field of dataSourceRef requires the CrossNamespaceVolumeDataSource feature gate to be enabled.
	"""
																								properties: {
																									apiGroup: {
																										description: """
	APIGroup is the group for the resource being referenced.
	If APIGroup is not specified, the specified Kind must be in the core API group.
	For any other third-party types, APIGroup is required.
	"""
																										type: "string"
																									}
																									kind: {
																										description: "Kind is the type of resource being referenced"
																										type:        "string"
																									}
																									name: {
																										description: "Name is the name of resource being referenced"
																										type:        "string"
																									}
																									namespace: {
																										description: """
	Namespace is the namespace of resource being referenced
	Note that when a namespace is specified, a gateway.networking.k8s.io/ReferenceGrant object is required in the referent namespace to allow that namespace's owner to accept the reference. See the ReferenceGrant documentation for details.
	(Alpha) This field requires the CrossNamespaceVolumeDataSource feature gate to be enabled.
	"""
																										type: "string"
																									}
																								}
																								required: [
																									"kind",
																									"name",
																								]
																								type: "object"
																							}
																							resources: {
																								description: """
	resources represents the minimum resources the volume should have.
	If RecoverVolumeExpansionFailure feature is enabled users are allowed to specify resource requirements
	that are lower than previous value but must still be higher than capacity recorded in the
	status field of the claim.
	More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#resources
	"""
																								properties: {
																									limits: {
																										additionalProperties: {
																											anyOf: [{
																												type: "integer"
																											}, {
																												type: "string"
																											}]
																											pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																											"x-kubernetes-int-or-string": true
																										}
																										description: """
	Limits describes the maximum amount of compute resources allowed.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																										type: "object"
																									}
																									requests: {
																										additionalProperties: {
																											anyOf: [{
																												type: "integer"
																											}, {
																												type: "string"
																											}]
																											pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																											"x-kubernetes-int-or-string": true
																										}
																										description: """
	Requests describes the minimum amount of compute resources required.
	If Requests is omitted for a container, it defaults to Limits if that is explicitly specified,
	otherwise to an implementation-defined value. Requests cannot exceed Limits.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																										type: "object"
																									}
																								}
																								type: "object"
																							}
																							selector: {
																								description: "selector is a label query over volumes to consider for binding."
																								properties: {
																									matchExpressions: {
																										description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																										items: {
																											description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																											properties: {
																												key: {
																													description: "key is the label key that the selector applies to."
																													type:        "string"
																												}
																												operator: {
																													description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																													type: "string"
																												}
																												values: {
																													description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																													items: type: "string"
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																											}
																											required: [
																												"key",
																												"operator",
																											]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									matchLabels: {
																										additionalProperties: type: "string"
																										description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																										type: "object"
																									}
																								}
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																							storageClassName: {
																								description: """
	storageClassName is the name of the StorageClass required by the claim.
	More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#class-1
	"""
																								type: "string"
																							}
																							volumeAttributesClassName: {
																								description: """
	volumeAttributesClassName may be used to set the VolumeAttributesClass used by this claim.
	If specified, the CSI driver will create or update the volume with the attributes defined
	in the corresponding VolumeAttributesClass. This has a different purpose than storageClassName,
	it can be changed after the claim is created. An empty string value means that no VolumeAttributesClass
	will be applied to the claim but it's not allowed to reset this field to empty string once it is set.
	If unspecified and the PersistentVolumeClaim is unbound, the default VolumeAttributesClass
	will be set by the persistentvolume controller if it exists.
	If the resource referred to by volumeAttributesClass does not exist, this PersistentVolumeClaim will be
	set to a Pending state, as reflected by the modifyVolumeStatus field, until such as a resource
	exists.
	More info: https://kubernetes.io/docs/concepts/storage/volume-attributes-classes/
	(Beta) Using this field requires the VolumeAttributesClass feature gate to be enabled (off by default).
	"""
																								type: "string"
																							}
																							volumeMode: {
																								description: """
	volumeMode defines what type of volume is required by the claim.
	Value of Filesystem is implied when not included in claim spec.
	"""
																								type: "string"
																							}
																							volumeName: {
																								description: "volumeName is the binding reference to the PersistentVolume backing this claim."
																								type:        "string"
																							}
																						}
																						type: "object"
																					}
																				}
																				required: ["spec"]
																				type: "object"
																			}
																			type: "object"
																		}
																		fc: {
																			description: "fc represents a Fibre Channel resource that is attached to a kubelet's host machine and then exposed to the pod."
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				lun: {
																					description: "lun is Optional: FC target lun number"
																					format:      "int32"
																					type:        "integer"
																				}
																				readOnly: {
																					description: """
	readOnly is Optional: Defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				targetWWNs: {
																					description: "targetWWNs is Optional: FC target worldwide names (WWNs)"
																					items: type: "string"
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				wwids: {
																					description: """
	wwids Optional: FC volume world wide identifiers (wwids)
	Either wwids or combination of targetWWNs and lun must be set, but not both simultaneously.
	"""
																					items: type: "string"
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																			}
																			type: "object"
																		}
																		flexVolume: {
																			description: """
	flexVolume represents a generic volume resource that is
	provisioned/attached using an exec based plugin.
	"""
																			properties: {
																				driver: {
																					description: "driver is the name of the driver to use for this volume."
																					type:        "string"
																				}
																				fsType: {
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". The default filesystem depends on FlexVolume script.
	"""
																					type: "string"
																				}
																				options: {
																					additionalProperties: type: "string"
																					description: "options is Optional: this field holds extra command options if any."
																					type:        "object"
																				}
																				readOnly: {
																					description: """
	readOnly is Optional: defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: """
	secretRef is Optional: secretRef is reference to the secret object containing
	sensitive information to pass to the plugin scripts. This may be
	empty if no secret object is specified. If the secret object
	contains more than one secret, all secrets are passed to the plugin
	scripts.
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																			}
																			required: ["driver"]
																			type: "object"
																		}
																		flocker: {
																			description: "flocker represents a Flocker volume attached to a kubelet's host machine. This depends on the Flocker control service being running"
																			properties: {
																				datasetName: {
																					description: """
	datasetName is Name of the dataset stored as metadata -> name on the dataset for Flocker
	should be considered as deprecated
	"""
																					type: "string"
																				}
																				datasetUUID: {
																					description: "datasetUUID is the UUID of the dataset. This is unique identifier of a Flocker dataset"
																					type:        "string"
																				}
																			}
																			type: "object"
																		}
																		gcePersistentDisk: {
																			description: """
	gcePersistentDisk represents a GCE Disk resource that is attached to a
	kubelet's host machine and then exposed to the pod.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk
	"""
																			properties: {
																				fsType: {
																					description: """
	fsType is filesystem type of the volume that you want to mount.
	Tip: Ensure that the filesystem type is supported by the host operating system.
	Examples: "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk
	"""
																					type: "string"
																				}
																				partition: {
																					description: """
	partition is the partition in the volume that you want to mount.
	If omitted, the default is to mount by volume name.
	Examples: For volume /dev/sda1, you specify the partition as "1".
	Similarly, the volume partition for /dev/sda is "0" (or you can leave the property empty).
	More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				pdName: {
																					description: """
	pdName is unique name of the PD resource in GCE. Used to identify the disk in GCE.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the ReadOnly setting in VolumeMounts.
	Defaults to false.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk
	"""
																					type: "boolean"
																				}
																			}
																			required: ["pdName"]
																			type: "object"
																		}
																		gitRepo: {
																			description: """
	gitRepo represents a git repository at a particular revision.
	DEPRECATED: GitRepo is deprecated. To provision a container with a git repo, mount an
	EmptyDir into an InitContainer that clones the repo using git, then mount the EmptyDir
	into the Pod's container.
	"""
																			properties: {
																				directory: {
																					description: """
	directory is the target directory name.
	Must not contain or start with '..'.  If '.' is supplied, the volume directory will be the
	git repository.  Otherwise, if specified, the volume will contain the git repository in
	the subdirectory with the given name.
	"""
																					type: "string"
																				}
																				repository: {
																					description: "repository is the URL"
																					type:        "string"
																				}
																				revision: {
																					description: "revision is the commit hash for the specified revision."
																					type:        "string"
																				}
																			}
																			required: ["repository"]
																			type: "object"
																		}
																		glusterfs: {
																			description: """
	glusterfs represents a Glusterfs mount on the host that shares a pod's lifetime.
	More info: https://examples.k8s.io/volumes/glusterfs/README.md
	"""
																			properties: {
																				endpoints: {
																					description: """
	endpoints is the endpoint name that details Glusterfs topology.
	More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod
	"""
																					type: "string"
																				}
																				path: {
																					description: """
	path is the Glusterfs volume path.
	More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the Glusterfs volume to be mounted with read-only permissions.
	Defaults to false.
	More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod
	"""
																					type: "boolean"
																				}
																			}
																			required: [
																				"endpoints",
																				"path",
																			]
																			type: "object"
																		}
																		hostPath: {
																			description: """
	hostPath represents a pre-existing file or directory on the host
	machine that is directly exposed to the container. This is generally
	used for system agents or other privileged things that are allowed
	to see the host machine. Most containers will NOT need this.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath
	"""
																			properties: {
																				path: {
																					description: """
	path of the directory on the host.
	If the path is a symlink, it will follow the link to the real path.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath
	"""
																					type: "string"
																				}
																				type: {
																					description: """
	type for HostPath Volume
	Defaults to ""
	More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath
	"""
																					type: "string"
																				}
																			}
																			required: ["path"]
																			type: "object"
																		}
																		image: {
																			description: """
	image represents an OCI object (a container image or artifact) pulled and mounted on the kubelet's host machine.
	The volume is resolved at pod startup depending on which PullPolicy value is provided:

	- Always: the kubelet always attempts to pull the reference. Container creation will fail If the pull fails.
	- Never: the kubelet never pulls the reference and only uses a local image or artifact. Container creation will fail if the reference isn't present.
	- IfNotPresent: the kubelet pulls if the reference isn't already present on disk. Container creation will fail if the reference isn't present and the pull fails.

	The volume gets re-resolved if the pod gets deleted and recreated, which means that new remote content will become available on pod recreation.
	A failure to resolve or pull the image during pod startup will block containers from starting and may add significant latency. Failures will be retried using normal volume backoff and will be reported on the pod reason and message.
	The types of objects that may be mounted by this volume are defined by the container runtime implementation on a host machine and at minimum must include all valid types supported by the container image field.
	The OCI object gets mounted in a single directory (spec.containers[*].volumeMounts.mountPath) by merging the manifest layers in the same way as for container images.
	The volume will be mounted read-only (ro) and non-executable files (noexec).
	Sub path mounts for containers are not supported (spec.containers[*].volumeMounts.subpath).
	The field spec.securityContext.fsGroupChangePolicy has no effect on this volume type.
	"""
																			properties: {
																				pullPolicy: {
																					description: """
	Policy for pulling OCI objects. Possible values are:
	Always: the kubelet always attempts to pull the reference. Container creation will fail If the pull fails.
	Never: the kubelet never pulls the reference and only uses a local image or artifact. Container creation will fail if the reference isn't present.
	IfNotPresent: the kubelet pulls if the reference isn't already present on disk. Container creation will fail if the reference isn't present and the pull fails.
	Defaults to Always if :latest tag is specified, or IfNotPresent otherwise.
	"""
																					type: "string"
																				}
																				reference: {
																					description: """
	Required: Image or artifact reference to be used.
	Behaves in the same way as pod.spec.containers[*].image.
	Pull secrets will be assembled in the same way as for the container image by looking up node credentials, SA image pull secrets, and pod spec image pull secrets.
	More info: https://kubernetes.io/docs/concepts/containers/images
	This field is optional to allow higher level config management to default or override
	container images in workload controllers like Deployments and StatefulSets.
	"""
																					type: "string"
																				}
																			}
																			type: "object"
																		}
																		iscsi: {
																			description: """
	iscsi represents an ISCSI Disk resource that is attached to a
	kubelet's host machine and then exposed to the pod.
	More info: https://examples.k8s.io/volumes/iscsi/README.md
	"""
																			properties: {
																				chapAuthDiscovery: {
																					description: "chapAuthDiscovery defines whether support iSCSI Discovery CHAP authentication"
																					type:        "boolean"
																				}
																				chapAuthSession: {
																					description: "chapAuthSession defines whether support iSCSI Session CHAP authentication"
																					type:        "boolean"
																				}
																				fsType: {
																					description: """
	fsType is the filesystem type of the volume that you want to mount.
	Tip: Ensure that the filesystem type is supported by the host operating system.
	Examples: "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#iscsi
	"""
																					type: "string"
																				}
																				initiatorName: {
																					description: """
	initiatorName is the custom iSCSI Initiator Name.
	If initiatorName is specified with iscsiInterface simultaneously, new iSCSI interface
	<target portal>:<volume name> will be created for the connection.
	"""
																					type: "string"
																				}
																				iqn: {
																					description: "iqn is the target iSCSI Qualified Name."
																					type:        "string"
																				}
																				iscsiInterface: {
																					default: "default"
																					description: """
	iscsiInterface is the interface Name that uses an iSCSI transport.
	Defaults to 'default' (tcp).
	"""
																					type: "string"
																				}
																				lun: {
																					description: "lun represents iSCSI Target Lun number."
																					format:      "int32"
																					type:        "integer"
																				}
																				portals: {
																					description: """
	portals is the iSCSI Target Portal List. The portal is either an IP or ip_addr:port if the port
	is other than default (typically TCP ports 860 and 3260).
	"""
																					items: type: "string"
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the ReadOnly setting in VolumeMounts.
	Defaults to false.
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: "secretRef is the CHAP Secret for iSCSI target and initiator authentication"
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				targetPortal: {
																					description: """
	targetPortal is iSCSI Target Portal. The Portal is either an IP or ip_addr:port if the port
	is other than default (typically TCP ports 860 and 3260).
	"""
																					type: "string"
																				}
																			}
																			required: [
																				"iqn",
																				"lun",
																				"targetPortal",
																			]
																			type: "object"
																		}
																		name: {
																			description: """
	name of the volume.
	Must be a DNS_LABEL and unique within the pod.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																			type: "string"
																		}
																		nfs: {
																			description: """
	nfs represents an NFS mount on the host that shares a pod's lifetime
	More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs
	"""
																			properties: {
																				path: {
																					description: """
	path that is exported by the NFS server.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the NFS export to be mounted with read-only permissions.
	Defaults to false.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs
	"""
																					type: "boolean"
																				}
																				server: {
																					description: """
	server is the hostname or IP address of the NFS server.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs
	"""
																					type: "string"
																				}
																			}
																			required: [
																				"path",
																				"server",
																			]
																			type: "object"
																		}
																		persistentVolumeClaim: {
																			description: """
	persistentVolumeClaimVolumeSource represents a reference to a
	PersistentVolumeClaim in the same namespace.
	More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims
	"""
																			properties: {
																				claimName: {
																					description: """
	claimName is the name of a PersistentVolumeClaim in the same namespace as the pod using this volume.
	More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly Will force the ReadOnly setting in VolumeMounts.
	Default false.
	"""
																					type: "boolean"
																				}
																			}
																			required: ["claimName"]
																			type: "object"
																		}
																		photonPersistentDisk: {
																			description: "photonPersistentDisk represents a PhotonController persistent disk attached and mounted on kubelets host machine"
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				pdID: {
																					description: "pdID is the ID that identifies Photon Controller persistent disk"
																					type:        "string"
																				}
																			}
																			required: ["pdID"]
																			type: "object"
																		}
																		portworxVolume: {
																			description: "portworxVolume represents a portworx volume attached and mounted on kubelets host machine"
																			properties: {
																				fsType: {
																					description: """
	fSType represents the filesystem type to mount
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				volumeID: {
																					description: "volumeID uniquely identifies a Portworx volume"
																					type:        "string"
																				}
																			}
																			required: ["volumeID"]
																			type: "object"
																		}
																		projected: {
																			description: "projected items for all in one resources secrets, configmaps, and downward API"
																			properties: {
																				defaultMode: {
																					description: """
	defaultMode are the mode bits used to set permissions on created files by default.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	Directories within the path are not affected by this setting.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				sources: {
																					description: """
	sources is the list of volume projections. Each entry in this list
	handles one source.
	"""
																					items: {
																						description: """
	Projection that may be projected along with other supported volume types.
	Exactly one of these fields must be set.
	"""
																						properties: {
																							clusterTrustBundle: {
																								description: """
	ClusterTrustBundle allows a pod to access the `.spec.trustBundle` field
	of ClusterTrustBundle objects in an auto-updating file.

	Alpha, gated by the ClusterTrustBundleProjection feature gate.

	ClusterTrustBundle objects can either be selected by name, or by the
	combination of signer name and a label selector.

	Kubelet performs aggressive normalization of the PEM contents written
	into the pod filesystem.  Esoteric PEM features such as inter-block
	comments and block headers are stripped.  Certificates are deduplicated.
	The ordering of certificates within the file is arbitrary, and Kubelet
	may change the order over time.
	"""
																								properties: {
																									labelSelector: {
																										description: """
	Select all ClusterTrustBundles that match this label selector.  Only has
	effect if signerName is set.  Mutually-exclusive with name.  If unset,
	interpreted as "match nothing".  If set but empty, interpreted as "match
	everything".
	"""
																										properties: {
																											matchExpressions: {
																												description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																												items: {
																													description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																													properties: {
																														key: {
																															description: "key is the label key that the selector applies to."
																															type:        "string"
																														}
																														operator: {
																															description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																															type: "string"
																														}
																														values: {
																															description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																															items: type: "string"
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																													}
																													required: [
																														"key",
																														"operator",
																													]
																													type: "object"
																												}
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																											matchLabels: {
																												additionalProperties: type: "string"
																												description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																												type: "object"
																											}
																										}
																										type:                    "object"
																										"x-kubernetes-map-type": "atomic"
																									}
																									name: {
																										description: """
	Select a single ClusterTrustBundle by object name.  Mutually-exclusive
	with signerName and labelSelector.
	"""
																										type: "string"
																									}
																									optional: {
																										description: """
	If true, don't block pod startup if the referenced ClusterTrustBundle(s)
	aren't available.  If using name, then the named ClusterTrustBundle is
	allowed not to exist.  If using signerName, then the combination of
	signerName and labelSelector is allowed to match zero
	ClusterTrustBundles.
	"""
																										type: "boolean"
																									}
																									path: {
																										description: "Relative path from the volume root to write the bundle."
																										type:        "string"
																									}
																									signerName: {
																										description: """
	Select all ClusterTrustBundles that match this signer name.
	Mutually-exclusive with name.  The contents of all selected
	ClusterTrustBundles will be unified and deduplicated.
	"""
																										type: "string"
																									}
																								}
																								required: ["path"]
																								type: "object"
																							}
																							configMap: {
																								description: "configMap information about the configMap data to project"
																								properties: {
																									items: {
																										description: """
	items if unspecified, each key-value pair in the Data field of the referenced
	ConfigMap will be projected into the volume as a file whose name is the
	key and content is the value. If specified, the listed keys will be
	projected into the specified paths, and unlisted keys will not be
	present. If a key is specified which is not present in the ConfigMap,
	the volume setup will error unless it is marked optional. Paths must be
	relative and may not contain the '..' path or start with '..'.
	"""
																										items: {
																											description: "Maps a string key to a path within a volume."
																											properties: {
																												key: {
																													description: "key is the key to project."
																													type:        "string"
																												}
																												mode: {
																													description: """
	mode is Optional: mode bits used to set permissions on this file.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																													format: "int32"
																													type:   "integer"
																												}
																												path: {
																													description: """
	path is the relative path of the file to map the key to.
	May not be an absolute path.
	May not contain the path element '..'.
	May not start with the string '..'.
	"""
																													type: "string"
																												}
																											}
																											required: [
																												"key",
																												"path",
																											]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									name: {
																										default: ""
																										description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																										type: "string"
																									}
																									optional: {
																										description: "optional specify whether the ConfigMap or its keys must be defined"
																										type:        "boolean"
																									}
																								}
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																							downwardAPI: {
																								description: "downwardAPI information about the downwardAPI data to project"
																								properties: items: {
																									description: "Items is a list of DownwardAPIVolume file"
																									items: {
																										description: "DownwardAPIVolumeFile represents information to create the file containing the pod field"
																										properties: {
																											fieldRef: {
																												description: "Required: Selects a field of the pod: only annotations, labels, name, namespace and uid are supported."
																												properties: {
																													apiVersion: {
																														description: "Version of the schema the FieldPath is written in terms of, defaults to \"v1\"."
																														type:        "string"
																													}
																													fieldPath: {
																														description: "Path of the field to select in the specified API version."
																														type:        "string"
																													}
																												}
																												required: ["fieldPath"]
																												type:                    "object"
																												"x-kubernetes-map-type": "atomic"
																											}
																											mode: {
																												description: """
	Optional: mode bits used to set permissions on this file, must be an octal value
	between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																												format: "int32"
																												type:   "integer"
																											}
																											path: {
																												description: "Required: Path is  the relative path name of the file to be created. Must not be absolute or contain the '..' path. Must be utf-8 encoded. The first item of the relative path must not start with '..'"
																												type:        "string"
																											}
																											resourceFieldRef: {
																												description: """
	Selects a resource of the container: only resources limits and requests
	(limits.cpu, limits.memory, requests.cpu and requests.memory) are currently supported.
	"""
																												properties: {
																													containerName: {
																														description: "Container name: required for volumes, optional for env vars"
																														type:        "string"
																													}
																													divisor: {
																														anyOf: [{
																															type: "integer"
																														}, {
																															type: "string"
																														}]
																														description:                  "Specifies the output format of the exposed resources, defaults to \"1\""
																														pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																														"x-kubernetes-int-or-string": true
																													}
																													resource: {
																														description: "Required: resource to select"
																														type:        "string"
																													}
																												}
																												required: ["resource"]
																												type:                    "object"
																												"x-kubernetes-map-type": "atomic"
																											}
																										}
																										required: ["path"]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								type: "object"
																							}
																							secret: {
																								description: "secret information about the secret data to project"
																								properties: {
																									items: {
																										description: """
	items if unspecified, each key-value pair in the Data field of the referenced
	Secret will be projected into the volume as a file whose name is the
	key and content is the value. If specified, the listed keys will be
	projected into the specified paths, and unlisted keys will not be
	present. If a key is specified which is not present in the Secret,
	the volume setup will error unless it is marked optional. Paths must be
	relative and may not contain the '..' path or start with '..'.
	"""
																										items: {
																											description: "Maps a string key to a path within a volume."
																											properties: {
																												key: {
																													description: "key is the key to project."
																													type:        "string"
																												}
																												mode: {
																													description: """
	mode is Optional: mode bits used to set permissions on this file.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																													format: "int32"
																													type:   "integer"
																												}
																												path: {
																													description: """
	path is the relative path of the file to map the key to.
	May not be an absolute path.
	May not contain the path element '..'.
	May not start with the string '..'.
	"""
																													type: "string"
																												}
																											}
																											required: [
																												"key",
																												"path",
																											]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									name: {
																										default: ""
																										description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																										type: "string"
																									}
																									optional: {
																										description: "optional field specify whether the Secret or its key must be defined"
																										type:        "boolean"
																									}
																								}
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																							serviceAccountToken: {
																								description: "serviceAccountToken is information about the serviceAccountToken data to project"
																								properties: {
																									audience: {
																										description: """
	audience is the intended audience of the token. A recipient of a token
	must identify itself with an identifier specified in the audience of the
	token, and otherwise should reject the token. The audience defaults to the
	identifier of the apiserver.
	"""
																										type: "string"
																									}
																									expirationSeconds: {
																										description: """
	expirationSeconds is the requested duration of validity of the service
	account token. As the token approaches expiration, the kubelet volume
	plugin will proactively rotate the service account token. The kubelet will
	start trying to rotate the token if the token is older than 80 percent of
	its time to live or if the token is older than 24 hours.Defaults to 1 hour
	and must be at least 10 minutes.
	"""
																										format: "int64"
																										type:   "integer"
																									}
																									path: {
																										description: """
	path is the path relative to the mount point of the file to project the
	token into.
	"""
																										type: "string"
																									}
																								}
																								required: ["path"]
																								type: "object"
																							}
																						}
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																			}
																			type: "object"
																		}
																		quobyte: {
																			description: "quobyte represents a Quobyte mount on the host that shares a pod's lifetime"
																			properties: {
																				group: {
																					description: """
	group to map volume access to
	Default is no group
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the Quobyte volume to be mounted with read-only permissions.
	Defaults to false.
	"""
																					type: "boolean"
																				}
																				registry: {
																					description: """
	registry represents a single or multiple Quobyte Registry services
	specified as a string as host:port pair (multiple entries are separated with commas)
	which acts as the central registry for volumes
	"""
																					type: "string"
																				}
																				tenant: {
																					description: """
	tenant owning the given Quobyte volume in the Backend
	Used with dynamically provisioned Quobyte volumes, value is set by the plugin
	"""
																					type: "string"
																				}
																				user: {
																					description: """
	user to map volume access to
	Defaults to serivceaccount user
	"""
																					type: "string"
																				}
																				volume: {
																					description: "volume is a string that references an already created Quobyte volume by name."
																					type:        "string"
																				}
																			}
																			required: [
																				"registry",
																				"volume",
																			]
																			type: "object"
																		}
																		rbd: {
																			description: """
	rbd represents a Rados Block Device mount on the host that shares a pod's lifetime.
	More info: https://examples.k8s.io/volumes/rbd/README.md
	"""
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type of the volume that you want to mount.
	Tip: Ensure that the filesystem type is supported by the host operating system.
	Examples: "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#rbd
	"""
																					type: "string"
																				}
																				image: {
																					description: """
	image is the rados image name.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																				keyring: {
																					default: "/etc/ceph/keyring"
																					description: """
	keyring is the path to key ring for RBDUser.
	Default is /etc/ceph/keyring.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																				monitors: {
																					description: """
	monitors is a collection of Ceph monitors.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					items: type: "string"
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				pool: {
																					default: "rbd"
																					description: """
	pool is the rados pool name.
	Default is rbd.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the ReadOnly setting in VolumeMounts.
	Defaults to false.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: """
	secretRef is name of the authentication secret for RBDUser. If provided
	overrides keyring.
	Default is nil.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				user: {
																					default: "admin"
																					description: """
	user is the rados user name.
	Default is admin.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																			}
																			required: [
																				"image",
																				"monitors",
																			]
																			type: "object"
																		}
																		scaleIO: {
																			description: "scaleIO represents a ScaleIO persistent volume attached and mounted on Kubernetes nodes."
																			properties: {
																				fsType: {
																					default: "xfs"
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs".
	Default is "xfs".
	"""
																					type: "string"
																				}
																				gateway: {
																					description: "gateway is the host address of the ScaleIO API Gateway."
																					type:        "string"
																				}
																				protectionDomain: {
																					description: "protectionDomain is the name of the ScaleIO Protection Domain for the configured storage."
																					type:        "string"
																				}
																				readOnly: {
																					description: """
	readOnly Defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: """
	secretRef references to the secret for ScaleIO user and other
	sensitive information. If this is not provided, Login operation will fail.
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				sslEnabled: {
																					description: "sslEnabled Flag enable/disable SSL communication with Gateway, default false"
																					type:        "boolean"
																				}
																				storageMode: {
																					default: "ThinProvisioned"
																					description: """
	storageMode indicates whether the storage for a volume should be ThickProvisioned or ThinProvisioned.
	Default is ThinProvisioned.
	"""
																					type: "string"
																				}
																				storagePool: {
																					description: "storagePool is the ScaleIO Storage Pool associated with the protection domain."
																					type:        "string"
																				}
																				system: {
																					description: "system is the name of the storage system as configured in ScaleIO."
																					type:        "string"
																				}
																				volumeName: {
																					description: """
	volumeName is the name of a volume already created in the ScaleIO system
	that is associated with this volume source.
	"""
																					type: "string"
																				}
																			}
																			required: [
																				"gateway",
																				"secretRef",
																				"system",
																			]
																			type: "object"
																		}
																		secret: {
																			description: """
	secret represents a secret that should populate this volume.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#secret
	"""
																			properties: {
																				defaultMode: {
																					description: """
	defaultMode is Optional: mode bits used to set permissions on created files by default.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values
	for mode bits. Defaults to 0644.
	Directories within the path are not affected by this setting.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				items: {
																					description: """
	items If unspecified, each key-value pair in the Data field of the referenced
	Secret will be projected into the volume as a file whose name is the
	key and content is the value. If specified, the listed keys will be
	projected into the specified paths, and unlisted keys will not be
	present. If a key is specified which is not present in the Secret,
	the volume setup will error unless it is marked optional. Paths must be
	relative and may not contain the '..' path or start with '..'.
	"""
																					items: {
																						description: "Maps a string key to a path within a volume."
																						properties: {
																							key: {
																								description: "key is the key to project."
																								type:        "string"
																							}
																							mode: {
																								description: """
	mode is Optional: mode bits used to set permissions on this file.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																								format: "int32"
																								type:   "integer"
																							}
																							path: {
																								description: """
	path is the relative path of the file to map the key to.
	May not be an absolute path.
	May not contain the path element '..'.
	May not start with the string '..'.
	"""
																								type: "string"
																							}
																						}
																						required: [
																							"key",
																							"path",
																						]
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				optional: {
																					description: "optional field specify whether the Secret or its keys must be defined"
																					type:        "boolean"
																				}
																				secretName: {
																					description: """
	secretName is the name of the secret in the pod's namespace to use.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#secret
	"""
																					type: "string"
																				}
																			}
																			type: "object"
																		}
																		storageos: {
																			description: "storageOS represents a StorageOS volume attached and mounted on Kubernetes nodes."
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: """
	secretRef specifies the secret to use for obtaining the StorageOS API
	credentials.  If not specified, default values will be attempted.
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				volumeName: {
																					description: """
	volumeName is the human-readable name of the StorageOS volume.  Volume
	names are only unique within a namespace.
	"""
																					type: "string"
																				}
																				volumeNamespace: {
																					description: """
	volumeNamespace specifies the scope of the volume within StorageOS.  If no
	namespace is specified then the Pod's namespace will be used.  This allows the
	Kubernetes name scoping to be mirrored within StorageOS for tighter integration.
	Set VolumeName to any name to override the default behaviour.
	Set to "default" if you are not using namespaces within StorageOS.
	Namespaces that do not pre-exist within StorageOS will be created.
	"""
																					type: "string"
																				}
																			}
																			type: "object"
																		}
																		vsphereVolume: {
																			description: "vsphereVolume represents a vSphere volume attached and mounted on kubelets host machine"
																			properties: {
																				fsType: {
																					description: """
	fsType is filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				storagePolicyID: {
																					description: "storagePolicyID is the storage Policy Based Management (SPBM) profile ID associated with the StoragePolicyName."
																					type:        "string"
																				}
																				storagePolicyName: {
																					description: "storagePolicyName is the storage Policy Based Management (SPBM) profile name."
																					type:        "string"
																				}
																				volumePath: {
																					description: "volumePath is the path that identifies vSphere volume vmdk"
																					type:        "string"
																				}
																			}
																			required: ["volumePath"]
																			type: "object"
																		}
																	}
																	required: ["name"]
																	type: "object"
																}
																type: "array"
															}
														}
														type: "object"
													}
													strategy: {
														description: "The daemonset strategy to use to replace existing pods with new ones."
														properties: {
															rollingUpdate: {
																description: "Rolling update config params. Present only if type = \"RollingUpdate\"."
																properties: {
																	maxSurge: {
																		anyOf: [{
																			type: "integer"
																		}, {
																			type: "string"
																		}]
																		description: """
	The maximum number of nodes with an existing available DaemonSet pod that
	can have an updated DaemonSet pod during during an update.
	Value can be an absolute number (ex: 5) or a percentage of desired pods (ex: 10%).
	This can not be 0 if MaxUnavailable is 0.
	Absolute number is calculated from percentage by rounding up to a minimum of 1.
	Default value is 0.
	Example: when this is set to 30%, at most 30% of the total number of nodes
	that should be running the daemon pod (i.e. status.desiredNumberScheduled)
	can have their a new pod created before the old pod is marked as deleted.
	The update starts by launching new pods on 30% of nodes. Once an updated
	pod is available (Ready for at least minReadySeconds) the old DaemonSet pod
	on that node is marked deleted. If the old pod becomes unavailable for any
	reason (Ready transitions to false, is evicted, or is drained) an updated
	pod is immediatedly created on that node without considering surge limits.
	Allowing surge implies the possibility that the resources consumed by the
	daemonset on any given node can double if the readiness check fails, and
	so resource intensive daemonsets should take into account that they may
	cause evictions during disruption.
	"""
																		"x-kubernetes-int-or-string": true
																	}
																	maxUnavailable: {
																		anyOf: [{
																			type: "integer"
																		}, {
																			type: "string"
																		}]
																		description: """
	The maximum number of DaemonSet pods that can be unavailable during the
	update. Value can be an absolute number (ex: 5) or a percentage of total
	number of DaemonSet pods at the start of the update (ex: 10%). Absolute
	number is calculated from percentage by rounding up.
	This cannot be 0 if MaxSurge is 0
	Default value is 1.
	Example: when this is set to 30%, at most 30% of the total number of nodes
	that should be running the daemon pod (i.e. status.desiredNumberScheduled)
	can have their pods stopped for an update at any given time. The update
	starts by stopping at most 30% of those DaemonSet pods and then brings
	up new DaemonSet pods in their place. Once the new pods are available,
	it then proceeds onto other DaemonSet pods, thus ensuring that at least
	70% of original number of DaemonSet pods are available at all times during
	the update.
	"""
																		"x-kubernetes-int-or-string": true
																	}
																}
																type: "object"
															}
															type: {
																description: "Type of daemon set update. Can be \"RollingUpdate\" or \"OnDelete\". Default is RollingUpdate."
																type:        "string"
															}
														}
														type: "object"
													}
												}
												type: "object"
											}
											envoyDeployment: {
												description: """
	EnvoyDeployment defines the desired state of the Envoy deployment resource.
	If unspecified, default settings for the managed Envoy deployment resource
	are applied.
	"""
												properties: {
													container: {
														description: "Container defines the desired specification of main container."
														properties: {
															env: {
																description: "List of environment variables to set in the container."
																items: {
																	description: "EnvVar represents an environment variable present in a Container."
																	properties: {
																		name: {
																			description: "Name of the environment variable. Must be a C_IDENTIFIER."
																			type:        "string"
																		}
																		value: {
																			description: """
	Variable references $(VAR_NAME) are expanded
	using the previously defined environment variables in the container and
	any service environment variables. If a variable cannot be resolved,
	the reference in the input string will be unchanged. Double $$ are reduced
	to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e.
	"$$(VAR_NAME)" will produce the string literal "$(VAR_NAME)".
	Escaped references will never be expanded, regardless of whether the variable
	exists or not.
	Defaults to "".
	"""
																			type: "string"
																		}
																		valueFrom: {
																			description: "Source for the environment variable's value. Cannot be used if value is not empty."
																			properties: {
																				configMapKeyRef: {
																					description: "Selects a key of a ConfigMap."
																					properties: {
																						key: {
																							description: "The key to select."
																							type:        "string"
																						}
																						name: {
																							default: ""
																							description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																							type: "string"
																						}
																						optional: {
																							description: "Specify whether the ConfigMap or its key must be defined"
																							type:        "boolean"
																						}
																					}
																					required: ["key"]
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				fieldRef: {
																					description: """
	Selects a field of the pod: supports metadata.name, metadata.namespace, `metadata.labels['<KEY>']`, `metadata.annotations['<KEY>']`,
	spec.nodeName, spec.serviceAccountName, status.hostIP, status.podIP, status.podIPs.
	"""
																					properties: {
																						apiVersion: {
																							description: "Version of the schema the FieldPath is written in terms of, defaults to \"v1\"."
																							type:        "string"
																						}
																						fieldPath: {
																							description: "Path of the field to select in the specified API version."
																							type:        "string"
																						}
																					}
																					required: ["fieldPath"]
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				resourceFieldRef: {
																					description: """
	Selects a resource of the container: only resources limits and requests
	(limits.cpu, limits.memory, limits.ephemeral-storage, requests.cpu, requests.memory and requests.ephemeral-storage) are currently supported.
	"""
																					properties: {
																						containerName: {
																							description: "Container name: required for volumes, optional for env vars"
																							type:        "string"
																						}
																						divisor: {
																							anyOf: [{
																								type: "integer"
																							}, {
																								type: "string"
																							}]
																							description:                  "Specifies the output format of the exposed resources, defaults to \"1\""
																							pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																							"x-kubernetes-int-or-string": true
																						}
																						resource: {
																							description: "Required: resource to select"
																							type:        "string"
																						}
																					}
																					required: ["resource"]
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				secretKeyRef: {
																					description: "Selects a key of a secret in the pod's namespace"
																					properties: {
																						key: {
																							description: "The key of the secret to select from.  Must be a valid secret key."
																							type:        "string"
																						}
																						name: {
																							default: ""
																							description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																							type: "string"
																						}
																						optional: {
																							description: "Specify whether the Secret or its key must be defined"
																							type:        "boolean"
																						}
																					}
																					required: ["key"]
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																			}
																			type: "object"
																		}
																	}
																	required: ["name"]
																	type: "object"
																}
																type: "array"
															}
															image: {
																description: "Image specifies the EnvoyProxy container image to be used, instead of the default image."
																type:        "string"
															}
															resources: {
																description: """
	Resources required by this container.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																properties: {
																	claims: {
																		description: """
	Claims lists the names of resources, defined in spec.resourceClaims,
	that are used by this container.

	This is an alpha field and requires enabling the
	DynamicResourceAllocation feature gate.

	This field is immutable. It can only be set for containers.
	"""
																		items: {
																			description: "ResourceClaim references one entry in PodSpec.ResourceClaims."
																			properties: {
																				name: {
																					description: """
	Name must match the name of one entry in pod.spec.resourceClaims of
	the Pod where this field is used. It makes that resource available
	inside a container.
	"""
																					type: "string"
																				}
																				request: {
																					description: """
	Request is the name chosen for a request in the referenced claim.
	If empty, everything from the claim is made available, otherwise
	only the result of this request.
	"""
																					type: "string"
																				}
																			}
																			required: ["name"]
																			type: "object"
																		}
																		type: "array"
																		"x-kubernetes-list-map-keys": ["name"]
																		"x-kubernetes-list-type": "map"
																	}
																	limits: {
																		additionalProperties: {
																			anyOf: [{
																				type: "integer"
																			}, {
																				type: "string"
																			}]
																			pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																			"x-kubernetes-int-or-string": true
																		}
																		description: """
	Limits describes the maximum amount of compute resources allowed.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																		type: "object"
																	}
																	requests: {
																		additionalProperties: {
																			anyOf: [{
																				type: "integer"
																			}, {
																				type: "string"
																			}]
																			pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																			"x-kubernetes-int-or-string": true
																		}
																		description: """
	Requests describes the minimum amount of compute resources required.
	If Requests is omitted for a container, it defaults to Limits if that is explicitly specified,
	otherwise to an implementation-defined value. Requests cannot exceed Limits.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																		type: "object"
																	}
																}
																type: "object"
															}
															securityContext: {
																description: """
	SecurityContext defines the security options the container should be run with.
	If set, the fields of SecurityContext override the equivalent fields of PodSecurityContext.
	More info: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
	"""
																properties: {
																	allowPrivilegeEscalation: {
																		description: """
	AllowPrivilegeEscalation controls whether a process can gain more
	privileges than its parent process. This bool directly controls if
	the no_new_privs flag will be set on the container process.
	AllowPrivilegeEscalation is true always when the container is:
	1) run as Privileged
	2) has CAP_SYS_ADMIN
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "boolean"
																	}
																	appArmorProfile: {
																		description: """
	appArmorProfile is the AppArmor options to use by this container. If set, this profile
	overrides the pod's appArmorProfile.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			localhostProfile: {
																				description: """
	localhostProfile indicates a profile loaded on the node that should be used.
	The profile must be preconfigured on the node to work.
	Must match the loaded name of the profile.
	Must be set if and only if type is "Localhost".
	"""
																				type: "string"
																			}
																			type: {
																				description: """
	type indicates which kind of AppArmor profile will be applied.
	Valid options are:
	  Localhost - a profile pre-loaded on the node.
	  RuntimeDefault - the container runtime's default profile.
	  Unconfined - no AppArmor enforcement.
	"""
																				type: "string"
																			}
																		}
																		required: ["type"]
																		type: "object"
																	}
																	capabilities: {
																		description: """
	The capabilities to add/drop when running containers.
	Defaults to the default set of capabilities granted by the container runtime.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			add: {
																				description: "Added capabilities"
																				items: {
																					description: "Capability represent POSIX capabilities type"
																					type:        "string"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																			drop: {
																				description: "Removed capabilities"
																				items: {
																					description: "Capability represent POSIX capabilities type"
																					type:        "string"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																		}
																		type: "object"
																	}
																	privileged: {
																		description: """
	Run container in privileged mode.
	Processes in privileged containers are essentially equivalent to root on the host.
	Defaults to false.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "boolean"
																	}
																	procMount: {
																		description: """
	procMount denotes the type of proc mount to use for the containers.
	The default value is Default which uses the container runtime defaults for
	readonly paths and masked paths.
	This requires the ProcMountType feature flag to be enabled.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "string"
																	}
																	readOnlyRootFilesystem: {
																		description: """
	Whether this container has a read-only root filesystem.
	Default is false.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "boolean"
																	}
																	runAsGroup: {
																		description: """
	The GID to run the entrypoint of the container process.
	Uses runtime default if unset.
	May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		format: "int64"
																		type:   "integer"
																	}
																	runAsNonRoot: {
																		description: """
	Indicates that the container must run as a non-root user.
	If true, the Kubelet will validate the image at runtime to ensure that it
	does not run as UID 0 (root) and fail to start the container if it does.
	If unset or false, no such validation will be performed.
	May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	"""
																		type: "boolean"
																	}
																	runAsUser: {
																		description: """
	The UID to run the entrypoint of the container process.
	Defaults to user specified in image metadata if unspecified.
	May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		format: "int64"
																		type:   "integer"
																	}
																	seLinuxOptions: {
																		description: """
	The SELinux context to be applied to the container.
	If unspecified, the container runtime will allocate a random SELinux context for each
	container.  May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			level: {
																				description: "Level is SELinux level label that applies to the container."
																				type:        "string"
																			}
																			role: {
																				description: "Role is a SELinux role label that applies to the container."
																				type:        "string"
																			}
																			type: {
																				description: "Type is a SELinux type label that applies to the container."
																				type:        "string"
																			}
																			user: {
																				description: "User is a SELinux user label that applies to the container."
																				type:        "string"
																			}
																		}
																		type: "object"
																	}
																	seccompProfile: {
																		description: """
	The seccomp options to use by this container. If seccomp options are
	provided at both the pod & container level, the container options
	override the pod options.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			localhostProfile: {
																				description: """
	localhostProfile indicates a profile defined in a file on the node should be used.
	The profile must be preconfigured on the node to work.
	Must be a descending path, relative to the kubelet's configured seccomp profile location.
	Must be set if type is "Localhost". Must NOT be set for any other type.
	"""
																				type: "string"
																			}
																			type: {
																				description: """
	type indicates which kind of seccomp profile will be applied.
	Valid options are:

	Localhost - a profile defined in a file on the node should be used.
	RuntimeDefault - the container runtime default profile should be used.
	Unconfined - no profile should be applied.
	"""
																				type: "string"
																			}
																		}
																		required: ["type"]
																		type: "object"
																	}
																	windowsOptions: {
																		description: """
	The Windows specific settings applied to all containers.
	If unspecified, the options from the PodSecurityContext will be used.
	If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is linux.
	"""
																		properties: {
																			gmsaCredentialSpec: {
																				description: """
	GMSACredentialSpec is where the GMSA admission webhook
	(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the
	GMSA credential spec named by the GMSACredentialSpecName field.
	"""
																				type: "string"
																			}
																			gmsaCredentialSpecName: {
																				description: "GMSACredentialSpecName is the name of the GMSA credential spec to use."
																				type:        "string"
																			}
																			hostProcess: {
																				description: """
	HostProcess determines if a container should be run as a 'Host Process' container.
	All of a Pod's containers must have the same effective HostProcess value
	(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).
	In addition, if HostProcess is true then HostNetwork must also be set to true.
	"""
																				type: "boolean"
																			}
																			runAsUserName: {
																				description: """
	The UserName in Windows to run the entrypoint of the container process.
	Defaults to the user specified in image metadata if unspecified.
	May also be set in PodSecurityContext. If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	"""
																				type: "string"
																			}
																		}
																		type: "object"
																	}
																}
																type: "object"
															}
															volumeMounts: {
																description: """
	VolumeMounts are volumes to mount into the container's filesystem.
	Cannot be updated.
	"""
																items: {
																	description: "VolumeMount describes a mounting of a Volume within a container."
																	properties: {
																		mountPath: {
																			description: """
	Path within the container at which the volume should be mounted.  Must
	not contain ':'.
	"""
																			type: "string"
																		}
																		mountPropagation: {
																			description: """
	mountPropagation determines how mounts are propagated from the host
	to container and the other way around.
	When not set, MountPropagationNone is used.
	This field is beta in 1.10.
	When RecursiveReadOnly is set to IfPossible or to Enabled, MountPropagation must be None or unspecified
	(which defaults to None).
	"""
																			type: "string"
																		}
																		name: {
																			description: "This must match the Name of a Volume."
																			type:        "string"
																		}
																		readOnly: {
																			description: """
	Mounted read-only if true, read-write otherwise (false or unspecified).
	Defaults to false.
	"""
																			type: "boolean"
																		}
																		recursiveReadOnly: {
																			description: """
	RecursiveReadOnly specifies whether read-only mounts should be handled
	recursively.

	If ReadOnly is false, this field has no meaning and must be unspecified.

	If ReadOnly is true, and this field is set to Disabled, the mount is not made
	recursively read-only.  If this field is set to IfPossible, the mount is made
	recursively read-only, if it is supported by the container runtime.  If this
	field is set to Enabled, the mount is made recursively read-only if it is
	supported by the container runtime, otherwise the pod will not be started and
	an error will be generated to indicate the reason.

	If this field is set to IfPossible or Enabled, MountPropagation must be set to
	None (or be unspecified, which defaults to None).

	If this field is not specified, it is treated as an equivalent of Disabled.
	"""
																			type: "string"
																		}
																		subPath: {
																			description: """
	Path within the volume from which the container's volume should be mounted.
	Defaults to "" (volume's root).
	"""
																			type: "string"
																		}
																		subPathExpr: {
																			description: """
	Expanded path within the volume from which the container's volume should be mounted.
	Behaves similarly to SubPath but environment variable references $(VAR_NAME) are expanded using the container's environment.
	Defaults to "" (volume's root).
	SubPathExpr and SubPath are mutually exclusive.
	"""
																			type: "string"
																		}
																	}
																	required: [
																		"mountPath",
																		"name",
																	]
																	type: "object"
																}
																type: "array"
															}
														}
														type: "object"
													}
													initContainers: {
														description: """
	List of initialization containers belonging to the pod.
	More info: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/
	"""
														items: {
															description: "A single application container that you want to run within a pod."
															properties: {
																args: {
																	description: """
	Arguments to the entrypoint.
	The container image's CMD is used if this is not provided.
	Variable references $(VAR_NAME) are expanded using the container's environment. If a variable
	cannot be resolved, the reference in the input string will be unchanged. Double $$ are reduced
	to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e. "$$(VAR_NAME)" will
	produce the string literal "$(VAR_NAME)". Escaped references will never be expanded, regardless
	of whether the variable exists or not. Cannot be updated.
	More info: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell
	"""
																	items: type: "string"
																	type:                     "array"
																	"x-kubernetes-list-type": "atomic"
																}
																command: {
																	description: """
	Entrypoint array. Not executed within a shell.
	The container image's ENTRYPOINT is used if this is not provided.
	Variable references $(VAR_NAME) are expanded using the container's environment. If a variable
	cannot be resolved, the reference in the input string will be unchanged. Double $$ are reduced
	to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e. "$$(VAR_NAME)" will
	produce the string literal "$(VAR_NAME)". Escaped references will never be expanded, regardless
	of whether the variable exists or not. Cannot be updated.
	More info: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell
	"""
																	items: type: "string"
																	type:                     "array"
																	"x-kubernetes-list-type": "atomic"
																}
																env: {
																	description: """
	List of environment variables to set in the container.
	Cannot be updated.
	"""
																	items: {
																		description: "EnvVar represents an environment variable present in a Container."
																		properties: {
																			name: {
																				description: "Name of the environment variable. Must be a C_IDENTIFIER."
																				type:        "string"
																			}
																			value: {
																				description: """
	Variable references $(VAR_NAME) are expanded
	using the previously defined environment variables in the container and
	any service environment variables. If a variable cannot be resolved,
	the reference in the input string will be unchanged. Double $$ are reduced
	to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e.
	"$$(VAR_NAME)" will produce the string literal "$(VAR_NAME)".
	Escaped references will never be expanded, regardless of whether the variable
	exists or not.
	Defaults to "".
	"""
																				type: "string"
																			}
																			valueFrom: {
																				description: "Source for the environment variable's value. Cannot be used if value is not empty."
																				properties: {
																					configMapKeyRef: {
																						description: "Selects a key of a ConfigMap."
																						properties: {
																							key: {
																								description: "The key to select."
																								type:        "string"
																							}
																							name: {
																								default: ""
																								description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																								type: "string"
																							}
																							optional: {
																								description: "Specify whether the ConfigMap or its key must be defined"
																								type:        "boolean"
																							}
																						}
																						required: ["key"]
																						type:                    "object"
																						"x-kubernetes-map-type": "atomic"
																					}
																					fieldRef: {
																						description: """
	Selects a field of the pod: supports metadata.name, metadata.namespace, `metadata.labels['<KEY>']`, `metadata.annotations['<KEY>']`,
	spec.nodeName, spec.serviceAccountName, status.hostIP, status.podIP, status.podIPs.
	"""
																						properties: {
																							apiVersion: {
																								description: "Version of the schema the FieldPath is written in terms of, defaults to \"v1\"."
																								type:        "string"
																							}
																							fieldPath: {
																								description: "Path of the field to select in the specified API version."
																								type:        "string"
																							}
																						}
																						required: ["fieldPath"]
																						type:                    "object"
																						"x-kubernetes-map-type": "atomic"
																					}
																					resourceFieldRef: {
																						description: """
	Selects a resource of the container: only resources limits and requests
	(limits.cpu, limits.memory, limits.ephemeral-storage, requests.cpu, requests.memory and requests.ephemeral-storage) are currently supported.
	"""
																						properties: {
																							containerName: {
																								description: "Container name: required for volumes, optional for env vars"
																								type:        "string"
																							}
																							divisor: {
																								anyOf: [{
																									type: "integer"
																								}, {
																									type: "string"
																								}]
																								description:                  "Specifies the output format of the exposed resources, defaults to \"1\""
																								pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																								"x-kubernetes-int-or-string": true
																							}
																							resource: {
																								description: "Required: resource to select"
																								type:        "string"
																							}
																						}
																						required: ["resource"]
																						type:                    "object"
																						"x-kubernetes-map-type": "atomic"
																					}
																					secretKeyRef: {
																						description: "Selects a key of a secret in the pod's namespace"
																						properties: {
																							key: {
																								description: "The key of the secret to select from.  Must be a valid secret key."
																								type:        "string"
																							}
																							name: {
																								default: ""
																								description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																								type: "string"
																							}
																							optional: {
																								description: "Specify whether the Secret or its key must be defined"
																								type:        "boolean"
																							}
																						}
																						required: ["key"]
																						type:                    "object"
																						"x-kubernetes-map-type": "atomic"
																					}
																				}
																				type: "object"
																			}
																		}
																		required: ["name"]
																		type: "object"
																	}
																	type: "array"
																	"x-kubernetes-list-map-keys": ["name"]
																	"x-kubernetes-list-type": "map"
																}
																envFrom: {
																	description: """
	List of sources to populate environment variables in the container.
	The keys defined within a source must be a C_IDENTIFIER. All invalid keys
	will be reported as an event when the container is starting. When a key exists in multiple
	sources, the value associated with the last source will take precedence.
	Values defined by an Env with a duplicate key will take precedence.
	Cannot be updated.
	"""
																	items: {
																		description: "EnvFromSource represents the source of a set of ConfigMaps"
																		properties: {
																			configMapRef: {
																				description: "The ConfigMap to select from"
																				properties: {
																					name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					optional: {
																						description: "Specify whether the ConfigMap must be defined"
																						type:        "boolean"
																					}
																				}
																				type:                    "object"
																				"x-kubernetes-map-type": "atomic"
																			}
																			prefix: {
																				description: "An optional identifier to prepend to each key in the ConfigMap. Must be a C_IDENTIFIER."
																				type:        "string"
																			}
																			secretRef: {
																				description: "The Secret to select from"
																				properties: {
																					name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					optional: {
																						description: "Specify whether the Secret must be defined"
																						type:        "boolean"
																					}
																				}
																				type:                    "object"
																				"x-kubernetes-map-type": "atomic"
																			}
																		}
																		type: "object"
																	}
																	type:                     "array"
																	"x-kubernetes-list-type": "atomic"
																}
																image: {
																	description: """
	Container image name.
	More info: https://kubernetes.io/docs/concepts/containers/images
	This field is optional to allow higher level config management to default or override
	container images in workload controllers like Deployments and StatefulSets.
	"""
																	type: "string"
																}
																imagePullPolicy: {
																	description: """
	Image pull policy.
	One of Always, Never, IfNotPresent.
	Defaults to Always if :latest tag is specified, or IfNotPresent otherwise.
	Cannot be updated.
	More info: https://kubernetes.io/docs/concepts/containers/images#updating-images
	"""
																	type: "string"
																}
																lifecycle: {
																	description: """
	Actions that the management system should take in response to container lifecycle events.
	Cannot be updated.
	"""
																	properties: {
																		postStart: {
																			description: """
	PostStart is called immediately after a container is created. If the handler fails,
	the container is terminated and restarted according to its restart policy.
	Other management of the container blocks until the hook completes.
	More info: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#container-hooks
	"""
																			properties: {
																				exec: {
																					description: "Exec specifies the action to take."
																					properties: command: {
																						description: """
	Command is the command line to execute inside the container, the working directory for the
	command  is root ('/') in the container's filesystem. The command is simply exec'd, it is
	not run inside a shell, so traditional shell instructions ('|', etc) won't work. To use
	a shell, you need to explicitly call out to that shell.
	Exit status of 0 is treated as live/healthy and non-zero is unhealthy.
	"""
																						items: type: "string"
																						type:                     "array"
																						"x-kubernetes-list-type": "atomic"
																					}
																					type: "object"
																				}
																				httpGet: {
																					description: "HTTPGet specifies the http request to perform."
																					properties: {
																						host: {
																							description: """
	Host name to connect to, defaults to the pod IP. You probably want to set
	"Host" in httpHeaders instead.
	"""
																							type: "string"
																						}
																						httpHeaders: {
																							description: "Custom headers to set in the request. HTTP allows repeated headers."
																							items: {
																								description: "HTTPHeader describes a custom header to be used in HTTP probes"
																								properties: {
																									name: {
																										description: """
	The header field name.
	This will be canonicalized upon output, so case-variant names will be understood as the same header.
	"""
																										type: "string"
																									}
																									value: {
																										description: "The header field value"
																										type:        "string"
																									}
																								}
																								required: [
																									"name",
																									"value",
																								]
																								type: "object"
																							}
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						path: {
																							description: "Path to access on the HTTP server."
																							type:        "string"
																						}
																						port: {
																							anyOf: [{
																								type: "integer"
																							}, {
																								type: "string"
																							}]
																							description: """
	Name or number of the port to access on the container.
	Number must be in the range 1 to 65535.
	Name must be an IANA_SVC_NAME.
	"""
																							"x-kubernetes-int-or-string": true
																						}
																						scheme: {
																							description: """
	Scheme to use for connecting to the host.
	Defaults to HTTP.
	"""
																							type: "string"
																						}
																					}
																					required: ["port"]
																					type: "object"
																				}
																				sleep: {
																					description: "Sleep represents the duration that the container should sleep before being terminated."
																					properties: seconds: {
																						description: "Seconds is the number of seconds to sleep."
																						format:      "int64"
																						type:        "integer"
																					}
																					required: ["seconds"]
																					type: "object"
																				}
																				tcpSocket: {
																					description: """
	Deprecated. TCPSocket is NOT supported as a LifecycleHandler and kept
	for the backward compatibility. There are no validation of this field and
	lifecycle hooks will fail in runtime when tcp handler is specified.
	"""
																					properties: {
																						host: {
																							description: "Optional: Host name to connect to, defaults to the pod IP."
																							type:        "string"
																						}
																						port: {
																							anyOf: [{
																								type: "integer"
																							}, {
																								type: "string"
																							}]
																							description: """
	Number or name of the port to access on the container.
	Number must be in the range 1 to 65535.
	Name must be an IANA_SVC_NAME.
	"""
																							"x-kubernetes-int-or-string": true
																						}
																					}
																					required: ["port"]
																					type: "object"
																				}
																			}
																			type: "object"
																		}
																		preStop: {
																			description: """
	PreStop is called immediately before a container is terminated due to an
	API request or management event such as liveness/startup probe failure,
	preemption, resource contention, etc. The handler is not called if the
	container crashes or exits. The Pod's termination grace period countdown begins before the
	PreStop hook is executed. Regardless of the outcome of the handler, the
	container will eventually terminate within the Pod's termination grace
	period (unless delayed by finalizers). Other management of the container blocks until the hook completes
	or until the termination grace period is reached.
	More info: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#container-hooks
	"""
																			properties: {
																				exec: {
																					description: "Exec specifies the action to take."
																					properties: command: {
																						description: """
	Command is the command line to execute inside the container, the working directory for the
	command  is root ('/') in the container's filesystem. The command is simply exec'd, it is
	not run inside a shell, so traditional shell instructions ('|', etc) won't work. To use
	a shell, you need to explicitly call out to that shell.
	Exit status of 0 is treated as live/healthy and non-zero is unhealthy.
	"""
																						items: type: "string"
																						type:                     "array"
																						"x-kubernetes-list-type": "atomic"
																					}
																					type: "object"
																				}
																				httpGet: {
																					description: "HTTPGet specifies the http request to perform."
																					properties: {
																						host: {
																							description: """
	Host name to connect to, defaults to the pod IP. You probably want to set
	"Host" in httpHeaders instead.
	"""
																							type: "string"
																						}
																						httpHeaders: {
																							description: "Custom headers to set in the request. HTTP allows repeated headers."
																							items: {
																								description: "HTTPHeader describes a custom header to be used in HTTP probes"
																								properties: {
																									name: {
																										description: """
	The header field name.
	This will be canonicalized upon output, so case-variant names will be understood as the same header.
	"""
																										type: "string"
																									}
																									value: {
																										description: "The header field value"
																										type:        "string"
																									}
																								}
																								required: [
																									"name",
																									"value",
																								]
																								type: "object"
																							}
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						path: {
																							description: "Path to access on the HTTP server."
																							type:        "string"
																						}
																						port: {
																							anyOf: [{
																								type: "integer"
																							}, {
																								type: "string"
																							}]
																							description: """
	Name or number of the port to access on the container.
	Number must be in the range 1 to 65535.
	Name must be an IANA_SVC_NAME.
	"""
																							"x-kubernetes-int-or-string": true
																						}
																						scheme: {
																							description: """
	Scheme to use for connecting to the host.
	Defaults to HTTP.
	"""
																							type: "string"
																						}
																					}
																					required: ["port"]
																					type: "object"
																				}
																				sleep: {
																					description: "Sleep represents the duration that the container should sleep before being terminated."
																					properties: seconds: {
																						description: "Seconds is the number of seconds to sleep."
																						format:      "int64"
																						type:        "integer"
																					}
																					required: ["seconds"]
																					type: "object"
																				}
																				tcpSocket: {
																					description: """
	Deprecated. TCPSocket is NOT supported as a LifecycleHandler and kept
	for the backward compatibility. There are no validation of this field and
	lifecycle hooks will fail in runtime when tcp handler is specified.
	"""
																					properties: {
																						host: {
																							description: "Optional: Host name to connect to, defaults to the pod IP."
																							type:        "string"
																						}
																						port: {
																							anyOf: [{
																								type: "integer"
																							}, {
																								type: "string"
																							}]
																							description: """
	Number or name of the port to access on the container.
	Number must be in the range 1 to 65535.
	Name must be an IANA_SVC_NAME.
	"""
																							"x-kubernetes-int-or-string": true
																						}
																					}
																					required: ["port"]
																					type: "object"
																				}
																			}
																			type: "object"
																		}
																	}
																	type: "object"
																}
																livenessProbe: {
																	description: """
	Periodic probe of container liveness.
	Container will be restarted if the probe fails.
	Cannot be updated.
	More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
	"""
																	properties: {
																		exec: {
																			description: "Exec specifies the action to take."
																			properties: command: {
																				description: """
	Command is the command line to execute inside the container, the working directory for the
	command  is root ('/') in the container's filesystem. The command is simply exec'd, it is
	not run inside a shell, so traditional shell instructions ('|', etc) won't work. To use
	a shell, you need to explicitly call out to that shell.
	Exit status of 0 is treated as live/healthy and non-zero is unhealthy.
	"""
																				items: type: "string"
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																			type: "object"
																		}
																		failureThreshold: {
																			description: """
	Minimum consecutive failures for the probe to be considered failed after having succeeded.
	Defaults to 3. Minimum value is 1.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		grpc: {
																			description: "GRPC specifies an action involving a GRPC port."
																			properties: {
																				port: {
																					description: "Port number of the gRPC service. Number must be in the range 1 to 65535."
																					format:      "int32"
																					type:        "integer"
																				}
																				service: {
																					default: ""
																					description: """
	Service is the name of the service to place in the gRPC HealthCheckRequest
	(see https://github.com/grpc/grpc/blob/master/doc/health-checking.md).

	If this is not specified, the default behavior is defined by gRPC.
	"""
																					type: "string"
																				}
																			}
																			required: ["port"]
																			type: "object"
																		}
																		httpGet: {
																			description: "HTTPGet specifies the http request to perform."
																			properties: {
																				host: {
																					description: """
	Host name to connect to, defaults to the pod IP. You probably want to set
	"Host" in httpHeaders instead.
	"""
																					type: "string"
																				}
																				httpHeaders: {
																					description: "Custom headers to set in the request. HTTP allows repeated headers."
																					items: {
																						description: "HTTPHeader describes a custom header to be used in HTTP probes"
																						properties: {
																							name: {
																								description: """
	The header field name.
	This will be canonicalized upon output, so case-variant names will be understood as the same header.
	"""
																								type: "string"
																							}
																							value: {
																								description: "The header field value"
																								type:        "string"
																							}
																						}
																						required: [
																							"name",
																							"value",
																						]
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				path: {
																					description: "Path to access on the HTTP server."
																					type:        "string"
																				}
																				port: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	Name or number of the port to access on the container.
	Number must be in the range 1 to 65535.
	Name must be an IANA_SVC_NAME.
	"""
																					"x-kubernetes-int-or-string": true
																				}
																				scheme: {
																					description: """
	Scheme to use for connecting to the host.
	Defaults to HTTP.
	"""
																					type: "string"
																				}
																			}
																			required: ["port"]
																			type: "object"
																		}
																		initialDelaySeconds: {
																			description: """
	Number of seconds after the container has started before liveness probes are initiated.
	More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		periodSeconds: {
																			description: """
	How often (in seconds) to perform the probe.
	Default to 10 seconds. Minimum value is 1.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		successThreshold: {
																			description: """
	Minimum consecutive successes for the probe to be considered successful after having failed.
	Defaults to 1. Must be 1 for liveness and startup. Minimum value is 1.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		tcpSocket: {
																			description: "TCPSocket specifies an action involving a TCP port."
																			properties: {
																				host: {
																					description: "Optional: Host name to connect to, defaults to the pod IP."
																					type:        "string"
																				}
																				port: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	Number or name of the port to access on the container.
	Number must be in the range 1 to 65535.
	Name must be an IANA_SVC_NAME.
	"""
																					"x-kubernetes-int-or-string": true
																				}
																			}
																			required: ["port"]
																			type: "object"
																		}
																		terminationGracePeriodSeconds: {
																			description: """
	Optional duration in seconds the pod needs to terminate gracefully upon probe failure.
	The grace period is the duration in seconds after the processes running in the pod are sent
	a termination signal and the time when the processes are forcibly halted with a kill signal.
	Set this value longer than the expected cleanup time for your process.
	If this value is nil, the pod's terminationGracePeriodSeconds will be used. Otherwise, this
	value overrides the value provided by the pod spec.
	Value must be non-negative integer. The value zero indicates stop immediately via
	the kill signal (no opportunity to shut down).
	This is a beta field and requires enabling ProbeTerminationGracePeriod feature gate.
	Minimum value is 1. spec.terminationGracePeriodSeconds is used if unset.
	"""
																			format: "int64"
																			type:   "integer"
																		}
																		timeoutSeconds: {
																			description: """
	Number of seconds after which the probe times out.
	Defaults to 1 second. Minimum value is 1.
	More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
	"""
																			format: "int32"
																			type:   "integer"
																		}
																	}
																	type: "object"
																}
																name: {
																	description: """
	Name of the container specified as a DNS_LABEL.
	Each container in a pod must have a unique name (DNS_LABEL).
	Cannot be updated.
	"""
																	type: "string"
																}
																ports: {
																	description: """
	List of ports to expose from the container. Not specifying a port here
	DOES NOT prevent that port from being exposed. Any port which is
	listening on the default "0.0.0.0" address inside a container will be
	accessible from the network.
	Modifying this array with strategic merge patch may corrupt the data.
	For more information See https://github.com/kubernetes/kubernetes/issues/108255.
	Cannot be updated.
	"""
																	items: {
																		description: "ContainerPort represents a network port in a single container."
																		properties: {
																			containerPort: {
																				description: """
	Number of port to expose on the pod's IP address.
	This must be a valid port number, 0 < x < 65536.
	"""
																				format: "int32"
																				type:   "integer"
																			}
																			hostIP: {
																				description: "What host IP to bind the external port to."
																				type:        "string"
																			}
																			hostPort: {
																				description: """
	Number of port to expose on the host.
	If specified, this must be a valid port number, 0 < x < 65536.
	If HostNetwork is specified, this must match ContainerPort.
	Most containers do not need this.
	"""
																				format: "int32"
																				type:   "integer"
																			}
																			name: {
																				description: """
	If specified, this must be an IANA_SVC_NAME and unique within the pod. Each
	named port in a pod must have a unique name. Name for the port that can be
	referred to by services.
	"""
																				type: "string"
																			}
																			protocol: {
																				default: "TCP"
																				description: """
	Protocol for port. Must be UDP, TCP, or SCTP.
	Defaults to "TCP".
	"""
																				type: "string"
																			}
																		}
																		required: ["containerPort"]
																		type: "object"
																	}
																	type: "array"
																	"x-kubernetes-list-map-keys": [
																		"containerPort",
																		"protocol",
																	]
																	"x-kubernetes-list-type": "map"
																}
																readinessProbe: {
																	description: """
	Periodic probe of container service readiness.
	Container will be removed from service endpoints if the probe fails.
	Cannot be updated.
	More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
	"""
																	properties: {
																		exec: {
																			description: "Exec specifies the action to take."
																			properties: command: {
																				description: """
	Command is the command line to execute inside the container, the working directory for the
	command  is root ('/') in the container's filesystem. The command is simply exec'd, it is
	not run inside a shell, so traditional shell instructions ('|', etc) won't work. To use
	a shell, you need to explicitly call out to that shell.
	Exit status of 0 is treated as live/healthy and non-zero is unhealthy.
	"""
																				items: type: "string"
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																			type: "object"
																		}
																		failureThreshold: {
																			description: """
	Minimum consecutive failures for the probe to be considered failed after having succeeded.
	Defaults to 3. Minimum value is 1.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		grpc: {
																			description: "GRPC specifies an action involving a GRPC port."
																			properties: {
																				port: {
																					description: "Port number of the gRPC service. Number must be in the range 1 to 65535."
																					format:      "int32"
																					type:        "integer"
																				}
																				service: {
																					default: ""
																					description: """
	Service is the name of the service to place in the gRPC HealthCheckRequest
	(see https://github.com/grpc/grpc/blob/master/doc/health-checking.md).

	If this is not specified, the default behavior is defined by gRPC.
	"""
																					type: "string"
																				}
																			}
																			required: ["port"]
																			type: "object"
																		}
																		httpGet: {
																			description: "HTTPGet specifies the http request to perform."
																			properties: {
																				host: {
																					description: """
	Host name to connect to, defaults to the pod IP. You probably want to set
	"Host" in httpHeaders instead.
	"""
																					type: "string"
																				}
																				httpHeaders: {
																					description: "Custom headers to set in the request. HTTP allows repeated headers."
																					items: {
																						description: "HTTPHeader describes a custom header to be used in HTTP probes"
																						properties: {
																							name: {
																								description: """
	The header field name.
	This will be canonicalized upon output, so case-variant names will be understood as the same header.
	"""
																								type: "string"
																							}
																							value: {
																								description: "The header field value"
																								type:        "string"
																							}
																						}
																						required: [
																							"name",
																							"value",
																						]
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				path: {
																					description: "Path to access on the HTTP server."
																					type:        "string"
																				}
																				port: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	Name or number of the port to access on the container.
	Number must be in the range 1 to 65535.
	Name must be an IANA_SVC_NAME.
	"""
																					"x-kubernetes-int-or-string": true
																				}
																				scheme: {
																					description: """
	Scheme to use for connecting to the host.
	Defaults to HTTP.
	"""
																					type: "string"
																				}
																			}
																			required: ["port"]
																			type: "object"
																		}
																		initialDelaySeconds: {
																			description: """
	Number of seconds after the container has started before liveness probes are initiated.
	More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		periodSeconds: {
																			description: """
	How often (in seconds) to perform the probe.
	Default to 10 seconds. Minimum value is 1.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		successThreshold: {
																			description: """
	Minimum consecutive successes for the probe to be considered successful after having failed.
	Defaults to 1. Must be 1 for liveness and startup. Minimum value is 1.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		tcpSocket: {
																			description: "TCPSocket specifies an action involving a TCP port."
																			properties: {
																				host: {
																					description: "Optional: Host name to connect to, defaults to the pod IP."
																					type:        "string"
																				}
																				port: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	Number or name of the port to access on the container.
	Number must be in the range 1 to 65535.
	Name must be an IANA_SVC_NAME.
	"""
																					"x-kubernetes-int-or-string": true
																				}
																			}
																			required: ["port"]
																			type: "object"
																		}
																		terminationGracePeriodSeconds: {
																			description: """
	Optional duration in seconds the pod needs to terminate gracefully upon probe failure.
	The grace period is the duration in seconds after the processes running in the pod are sent
	a termination signal and the time when the processes are forcibly halted with a kill signal.
	Set this value longer than the expected cleanup time for your process.
	If this value is nil, the pod's terminationGracePeriodSeconds will be used. Otherwise, this
	value overrides the value provided by the pod spec.
	Value must be non-negative integer. The value zero indicates stop immediately via
	the kill signal (no opportunity to shut down).
	This is a beta field and requires enabling ProbeTerminationGracePeriod feature gate.
	Minimum value is 1. spec.terminationGracePeriodSeconds is used if unset.
	"""
																			format: "int64"
																			type:   "integer"
																		}
																		timeoutSeconds: {
																			description: """
	Number of seconds after which the probe times out.
	Defaults to 1 second. Minimum value is 1.
	More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
	"""
																			format: "int32"
																			type:   "integer"
																		}
																	}
																	type: "object"
																}
																resizePolicy: {
																	description: "Resources resize policy for the container."
																	items: {
																		description: "ContainerResizePolicy represents resource resize policy for the container."
																		properties: {
																			resourceName: {
																				description: """
	Name of the resource to which this resource resize policy applies.
	Supported values: cpu, memory.
	"""
																				type: "string"
																			}
																			restartPolicy: {
																				description: """
	Restart policy to apply when specified resource is resized.
	If not specified, it defaults to NotRequired.
	"""
																				type: "string"
																			}
																		}
																		required: [
																			"resourceName",
																			"restartPolicy",
																		]
																		type: "object"
																	}
																	type:                     "array"
																	"x-kubernetes-list-type": "atomic"
																}
																resources: {
																	description: """
	Compute Resources required by this container.
	Cannot be updated.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																	properties: {
																		claims: {
																			description: """
	Claims lists the names of resources, defined in spec.resourceClaims,
	that are used by this container.

	This is an alpha field and requires enabling the
	DynamicResourceAllocation feature gate.

	This field is immutable. It can only be set for containers.
	"""
																			items: {
																				description: "ResourceClaim references one entry in PodSpec.ResourceClaims."
																				properties: {
																					name: {
																						description: """
	Name must match the name of one entry in pod.spec.resourceClaims of
	the Pod where this field is used. It makes that resource available
	inside a container.
	"""
																						type: "string"
																					}
																					request: {
																						description: """
	Request is the name chosen for a request in the referenced claim.
	If empty, everything from the claim is made available, otherwise
	only the result of this request.
	"""
																						type: "string"
																					}
																				}
																				required: ["name"]
																				type: "object"
																			}
																			type: "array"
																			"x-kubernetes-list-map-keys": ["name"]
																			"x-kubernetes-list-type": "map"
																		}
																		limits: {
																			additionalProperties: {
																				anyOf: [{
																					type: "integer"
																				}, {
																					type: "string"
																				}]
																				pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																				"x-kubernetes-int-or-string": true
																			}
																			description: """
	Limits describes the maximum amount of compute resources allowed.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																			type: "object"
																		}
																		requests: {
																			additionalProperties: {
																				anyOf: [{
																					type: "integer"
																				}, {
																					type: "string"
																				}]
																				pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																				"x-kubernetes-int-or-string": true
																			}
																			description: """
	Requests describes the minimum amount of compute resources required.
	If Requests is omitted for a container, it defaults to Limits if that is explicitly specified,
	otherwise to an implementation-defined value. Requests cannot exceed Limits.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																			type: "object"
																		}
																	}
																	type: "object"
																}
																restartPolicy: {
																	description: """
	RestartPolicy defines the restart behavior of individual containers in a pod.
	This field may only be set for init containers, and the only allowed value is "Always".
	For non-init containers or when this field is not specified,
	the restart behavior is defined by the Pod's restart policy and the container type.
	Setting the RestartPolicy as "Always" for the init container will have the following effect:
	this init container will be continually restarted on
	exit until all regular containers have terminated. Once all regular
	containers have completed, all init containers with restartPolicy "Always"
	will be shut down. This lifecycle differs from normal init containers and
	is often referred to as a "sidecar" container. Although this init
	container still starts in the init container sequence, it does not wait
	for the container to complete before proceeding to the next init
	container. Instead, the next init container starts immediately after this
	init container is started, or after any startupProbe has successfully
	completed.
	"""
																	type: "string"
																}
																securityContext: {
																	description: """
	SecurityContext defines the security options the container should be run with.
	If set, the fields of SecurityContext override the equivalent fields of PodSecurityContext.
	More info: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
	"""
																	properties: {
																		allowPrivilegeEscalation: {
																			description: """
	AllowPrivilegeEscalation controls whether a process can gain more
	privileges than its parent process. This bool directly controls if
	the no_new_privs flag will be set on the container process.
	AllowPrivilegeEscalation is true always when the container is:
	1) run as Privileged
	2) has CAP_SYS_ADMIN
	Note that this field cannot be set when spec.os.name is windows.
	"""
																			type: "boolean"
																		}
																		appArmorProfile: {
																			description: """
	appArmorProfile is the AppArmor options to use by this container. If set, this profile
	overrides the pod's appArmorProfile.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																			properties: {
																				localhostProfile: {
																					description: """
	localhostProfile indicates a profile loaded on the node that should be used.
	The profile must be preconfigured on the node to work.
	Must match the loaded name of the profile.
	Must be set if and only if type is "Localhost".
	"""
																					type: "string"
																				}
																				type: {
																					description: """
	type indicates which kind of AppArmor profile will be applied.
	Valid options are:
	  Localhost - a profile pre-loaded on the node.
	  RuntimeDefault - the container runtime's default profile.
	  Unconfined - no AppArmor enforcement.
	"""
																					type: "string"
																				}
																			}
																			required: ["type"]
																			type: "object"
																		}
																		capabilities: {
																			description: """
	The capabilities to add/drop when running containers.
	Defaults to the default set of capabilities granted by the container runtime.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																			properties: {
																				add: {
																					description: "Added capabilities"
																					items: {
																						description: "Capability represent POSIX capabilities type"
																						type:        "string"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				drop: {
																					description: "Removed capabilities"
																					items: {
																						description: "Capability represent POSIX capabilities type"
																						type:        "string"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																			}
																			type: "object"
																		}
																		privileged: {
																			description: """
	Run container in privileged mode.
	Processes in privileged containers are essentially equivalent to root on the host.
	Defaults to false.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																			type: "boolean"
																		}
																		procMount: {
																			description: """
	procMount denotes the type of proc mount to use for the containers.
	The default value is Default which uses the container runtime defaults for
	readonly paths and masked paths.
	This requires the ProcMountType feature flag to be enabled.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																			type: "string"
																		}
																		readOnlyRootFilesystem: {
																			description: """
	Whether this container has a read-only root filesystem.
	Default is false.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																			type: "boolean"
																		}
																		runAsGroup: {
																			description: """
	The GID to run the entrypoint of the container process.
	Uses runtime default if unset.
	May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																			format: "int64"
																			type:   "integer"
																		}
																		runAsNonRoot: {
																			description: """
	Indicates that the container must run as a non-root user.
	If true, the Kubelet will validate the image at runtime to ensure that it
	does not run as UID 0 (root) and fail to start the container if it does.
	If unset or false, no such validation will be performed.
	May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	"""
																			type: "boolean"
																		}
																		runAsUser: {
																			description: """
	The UID to run the entrypoint of the container process.
	Defaults to user specified in image metadata if unspecified.
	May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																			format: "int64"
																			type:   "integer"
																		}
																		seLinuxOptions: {
																			description: """
	The SELinux context to be applied to the container.
	If unspecified, the container runtime will allocate a random SELinux context for each
	container.  May also be set in PodSecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																			properties: {
																				level: {
																					description: "Level is SELinux level label that applies to the container."
																					type:        "string"
																				}
																				role: {
																					description: "Role is a SELinux role label that applies to the container."
																					type:        "string"
																				}
																				type: {
																					description: "Type is a SELinux type label that applies to the container."
																					type:        "string"
																				}
																				user: {
																					description: "User is a SELinux user label that applies to the container."
																					type:        "string"
																				}
																			}
																			type: "object"
																		}
																		seccompProfile: {
																			description: """
	The seccomp options to use by this container. If seccomp options are
	provided at both the pod & container level, the container options
	override the pod options.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																			properties: {
																				localhostProfile: {
																					description: """
	localhostProfile indicates a profile defined in a file on the node should be used.
	The profile must be preconfigured on the node to work.
	Must be a descending path, relative to the kubelet's configured seccomp profile location.
	Must be set if type is "Localhost". Must NOT be set for any other type.
	"""
																					type: "string"
																				}
																				type: {
																					description: """
	type indicates which kind of seccomp profile will be applied.
	Valid options are:

	Localhost - a profile defined in a file on the node should be used.
	RuntimeDefault - the container runtime default profile should be used.
	Unconfined - no profile should be applied.
	"""
																					type: "string"
																				}
																			}
																			required: ["type"]
																			type: "object"
																		}
																		windowsOptions: {
																			description: """
	The Windows specific settings applied to all containers.
	If unspecified, the options from the PodSecurityContext will be used.
	If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is linux.
	"""
																			properties: {
																				gmsaCredentialSpec: {
																					description: """
	GMSACredentialSpec is where the GMSA admission webhook
	(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the
	GMSA credential spec named by the GMSACredentialSpecName field.
	"""
																					type: "string"
																				}
																				gmsaCredentialSpecName: {
																					description: "GMSACredentialSpecName is the name of the GMSA credential spec to use."
																					type:        "string"
																				}
																				hostProcess: {
																					description: """
	HostProcess determines if a container should be run as a 'Host Process' container.
	All of a Pod's containers must have the same effective HostProcess value
	(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).
	In addition, if HostProcess is true then HostNetwork must also be set to true.
	"""
																					type: "boolean"
																				}
																				runAsUserName: {
																					description: """
	The UserName in Windows to run the entrypoint of the container process.
	Defaults to the user specified in image metadata if unspecified.
	May also be set in PodSecurityContext. If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	"""
																					type: "string"
																				}
																			}
																			type: "object"
																		}
																	}
																	type: "object"
																}
																startupProbe: {
																	description: """
	StartupProbe indicates that the Pod has successfully initialized.
	If specified, no other probes are executed until this completes successfully.
	If this probe fails, the Pod will be restarted, just as if the livenessProbe failed.
	This can be used to provide different probe parameters at the beginning of a Pod's lifecycle,
	when it might take a long time to load data or warm a cache, than during steady-state operation.
	This cannot be updated.
	More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
	"""
																	properties: {
																		exec: {
																			description: "Exec specifies the action to take."
																			properties: command: {
																				description: """
	Command is the command line to execute inside the container, the working directory for the
	command  is root ('/') in the container's filesystem. The command is simply exec'd, it is
	not run inside a shell, so traditional shell instructions ('|', etc) won't work. To use
	a shell, you need to explicitly call out to that shell.
	Exit status of 0 is treated as live/healthy and non-zero is unhealthy.
	"""
																				items: type: "string"
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																			type: "object"
																		}
																		failureThreshold: {
																			description: """
	Minimum consecutive failures for the probe to be considered failed after having succeeded.
	Defaults to 3. Minimum value is 1.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		grpc: {
																			description: "GRPC specifies an action involving a GRPC port."
																			properties: {
																				port: {
																					description: "Port number of the gRPC service. Number must be in the range 1 to 65535."
																					format:      "int32"
																					type:        "integer"
																				}
																				service: {
																					default: ""
																					description: """
	Service is the name of the service to place in the gRPC HealthCheckRequest
	(see https://github.com/grpc/grpc/blob/master/doc/health-checking.md).

	If this is not specified, the default behavior is defined by gRPC.
	"""
																					type: "string"
																				}
																			}
																			required: ["port"]
																			type: "object"
																		}
																		httpGet: {
																			description: "HTTPGet specifies the http request to perform."
																			properties: {
																				host: {
																					description: """
	Host name to connect to, defaults to the pod IP. You probably want to set
	"Host" in httpHeaders instead.
	"""
																					type: "string"
																				}
																				httpHeaders: {
																					description: "Custom headers to set in the request. HTTP allows repeated headers."
																					items: {
																						description: "HTTPHeader describes a custom header to be used in HTTP probes"
																						properties: {
																							name: {
																								description: """
	The header field name.
	This will be canonicalized upon output, so case-variant names will be understood as the same header.
	"""
																								type: "string"
																							}
																							value: {
																								description: "The header field value"
																								type:        "string"
																							}
																						}
																						required: [
																							"name",
																							"value",
																						]
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				path: {
																					description: "Path to access on the HTTP server."
																					type:        "string"
																				}
																				port: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	Name or number of the port to access on the container.
	Number must be in the range 1 to 65535.
	Name must be an IANA_SVC_NAME.
	"""
																					"x-kubernetes-int-or-string": true
																				}
																				scheme: {
																					description: """
	Scheme to use for connecting to the host.
	Defaults to HTTP.
	"""
																					type: "string"
																				}
																			}
																			required: ["port"]
																			type: "object"
																		}
																		initialDelaySeconds: {
																			description: """
	Number of seconds after the container has started before liveness probes are initiated.
	More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		periodSeconds: {
																			description: """
	How often (in seconds) to perform the probe.
	Default to 10 seconds. Minimum value is 1.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		successThreshold: {
																			description: """
	Minimum consecutive successes for the probe to be considered successful after having failed.
	Defaults to 1. Must be 1 for liveness and startup. Minimum value is 1.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		tcpSocket: {
																			description: "TCPSocket specifies an action involving a TCP port."
																			properties: {
																				host: {
																					description: "Optional: Host name to connect to, defaults to the pod IP."
																					type:        "string"
																				}
																				port: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	Number or name of the port to access on the container.
	Number must be in the range 1 to 65535.
	Name must be an IANA_SVC_NAME.
	"""
																					"x-kubernetes-int-or-string": true
																				}
																			}
																			required: ["port"]
																			type: "object"
																		}
																		terminationGracePeriodSeconds: {
																			description: """
	Optional duration in seconds the pod needs to terminate gracefully upon probe failure.
	The grace period is the duration in seconds after the processes running in the pod are sent
	a termination signal and the time when the processes are forcibly halted with a kill signal.
	Set this value longer than the expected cleanup time for your process.
	If this value is nil, the pod's terminationGracePeriodSeconds will be used. Otherwise, this
	value overrides the value provided by the pod spec.
	Value must be non-negative integer. The value zero indicates stop immediately via
	the kill signal (no opportunity to shut down).
	This is a beta field and requires enabling ProbeTerminationGracePeriod feature gate.
	Minimum value is 1. spec.terminationGracePeriodSeconds is used if unset.
	"""
																			format: "int64"
																			type:   "integer"
																		}
																		timeoutSeconds: {
																			description: """
	Number of seconds after which the probe times out.
	Defaults to 1 second. Minimum value is 1.
	More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
	"""
																			format: "int32"
																			type:   "integer"
																		}
																	}
																	type: "object"
																}
																stdin: {
																	description: """
	Whether this container should allocate a buffer for stdin in the container runtime. If this
	is not set, reads from stdin in the container will always result in EOF.
	Default is false.
	"""
																	type: "boolean"
																}
																stdinOnce: {
																	description: """
	Whether the container runtime should close the stdin channel after it has been opened by
	a single attach. When stdin is true the stdin stream will remain open across multiple attach
	sessions. If stdinOnce is set to true, stdin is opened on container start, is empty until the
	first client attaches to stdin, and then remains open and accepts data until the client disconnects,
	at which time stdin is closed and remains closed until the container is restarted. If this
	flag is false, a container processes that reads from stdin will never receive an EOF.
	Default is false
	"""
																	type: "boolean"
																}
																terminationMessagePath: {
																	description: """
	Optional: Path at which the file to which the container's termination message
	will be written is mounted into the container's filesystem.
	Message written is intended to be brief final status, such as an assertion failure message.
	Will be truncated by the node if greater than 4096 bytes. The total message length across
	all containers will be limited to 12kb.
	Defaults to /dev/termination-log.
	Cannot be updated.
	"""
																	type: "string"
																}
																terminationMessagePolicy: {
																	description: """
	Indicate how the termination message should be populated. File will use the contents of
	terminationMessagePath to populate the container status message on both success and failure.
	FallbackToLogsOnError will use the last chunk of container log output if the termination
	message file is empty and the container exited with an error.
	The log output is limited to 2048 bytes or 80 lines, whichever is smaller.
	Defaults to File.
	Cannot be updated.
	"""
																	type: "string"
																}
																tty: {
																	description: """
	Whether this container should allocate a TTY for itself, also requires 'stdin' to be true.
	Default is false.
	"""
																	type: "boolean"
																}
																volumeDevices: {
																	description: "volumeDevices is the list of block devices to be used by the container."
																	items: {
																		description: "volumeDevice describes a mapping of a raw block device within a container."
																		properties: {
																			devicePath: {
																				description: "devicePath is the path inside of the container that the device will be mapped to."
																				type:        "string"
																			}
																			name: {
																				description: "name must match the name of a persistentVolumeClaim in the pod"
																				type:        "string"
																			}
																		}
																		required: [
																			"devicePath",
																			"name",
																		]
																		type: "object"
																	}
																	type: "array"
																	"x-kubernetes-list-map-keys": ["devicePath"]
																	"x-kubernetes-list-type": "map"
																}
																volumeMounts: {
																	description: """
	Pod volumes to mount into the container's filesystem.
	Cannot be updated.
	"""
																	items: {
																		description: "VolumeMount describes a mounting of a Volume within a container."
																		properties: {
																			mountPath: {
																				description: """
	Path within the container at which the volume should be mounted.  Must
	not contain ':'.
	"""
																				type: "string"
																			}
																			mountPropagation: {
																				description: """
	mountPropagation determines how mounts are propagated from the host
	to container and the other way around.
	When not set, MountPropagationNone is used.
	This field is beta in 1.10.
	When RecursiveReadOnly is set to IfPossible or to Enabled, MountPropagation must be None or unspecified
	(which defaults to None).
	"""
																				type: "string"
																			}
																			name: {
																				description: "This must match the Name of a Volume."
																				type:        "string"
																			}
																			readOnly: {
																				description: """
	Mounted read-only if true, read-write otherwise (false or unspecified).
	Defaults to false.
	"""
																				type: "boolean"
																			}
																			recursiveReadOnly: {
																				description: """
	RecursiveReadOnly specifies whether read-only mounts should be handled
	recursively.

	If ReadOnly is false, this field has no meaning and must be unspecified.

	If ReadOnly is true, and this field is set to Disabled, the mount is not made
	recursively read-only.  If this field is set to IfPossible, the mount is made
	recursively read-only, if it is supported by the container runtime.  If this
	field is set to Enabled, the mount is made recursively read-only if it is
	supported by the container runtime, otherwise the pod will not be started and
	an error will be generated to indicate the reason.

	If this field is set to IfPossible or Enabled, MountPropagation must be set to
	None (or be unspecified, which defaults to None).

	If this field is not specified, it is treated as an equivalent of Disabled.
	"""
																				type: "string"
																			}
																			subPath: {
																				description: """
	Path within the volume from which the container's volume should be mounted.
	Defaults to "" (volume's root).
	"""
																				type: "string"
																			}
																			subPathExpr: {
																				description: """
	Expanded path within the volume from which the container's volume should be mounted.
	Behaves similarly to SubPath but environment variable references $(VAR_NAME) are expanded using the container's environment.
	Defaults to "" (volume's root).
	SubPathExpr and SubPath are mutually exclusive.
	"""
																				type: "string"
																			}
																		}
																		required: [
																			"mountPath",
																			"name",
																		]
																		type: "object"
																	}
																	type: "array"
																	"x-kubernetes-list-map-keys": ["mountPath"]
																	"x-kubernetes-list-type": "map"
																}
																workingDir: {
																	description: """
	Container's working directory.
	If not specified, the container runtime's default will be used, which
	might be configured in the container image.
	Cannot be updated.
	"""
																	type: "string"
																}
															}
															required: ["name"]
															type: "object"
														}
														type: "array"
													}
													name: {
														description: """
	Name of the deployment.
	When unset, this defaults to an autogenerated name.
	"""
														type: "string"
													}
													patch: {
														description: "Patch defines how to perform the patch operation to deployment"
														properties: {
															type: {
																description: """
	Type is the type of merge operation to perform

	By default, StrategicMerge is used as the patch type.
	"""
																type: "string"
															}
															value: {
																description:                            "Object contains the raw configuration for merged object"
																"x-kubernetes-preserve-unknown-fields": true
															}
														}
														required: ["value"]
														type: "object"
													}
													pod: {
														description: "Pod defines the desired specification of pod."
														properties: {
															affinity: {
																description: "If specified, the pod's scheduling constraints."
																properties: {
																	nodeAffinity: {
																		description: "Describes node affinity scheduling rules for the pod."
																		properties: {
																			preferredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	The scheduler will prefer to schedule pods to nodes that satisfy
	the affinity expressions specified by this field, but it may choose
	a node that violates one or more of the expressions. The node that is
	most preferred is the one with the greatest sum of weights, i.e.
	for each node that meets all of the scheduling requirements (resource
	request, requiredDuringScheduling affinity expressions, etc.),
	compute a sum by iterating through the elements of this field and adding
	"weight" to the sum if the node matches the corresponding matchExpressions; the
	node(s) with the highest sum are the most preferred.
	"""
																				items: {
																					description: """
	An empty preferred scheduling term matches all objects with implicit weight 0
	(i.e. it's a no-op). A null preferred scheduling term matches no objects (i.e. is also a no-op).
	"""
																					properties: {
																						preference: {
																							description: "A node selector term, associated with the corresponding weight."
																							properties: {
																								matchExpressions: {
																									description: "A list of node selector requirements by node's labels."
																									items: {
																										description: """
	A node selector requirement is a selector that contains values, a key, and an operator
	that relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "The label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	Represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	An array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. If the operator is Gt or Lt, the values
	array must have a single element, which will be interpreted as an integer.
	This array is replaced during a strategic merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								matchFields: {
																									description: "A list of node selector requirements by node's fields."
																									items: {
																										description: """
	A node selector requirement is a selector that contains values, a key, and an operator
	that relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "The label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	Represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	An array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. If the operator is Gt or Lt, the values
	array must have a single element, which will be interpreted as an integer.
	This array is replaced during a strategic merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						weight: {
																							description: "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100."
																							format:      "int32"
																							type:        "integer"
																						}
																					}
																					required: [
																						"preference",
																						"weight",
																					]
																					type: "object"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																			requiredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	If the affinity requirements specified by this field are not met at
	scheduling time, the pod will not be scheduled onto the node.
	If the affinity requirements specified by this field cease to be met
	at some point during pod execution (e.g. due to an update), the system
	may or may not try to eventually evict the pod from its node.
	"""
																				properties: nodeSelectorTerms: {
																					description: "Required. A list of node selector terms. The terms are ORed."
																					items: {
																						description: """
	A null or empty node selector term matches no objects. The requirements of
	them are ANDed.
	The TopologySelectorTerm type implements a subset of the NodeSelectorTerm.
	"""
																						properties: {
																							matchExpressions: {
																								description: "A list of node selector requirements by node's labels."
																								items: {
																									description: """
	A node selector requirement is a selector that contains values, a key, and an operator
	that relates the key and values.
	"""
																									properties: {
																										key: {
																											description: "The label key that the selector applies to."
																											type:        "string"
																										}
																										operator: {
																											description: """
	Represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
	"""
																											type: "string"
																										}
																										values: {
																											description: """
	An array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. If the operator is Gt or Lt, the values
	array must have a single element, which will be interpreted as an integer.
	This array is replaced during a strategic merge patch.
	"""
																											items: type: "string"
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																									}
																									required: [
																										"key",
																										"operator",
																									]
																									type: "object"
																								}
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																							matchFields: {
																								description: "A list of node selector requirements by node's fields."
																								items: {
																									description: """
	A node selector requirement is a selector that contains values, a key, and an operator
	that relates the key and values.
	"""
																									properties: {
																										key: {
																											description: "The label key that the selector applies to."
																											type:        "string"
																										}
																										operator: {
																											description: """
	Represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
	"""
																											type: "string"
																										}
																										values: {
																											description: """
	An array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. If the operator is Gt or Lt, the values
	array must have a single element, which will be interpreted as an integer.
	This array is replaced during a strategic merge patch.
	"""
																											items: type: "string"
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																									}
																									required: [
																										"key",
																										"operator",
																									]
																									type: "object"
																								}
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																						}
																						type:                    "object"
																						"x-kubernetes-map-type": "atomic"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				required: ["nodeSelectorTerms"]
																				type:                    "object"
																				"x-kubernetes-map-type": "atomic"
																			}
																		}
																		type: "object"
																	}
																	podAffinity: {
																		description: "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s))."
																		properties: {
																			preferredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	The scheduler will prefer to schedule pods to nodes that satisfy
	the affinity expressions specified by this field, but it may choose
	a node that violates one or more of the expressions. The node that is
	most preferred is the one with the greatest sum of weights, i.e.
	for each node that meets all of the scheduling requirements (resource
	request, requiredDuringScheduling affinity expressions, etc.),
	compute a sum by iterating through the elements of this field and adding
	"weight" to the sum if the node has pods which matches the corresponding podAffinityTerm; the
	node(s) with the highest sum are the most preferred.
	"""
																				items: {
																					description: "The weights of all of the matched WeightedPodAffinityTerm fields are added per-node to find the most preferred node(s)"
																					properties: {
																						podAffinityTerm: {
																							description: "Required. A pod affinity term, associated with the corresponding weight."
																							properties: {
																								labelSelector: {
																									description: """
	A label query over a set of resources, in this case pods.
	If it's null, this PodAffinityTerm matches with no Pods.
	"""
																									properties: {
																										matchExpressions: {
																											description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																											items: {
																												description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																												properties: {
																													key: {
																														description: "key is the label key that the selector applies to."
																														type:        "string"
																													}
																													operator: {
																														description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																														type: "string"
																													}
																													values: {
																														description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																														items: type: "string"
																														type:                     "array"
																														"x-kubernetes-list-type": "atomic"
																													}
																												}
																												required: [
																													"key",
																													"operator",
																												]
																												type: "object"
																											}
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																										matchLabels: {
																											additionalProperties: type: "string"
																											description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																											type: "object"
																										}
																									}
																									type:                    "object"
																									"x-kubernetes-map-type": "atomic"
																								}
																								matchLabelKeys: {
																									description: """
	MatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both matchLabelKeys and labelSelector.
	Also, matchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								mismatchLabelKeys: {
																									description: """
	MismatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both mismatchLabelKeys and labelSelector.
	Also, mismatchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								namespaceSelector: {
																									description: """
	A label query over the set of namespaces that the term applies to.
	The term is applied to the union of the namespaces selected by this field
	and the ones listed in the namespaces field.
	null selector and null or empty namespaces list means "this pod's namespace".
	An empty selector ({}) matches all namespaces.
	"""
																									properties: {
																										matchExpressions: {
																											description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																											items: {
																												description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																												properties: {
																													key: {
																														description: "key is the label key that the selector applies to."
																														type:        "string"
																													}
																													operator: {
																														description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																														type: "string"
																													}
																													values: {
																														description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																														items: type: "string"
																														type:                     "array"
																														"x-kubernetes-list-type": "atomic"
																													}
																												}
																												required: [
																													"key",
																													"operator",
																												]
																												type: "object"
																											}
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																										matchLabels: {
																											additionalProperties: type: "string"
																											description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																											type: "object"
																										}
																									}
																									type:                    "object"
																									"x-kubernetes-map-type": "atomic"
																								}
																								namespaces: {
																									description: """
	namespaces specifies a static list of namespace names that the term applies to.
	The term is applied to the union of the namespaces listed in this field
	and the ones selected by namespaceSelector.
	null or empty namespaces list and null namespaceSelector means "this pod's namespace".
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								topologyKey: {
																									description: """
	This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching
	the labelSelector in the specified namespaces, where co-located is defined as running on a node
	whose value of the label with key topologyKey matches that of any node on which any of the
	selected pods is running.
	Empty topologyKey is not allowed.
	"""
																									type: "string"
																								}
																							}
																							required: ["topologyKey"]
																							type: "object"
																						}
																						weight: {
																							description: """
	weight associated with matching the corresponding podAffinityTerm,
	in the range 1-100.
	"""
																							format: "int32"
																							type:   "integer"
																						}
																					}
																					required: [
																						"podAffinityTerm",
																						"weight",
																					]
																					type: "object"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																			requiredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	If the affinity requirements specified by this field are not met at
	scheduling time, the pod will not be scheduled onto the node.
	If the affinity requirements specified by this field cease to be met
	at some point during pod execution (e.g. due to a pod label update), the
	system may or may not try to eventually evict the pod from its node.
	When there are multiple elements, the lists of nodes corresponding to each
	podAffinityTerm are intersected, i.e. all terms must be satisfied.
	"""
																				items: {
																					description: """
	Defines a set of pods (namely those matching the labelSelector
	relative to the given namespace(s)) that this pod should be
	co-located (affinity) or not co-located (anti-affinity) with,
	where co-located is defined as running on a node whose value of
	the label with key <topologyKey> matches that of any node on which
	a pod of the set of pods is running
	"""
																					properties: {
																						labelSelector: {
																							description: """
	A label query over a set of resources, in this case pods.
	If it's null, this PodAffinityTerm matches with no Pods.
	"""
																							properties: {
																								matchExpressions: {
																									description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																									items: {
																										description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "key is the label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								matchLabels: {
																									additionalProperties: type: "string"
																									description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																									type: "object"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						matchLabelKeys: {
																							description: """
	MatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both matchLabelKeys and labelSelector.
	Also, matchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						mismatchLabelKeys: {
																							description: """
	MismatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both mismatchLabelKeys and labelSelector.
	Also, mismatchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						namespaceSelector: {
																							description: """
	A label query over the set of namespaces that the term applies to.
	The term is applied to the union of the namespaces selected by this field
	and the ones listed in the namespaces field.
	null selector and null or empty namespaces list means "this pod's namespace".
	An empty selector ({}) matches all namespaces.
	"""
																							properties: {
																								matchExpressions: {
																									description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																									items: {
																										description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "key is the label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								matchLabels: {
																									additionalProperties: type: "string"
																									description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																									type: "object"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						namespaces: {
																							description: """
	namespaces specifies a static list of namespace names that the term applies to.
	The term is applied to the union of the namespaces listed in this field
	and the ones selected by namespaceSelector.
	null or empty namespaces list and null namespaceSelector means "this pod's namespace".
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						topologyKey: {
																							description: """
	This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching
	the labelSelector in the specified namespaces, where co-located is defined as running on a node
	whose value of the label with key topologyKey matches that of any node on which any of the
	selected pods is running.
	Empty topologyKey is not allowed.
	"""
																							type: "string"
																						}
																					}
																					required: ["topologyKey"]
																					type: "object"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																		}
																		type: "object"
																	}
																	podAntiAffinity: {
																		description: "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s))."
																		properties: {
																			preferredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	The scheduler will prefer to schedule pods to nodes that satisfy
	the anti-affinity expressions specified by this field, but it may choose
	a node that violates one or more of the expressions. The node that is
	most preferred is the one with the greatest sum of weights, i.e.
	for each node that meets all of the scheduling requirements (resource
	request, requiredDuringScheduling anti-affinity expressions, etc.),
	compute a sum by iterating through the elements of this field and adding
	"weight" to the sum if the node has pods which matches the corresponding podAffinityTerm; the
	node(s) with the highest sum are the most preferred.
	"""
																				items: {
																					description: "The weights of all of the matched WeightedPodAffinityTerm fields are added per-node to find the most preferred node(s)"
																					properties: {
																						podAffinityTerm: {
																							description: "Required. A pod affinity term, associated with the corresponding weight."
																							properties: {
																								labelSelector: {
																									description: """
	A label query over a set of resources, in this case pods.
	If it's null, this PodAffinityTerm matches with no Pods.
	"""
																									properties: {
																										matchExpressions: {
																											description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																											items: {
																												description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																												properties: {
																													key: {
																														description: "key is the label key that the selector applies to."
																														type:        "string"
																													}
																													operator: {
																														description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																														type: "string"
																													}
																													values: {
																														description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																														items: type: "string"
																														type:                     "array"
																														"x-kubernetes-list-type": "atomic"
																													}
																												}
																												required: [
																													"key",
																													"operator",
																												]
																												type: "object"
																											}
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																										matchLabels: {
																											additionalProperties: type: "string"
																											description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																											type: "object"
																										}
																									}
																									type:                    "object"
																									"x-kubernetes-map-type": "atomic"
																								}
																								matchLabelKeys: {
																									description: """
	MatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both matchLabelKeys and labelSelector.
	Also, matchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								mismatchLabelKeys: {
																									description: """
	MismatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both mismatchLabelKeys and labelSelector.
	Also, mismatchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								namespaceSelector: {
																									description: """
	A label query over the set of namespaces that the term applies to.
	The term is applied to the union of the namespaces selected by this field
	and the ones listed in the namespaces field.
	null selector and null or empty namespaces list means "this pod's namespace".
	An empty selector ({}) matches all namespaces.
	"""
																									properties: {
																										matchExpressions: {
																											description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																											items: {
																												description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																												properties: {
																													key: {
																														description: "key is the label key that the selector applies to."
																														type:        "string"
																													}
																													operator: {
																														description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																														type: "string"
																													}
																													values: {
																														description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																														items: type: "string"
																														type:                     "array"
																														"x-kubernetes-list-type": "atomic"
																													}
																												}
																												required: [
																													"key",
																													"operator",
																												]
																												type: "object"
																											}
																											type:                     "array"
																											"x-kubernetes-list-type": "atomic"
																										}
																										matchLabels: {
																											additionalProperties: type: "string"
																											description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																											type: "object"
																										}
																									}
																									type:                    "object"
																									"x-kubernetes-map-type": "atomic"
																								}
																								namespaces: {
																									description: """
	namespaces specifies a static list of namespace names that the term applies to.
	The term is applied to the union of the namespaces listed in this field
	and the ones selected by namespaceSelector.
	null or empty namespaces list and null namespaceSelector means "this pod's namespace".
	"""
																									items: type: "string"
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								topologyKey: {
																									description: """
	This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching
	the labelSelector in the specified namespaces, where co-located is defined as running on a node
	whose value of the label with key topologyKey matches that of any node on which any of the
	selected pods is running.
	Empty topologyKey is not allowed.
	"""
																									type: "string"
																								}
																							}
																							required: ["topologyKey"]
																							type: "object"
																						}
																						weight: {
																							description: """
	weight associated with matching the corresponding podAffinityTerm,
	in the range 1-100.
	"""
																							format: "int32"
																							type:   "integer"
																						}
																					}
																					required: [
																						"podAffinityTerm",
																						"weight",
																					]
																					type: "object"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																			requiredDuringSchedulingIgnoredDuringExecution: {
																				description: """
	If the anti-affinity requirements specified by this field are not met at
	scheduling time, the pod will not be scheduled onto the node.
	If the anti-affinity requirements specified by this field cease to be met
	at some point during pod execution (e.g. due to a pod label update), the
	system may or may not try to eventually evict the pod from its node.
	When there are multiple elements, the lists of nodes corresponding to each
	podAffinityTerm are intersected, i.e. all terms must be satisfied.
	"""
																				items: {
																					description: """
	Defines a set of pods (namely those matching the labelSelector
	relative to the given namespace(s)) that this pod should be
	co-located (affinity) or not co-located (anti-affinity) with,
	where co-located is defined as running on a node whose value of
	the label with key <topologyKey> matches that of any node on which
	a pod of the set of pods is running
	"""
																					properties: {
																						labelSelector: {
																							description: """
	A label query over a set of resources, in this case pods.
	If it's null, this PodAffinityTerm matches with no Pods.
	"""
																							properties: {
																								matchExpressions: {
																									description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																									items: {
																										description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "key is the label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								matchLabels: {
																									additionalProperties: type: "string"
																									description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																									type: "object"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						matchLabelKeys: {
																							description: """
	MatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both matchLabelKeys and labelSelector.
	Also, matchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						mismatchLabelKeys: {
																							description: """
	MismatchLabelKeys is a set of pod label keys to select which pods will
	be taken into consideration. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`
	to select the group of existing pods which pods will be taken into consideration
	for the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming
	pod labels will be ignored. The default value is empty.
	The same key is forbidden to exist in both mismatchLabelKeys and labelSelector.
	Also, mismatchLabelKeys cannot be set when labelSelector isn't set.
	This is a beta field and requires enabling MatchLabelKeysInPodAffinity feature gate (enabled by default).
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						namespaceSelector: {
																							description: """
	A label query over the set of namespaces that the term applies to.
	The term is applied to the union of the namespaces selected by this field
	and the ones listed in the namespaces field.
	null selector and null or empty namespaces list means "this pod's namespace".
	An empty selector ({}) matches all namespaces.
	"""
																							properties: {
																								matchExpressions: {
																									description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																									items: {
																										description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																										properties: {
																											key: {
																												description: "key is the label key that the selector applies to."
																												type:        "string"
																											}
																											operator: {
																												description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																												type: "string"
																											}
																											values: {
																												description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																												items: type: "string"
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: [
																											"key",
																											"operator",
																										]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								matchLabels: {
																									additionalProperties: type: "string"
																									description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																									type: "object"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						namespaces: {
																							description: """
	namespaces specifies a static list of namespace names that the term applies to.
	The term is applied to the union of the namespaces listed in this field
	and the ones selected by namespaceSelector.
	null or empty namespaces list and null namespaceSelector means "this pod's namespace".
	"""
																							items: type: "string"
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						topologyKey: {
																							description: """
	This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching
	the labelSelector in the specified namespaces, where co-located is defined as running on a node
	whose value of the label with key topologyKey matches that of any node on which any of the
	selected pods is running.
	Empty topologyKey is not allowed.
	"""
																							type: "string"
																						}
																					}
																					required: ["topologyKey"]
																					type: "object"
																				}
																				type:                     "array"
																				"x-kubernetes-list-type": "atomic"
																			}
																		}
																		type: "object"
																	}
																}
																type: "object"
															}
															annotations: {
																additionalProperties: type: "string"
																description: """
	Annotations are the annotations that should be appended to the pods.
	By default, no pod annotations are appended.
	"""
																type: "object"
															}
															imagePullSecrets: {
																description: """
	ImagePullSecrets is an optional list of references to secrets
	in the same namespace to use for pulling any of the images used by this PodSpec.
	If specified, these secrets will be passed to individual puller implementations for them to use.
	More info: https://kubernetes.io/docs/concepts/containers/images#specifying-imagepullsecrets-on-a-pod
	"""
																items: {
																	description: """
	LocalObjectReference contains enough information to let you locate the
	referenced object inside the same namespace.
	"""
																	properties: name: {
																		default: ""
																		description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																		type: "string"
																	}
																	type:                    "object"
																	"x-kubernetes-map-type": "atomic"
																}
																type: "array"
															}
															labels: {
																additionalProperties: type: "string"
																description: """
	Labels are the additional labels that should be tagged to the pods.
	By default, no additional pod labels are tagged.
	"""
																type: "object"
															}
															nodeSelector: {
																additionalProperties: type: "string"
																description: """
	NodeSelector is a selector which must be true for the pod to fit on a node.
	Selector which must match a node's labels for the pod to be scheduled on that node.
	More info: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
	"""
																type: "object"
															}
															securityContext: {
																description: """
	SecurityContext holds pod-level security attributes and common container settings.
	Optional: Defaults to empty.  See type description for default values of each field.
	"""
																properties: {
																	appArmorProfile: {
																		description: """
	appArmorProfile is the AppArmor options to use by the containers in this pod.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			localhostProfile: {
																				description: """
	localhostProfile indicates a profile loaded on the node that should be used.
	The profile must be preconfigured on the node to work.
	Must match the loaded name of the profile.
	Must be set if and only if type is "Localhost".
	"""
																				type: "string"
																			}
																			type: {
																				description: """
	type indicates which kind of AppArmor profile will be applied.
	Valid options are:
	  Localhost - a profile pre-loaded on the node.
	  RuntimeDefault - the container runtime's default profile.
	  Unconfined - no AppArmor enforcement.
	"""
																				type: "string"
																			}
																		}
																		required: ["type"]
																		type: "object"
																	}
																	fsGroup: {
																		description: """
	A special supplemental group that applies to all containers in a pod.
	Some volume types allow the Kubelet to change the ownership of that volume
	to be owned by the pod:

	1. The owning GID will be the FSGroup
	2. The setgid bit is set (new files created in the volume will be owned by FSGroup)
	3. The permission bits are OR'd with rw-rw----

	If unset, the Kubelet will not modify the ownership and permissions of any volume.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		format: "int64"
																		type:   "integer"
																	}
																	fsGroupChangePolicy: {
																		description: """
	fsGroupChangePolicy defines behavior of changing ownership and permission of the volume
	before being exposed inside Pod. This field will only apply to
	volume types which support fsGroup based ownership(and permissions).
	It will have no effect on ephemeral volume types such as: secret, configmaps
	and emptydir.
	Valid values are "OnRootMismatch" and "Always". If not specified, "Always" is used.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "string"
																	}
																	runAsGroup: {
																		description: """
	The GID to run the entrypoint of the container process.
	Uses runtime default if unset.
	May also be set in SecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence
	for that container.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		format: "int64"
																		type:   "integer"
																	}
																	runAsNonRoot: {
																		description: """
	Indicates that the container must run as a non-root user.
	If true, the Kubelet will validate the image at runtime to ensure that it
	does not run as UID 0 (root) and fail to start the container if it does.
	If unset or false, no such validation will be performed.
	May also be set in SecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	"""
																		type: "boolean"
																	}
																	runAsUser: {
																		description: """
	The UID to run the entrypoint of the container process.
	Defaults to user specified in image metadata if unspecified.
	May also be set in SecurityContext.  If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence
	for that container.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		format: "int64"
																		type:   "integer"
																	}
																	seLinuxOptions: {
																		description: """
	The SELinux context to be applied to all containers.
	If unspecified, the container runtime will allocate a random SELinux context for each
	container.  May also be set in SecurityContext.  If set in
	both SecurityContext and PodSecurityContext, the value specified in SecurityContext
	takes precedence for that container.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			level: {
																				description: "Level is SELinux level label that applies to the container."
																				type:        "string"
																			}
																			role: {
																				description: "Role is a SELinux role label that applies to the container."
																				type:        "string"
																			}
																			type: {
																				description: "Type is a SELinux type label that applies to the container."
																				type:        "string"
																			}
																			user: {
																				description: "User is a SELinux user label that applies to the container."
																				type:        "string"
																			}
																		}
																		type: "object"
																	}
																	seccompProfile: {
																		description: """
	The seccomp options to use by the containers in this pod.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		properties: {
																			localhostProfile: {
																				description: """
	localhostProfile indicates a profile defined in a file on the node should be used.
	The profile must be preconfigured on the node to work.
	Must be a descending path, relative to the kubelet's configured seccomp profile location.
	Must be set if type is "Localhost". Must NOT be set for any other type.
	"""
																				type: "string"
																			}
																			type: {
																				description: """
	type indicates which kind of seccomp profile will be applied.
	Valid options are:

	Localhost - a profile defined in a file on the node should be used.
	RuntimeDefault - the container runtime default profile should be used.
	Unconfined - no profile should be applied.
	"""
																				type: "string"
																			}
																		}
																		required: ["type"]
																		type: "object"
																	}
																	supplementalGroups: {
																		description: """
	A list of groups applied to the first process run in each container, in
	addition to the container's primary GID and fsGroup (if specified).  If
	the SupplementalGroupsPolicy feature is enabled, the
	supplementalGroupsPolicy field determines whether these are in addition
	to or instead of any group memberships defined in the container image.
	If unspecified, no additional groups are added, though group memberships
	defined in the container image may still be used, depending on the
	supplementalGroupsPolicy field.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		items: {
																			format: "int64"
																			type:   "integer"
																		}
																		type:                     "array"
																		"x-kubernetes-list-type": "atomic"
																	}
																	supplementalGroupsPolicy: {
																		description: """
	Defines how supplemental groups of the first container processes are calculated.
	Valid values are "Merge" and "Strict". If not specified, "Merge" is used.
	(Alpha) Using the field requires the SupplementalGroupsPolicy feature gate to be enabled
	and the container runtime must implement support for this feature.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		type: "string"
																	}
																	sysctls: {
																		description: """
	Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported
	sysctls (by the container runtime) might fail to launch.
	Note that this field cannot be set when spec.os.name is windows.
	"""
																		items: {
																			description: "Sysctl defines a kernel parameter to be set"
																			properties: {
																				name: {
																					description: "Name of a property to set"
																					type:        "string"
																				}
																				value: {
																					description: "Value of a property to set"
																					type:        "string"
																				}
																			}
																			required: [
																				"name",
																				"value",
																			]
																			type: "object"
																		}
																		type:                     "array"
																		"x-kubernetes-list-type": "atomic"
																	}
																	windowsOptions: {
																		description: """
	The Windows specific settings applied to all containers.
	If unspecified, the options within a container's SecurityContext will be used.
	If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.
	Note that this field cannot be set when spec.os.name is linux.
	"""
																		properties: {
																			gmsaCredentialSpec: {
																				description: """
	GMSACredentialSpec is where the GMSA admission webhook
	(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the
	GMSA credential spec named by the GMSACredentialSpecName field.
	"""
																				type: "string"
																			}
																			gmsaCredentialSpecName: {
																				description: "GMSACredentialSpecName is the name of the GMSA credential spec to use."
																				type:        "string"
																			}
																			hostProcess: {
																				description: """
	HostProcess determines if a container should be run as a 'Host Process' container.
	All of a Pod's containers must have the same effective HostProcess value
	(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).
	In addition, if HostProcess is true then HostNetwork must also be set to true.
	"""
																				type: "boolean"
																			}
																			runAsUserName: {
																				description: """
	The UserName in Windows to run the entrypoint of the container process.
	Defaults to the user specified in image metadata if unspecified.
	May also be set in PodSecurityContext. If set in both SecurityContext and
	PodSecurityContext, the value specified in SecurityContext takes precedence.
	"""
																				type: "string"
																			}
																		}
																		type: "object"
																	}
																}
																type: "object"
															}
															tolerations: {
																description: "If specified, the pod's tolerations."
																items: {
																	description: """
	The pod this Toleration is attached to tolerates any taint that matches
	the triple <key,value,effect> using the matching operator <operator>.
	"""
																	properties: {
																		effect: {
																			description: """
	Effect indicates the taint effect to match. Empty means match all taint effects.
	When specified, allowed values are NoSchedule, PreferNoSchedule and NoExecute.
	"""
																			type: "string"
																		}
																		key: {
																			description: """
	Key is the taint key that the toleration applies to. Empty means match all taint keys.
	If the key is empty, operator must be Exists; this combination means to match all values and all keys.
	"""
																			type: "string"
																		}
																		operator: {
																			description: """
	Operator represents a key's relationship to the value.
	Valid operators are Exists and Equal. Defaults to Equal.
	Exists is equivalent to wildcard for value, so that a pod can
	tolerate all taints of a particular category.
	"""
																			type: "string"
																		}
																		tolerationSeconds: {
																			description: """
	TolerationSeconds represents the period of time the toleration (which must be
	of effect NoExecute, otherwise this field is ignored) tolerates the taint. By default,
	it is not set, which means tolerate the taint forever (do not evict). Zero and
	negative values will be treated as 0 (evict immediately) by the system.
	"""
																			format: "int64"
																			type:   "integer"
																		}
																		value: {
																			description: """
	Value is the taint value the toleration matches to.
	If the operator is Exists, the value should be empty, otherwise just a regular string.
	"""
																			type: "string"
																		}
																	}
																	type: "object"
																}
																type: "array"
															}
															topologySpreadConstraints: {
																description: """
	TopologySpreadConstraints describes how a group of pods ought to spread across topology
	domains. Scheduler will schedule pods in a way which abides by the constraints.
	All topologySpreadConstraints are ANDed.
	"""
																items: {
																	description: "TopologySpreadConstraint specifies how to spread matching pods among the given topology."
																	properties: {
																		labelSelector: {
																			description: """
	LabelSelector is used to find matching pods.
	Pods that match this label selector are counted to determine the number of pods
	in their corresponding topology domain.
	"""
																			properties: {
																				matchExpressions: {
																					description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																					items: {
																						description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																						properties: {
																							key: {
																								description: "key is the label key that the selector applies to."
																								type:        "string"
																							}
																							operator: {
																								description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																								type: "string"
																							}
																							values: {
																								description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																								items: type: "string"
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																						}
																						required: [
																							"key",
																							"operator",
																						]
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				matchLabels: {
																					additionalProperties: type: "string"
																					description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																					type: "object"
																				}
																			}
																			type:                    "object"
																			"x-kubernetes-map-type": "atomic"
																		}
																		matchLabelKeys: {
																			description: """
	MatchLabelKeys is a set of pod label keys to select the pods over which
	spreading will be calculated. The keys are used to lookup values from the
	incoming pod labels, those key-value labels are ANDed with labelSelector
	to select the group of existing pods over which spreading will be calculated
	for the incoming pod. The same key is forbidden to exist in both MatchLabelKeys and LabelSelector.
	MatchLabelKeys cannot be set when LabelSelector isn't set.
	Keys that don't exist in the incoming pod labels will
	be ignored. A null or empty list means only match against labelSelector.

	This is a beta field and requires the MatchLabelKeysInPodTopologySpread feature gate to be enabled (enabled by default).
	"""
																			items: type: "string"
																			type:                     "array"
																			"x-kubernetes-list-type": "atomic"
																		}
																		maxSkew: {
																			description: """
	MaxSkew describes the degree to which pods may be unevenly distributed.
	When `whenUnsatisfiable=DoNotSchedule`, it is the maximum permitted difference
	between the number of matching pods in the target topology and the global minimum.
	The global minimum is the minimum number of matching pods in an eligible domain
	or zero if the number of eligible domains is less than MinDomains.
	For example, in a 3-zone cluster, MaxSkew is set to 1, and pods with the same
	labelSelector spread as 2/2/1:
	In this case, the global minimum is 1.
	| zone1 | zone2 | zone3 |
	|  P P  |  P P  |   P   |
	- if MaxSkew is 1, incoming pod can only be scheduled to zone3 to become 2/2/2;
	scheduling it onto zone1(zone2) would make the ActualSkew(3-1) on zone1(zone2)
	violate MaxSkew(1).
	- if MaxSkew is 2, incoming pod can be scheduled onto any zone.
	When `whenUnsatisfiable=ScheduleAnyway`, it is used to give higher precedence
	to topologies that satisfy it.
	It's a required field. Default value is 1 and 0 is not allowed.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		minDomains: {
																			description: """
	MinDomains indicates a minimum number of eligible domains.
	When the number of eligible domains with matching topology keys is less than minDomains,
	Pod Topology Spread treats "global minimum" as 0, and then the calculation of Skew is performed.
	And when the number of eligible domains with matching topology keys equals or greater than minDomains,
	this value has no effect on scheduling.
	As a result, when the number of eligible domains is less than minDomains,
	scheduler won't schedule more than maxSkew Pods to those domains.
	If value is nil, the constraint behaves as if MinDomains is equal to 1.
	Valid values are integers greater than 0.
	When value is not nil, WhenUnsatisfiable must be DoNotSchedule.

	For example, in a 3-zone cluster, MaxSkew is set to 2, MinDomains is set to 5 and pods with the same
	labelSelector spread as 2/2/2:
	| zone1 | zone2 | zone3 |
	|  P P  |  P P  |  P P  |
	The number of domains is less than 5(MinDomains), so "global minimum" is treated as 0.
	In this situation, new pod with the same labelSelector cannot be scheduled,
	because computed skew will be 3(3 - 0) if new Pod is scheduled to any of the three zones,
	it will violate MaxSkew.
	"""
																			format: "int32"
																			type:   "integer"
																		}
																		nodeAffinityPolicy: {
																			description: """
	NodeAffinityPolicy indicates how we will treat Pod's nodeAffinity/nodeSelector
	when calculating pod topology spread skew. Options are:
	- Honor: only nodes matching nodeAffinity/nodeSelector are included in the calculations.
	- Ignore: nodeAffinity/nodeSelector are ignored. All nodes are included in the calculations.

	If this value is nil, the behavior is equivalent to the Honor policy.
	This is a beta-level feature default enabled by the NodeInclusionPolicyInPodTopologySpread feature flag.
	"""
																			type: "string"
																		}
																		nodeTaintsPolicy: {
																			description: """
	NodeTaintsPolicy indicates how we will treat node taints when calculating
	pod topology spread skew. Options are:
	- Honor: nodes without taints, along with tainted nodes for which the incoming pod
	has a toleration, are included.
	- Ignore: node taints are ignored. All nodes are included.

	If this value is nil, the behavior is equivalent to the Ignore policy.
	This is a beta-level feature default enabled by the NodeInclusionPolicyInPodTopologySpread feature flag.
	"""
																			type: "string"
																		}
																		topologyKey: {
																			description: """
	TopologyKey is the key of node labels. Nodes that have a label with this key
	and identical values are considered to be in the same topology.
	We consider each <key, value> as a "bucket", and try to put balanced number
	of pods into each bucket.
	We define a domain as a particular instance of a topology.
	Also, we define an eligible domain as a domain whose nodes meet the requirements of
	nodeAffinityPolicy and nodeTaintsPolicy.
	e.g. If TopologyKey is "kubernetes.io/hostname", each Node is a domain of that topology.
	And, if TopologyKey is "topology.kubernetes.io/zone", each zone is a domain of that topology.
	It's a required field.
	"""
																			type: "string"
																		}
																		whenUnsatisfiable: {
																			description: """
	WhenUnsatisfiable indicates how to deal with a pod if it doesn't satisfy
	the spread constraint.
	- DoNotSchedule (default) tells the scheduler not to schedule it.
	- ScheduleAnyway tells the scheduler to schedule the pod in any location,
	  but giving higher precedence to topologies that would help reduce the
	  skew.
	A constraint is considered "Unsatisfiable" for an incoming pod
	if and only if every possible node assignment for that pod would violate
	"MaxSkew" on some topology.
	For example, in a 3-zone cluster, MaxSkew is set to 1, and pods with the same
	labelSelector spread as 3/1/1:
	| zone1 | zone2 | zone3 |
	| P P P |   P   |   P   |
	If WhenUnsatisfiable is set to DoNotSchedule, incoming pod can only be scheduled
	to zone2(zone3) to become 3/2/1(3/1/2) as ActualSkew(2-1) on zone2(zone3) satisfies
	MaxSkew(1). In other words, the cluster can still be imbalanced, but scheduler
	won't make it *more* imbalanced.
	It's a required field.
	"""
																			type: "string"
																		}
																	}
																	required: [
																		"maxSkew",
																		"topologyKey",
																		"whenUnsatisfiable",
																	]
																	type: "object"
																}
																type: "array"
															}
															volumes: {
																description: """
	Volumes that can be mounted by containers belonging to the pod.
	More info: https://kubernetes.io/docs/concepts/storage/volumes
	"""
																items: {
																	description: "Volume represents a named volume in a pod that may be accessed by any container in the pod."
																	properties: {
																		awsElasticBlockStore: {
																			description: """
	awsElasticBlockStore represents an AWS Disk resource that is attached to a
	kubelet's host machine and then exposed to the pod.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore
	"""
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type of the volume that you want to mount.
	Tip: Ensure that the filesystem type is supported by the host operating system.
	Examples: "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore
	"""
																					type: "string"
																				}
																				partition: {
																					description: """
	partition is the partition in the volume that you want to mount.
	If omitted, the default is to mount by volume name.
	Examples: For volume /dev/sda1, you specify the partition as "1".
	Similarly, the volume partition for /dev/sda is "0" (or you can leave the property empty).
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				readOnly: {
																					description: """
	readOnly value true will force the readOnly setting in VolumeMounts.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore
	"""
																					type: "boolean"
																				}
																				volumeID: {
																					description: """
	volumeID is unique ID of the persistent disk resource in AWS (Amazon EBS volume).
	More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore
	"""
																					type: "string"
																				}
																			}
																			required: ["volumeID"]
																			type: "object"
																		}
																		azureDisk: {
																			description: "azureDisk represents an Azure Data Disk mount on the host and bind mount to the pod."
																			properties: {
																				cachingMode: {
																					description: "cachingMode is the Host Caching mode: None, Read Only, Read Write."
																					type:        "string"
																				}
																				diskName: {
																					description: "diskName is the Name of the data disk in the blob storage"
																					type:        "string"
																				}
																				diskURI: {
																					description: "diskURI is the URI of data disk in the blob storage"
																					type:        "string"
																				}
																				fsType: {
																					default: "ext4"
																					description: """
	fsType is Filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				kind: {
																					description: "kind expected values are Shared: multiple blob disks per storage account  Dedicated: single blob disk per storage account  Managed: azure managed data disk (only in managed availability set). defaults to shared"
																					type:        "string"
																				}
																				readOnly: {
																					default: false
																					description: """
	readOnly Defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																			}
																			required: [
																				"diskName",
																				"diskURI",
																			]
																			type: "object"
																		}
																		azureFile: {
																			description: "azureFile represents an Azure File Service mount on the host and bind mount to the pod."
																			properties: {
																				readOnly: {
																					description: """
	readOnly defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				secretName: {
																					description: "secretName is the  name of secret that contains Azure Storage Account Name and Key"
																					type:        "string"
																				}
																				shareName: {
																					description: "shareName is the azure share Name"
																					type:        "string"
																				}
																			}
																			required: [
																				"secretName",
																				"shareName",
																			]
																			type: "object"
																		}
																		cephfs: {
																			description: "cephFS represents a Ceph FS mount on the host that shares a pod's lifetime"
																			properties: {
																				monitors: {
																					description: """
	monitors is Required: Monitors is a collection of Ceph monitors
	More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it
	"""
																					items: type: "string"
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				path: {
																					description: "path is Optional: Used as the mounted root, rather than the full Ceph tree, default is /"
																					type:        "string"
																				}
																				readOnly: {
																					description: """
	readOnly is Optional: Defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it
	"""
																					type: "boolean"
																				}
																				secretFile: {
																					description: """
	secretFile is Optional: SecretFile is the path to key ring for User, default is /etc/ceph/user.secret
	More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																				secretRef: {
																					description: """
	secretRef is Optional: SecretRef is reference to the authentication secret for User, default is empty.
	More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				user: {
																					description: """
	user is optional: User is the rados user name, default is admin
	More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																			}
																			required: ["monitors"]
																			type: "object"
																		}
																		cinder: {
																			description: """
	cinder represents a cinder volume attached and mounted on kubelets host machine.
	More info: https://examples.k8s.io/mysql-cinder-pd/README.md
	"""
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Examples: "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	More info: https://examples.k8s.io/mysql-cinder-pd/README.md
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	More info: https://examples.k8s.io/mysql-cinder-pd/README.md
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: """
	secretRef is optional: points to a secret object containing parameters used to connect
	to OpenStack.
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				volumeID: {
																					description: """
	volumeID used to identify the volume in cinder.
	More info: https://examples.k8s.io/mysql-cinder-pd/README.md
	"""
																					type: "string"
																				}
																			}
																			required: ["volumeID"]
																			type: "object"
																		}
																		configMap: {
																			description: "configMap represents a configMap that should populate this volume"
																			properties: {
																				defaultMode: {
																					description: """
	defaultMode is optional: mode bits used to set permissions on created files by default.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	Defaults to 0644.
	Directories within the path are not affected by this setting.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				items: {
																					description: """
	items if unspecified, each key-value pair in the Data field of the referenced
	ConfigMap will be projected into the volume as a file whose name is the
	key and content is the value. If specified, the listed keys will be
	projected into the specified paths, and unlisted keys will not be
	present. If a key is specified which is not present in the ConfigMap,
	the volume setup will error unless it is marked optional. Paths must be
	relative and may not contain the '..' path or start with '..'.
	"""
																					items: {
																						description: "Maps a string key to a path within a volume."
																						properties: {
																							key: {
																								description: "key is the key to project."
																								type:        "string"
																							}
																							mode: {
																								description: """
	mode is Optional: mode bits used to set permissions on this file.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																								format: "int32"
																								type:   "integer"
																							}
																							path: {
																								description: """
	path is the relative path of the file to map the key to.
	May not be an absolute path.
	May not contain the path element '..'.
	May not start with the string '..'.
	"""
																								type: "string"
																							}
																						}
																						required: [
																							"key",
																							"path",
																						]
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				name: {
																					default: ""
																					description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																					type: "string"
																				}
																				optional: {
																					description: "optional specify whether the ConfigMap or its keys must be defined"
																					type:        "boolean"
																				}
																			}
																			type:                    "object"
																			"x-kubernetes-map-type": "atomic"
																		}
																		csi: {
																			description: "csi (Container Storage Interface) represents ephemeral storage that is handled by certain external CSI drivers (Beta feature)."
																			properties: {
																				driver: {
																					description: """
	driver is the name of the CSI driver that handles this volume.
	Consult with your admin for the correct name as registered in the cluster.
	"""
																					type: "string"
																				}
																				fsType: {
																					description: """
	fsType to mount. Ex. "ext4", "xfs", "ntfs".
	If not provided, the empty value is passed to the associated CSI driver
	which will determine the default filesystem to apply.
	"""
																					type: "string"
																				}
																				nodePublishSecretRef: {
																					description: """
	nodePublishSecretRef is a reference to the secret object containing
	sensitive information to pass to the CSI driver to complete the CSI
	NodePublishVolume and NodeUnpublishVolume calls.
	This field is optional, and  may be empty if no secret is required. If the
	secret object contains more than one secret, all secret references are passed.
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				readOnly: {
																					description: """
	readOnly specifies a read-only configuration for the volume.
	Defaults to false (read/write).
	"""
																					type: "boolean"
																				}
																				volumeAttributes: {
																					additionalProperties: type: "string"
																					description: """
	volumeAttributes stores driver-specific properties that are passed to the CSI
	driver. Consult your driver's documentation for supported values.
	"""
																					type: "object"
																				}
																			}
																			required: ["driver"]
																			type: "object"
																		}
																		downwardAPI: {
																			description: "downwardAPI represents downward API about the pod that should populate this volume"
																			properties: {
																				defaultMode: {
																					description: """
	Optional: mode bits to use on created files by default. Must be a
	Optional: mode bits used to set permissions on created files by default.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	Defaults to 0644.
	Directories within the path are not affected by this setting.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				items: {
																					description: "Items is a list of downward API volume file"
																					items: {
																						description: "DownwardAPIVolumeFile represents information to create the file containing the pod field"
																						properties: {
																							fieldRef: {
																								description: "Required: Selects a field of the pod: only annotations, labels, name, namespace and uid are supported."
																								properties: {
																									apiVersion: {
																										description: "Version of the schema the FieldPath is written in terms of, defaults to \"v1\"."
																										type:        "string"
																									}
																									fieldPath: {
																										description: "Path of the field to select in the specified API version."
																										type:        "string"
																									}
																								}
																								required: ["fieldPath"]
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																							mode: {
																								description: """
	Optional: mode bits used to set permissions on this file, must be an octal value
	between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																								format: "int32"
																								type:   "integer"
																							}
																							path: {
																								description: "Required: Path is  the relative path name of the file to be created. Must not be absolute or contain the '..' path. Must be utf-8 encoded. The first item of the relative path must not start with '..'"
																								type:        "string"
																							}
																							resourceFieldRef: {
																								description: """
	Selects a resource of the container: only resources limits and requests
	(limits.cpu, limits.memory, requests.cpu and requests.memory) are currently supported.
	"""
																								properties: {
																									containerName: {
																										description: "Container name: required for volumes, optional for env vars"
																										type:        "string"
																									}
																									divisor: {
																										anyOf: [{
																											type: "integer"
																										}, {
																											type: "string"
																										}]
																										description:                  "Specifies the output format of the exposed resources, defaults to \"1\""
																										pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																										"x-kubernetes-int-or-string": true
																									}
																									resource: {
																										description: "Required: resource to select"
																										type:        "string"
																									}
																								}
																								required: ["resource"]
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																						}
																						required: ["path"]
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																			}
																			type: "object"
																		}
																		emptyDir: {
																			description: """
	emptyDir represents a temporary directory that shares a pod's lifetime.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir
	"""
																			properties: {
																				medium: {
																					description: """
	medium represents what type of storage medium should back this directory.
	The default is "" which means to use the node's default medium.
	Must be an empty string (default) or Memory.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir
	"""
																					type: "string"
																				}
																				sizeLimit: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	sizeLimit is the total amount of local storage required for this EmptyDir volume.
	The size limit is also applicable for memory medium.
	The maximum usage on memory medium EmptyDir would be the minimum value between
	the SizeLimit specified here and the sum of memory limits of all containers in a pod.
	The default is nil which means that the limit is undefined.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir
	"""
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																			}
																			type: "object"
																		}
																		ephemeral: {
																			description: """
	ephemeral represents a volume that is handled by a cluster storage driver.
	The volume's lifecycle is tied to the pod that defines it - it will be created before the pod starts,
	and deleted when the pod is removed.

	Use this if:
	a) the volume is only needed while the pod runs,
	b) features of normal volumes like restoring from snapshot or capacity
	   tracking are needed,
	c) the storage driver is specified through a storage class, and
	d) the storage driver supports dynamic volume provisioning through
	   a PersistentVolumeClaim (see EphemeralVolumeSource for more
	   information on the connection between this volume type
	   and PersistentVolumeClaim).

	Use PersistentVolumeClaim or one of the vendor-specific
	APIs for volumes that persist for longer than the lifecycle
	of an individual pod.

	Use CSI for light-weight local ephemeral volumes if the CSI driver is meant to
	be used that way - see the documentation of the driver for
	more information.

	A pod can use both types of ephemeral volumes and
	persistent volumes at the same time.
	"""
																			properties: volumeClaimTemplate: {
																				description: """
	Will be used to create a stand-alone PVC to provision the volume.
	The pod in which this EphemeralVolumeSource is embedded will be the
	owner of the PVC, i.e. the PVC will be deleted together with the
	pod.  The name of the PVC will be `<pod name>-<volume name>` where
	`<volume name>` is the name from the `PodSpec.Volumes` array
	entry. Pod validation will reject the pod if the concatenated name
	is not valid for a PVC (for example, too long).

	An existing PVC with that name that is not owned by the pod
	will *not* be used for the pod to avoid using an unrelated
	volume by mistake. Starting the pod is then blocked until
	the unrelated PVC is removed. If such a pre-created PVC is
	meant to be used by the pod, the PVC has to updated with an
	owner reference to the pod once the pod exists. Normally
	this should not be necessary, but it may be useful when
	manually reconstructing a broken cluster.

	This field is read-only and no changes will be made by Kubernetes
	to the PVC after it has been created.

	Required, must not be nil.
	"""
																				properties: {
																					metadata: {
																						description: """
	May contain labels and annotations that will be copied into the PVC
	when creating it. No other fields are allowed and will be rejected during
	validation.
	"""
																						type: "object"
																					}
																					spec: {
																						description: """
	The specification for the PersistentVolumeClaim. The entire content is
	copied unchanged into the PVC that gets created from this
	template. The same fields as in a PersistentVolumeClaim
	are also valid here.
	"""
																						properties: {
																							accessModes: {
																								description: """
	accessModes contains the desired access modes the volume should have.
	More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes-1
	"""
																								items: type: "string"
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																							dataSource: {
																								description: """
	dataSource field can be used to specify either:
	* An existing VolumeSnapshot object (snapshot.storage.k8s.io/VolumeSnapshot)
	* An existing PVC (PersistentVolumeClaim)
	If the provisioner or an external controller can support the specified data source,
	it will create a new volume based on the contents of the specified data source.
	When the AnyVolumeDataSource feature gate is enabled, dataSource contents will be copied to dataSourceRef,
	and dataSourceRef contents will be copied to dataSource when dataSourceRef.namespace is not specified.
	If the namespace is specified, then dataSourceRef will not be copied to dataSource.
	"""
																								properties: {
																									apiGroup: {
																										description: """
	APIGroup is the group for the resource being referenced.
	If APIGroup is not specified, the specified Kind must be in the core API group.
	For any other third-party types, APIGroup is required.
	"""
																										type: "string"
																									}
																									kind: {
																										description: "Kind is the type of resource being referenced"
																										type:        "string"
																									}
																									name: {
																										description: "Name is the name of resource being referenced"
																										type:        "string"
																									}
																								}
																								required: [
																									"kind",
																									"name",
																								]
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																							dataSourceRef: {
																								description: """
	dataSourceRef specifies the object from which to populate the volume with data, if a non-empty
	volume is desired. This may be any object from a non-empty API group (non
	core object) or a PersistentVolumeClaim object.
	When this field is specified, volume binding will only succeed if the type of
	the specified object matches some installed volume populator or dynamic
	provisioner.
	This field will replace the functionality of the dataSource field and as such
	if both fields are non-empty, they must have the same value. For backwards
	compatibility, when namespace isn't specified in dataSourceRef,
	both fields (dataSource and dataSourceRef) will be set to the same
	value automatically if one of them is empty and the other is non-empty.
	When namespace is specified in dataSourceRef,
	dataSource isn't set to the same value and must be empty.
	There are three important differences between dataSource and dataSourceRef:
	* While dataSource only allows two specific types of objects, dataSourceRef
	  allows any non-core object, as well as PersistentVolumeClaim objects.
	* While dataSource ignores disallowed values (dropping them), dataSourceRef
	  preserves all values, and generates an error if a disallowed value is
	  specified.
	* While dataSource only allows local objects, dataSourceRef allows objects
	  in any namespaces.
	(Beta) Using this field requires the AnyVolumeDataSource feature gate to be enabled.
	(Alpha) Using the namespace field of dataSourceRef requires the CrossNamespaceVolumeDataSource feature gate to be enabled.
	"""
																								properties: {
																									apiGroup: {
																										description: """
	APIGroup is the group for the resource being referenced.
	If APIGroup is not specified, the specified Kind must be in the core API group.
	For any other third-party types, APIGroup is required.
	"""
																										type: "string"
																									}
																									kind: {
																										description: "Kind is the type of resource being referenced"
																										type:        "string"
																									}
																									name: {
																										description: "Name is the name of resource being referenced"
																										type:        "string"
																									}
																									namespace: {
																										description: """
	Namespace is the namespace of resource being referenced
	Note that when a namespace is specified, a gateway.networking.k8s.io/ReferenceGrant object is required in the referent namespace to allow that namespace's owner to accept the reference. See the ReferenceGrant documentation for details.
	(Alpha) This field requires the CrossNamespaceVolumeDataSource feature gate to be enabled.
	"""
																										type: "string"
																									}
																								}
																								required: [
																									"kind",
																									"name",
																								]
																								type: "object"
																							}
																							resources: {
																								description: """
	resources represents the minimum resources the volume should have.
	If RecoverVolumeExpansionFailure feature is enabled users are allowed to specify resource requirements
	that are lower than previous value but must still be higher than capacity recorded in the
	status field of the claim.
	More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#resources
	"""
																								properties: {
																									limits: {
																										additionalProperties: {
																											anyOf: [{
																												type: "integer"
																											}, {
																												type: "string"
																											}]
																											pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																											"x-kubernetes-int-or-string": true
																										}
																										description: """
	Limits describes the maximum amount of compute resources allowed.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																										type: "object"
																									}
																									requests: {
																										additionalProperties: {
																											anyOf: [{
																												type: "integer"
																											}, {
																												type: "string"
																											}]
																											pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																											"x-kubernetes-int-or-string": true
																										}
																										description: """
	Requests describes the minimum amount of compute resources required.
	If Requests is omitted for a container, it defaults to Limits if that is explicitly specified,
	otherwise to an implementation-defined value. Requests cannot exceed Limits.
	More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
	"""
																										type: "object"
																									}
																								}
																								type: "object"
																							}
																							selector: {
																								description: "selector is a label query over volumes to consider for binding."
																								properties: {
																									matchExpressions: {
																										description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																										items: {
																											description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																											properties: {
																												key: {
																													description: "key is the label key that the selector applies to."
																													type:        "string"
																												}
																												operator: {
																													description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																													type: "string"
																												}
																												values: {
																													description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																													items: type: "string"
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																											}
																											required: [
																												"key",
																												"operator",
																											]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									matchLabels: {
																										additionalProperties: type: "string"
																										description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																										type: "object"
																									}
																								}
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																							storageClassName: {
																								description: """
	storageClassName is the name of the StorageClass required by the claim.
	More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#class-1
	"""
																								type: "string"
																							}
																							volumeAttributesClassName: {
																								description: """
	volumeAttributesClassName may be used to set the VolumeAttributesClass used by this claim.
	If specified, the CSI driver will create or update the volume with the attributes defined
	in the corresponding VolumeAttributesClass. This has a different purpose than storageClassName,
	it can be changed after the claim is created. An empty string value means that no VolumeAttributesClass
	will be applied to the claim but it's not allowed to reset this field to empty string once it is set.
	If unspecified and the PersistentVolumeClaim is unbound, the default VolumeAttributesClass
	will be set by the persistentvolume controller if it exists.
	If the resource referred to by volumeAttributesClass does not exist, this PersistentVolumeClaim will be
	set to a Pending state, as reflected by the modifyVolumeStatus field, until such as a resource
	exists.
	More info: https://kubernetes.io/docs/concepts/storage/volume-attributes-classes/
	(Beta) Using this field requires the VolumeAttributesClass feature gate to be enabled (off by default).
	"""
																								type: "string"
																							}
																							volumeMode: {
																								description: """
	volumeMode defines what type of volume is required by the claim.
	Value of Filesystem is implied when not included in claim spec.
	"""
																								type: "string"
																							}
																							volumeName: {
																								description: "volumeName is the binding reference to the PersistentVolume backing this claim."
																								type:        "string"
																							}
																						}
																						type: "object"
																					}
																				}
																				required: ["spec"]
																				type: "object"
																			}
																			type: "object"
																		}
																		fc: {
																			description: "fc represents a Fibre Channel resource that is attached to a kubelet's host machine and then exposed to the pod."
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				lun: {
																					description: "lun is Optional: FC target lun number"
																					format:      "int32"
																					type:        "integer"
																				}
																				readOnly: {
																					description: """
	readOnly is Optional: Defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				targetWWNs: {
																					description: "targetWWNs is Optional: FC target worldwide names (WWNs)"
																					items: type: "string"
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				wwids: {
																					description: """
	wwids Optional: FC volume world wide identifiers (wwids)
	Either wwids or combination of targetWWNs and lun must be set, but not both simultaneously.
	"""
																					items: type: "string"
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																			}
																			type: "object"
																		}
																		flexVolume: {
																			description: """
	flexVolume represents a generic volume resource that is
	provisioned/attached using an exec based plugin.
	"""
																			properties: {
																				driver: {
																					description: "driver is the name of the driver to use for this volume."
																					type:        "string"
																				}
																				fsType: {
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". The default filesystem depends on FlexVolume script.
	"""
																					type: "string"
																				}
																				options: {
																					additionalProperties: type: "string"
																					description: "options is Optional: this field holds extra command options if any."
																					type:        "object"
																				}
																				readOnly: {
																					description: """
	readOnly is Optional: defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: """
	secretRef is Optional: secretRef is reference to the secret object containing
	sensitive information to pass to the plugin scripts. This may be
	empty if no secret object is specified. If the secret object
	contains more than one secret, all secrets are passed to the plugin
	scripts.
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																			}
																			required: ["driver"]
																			type: "object"
																		}
																		flocker: {
																			description: "flocker represents a Flocker volume attached to a kubelet's host machine. This depends on the Flocker control service being running"
																			properties: {
																				datasetName: {
																					description: """
	datasetName is Name of the dataset stored as metadata -> name on the dataset for Flocker
	should be considered as deprecated
	"""
																					type: "string"
																				}
																				datasetUUID: {
																					description: "datasetUUID is the UUID of the dataset. This is unique identifier of a Flocker dataset"
																					type:        "string"
																				}
																			}
																			type: "object"
																		}
																		gcePersistentDisk: {
																			description: """
	gcePersistentDisk represents a GCE Disk resource that is attached to a
	kubelet's host machine and then exposed to the pod.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk
	"""
																			properties: {
																				fsType: {
																					description: """
	fsType is filesystem type of the volume that you want to mount.
	Tip: Ensure that the filesystem type is supported by the host operating system.
	Examples: "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk
	"""
																					type: "string"
																				}
																				partition: {
																					description: """
	partition is the partition in the volume that you want to mount.
	If omitted, the default is to mount by volume name.
	Examples: For volume /dev/sda1, you specify the partition as "1".
	Similarly, the volume partition for /dev/sda is "0" (or you can leave the property empty).
	More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				pdName: {
																					description: """
	pdName is unique name of the PD resource in GCE. Used to identify the disk in GCE.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the ReadOnly setting in VolumeMounts.
	Defaults to false.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk
	"""
																					type: "boolean"
																				}
																			}
																			required: ["pdName"]
																			type: "object"
																		}
																		gitRepo: {
																			description: """
	gitRepo represents a git repository at a particular revision.
	DEPRECATED: GitRepo is deprecated. To provision a container with a git repo, mount an
	EmptyDir into an InitContainer that clones the repo using git, then mount the EmptyDir
	into the Pod's container.
	"""
																			properties: {
																				directory: {
																					description: """
	directory is the target directory name.
	Must not contain or start with '..'.  If '.' is supplied, the volume directory will be the
	git repository.  Otherwise, if specified, the volume will contain the git repository in
	the subdirectory with the given name.
	"""
																					type: "string"
																				}
																				repository: {
																					description: "repository is the URL"
																					type:        "string"
																				}
																				revision: {
																					description: "revision is the commit hash for the specified revision."
																					type:        "string"
																				}
																			}
																			required: ["repository"]
																			type: "object"
																		}
																		glusterfs: {
																			description: """
	glusterfs represents a Glusterfs mount on the host that shares a pod's lifetime.
	More info: https://examples.k8s.io/volumes/glusterfs/README.md
	"""
																			properties: {
																				endpoints: {
																					description: """
	endpoints is the endpoint name that details Glusterfs topology.
	More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod
	"""
																					type: "string"
																				}
																				path: {
																					description: """
	path is the Glusterfs volume path.
	More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the Glusterfs volume to be mounted with read-only permissions.
	Defaults to false.
	More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod
	"""
																					type: "boolean"
																				}
																			}
																			required: [
																				"endpoints",
																				"path",
																			]
																			type: "object"
																		}
																		hostPath: {
																			description: """
	hostPath represents a pre-existing file or directory on the host
	machine that is directly exposed to the container. This is generally
	used for system agents or other privileged things that are allowed
	to see the host machine. Most containers will NOT need this.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath
	"""
																			properties: {
																				path: {
																					description: """
	path of the directory on the host.
	If the path is a symlink, it will follow the link to the real path.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath
	"""
																					type: "string"
																				}
																				type: {
																					description: """
	type for HostPath Volume
	Defaults to ""
	More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath
	"""
																					type: "string"
																				}
																			}
																			required: ["path"]
																			type: "object"
																		}
																		image: {
																			description: """
	image represents an OCI object (a container image or artifact) pulled and mounted on the kubelet's host machine.
	The volume is resolved at pod startup depending on which PullPolicy value is provided:

	- Always: the kubelet always attempts to pull the reference. Container creation will fail If the pull fails.
	- Never: the kubelet never pulls the reference and only uses a local image or artifact. Container creation will fail if the reference isn't present.
	- IfNotPresent: the kubelet pulls if the reference isn't already present on disk. Container creation will fail if the reference isn't present and the pull fails.

	The volume gets re-resolved if the pod gets deleted and recreated, which means that new remote content will become available on pod recreation.
	A failure to resolve or pull the image during pod startup will block containers from starting and may add significant latency. Failures will be retried using normal volume backoff and will be reported on the pod reason and message.
	The types of objects that may be mounted by this volume are defined by the container runtime implementation on a host machine and at minimum must include all valid types supported by the container image field.
	The OCI object gets mounted in a single directory (spec.containers[*].volumeMounts.mountPath) by merging the manifest layers in the same way as for container images.
	The volume will be mounted read-only (ro) and non-executable files (noexec).
	Sub path mounts for containers are not supported (spec.containers[*].volumeMounts.subpath).
	The field spec.securityContext.fsGroupChangePolicy has no effect on this volume type.
	"""
																			properties: {
																				pullPolicy: {
																					description: """
	Policy for pulling OCI objects. Possible values are:
	Always: the kubelet always attempts to pull the reference. Container creation will fail If the pull fails.
	Never: the kubelet never pulls the reference and only uses a local image or artifact. Container creation will fail if the reference isn't present.
	IfNotPresent: the kubelet pulls if the reference isn't already present on disk. Container creation will fail if the reference isn't present and the pull fails.
	Defaults to Always if :latest tag is specified, or IfNotPresent otherwise.
	"""
																					type: "string"
																				}
																				reference: {
																					description: """
	Required: Image or artifact reference to be used.
	Behaves in the same way as pod.spec.containers[*].image.
	Pull secrets will be assembled in the same way as for the container image by looking up node credentials, SA image pull secrets, and pod spec image pull secrets.
	More info: https://kubernetes.io/docs/concepts/containers/images
	This field is optional to allow higher level config management to default or override
	container images in workload controllers like Deployments and StatefulSets.
	"""
																					type: "string"
																				}
																			}
																			type: "object"
																		}
																		iscsi: {
																			description: """
	iscsi represents an ISCSI Disk resource that is attached to a
	kubelet's host machine and then exposed to the pod.
	More info: https://examples.k8s.io/volumes/iscsi/README.md
	"""
																			properties: {
																				chapAuthDiscovery: {
																					description: "chapAuthDiscovery defines whether support iSCSI Discovery CHAP authentication"
																					type:        "boolean"
																				}
																				chapAuthSession: {
																					description: "chapAuthSession defines whether support iSCSI Session CHAP authentication"
																					type:        "boolean"
																				}
																				fsType: {
																					description: """
	fsType is the filesystem type of the volume that you want to mount.
	Tip: Ensure that the filesystem type is supported by the host operating system.
	Examples: "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#iscsi
	"""
																					type: "string"
																				}
																				initiatorName: {
																					description: """
	initiatorName is the custom iSCSI Initiator Name.
	If initiatorName is specified with iscsiInterface simultaneously, new iSCSI interface
	<target portal>:<volume name> will be created for the connection.
	"""
																					type: "string"
																				}
																				iqn: {
																					description: "iqn is the target iSCSI Qualified Name."
																					type:        "string"
																				}
																				iscsiInterface: {
																					default: "default"
																					description: """
	iscsiInterface is the interface Name that uses an iSCSI transport.
	Defaults to 'default' (tcp).
	"""
																					type: "string"
																				}
																				lun: {
																					description: "lun represents iSCSI Target Lun number."
																					format:      "int32"
																					type:        "integer"
																				}
																				portals: {
																					description: """
	portals is the iSCSI Target Portal List. The portal is either an IP or ip_addr:port if the port
	is other than default (typically TCP ports 860 and 3260).
	"""
																					items: type: "string"
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the ReadOnly setting in VolumeMounts.
	Defaults to false.
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: "secretRef is the CHAP Secret for iSCSI target and initiator authentication"
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				targetPortal: {
																					description: """
	targetPortal is iSCSI Target Portal. The Portal is either an IP or ip_addr:port if the port
	is other than default (typically TCP ports 860 and 3260).
	"""
																					type: "string"
																				}
																			}
																			required: [
																				"iqn",
																				"lun",
																				"targetPortal",
																			]
																			type: "object"
																		}
																		name: {
																			description: """
	name of the volume.
	Must be a DNS_LABEL and unique within the pod.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																			type: "string"
																		}
																		nfs: {
																			description: """
	nfs represents an NFS mount on the host that shares a pod's lifetime
	More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs
	"""
																			properties: {
																				path: {
																					description: """
	path that is exported by the NFS server.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the NFS export to be mounted with read-only permissions.
	Defaults to false.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs
	"""
																					type: "boolean"
																				}
																				server: {
																					description: """
	server is the hostname or IP address of the NFS server.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs
	"""
																					type: "string"
																				}
																			}
																			required: [
																				"path",
																				"server",
																			]
																			type: "object"
																		}
																		persistentVolumeClaim: {
																			description: """
	persistentVolumeClaimVolumeSource represents a reference to a
	PersistentVolumeClaim in the same namespace.
	More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims
	"""
																			properties: {
																				claimName: {
																					description: """
	claimName is the name of a PersistentVolumeClaim in the same namespace as the pod using this volume.
	More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly Will force the ReadOnly setting in VolumeMounts.
	Default false.
	"""
																					type: "boolean"
																				}
																			}
																			required: ["claimName"]
																			type: "object"
																		}
																		photonPersistentDisk: {
																			description: "photonPersistentDisk represents a PhotonController persistent disk attached and mounted on kubelets host machine"
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				pdID: {
																					description: "pdID is the ID that identifies Photon Controller persistent disk"
																					type:        "string"
																				}
																			}
																			required: ["pdID"]
																			type: "object"
																		}
																		portworxVolume: {
																			description: "portworxVolume represents a portworx volume attached and mounted on kubelets host machine"
																			properties: {
																				fsType: {
																					description: """
	fSType represents the filesystem type to mount
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				volumeID: {
																					description: "volumeID uniquely identifies a Portworx volume"
																					type:        "string"
																				}
																			}
																			required: ["volumeID"]
																			type: "object"
																		}
																		projected: {
																			description: "projected items for all in one resources secrets, configmaps, and downward API"
																			properties: {
																				defaultMode: {
																					description: """
	defaultMode are the mode bits used to set permissions on created files by default.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	Directories within the path are not affected by this setting.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				sources: {
																					description: """
	sources is the list of volume projections. Each entry in this list
	handles one source.
	"""
																					items: {
																						description: """
	Projection that may be projected along with other supported volume types.
	Exactly one of these fields must be set.
	"""
																						properties: {
																							clusterTrustBundle: {
																								description: """
	ClusterTrustBundle allows a pod to access the `.spec.trustBundle` field
	of ClusterTrustBundle objects in an auto-updating file.

	Alpha, gated by the ClusterTrustBundleProjection feature gate.

	ClusterTrustBundle objects can either be selected by name, or by the
	combination of signer name and a label selector.

	Kubelet performs aggressive normalization of the PEM contents written
	into the pod filesystem.  Esoteric PEM features such as inter-block
	comments and block headers are stripped.  Certificates are deduplicated.
	The ordering of certificates within the file is arbitrary, and Kubelet
	may change the order over time.
	"""
																								properties: {
																									labelSelector: {
																										description: """
	Select all ClusterTrustBundles that match this label selector.  Only has
	effect if signerName is set.  Mutually-exclusive with name.  If unset,
	interpreted as "match nothing".  If set but empty, interpreted as "match
	everything".
	"""
																										properties: {
																											matchExpressions: {
																												description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																												items: {
																													description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																													properties: {
																														key: {
																															description: "key is the label key that the selector applies to."
																															type:        "string"
																														}
																														operator: {
																															description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																															type: "string"
																														}
																														values: {
																															description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																															items: type: "string"
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																													}
																													required: [
																														"key",
																														"operator",
																													]
																													type: "object"
																												}
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																											matchLabels: {
																												additionalProperties: type: "string"
																												description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																												type: "object"
																											}
																										}
																										type:                    "object"
																										"x-kubernetes-map-type": "atomic"
																									}
																									name: {
																										description: """
	Select a single ClusterTrustBundle by object name.  Mutually-exclusive
	with signerName and labelSelector.
	"""
																										type: "string"
																									}
																									optional: {
																										description: """
	If true, don't block pod startup if the referenced ClusterTrustBundle(s)
	aren't available.  If using name, then the named ClusterTrustBundle is
	allowed not to exist.  If using signerName, then the combination of
	signerName and labelSelector is allowed to match zero
	ClusterTrustBundles.
	"""
																										type: "boolean"
																									}
																									path: {
																										description: "Relative path from the volume root to write the bundle."
																										type:        "string"
																									}
																									signerName: {
																										description: """
	Select all ClusterTrustBundles that match this signer name.
	Mutually-exclusive with name.  The contents of all selected
	ClusterTrustBundles will be unified and deduplicated.
	"""
																										type: "string"
																									}
																								}
																								required: ["path"]
																								type: "object"
																							}
																							configMap: {
																								description: "configMap information about the configMap data to project"
																								properties: {
																									items: {
																										description: """
	items if unspecified, each key-value pair in the Data field of the referenced
	ConfigMap will be projected into the volume as a file whose name is the
	key and content is the value. If specified, the listed keys will be
	projected into the specified paths, and unlisted keys will not be
	present. If a key is specified which is not present in the ConfigMap,
	the volume setup will error unless it is marked optional. Paths must be
	relative and may not contain the '..' path or start with '..'.
	"""
																										items: {
																											description: "Maps a string key to a path within a volume."
																											properties: {
																												key: {
																													description: "key is the key to project."
																													type:        "string"
																												}
																												mode: {
																													description: """
	mode is Optional: mode bits used to set permissions on this file.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																													format: "int32"
																													type:   "integer"
																												}
																												path: {
																													description: """
	path is the relative path of the file to map the key to.
	May not be an absolute path.
	May not contain the path element '..'.
	May not start with the string '..'.
	"""
																													type: "string"
																												}
																											}
																											required: [
																												"key",
																												"path",
																											]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									name: {
																										default: ""
																										description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																										type: "string"
																									}
																									optional: {
																										description: "optional specify whether the ConfigMap or its keys must be defined"
																										type:        "boolean"
																									}
																								}
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																							downwardAPI: {
																								description: "downwardAPI information about the downwardAPI data to project"
																								properties: items: {
																									description: "Items is a list of DownwardAPIVolume file"
																									items: {
																										description: "DownwardAPIVolumeFile represents information to create the file containing the pod field"
																										properties: {
																											fieldRef: {
																												description: "Required: Selects a field of the pod: only annotations, labels, name, namespace and uid are supported."
																												properties: {
																													apiVersion: {
																														description: "Version of the schema the FieldPath is written in terms of, defaults to \"v1\"."
																														type:        "string"
																													}
																													fieldPath: {
																														description: "Path of the field to select in the specified API version."
																														type:        "string"
																													}
																												}
																												required: ["fieldPath"]
																												type:                    "object"
																												"x-kubernetes-map-type": "atomic"
																											}
																											mode: {
																												description: """
	Optional: mode bits used to set permissions on this file, must be an octal value
	between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																												format: "int32"
																												type:   "integer"
																											}
																											path: {
																												description: "Required: Path is  the relative path name of the file to be created. Must not be absolute or contain the '..' path. Must be utf-8 encoded. The first item of the relative path must not start with '..'"
																												type:        "string"
																											}
																											resourceFieldRef: {
																												description: """
	Selects a resource of the container: only resources limits and requests
	(limits.cpu, limits.memory, requests.cpu and requests.memory) are currently supported.
	"""
																												properties: {
																													containerName: {
																														description: "Container name: required for volumes, optional for env vars"
																														type:        "string"
																													}
																													divisor: {
																														anyOf: [{
																															type: "integer"
																														}, {
																															type: "string"
																														}]
																														description:                  "Specifies the output format of the exposed resources, defaults to \"1\""
																														pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																														"x-kubernetes-int-or-string": true
																													}
																													resource: {
																														description: "Required: resource to select"
																														type:        "string"
																													}
																												}
																												required: ["resource"]
																												type:                    "object"
																												"x-kubernetes-map-type": "atomic"
																											}
																										}
																										required: ["path"]
																										type: "object"
																									}
																									type:                     "array"
																									"x-kubernetes-list-type": "atomic"
																								}
																								type: "object"
																							}
																							secret: {
																								description: "secret information about the secret data to project"
																								properties: {
																									items: {
																										description: """
	items if unspecified, each key-value pair in the Data field of the referenced
	Secret will be projected into the volume as a file whose name is the
	key and content is the value. If specified, the listed keys will be
	projected into the specified paths, and unlisted keys will not be
	present. If a key is specified which is not present in the Secret,
	the volume setup will error unless it is marked optional. Paths must be
	relative and may not contain the '..' path or start with '..'.
	"""
																										items: {
																											description: "Maps a string key to a path within a volume."
																											properties: {
																												key: {
																													description: "key is the key to project."
																													type:        "string"
																												}
																												mode: {
																													description: """
	mode is Optional: mode bits used to set permissions on this file.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																													format: "int32"
																													type:   "integer"
																												}
																												path: {
																													description: """
	path is the relative path of the file to map the key to.
	May not be an absolute path.
	May not contain the path element '..'.
	May not start with the string '..'.
	"""
																													type: "string"
																												}
																											}
																											required: [
																												"key",
																												"path",
																											]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									name: {
																										default: ""
																										description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																										type: "string"
																									}
																									optional: {
																										description: "optional field specify whether the Secret or its key must be defined"
																										type:        "boolean"
																									}
																								}
																								type:                    "object"
																								"x-kubernetes-map-type": "atomic"
																							}
																							serviceAccountToken: {
																								description: "serviceAccountToken is information about the serviceAccountToken data to project"
																								properties: {
																									audience: {
																										description: """
	audience is the intended audience of the token. A recipient of a token
	must identify itself with an identifier specified in the audience of the
	token, and otherwise should reject the token. The audience defaults to the
	identifier of the apiserver.
	"""
																										type: "string"
																									}
																									expirationSeconds: {
																										description: """
	expirationSeconds is the requested duration of validity of the service
	account token. As the token approaches expiration, the kubelet volume
	plugin will proactively rotate the service account token. The kubelet will
	start trying to rotate the token if the token is older than 80 percent of
	its time to live or if the token is older than 24 hours.Defaults to 1 hour
	and must be at least 10 minutes.
	"""
																										format: "int64"
																										type:   "integer"
																									}
																									path: {
																										description: """
	path is the path relative to the mount point of the file to project the
	token into.
	"""
																										type: "string"
																									}
																								}
																								required: ["path"]
																								type: "object"
																							}
																						}
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																			}
																			type: "object"
																		}
																		quobyte: {
																			description: "quobyte represents a Quobyte mount on the host that shares a pod's lifetime"
																			properties: {
																				group: {
																					description: """
	group to map volume access to
	Default is no group
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the Quobyte volume to be mounted with read-only permissions.
	Defaults to false.
	"""
																					type: "boolean"
																				}
																				registry: {
																					description: """
	registry represents a single or multiple Quobyte Registry services
	specified as a string as host:port pair (multiple entries are separated with commas)
	which acts as the central registry for volumes
	"""
																					type: "string"
																				}
																				tenant: {
																					description: """
	tenant owning the given Quobyte volume in the Backend
	Used with dynamically provisioned Quobyte volumes, value is set by the plugin
	"""
																					type: "string"
																				}
																				user: {
																					description: """
	user to map volume access to
	Defaults to serivceaccount user
	"""
																					type: "string"
																				}
																				volume: {
																					description: "volume is a string that references an already created Quobyte volume by name."
																					type:        "string"
																				}
																			}
																			required: [
																				"registry",
																				"volume",
																			]
																			type: "object"
																		}
																		rbd: {
																			description: """
	rbd represents a Rados Block Device mount on the host that shares a pod's lifetime.
	More info: https://examples.k8s.io/volumes/rbd/README.md
	"""
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type of the volume that you want to mount.
	Tip: Ensure that the filesystem type is supported by the host operating system.
	Examples: "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#rbd
	"""
																					type: "string"
																				}
																				image: {
																					description: """
	image is the rados image name.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																				keyring: {
																					default: "/etc/ceph/keyring"
																					description: """
	keyring is the path to key ring for RBDUser.
	Default is /etc/ceph/keyring.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																				monitors: {
																					description: """
	monitors is a collection of Ceph monitors.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					items: type: "string"
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				pool: {
																					default: "rbd"
																					description: """
	pool is the rados pool name.
	Default is rbd.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly here will force the ReadOnly setting in VolumeMounts.
	Defaults to false.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: """
	secretRef is name of the authentication secret for RBDUser. If provided
	overrides keyring.
	Default is nil.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				user: {
																					default: "admin"
																					description: """
	user is the rados user name.
	Default is admin.
	More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it
	"""
																					type: "string"
																				}
																			}
																			required: [
																				"image",
																				"monitors",
																			]
																			type: "object"
																		}
																		scaleIO: {
																			description: "scaleIO represents a ScaleIO persistent volume attached and mounted on Kubernetes nodes."
																			properties: {
																				fsType: {
																					default: "xfs"
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs".
	Default is "xfs".
	"""
																					type: "string"
																				}
																				gateway: {
																					description: "gateway is the host address of the ScaleIO API Gateway."
																					type:        "string"
																				}
																				protectionDomain: {
																					description: "protectionDomain is the name of the ScaleIO Protection Domain for the configured storage."
																					type:        "string"
																				}
																				readOnly: {
																					description: """
	readOnly Defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: """
	secretRef references to the secret for ScaleIO user and other
	sensitive information. If this is not provided, Login operation will fail.
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				sslEnabled: {
																					description: "sslEnabled Flag enable/disable SSL communication with Gateway, default false"
																					type:        "boolean"
																				}
																				storageMode: {
																					default: "ThinProvisioned"
																					description: """
	storageMode indicates whether the storage for a volume should be ThickProvisioned or ThinProvisioned.
	Default is ThinProvisioned.
	"""
																					type: "string"
																				}
																				storagePool: {
																					description: "storagePool is the ScaleIO Storage Pool associated with the protection domain."
																					type:        "string"
																				}
																				system: {
																					description: "system is the name of the storage system as configured in ScaleIO."
																					type:        "string"
																				}
																				volumeName: {
																					description: """
	volumeName is the name of a volume already created in the ScaleIO system
	that is associated with this volume source.
	"""
																					type: "string"
																				}
																			}
																			required: [
																				"gateway",
																				"secretRef",
																				"system",
																			]
																			type: "object"
																		}
																		secret: {
																			description: """
	secret represents a secret that should populate this volume.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#secret
	"""
																			properties: {
																				defaultMode: {
																					description: """
	defaultMode is Optional: mode bits used to set permissions on created files by default.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values
	for mode bits. Defaults to 0644.
	Directories within the path are not affected by this setting.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				items: {
																					description: """
	items If unspecified, each key-value pair in the Data field of the referenced
	Secret will be projected into the volume as a file whose name is the
	key and content is the value. If specified, the listed keys will be
	projected into the specified paths, and unlisted keys will not be
	present. If a key is specified which is not present in the Secret,
	the volume setup will error unless it is marked optional. Paths must be
	relative and may not contain the '..' path or start with '..'.
	"""
																					items: {
																						description: "Maps a string key to a path within a volume."
																						properties: {
																							key: {
																								description: "key is the key to project."
																								type:        "string"
																							}
																							mode: {
																								description: """
	mode is Optional: mode bits used to set permissions on this file.
	Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511.
	YAML accepts both octal and decimal values, JSON requires decimal values for mode bits.
	If not specified, the volume defaultMode will be used.
	This might be in conflict with other options that affect the file
	mode, like fsGroup, and the result can be other mode bits set.
	"""
																								format: "int32"
																								type:   "integer"
																							}
																							path: {
																								description: """
	path is the relative path of the file to map the key to.
	May not be an absolute path.
	May not contain the path element '..'.
	May not start with the string '..'.
	"""
																								type: "string"
																							}
																						}
																						required: [
																							"key",
																							"path",
																						]
																						type: "object"
																					}
																					type:                     "array"
																					"x-kubernetes-list-type": "atomic"
																				}
																				optional: {
																					description: "optional field specify whether the Secret or its keys must be defined"
																					type:        "boolean"
																				}
																				secretName: {
																					description: """
	secretName is the name of the secret in the pod's namespace to use.
	More info: https://kubernetes.io/docs/concepts/storage/volumes#secret
	"""
																					type: "string"
																				}
																			}
																			type: "object"
																		}
																		storageos: {
																			description: "storageOS represents a StorageOS volume attached and mounted on Kubernetes nodes."
																			properties: {
																				fsType: {
																					description: """
	fsType is the filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				readOnly: {
																					description: """
	readOnly defaults to false (read/write). ReadOnly here will force
	the ReadOnly setting in VolumeMounts.
	"""
																					type: "boolean"
																				}
																				secretRef: {
																					description: """
	secretRef specifies the secret to use for obtaining the StorageOS API
	credentials.  If not specified, default values will be attempted.
	"""
																					properties: name: {
																						default: ""
																						description: """
	Name of the referent.
	This field is effectively required, but due to backwards compatibility is
	allowed to be empty. Instances of this type with an empty value here are
	almost certainly wrong.
	More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
	"""
																						type: "string"
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																				volumeName: {
																					description: """
	volumeName is the human-readable name of the StorageOS volume.  Volume
	names are only unique within a namespace.
	"""
																					type: "string"
																				}
																				volumeNamespace: {
																					description: """
	volumeNamespace specifies the scope of the volume within StorageOS.  If no
	namespace is specified then the Pod's namespace will be used.  This allows the
	Kubernetes name scoping to be mirrored within StorageOS for tighter integration.
	Set VolumeName to any name to override the default behaviour.
	Set to "default" if you are not using namespaces within StorageOS.
	Namespaces that do not pre-exist within StorageOS will be created.
	"""
																					type: "string"
																				}
																			}
																			type: "object"
																		}
																		vsphereVolume: {
																			description: "vsphereVolume represents a vSphere volume attached and mounted on kubelets host machine"
																			properties: {
																				fsType: {
																					description: """
	fsType is filesystem type to mount.
	Must be a filesystem type supported by the host operating system.
	Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.
	"""
																					type: "string"
																				}
																				storagePolicyID: {
																					description: "storagePolicyID is the storage Policy Based Management (SPBM) profile ID associated with the StoragePolicyName."
																					type:        "string"
																				}
																				storagePolicyName: {
																					description: "storagePolicyName is the storage Policy Based Management (SPBM) profile name."
																					type:        "string"
																				}
																				volumePath: {
																					description: "volumePath is the path that identifies vSphere volume vmdk"
																					type:        "string"
																				}
																			}
																			required: ["volumePath"]
																			type: "object"
																		}
																	}
																	required: ["name"]
																	type: "object"
																}
																type: "array"
															}
														}
														type: "object"
													}
													replicas: {
														description: "Replicas is the number of desired pods. Defaults to 1."
														format:      "int32"
														type:        "integer"
													}
													strategy: {
														description: "The deployment strategy to use to replace existing pods with new ones."
														properties: {
															rollingUpdate: {
																description: """
	Rolling update config params. Present only if DeploymentStrategyType =
	RollingUpdate.
	"""
																properties: {
																	maxSurge: {
																		anyOf: [{
																			type: "integer"
																		}, {
																			type: "string"
																		}]
																		description: """
	The maximum number of pods that can be scheduled above the desired number of
	pods.
	Value can be an absolute number (ex: 5) or a percentage of desired pods (ex: 10%).
	This can not be 0 if MaxUnavailable is 0.
	Absolute number is calculated from percentage by rounding up.
	Defaults to 25%.
	Example: when this is set to 30%, the new ReplicaSet can be scaled up immediately when
	the rolling update starts, such that the total number of old and new pods do not exceed
	130% of desired pods. Once old pods have been killed,
	new ReplicaSet can be scaled up further, ensuring that total number of pods running
	at any time during the update is at most 130% of desired pods.
	"""
																		"x-kubernetes-int-or-string": true
																	}
																	maxUnavailable: {
																		anyOf: [{
																			type: "integer"
																		}, {
																			type: "string"
																		}]
																		description: """
	The maximum number of pods that can be unavailable during the update.
	Value can be an absolute number (ex: 5) or a percentage of desired pods (ex: 10%).
	Absolute number is calculated from percentage by rounding down.
	This can not be 0 if MaxSurge is 0.
	Defaults to 25%.
	Example: when this is set to 30%, the old ReplicaSet can be scaled down to 70% of desired pods
	immediately when the rolling update starts. Once new pods are ready, old ReplicaSet
	can be scaled down further, followed by scaling up the new ReplicaSet, ensuring
	that the total number of pods available at all times during the update is at
	least 70% of desired pods.
	"""
																		"x-kubernetes-int-or-string": true
																	}
																}
																type: "object"
															}
															type: {
																description: "Type of deployment. Can be \"Recreate\" or \"RollingUpdate\". Default is RollingUpdate."
																type:        "string"
															}
														}
														type: "object"
													}
												}
												type: "object"
											}
											envoyHpa: {
												description: """
	EnvoyHpa defines the Horizontal Pod Autoscaler settings for Envoy Proxy Deployment.
	Once the HPA is being set, Replicas field from EnvoyDeployment will be ignored.
	"""
												properties: {
													behavior: {
														description: """
	behavior configures the scaling behavior of the target
	in both Up and Down directions (scaleUp and scaleDown fields respectively).
	If not set, the default HPAScalingRules for scale up and scale down are used.
	See k8s.io.autoscaling.v2.HorizontalPodAutoScalerBehavior.
	"""
														properties: {
															scaleDown: {
																description: """
	scaleDown is scaling policy for scaling Down.
	If not set, the default value is to allow to scale down to minReplicas pods, with a
	300 second stabilization window (i.e., the highest recommendation for
	the last 300sec is used).
	"""
																properties: {
																	policies: {
																		description: """
	policies is a list of potential scaling polices which can be used during scaling.
	At least one policy must be specified, otherwise the HPAScalingRules will be discarded as invalid
	"""
																		items: {
																			description: "HPAScalingPolicy is a single policy which must hold true for a specified past interval."
																			properties: {
																				periodSeconds: {
																					description: """
	periodSeconds specifies the window of time for which the policy should hold true.
	PeriodSeconds must be greater than zero and less than or equal to 1800 (30 min).
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				type: {
																					description: "type is used to specify the scaling policy."
																					type:        "string"
																				}
																				value: {
																					description: """
	value contains the amount of change which is permitted by the policy.
	It must be greater than zero
	"""
																					format: "int32"
																					type:   "integer"
																				}
																			}
																			required: [
																				"periodSeconds",
																				"type",
																				"value",
																			]
																			type: "object"
																		}
																		type:                     "array"
																		"x-kubernetes-list-type": "atomic"
																	}
																	selectPolicy: {
																		description: """
	selectPolicy is used to specify which policy should be used.
	If not set, the default value Max is used.
	"""
																		type: "string"
																	}
																	stabilizationWindowSeconds: {
																		description: """
	stabilizationWindowSeconds is the number of seconds for which past recommendations should be
	considered while scaling up or scaling down.
	StabilizationWindowSeconds must be greater than or equal to zero and less than or equal to 3600 (one hour).
	If not set, use the default values:
	- For scale up: 0 (i.e. no stabilization is done).
	- For scale down: 300 (i.e. the stabilization window is 300 seconds long).
	"""
																		format: "int32"
																		type:   "integer"
																	}
																}
																type: "object"
															}
															scaleUp: {
																description: """
	scaleUp is scaling policy for scaling Up.
	If not set, the default value is the higher of:
	  * increase no more than 4 pods per 60 seconds
	  * double the number of pods per 60 seconds
	No stabilization is used.
	"""
																properties: {
																	policies: {
																		description: """
	policies is a list of potential scaling polices which can be used during scaling.
	At least one policy must be specified, otherwise the HPAScalingRules will be discarded as invalid
	"""
																		items: {
																			description: "HPAScalingPolicy is a single policy which must hold true for a specified past interval."
																			properties: {
																				periodSeconds: {
																					description: """
	periodSeconds specifies the window of time for which the policy should hold true.
	PeriodSeconds must be greater than zero and less than or equal to 1800 (30 min).
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				type: {
																					description: "type is used to specify the scaling policy."
																					type:        "string"
																				}
																				value: {
																					description: """
	value contains the amount of change which is permitted by the policy.
	It must be greater than zero
	"""
																					format: "int32"
																					type:   "integer"
																				}
																			}
																			required: [
																				"periodSeconds",
																				"type",
																				"value",
																			]
																			type: "object"
																		}
																		type:                     "array"
																		"x-kubernetes-list-type": "atomic"
																	}
																	selectPolicy: {
																		description: """
	selectPolicy is used to specify which policy should be used.
	If not set, the default value Max is used.
	"""
																		type: "string"
																	}
																	stabilizationWindowSeconds: {
																		description: """
	stabilizationWindowSeconds is the number of seconds for which past recommendations should be
	considered while scaling up or scaling down.
	StabilizationWindowSeconds must be greater than or equal to zero and less than or equal to 3600 (one hour).
	If not set, use the default values:
	- For scale up: 0 (i.e. no stabilization is done).
	- For scale down: 300 (i.e. the stabilization window is 300 seconds long).
	"""
																		format: "int32"
																		type:   "integer"
																	}
																}
																type: "object"
															}
														}
														type: "object"
													}
													maxReplicas: {
														description: """
	maxReplicas is the upper limit for the number of replicas to which the autoscaler can scale up.
	It cannot be less that minReplicas.
	"""
														format: "int32"
														type:   "integer"
														"x-kubernetes-validations": [{
															message: "maxReplicas must be greater than 0"
															rule:    "self > 0"
														}]
													}
													metrics: {
														description: """
	metrics contains the specifications for which to use to calculate the
	desired replica count (the maximum replica count across all metrics will
	be used).
	If left empty, it defaults to being based on CPU utilization with average on 80% usage.
	"""
														items: {
															description: """
	MetricSpec specifies how to scale based on a single metric
	(only `type` and one other matching field should be set at once).
	"""
															properties: {
																containerResource: {
																	description: """
	containerResource refers to a resource metric (such as those specified in
	requests and limits) known to Kubernetes describing a single container in
	each pod of the current scale target (e.g. CPU or memory). Such metrics are
	built in to Kubernetes, and have special scaling options on top of those
	available to normal per-pod metrics using the "pods" source.
	This is an alpha feature and can be enabled by the HPAContainerMetrics feature flag.
	"""
																	properties: {
																		container: {
																			description: "container is the name of the container in the pods of the scaling target"
																			type:        "string"
																		}
																		name: {
																			description: "name is the name of the resource in question."
																			type:        "string"
																		}
																		target: {
																			description: "target specifies the target value for the given metric"
																			properties: {
																				averageUtilization: {
																					description: """
	averageUtilization is the target value of the average of the
	resource metric across all relevant pods, represented as a percentage of
	the requested value of the resource for the pods.
	Currently only valid for Resource metric source type
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				averageValue: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	averageValue is the target value of the average of the
	metric across all relevant pods (as a quantity)
	"""
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																				type: {
																					description: "type represents whether the metric type is Utilization, Value, or AverageValue"
																					type:        "string"
																				}
																				value: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description:                  "value is the target value of the metric (as a quantity)."
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																			}
																			required: ["type"]
																			type: "object"
																		}
																	}
																	required: [
																		"container",
																		"name",
																		"target",
																	]
																	type: "object"
																}
																external: {
																	description: """
	external refers to a global metric that is not associated
	with any Kubernetes object. It allows autoscaling based on information
	coming from components running outside of cluster
	(for example length of queue in cloud messaging service, or
	QPS from loadbalancer running outside of cluster).
	"""
																	properties: {
																		metric: {
																			description: "metric identifies the target metric by name and selector"
																			properties: {
																				name: {
																					description: "name is the name of the given metric"
																					type:        "string"
																				}
																				selector: {
																					description: """
	selector is the string-encoded form of a standard kubernetes label selector for the given metric
	When set, it is passed as an additional parameter to the metrics server for more specific metrics scoping.
	When unset, just the metricName will be used to gather metrics.
	"""
																					properties: {
																						matchExpressions: {
																							description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																							items: {
																								description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																								properties: {
																									key: {
																										description: "key is the label key that the selector applies to."
																										type:        "string"
																									}
																									operator: {
																										description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																										type: "string"
																									}
																									values: {
																										description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																										items: type: "string"
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																								}
																								required: [
																									"key",
																									"operator",
																								]
																								type: "object"
																							}
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						matchLabels: {
																							additionalProperties: type: "string"
																							description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																							type: "object"
																						}
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																			}
																			required: ["name"]
																			type: "object"
																		}
																		target: {
																			description: "target specifies the target value for the given metric"
																			properties: {
																				averageUtilization: {
																					description: """
	averageUtilization is the target value of the average of the
	resource metric across all relevant pods, represented as a percentage of
	the requested value of the resource for the pods.
	Currently only valid for Resource metric source type
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				averageValue: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	averageValue is the target value of the average of the
	metric across all relevant pods (as a quantity)
	"""
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																				type: {
																					description: "type represents whether the metric type is Utilization, Value, or AverageValue"
																					type:        "string"
																				}
																				value: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description:                  "value is the target value of the metric (as a quantity)."
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																			}
																			required: ["type"]
																			type: "object"
																		}
																	}
																	required: [
																		"metric",
																		"target",
																	]
																	type: "object"
																}
																object: {
																	description: """
	object refers to a metric describing a single kubernetes object
	(for example, hits-per-second on an Ingress object).
	"""
																	properties: {
																		describedObject: {
																			description: "describedObject specifies the descriptions of a object,such as kind,name apiVersion"
																			properties: {
																				apiVersion: {
																					description: "apiVersion is the API version of the referent"
																					type:        "string"
																				}
																				kind: {
																					description: "kind is the kind of the referent; More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds"
																					type:        "string"
																				}
																				name: {
																					description: "name is the name of the referent; More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																					type:        "string"
																				}
																			}
																			required: [
																				"kind",
																				"name",
																			]
																			type: "object"
																		}
																		metric: {
																			description: "metric identifies the target metric by name and selector"
																			properties: {
																				name: {
																					description: "name is the name of the given metric"
																					type:        "string"
																				}
																				selector: {
																					description: """
	selector is the string-encoded form of a standard kubernetes label selector for the given metric
	When set, it is passed as an additional parameter to the metrics server for more specific metrics scoping.
	When unset, just the metricName will be used to gather metrics.
	"""
																					properties: {
																						matchExpressions: {
																							description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																							items: {
																								description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																								properties: {
																									key: {
																										description: "key is the label key that the selector applies to."
																										type:        "string"
																									}
																									operator: {
																										description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																										type: "string"
																									}
																									values: {
																										description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																										items: type: "string"
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																								}
																								required: [
																									"key",
																									"operator",
																								]
																								type: "object"
																							}
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						matchLabels: {
																							additionalProperties: type: "string"
																							description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																							type: "object"
																						}
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																			}
																			required: ["name"]
																			type: "object"
																		}
																		target: {
																			description: "target specifies the target value for the given metric"
																			properties: {
																				averageUtilization: {
																					description: """
	averageUtilization is the target value of the average of the
	resource metric across all relevant pods, represented as a percentage of
	the requested value of the resource for the pods.
	Currently only valid for Resource metric source type
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				averageValue: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	averageValue is the target value of the average of the
	metric across all relevant pods (as a quantity)
	"""
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																				type: {
																					description: "type represents whether the metric type is Utilization, Value, or AverageValue"
																					type:        "string"
																				}
																				value: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description:                  "value is the target value of the metric (as a quantity)."
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																			}
																			required: ["type"]
																			type: "object"
																		}
																	}
																	required: [
																		"describedObject",
																		"metric",
																		"target",
																	]
																	type: "object"
																}
																pods: {
																	description: """
	pods refers to a metric describing each pod in the current scale target
	(for example, transactions-processed-per-second).  The values will be
	averaged together before being compared to the target value.
	"""
																	properties: {
																		metric: {
																			description: "metric identifies the target metric by name and selector"
																			properties: {
																				name: {
																					description: "name is the name of the given metric"
																					type:        "string"
																				}
																				selector: {
																					description: """
	selector is the string-encoded form of a standard kubernetes label selector for the given metric
	When set, it is passed as an additional parameter to the metrics server for more specific metrics scoping.
	When unset, just the metricName will be used to gather metrics.
	"""
																					properties: {
																						matchExpressions: {
																							description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																							items: {
																								description: """
	A label selector requirement is a selector that contains values, a key, and an operator that
	relates the key and values.
	"""
																								properties: {
																									key: {
																										description: "key is the label key that the selector applies to."
																										type:        "string"
																									}
																									operator: {
																										description: """
	operator represents a key's relationship to a set of values.
	Valid operators are In, NotIn, Exists and DoesNotExist.
	"""
																										type: "string"
																									}
																									values: {
																										description: """
	values is an array of string values. If the operator is In or NotIn,
	the values array must be non-empty. If the operator is Exists or DoesNotExist,
	the values array must be empty. This array is replaced during a strategic
	merge patch.
	"""
																										items: type: "string"
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																								}
																								required: [
																									"key",
																									"operator",
																								]
																								type: "object"
																							}
																							type:                     "array"
																							"x-kubernetes-list-type": "atomic"
																						}
																						matchLabels: {
																							additionalProperties: type: "string"
																							description: """
	matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
	map is equivalent to an element of matchExpressions, whose key field is "key", the
	operator is "In", and the values array contains only "value". The requirements are ANDed.
	"""
																							type: "object"
																						}
																					}
																					type:                    "object"
																					"x-kubernetes-map-type": "atomic"
																				}
																			}
																			required: ["name"]
																			type: "object"
																		}
																		target: {
																			description: "target specifies the target value for the given metric"
																			properties: {
																				averageUtilization: {
																					description: """
	averageUtilization is the target value of the average of the
	resource metric across all relevant pods, represented as a percentage of
	the requested value of the resource for the pods.
	Currently only valid for Resource metric source type
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				averageValue: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	averageValue is the target value of the average of the
	metric across all relevant pods (as a quantity)
	"""
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																				type: {
																					description: "type represents whether the metric type is Utilization, Value, or AverageValue"
																					type:        "string"
																				}
																				value: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description:                  "value is the target value of the metric (as a quantity)."
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																			}
																			required: ["type"]
																			type: "object"
																		}
																	}
																	required: [
																		"metric",
																		"target",
																	]
																	type: "object"
																}
																resource: {
																	description: """
	resource refers to a resource metric (such as those specified in
	requests and limits) known to Kubernetes describing each pod in the
	current scale target (e.g. CPU or memory). Such metrics are built in to
	Kubernetes, and have special scaling options on top of those available
	to normal per-pod metrics using the "pods" source.
	"""
																	properties: {
																		name: {
																			description: "name is the name of the resource in question."
																			type:        "string"
																		}
																		target: {
																			description: "target specifies the target value for the given metric"
																			properties: {
																				averageUtilization: {
																					description: """
	averageUtilization is the target value of the average of the
	resource metric across all relevant pods, represented as a percentage of
	the requested value of the resource for the pods.
	Currently only valid for Resource metric source type
	"""
																					format: "int32"
																					type:   "integer"
																				}
																				averageValue: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	averageValue is the target value of the average of the
	metric across all relevant pods (as a quantity)
	"""
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																				type: {
																					description: "type represents whether the metric type is Utilization, Value, or AverageValue"
																					type:        "string"
																				}
																				value: {
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description:                  "value is the target value of the metric (as a quantity)."
																					pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					"x-kubernetes-int-or-string": true
																				}
																			}
																			required: ["type"]
																			type: "object"
																		}
																	}
																	required: [
																		"name",
																		"target",
																	]
																	type: "object"
																}
																type: {
																	description: """
	type is the type of metric source.  It should be one of "ContainerResource", "External",
	"Object", "Pods" or "Resource", each mapping to a matching field in the object.
	Note: "ContainerResource" type is available on when the feature-gate
	HPAContainerMetrics is enabled
	"""
																	type: "string"
																}
															}
															required: ["type"]
															type: "object"
														}
														type: "array"
													}
													minReplicas: {
														description: """
	minReplicas is the lower limit for the number of replicas to which the autoscaler
	can scale down. It defaults to 1 replica.
	"""
														format: "int32"
														type:   "integer"
														"x-kubernetes-validations": [{
															message: "minReplicas must be greater than 0"
															rule:    "self > 0"
														}]
													}
												}
												required: ["maxReplicas"]
												type: "object"
												"x-kubernetes-validations": [{
													message: "maxReplicas cannot be less than minReplicas"
													rule:    "!has(self.minReplicas) || self.maxReplicas >= self.minReplicas"
												}]
											}
											envoyPDB: {
												description: "EnvoyPDB allows to control the pod disruption budget of an Envoy Proxy."
												properties: minAvailable: {
													description: """
	MinAvailable specifies the minimum number of pods that must be available at all times during voluntary disruptions,
	such as node drains or updates. This setting ensures that your envoy proxy maintains a certain level of availability
	and resilience during maintenance operations.
	"""
													format: "int32"
													type:   "integer"
												}
												type: "object"
											}
											envoyService: {
												description: """
	EnvoyService defines the desired state of the Envoy service resource.
	If unspecified, default settings for the managed Envoy service resource
	are applied.
	"""
												properties: {
													allocateLoadBalancerNodePorts: {
														description: """
	AllocateLoadBalancerNodePorts defines if NodePorts will be automatically allocated for
	services with type LoadBalancer. Default is "true". It may be set to "false" if the cluster
	load-balancer does not rely on NodePorts. If the caller requests specific NodePorts (by specifying a
	value), those requests will be respected, regardless of this field. This field may only be set for
	services with type LoadBalancer and will be cleared if the type is changed to any other type.
	"""
														type: "boolean"
													}
													annotations: {
														additionalProperties: type: "string"
														description: """
	Annotations that should be appended to the service.
	By default, no annotations are appended.
	"""
														type: "object"
													}
													externalTrafficPolicy: {
														default: "Local"
														description: """
	ExternalTrafficPolicy determines the externalTrafficPolicy for the Envoy Service. Valid options
	are Local and Cluster. Default is "Local". "Local" means traffic will only go to pods on the node
	receiving the traffic. "Cluster" means connections are loadbalanced to all pods in the cluster.
	"""
														enum: [
															"Local",
															"Cluster",
														]
														type: "string"
													}
													labels: {
														additionalProperties: type: "string"
														description: """
	Labels that should be appended to the service.
	By default, no labels are appended.
	"""
														type: "object"
													}
													loadBalancerClass: {
														description: """
	LoadBalancerClass, when specified, allows for choosing the LoadBalancer provider
	implementation if more than one are available or is otherwise expected to be specified
	"""
														type: "string"
													}
													loadBalancerIP: {
														description: """
	LoadBalancerIP defines the IP Address of the underlying load balancer service. This field
	may be ignored if the load balancer provider does not support this feature.
	This field has been deprecated in Kubernetes, but it is still used for setting the IP Address in some cloud
	providers such as GCP.
	"""
														type: "string"
														"x-kubernetes-validations": [{
															message: "loadBalancerIP must be a valid IPv4 address"
															rule:    "self.matches(r\"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$\")"
														}]
													}
													loadBalancerSourceRanges: {
														description: """
	LoadBalancerSourceRanges defines a list of allowed IP addresses which will be configured as
	firewall rules on the platform providers load balancer. This is not guaranteed to be working as
	it happens outside of kubernetes and has to be supported and handled by the platform provider.
	This field may only be set for services with type LoadBalancer and will be cleared if the type
	is changed to any other type.
	"""
														items: type: "string"
														type: "array"
													}
													name: {
														description: """
	Name of the service.
	When unset, this defaults to an autogenerated name.
	"""
														type: "string"
													}
													patch: {
														description: "Patch defines how to perform the patch operation to the service"
														properties: {
															type: {
																description: """
	Type is the type of merge operation to perform

	By default, StrategicMerge is used as the patch type.
	"""
																type: "string"
															}
															value: {
																description:                            "Object contains the raw configuration for merged object"
																"x-kubernetes-preserve-unknown-fields": true
															}
														}
														required: ["value"]
														type: "object"
													}
													type: {
														default: "LoadBalancer"
														description: """
	Type determines how the Service is exposed. Defaults to LoadBalancer.
	Valid options are ClusterIP, LoadBalancer and NodePort.
	"LoadBalancer" means a service will be exposed via an external load balancer (if the cloud provider supports it).
	"ClusterIP" means a service will only be accessible inside the cluster, via the cluster IP.
	"NodePort" means a service will be exposed on a static Port on all Nodes of the cluster.
	"""
														enum: [
															"ClusterIP",
															"LoadBalancer",
															"NodePort",
														]
														type: "string"
													}
												}
												type: "object"
												"x-kubernetes-validations": [{
													message: "allocateLoadBalancerNodePorts can only be set for LoadBalancer type"
													rule:    "!has(self.allocateLoadBalancerNodePorts) || self.type == 'LoadBalancer'"
												}, {
													message: "loadBalancerSourceRanges can only be set for LoadBalancer type"
													rule:    "!has(self.loadBalancerSourceRanges) || self.type == 'LoadBalancer'"
												}, {
													message: "loadBalancerIP can only be set for LoadBalancer type"
													rule:    "!has(self.loadBalancerIP) || self.type == 'LoadBalancer'"
												}]
											}
											useListenerPortAsContainerPort: {
												description: """
	UseListenerPortAsContainerPort disables the port shifting feature in the Envoy Proxy.
	When set to false (default value), if the service port is a privileged port (1-1023), add a constant to the value converting it into an ephemeral port.
	This allows the container to bind to the port without needing a CAP_NET_BIND_SERVICE capability.
	"""
												type: "boolean"
											}
										}
										type: "object"
										"x-kubernetes-validations": [{
											message: "only one of envoyDeployment or envoyDaemonSet can be specified"
											rule:    "((has(self.envoyDeployment) && !has(self.envoyDaemonSet)) || (!has(self.envoyDeployment) && has(self.envoyDaemonSet))) || (!has(self.envoyDeployment) && !has(self.envoyDaemonSet))"
										}, {
											message: "cannot use envoyHpa if envoyDaemonSet is used"
											rule:    "((has(self.envoyHpa) && !has(self.envoyDaemonSet)) || (!has(self.envoyHpa) && has(self.envoyDaemonSet))) || (!has(self.envoyHpa) && !has(self.envoyDaemonSet))"
										}]
									}
									type: {
										description: """
	Type is the type of resource provider to use. A resource provider provides
	infrastructure resources for running the data plane, e.g. Envoy proxy, and
	optional auxiliary control planes. Supported types are "Kubernetes".
	"""
										enum: [
											"Kubernetes",
											"Custom",
										]
										type: "string"
									}
								}
								required: ["type"]
								type: "object"
							}
							routingType: {
								description: """
	RoutingType can be set to "Service" to use the Service Cluster IP for routing to the backend,
	or it can be set to "Endpoint" to use Endpoint routing. The default is "Endpoint".
	"""
								type: "string"
							}
							shutdown: {
								description: "Shutdown defines configuration for graceful envoy shutdown process."
								properties: {
									drainTimeout: {
										description: """
	DrainTimeout defines the graceful drain timeout. This should be less than the pod's terminationGracePeriodSeconds.
	If unspecified, defaults to 60 seconds.
	"""
										type: "string"
									}
									minDrainDuration: {
										description: """
	MinDrainDuration defines the minimum drain duration allowing time for endpoint deprogramming to complete.
	If unspecified, defaults to 10 seconds.
	"""
										type: "string"
									}
								}
								type: "object"
							}
							telemetry: {
								description: "Telemetry defines telemetry parameters for managed proxies."
								properties: {
									accessLog: {
										description: """
	AccessLogs defines accesslog parameters for managed proxies.
	If unspecified, will send default format to stdout.
	"""
										properties: {
											disable: {
												description: "Disable disables access logging for managed proxies if set to true."
												type:        "boolean"
											}
											settings: {
												description: """
	Settings defines accesslog settings for managed proxies.
	If unspecified, will send default format to stdout.
	"""
												items: {
													properties: {
														format: {
															description: """
	Format defines the format of accesslog.
	This will be ignored if sink type is ALS.
	"""
															properties: {
																json: {
																	additionalProperties: type: "string"
																	description: """
	JSON is additional attributes that describe the specific event occurrence.
	Structured format for the envoy access logs. Envoy [command operators](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators)
	can be used as values for fields within the Struct.
	It's required when the format type is "JSON".
	"""
																	type: "object"
																}
																text: {
																	description: """
	Text defines the text accesslog format, following Envoy accesslog formatting,
	It's required when the format type is "Text".
	Envoy [command operators](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators) may be used in the format.
	The [format string documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#config-access-log-format-strings) provides more information.
	"""
																	type: "string"
																}
																type: {
																	description: "Type defines the type of accesslog format."
																	enum: [
																		"Text",
																		"JSON",
																	]
																	type: "string"
																}
															}
															type: "object"
															"x-kubernetes-validations": [{
																message: "If AccessLogFormat type is Text, text field needs to be set."
																rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
															}, {
																message: "If AccessLogFormat type is JSON, json field needs to be set."
																rule:    "self.type == 'JSON' ? has(self.json) : !has(self.json)"
															}]
														}
														matches: {
															description: """
	Matches defines the match conditions for accesslog in CEL expression.
	An accesslog will be emitted only when one or more match conditions are evaluated to true.
	Invalid [CEL](https://www.envoyproxy.io/docs/envoy/latest/xds/type/v3/cel.proto.html#common-expression-language-cel-proto) expressions will be ignored.
	"""
															items: type: "string"
															maxItems: 10
															type:     "array"
														}
														sinks: {
															description: "Sinks defines the sinks of accesslog."
															items: {
																description: "ProxyAccessLogSink defines the sink of accesslog."
																properties: {
																	als: {
																		description: "ALS defines the gRPC Access Log Service (ALS) sink."
																		properties: {
																			backendRef: {
																				description: """
	BackendRef references a Kubernetes object that represents the
	backend server to which the authorization request will be sent.

	Deprecated: Use BackendRefs instead.
	"""
																				properties: {
																					group: {
																						default: ""
																						description: """
	Group is the group of the referent. For example, "gateway.networking.k8s.io".
	When unspecified or empty string, core API group is inferred.
	"""
																						maxLength: 253
																						pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																						type:      "string"
																					}
																					kind: {
																						default: "Service"
																						description: """
	Kind is the Kubernetes resource kind of the referent. For example
	"Service".

	Defaults to "Service" when not specified.

	ExternalName services can refer to CNAME DNS records that may live
	outside of the cluster and as such are difficult to reason about in
	terms of conformance. They also may not be safe to forward to (see
	CVE-2021-25740 for more information). Implementations SHOULD NOT
	support ExternalName Services.

	Support: Core (Services with a type other than ExternalName)

	Support: Implementation-specific (Services with type ExternalName)
	"""
																						maxLength: 63
																						minLength: 1
																						pattern:   "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
																						type:      "string"
																					}
																					name: {
																						description: "Name is the name of the referent."
																						maxLength:   253
																						minLength:   1
																						type:        "string"
																					}
																					namespace: {
																						description: """
	Namespace is the namespace of the backend. When unspecified, the local
	namespace is inferred.

	Note that when a namespace different than the local namespace is specified,
	a ReferenceGrant object is required in the referent namespace to allow that
	namespace's owner to accept the reference. See the ReferenceGrant
	documentation for details.

	Support: Core
	"""
																						maxLength: 63
																						minLength: 1
																						pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
																						type:      "string"
																					}
																					port: {
																						description: """
	Port specifies the destination port number to use for this resource.
	Port is required when the referent is a Kubernetes Service. In this
	case, the port number is the service port number, not the target port.
	For other resources, destination port might be derived from the referent
	resource or this field.
	"""
																						format:  "int32"
																						maximum: 65535
																						minimum: 1
																						type:    "integer"
																					}
																				}
																				required: ["name"]
																				type: "object"
																				"x-kubernetes-validations": [{
																					message: "Must have port for Service reference"
																					rule:    "(size(self.group) == 0 && self.kind == 'Service') ? has(self.port) : true"
																				}]
																			}
																			backendRefs: {
																				description: """
	BackendRefs references a Kubernetes object that represents the
	backend server to which the authorization request will be sent.
	"""
																				items: {
																					description: "BackendRef defines how an ObjectReference that is specific to BackendRef."
																					properties: {
																						fallback: {
																							description: """
	Fallback indicates whether the backend is designated as a fallback.
	Multiple fallback backends can be configured.
	It is highly recommended to configure active or passive health checks to ensure that failover can be detected
	when the active backends become unhealthy and to automatically readjust once the primary backends are healthy again.
	The overprovisioning factor is set to 1.4, meaning the fallback backends will only start receiving traffic when
	the health of the active backends falls below 72%.
	"""
																							type: "boolean"
																						}
																						group: {
																							default: ""
																							description: """
	Group is the group of the referent. For example, "gateway.networking.k8s.io".
	When unspecified or empty string, core API group is inferred.
	"""
																							maxLength: 253
																							pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																							type:      "string"
																						}
																						kind: {
																							default: "Service"
																							description: """
	Kind is the Kubernetes resource kind of the referent. For example
	"Service".

	Defaults to "Service" when not specified.

	ExternalName services can refer to CNAME DNS records that may live
	outside of the cluster and as such are difficult to reason about in
	terms of conformance. They also may not be safe to forward to (see
	CVE-2021-25740 for more information). Implementations SHOULD NOT
	support ExternalName Services.

	Support: Core (Services with a type other than ExternalName)

	Support: Implementation-specific (Services with type ExternalName)
	"""
																							maxLength: 63
																							minLength: 1
																							pattern:   "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
																							type:      "string"
																						}
																						name: {
																							description: "Name is the name of the referent."
																							maxLength:   253
																							minLength:   1
																							type:        "string"
																						}
																						namespace: {
																							description: """
	Namespace is the namespace of the backend. When unspecified, the local
	namespace is inferred.

	Note that when a namespace different than the local namespace is specified,
	a ReferenceGrant object is required in the referent namespace to allow that
	namespace's owner to accept the reference. See the ReferenceGrant
	documentation for details.

	Support: Core
	"""
																							maxLength: 63
																							minLength: 1
																							pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
																							type:      "string"
																						}
																						port: {
																							description: """
	Port specifies the destination port number to use for this resource.
	Port is required when the referent is a Kubernetes Service. In this
	case, the port number is the service port number, not the target port.
	For other resources, destination port might be derived from the referent
	resource or this field.
	"""
																							format:  "int32"
																							maximum: 65535
																							minimum: 1
																							type:    "integer"
																						}
																					}
																					required: ["name"]
																					type: "object"
																					"x-kubernetes-validations": [{
																						message: "Must have port for Service reference"
																						rule:    "(size(self.group) == 0 && self.kind == 'Service') ? has(self.port) : true"
																					}]
																				}
																				maxItems: 16
																				type:     "array"
																			}
																			backendSettings: {
																				description: """
	BackendSettings holds configuration for managing the connection
	to the backend.
	"""
																				properties: {
																					circuitBreaker: {
																						description: """
	Circuit Breaker settings for the upstream connections and requests.
	If not set, circuit breakers will be enabled with the default thresholds
	"""
																						properties: {
																							maxConnections: {
																								default:     1024
																								description: "The maximum number of connections that Envoy will establish to the referenced backend defined within a xRoute rule."
																								format:      "int64"
																								maximum:     4294967295
																								minimum:     0
																								type:        "integer"
																							}
																							maxParallelRequests: {
																								default:     1024
																								description: "The maximum number of parallel requests that Envoy will make to the referenced backend defined within a xRoute rule."
																								format:      "int64"
																								maximum:     4294967295
																								minimum:     0
																								type:        "integer"
																							}
																							maxParallelRetries: {
																								default:     1024
																								description: "The maximum number of parallel retries that Envoy will make to the referenced backend defined within a xRoute rule."
																								format:      "int64"
																								maximum:     4294967295
																								minimum:     0
																								type:        "integer"
																							}
																							maxPendingRequests: {
																								default:     1024
																								description: "The maximum number of pending requests that Envoy will queue to the referenced backend defined within a xRoute rule."
																								format:      "int64"
																								maximum:     4294967295
																								minimum:     0
																								type:        "integer"
																							}
																							maxRequestsPerConnection: {
																								description: """
	The maximum number of requests that Envoy will make over a single connection to the referenced backend defined within a xRoute rule.
	Default: unlimited.
	"""
																								format:  "int64"
																								maximum: 4294967295
																								minimum: 0
																								type:    "integer"
																							}
																						}
																						type: "object"
																					}
																					connection: {
																						description: "Connection includes backend connection settings."
																						properties: {
																							bufferLimit: {
																								allOf: [{
																									pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																								}, {
																									pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																								}]
																								anyOf: [{
																									type: "integer"
																								}, {
																									type: "string"
																								}]
																								description: """
	BufferLimit Soft limit on size of the cluster’s connections read and write buffers.
	BufferLimit applies to connection streaming (maybe non-streaming) channel between processes, it's in user space.
	If unspecified, an implementation defined default is applied (32768 bytes).
	For example, 20Mi, 1Gi, 256Ki etc.
	Note: that when the suffix is not provided, the value is interpreted as bytes.
	"""
																								"x-kubernetes-int-or-string": true
																							}
																							socketBufferLimit: {
																								allOf: [{
																									pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																								}, {
																									pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																								}]
																								anyOf: [{
																									type: "integer"
																								}, {
																									type: "string"
																								}]
																								description: """
	SocketBufferLimit provides configuration for the maximum buffer size in bytes for each socket
	to backend.
	SocketBufferLimit applies to socket streaming channel between TCP/IP stacks, it's in kernel space.
	For example, 20Mi, 1Gi, 256Ki etc.
	Note that when the suffix is not provided, the value is interpreted as bytes.
	"""
																								"x-kubernetes-int-or-string": true
																							}
																						}
																						type: "object"
																					}
																					dns: {
																						description: "DNS includes dns resolution settings."
																						properties: {
																							dnsRefreshRate: {
																								description: """
	DNSRefreshRate specifies the rate at which DNS records should be refreshed.
	Defaults to 30 seconds.
	"""
																								type: "string"
																							}
																							respectDnsTtl: {
																								description: """
	RespectDNSTTL indicates whether the DNS Time-To-Live (TTL) should be respected.
	If the value is set to true, the DNS refresh rate will be set to the resource record’s TTL.
	Defaults to true.
	"""
																								type: "boolean"
																							}
																						}
																						type: "object"
																					}
																					healthCheck: {
																						description: "HealthCheck allows gateway to perform active health checking on backends."
																						properties: {
																							active: {
																								description: "Active health check configuration"
																								properties: {
																									grpc: {
																										description: """
	GRPC defines the configuration of the GRPC health checker.
	It's optional, and can only be used if the specified type is GRPC.
	"""
																										properties: service: {
																											description: """
	Service to send in the health check request.
	If this is not specified, then the health check request applies to the entire
	server and not to a specific service.
	"""
																											type: "string"
																										}
																										type: "object"
																									}
																									healthyThreshold: {
																										default:     1
																										description: "HealthyThreshold defines the number of healthy health checks required before a backend host is marked healthy."
																										format:      "int32"
																										minimum:     1
																										type:        "integer"
																									}
																									http: {
																										description: """
	HTTP defines the configuration of http health checker.
	It's required while the health checker type is HTTP.
	"""
																										properties: {
																											expectedResponse: {
																												description: "ExpectedResponse defines a list of HTTP expected responses to match."
																												properties: {
																													binary: {
																														description: "Binary payload base64 encoded."
																														format:      "byte"
																														type:        "string"
																													}
																													text: {
																														description: "Text payload in plain text."
																														type:        "string"
																													}
																													type: {
																														allOf: [{
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}, {
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}]
																														description: "Type defines the type of the payload."
																														type:        "string"
																													}
																												}
																												required: ["type"]
																												type: "object"
																												"x-kubernetes-validations": [{
																													message: "If payload type is Text, text field needs to be set."
																													rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																												}, {
																													message: "If payload type is Binary, binary field needs to be set."
																													rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																												}]
																											}
																											expectedStatuses: {
																												description: """
	ExpectedStatuses defines a list of HTTP response statuses considered healthy.
	Defaults to 200 only
	"""
																												items: {
																													description:      "HTTPStatus defines the http status code."
																													exclusiveMaximum: true
																													maximum:          600
																													minimum:          100
																													type:             "integer"
																												}
																												type: "array"
																											}
																											method: {
																												description: """
	Method defines the HTTP method used for health checking.
	Defaults to GET
	"""
																												type: "string"
																											}
																											path: {
																												description: "Path defines the HTTP path that will be requested during health checking."
																												maxLength:   1024
																												minLength:   1
																												type:        "string"
																											}
																										}
																										required: ["path"]
																										type: "object"
																									}
																									interval: {
																										default:     "3s"
																										description: "Interval defines the time between active health checks."
																										format:      "duration"
																										type:        "string"
																									}
																									tcp: {
																										description: """
	TCP defines the configuration of tcp health checker.
	It's required while the health checker type is TCP.
	"""
																										properties: {
																											receive: {
																												description: "Receive defines the expected response payload."
																												properties: {
																													binary: {
																														description: "Binary payload base64 encoded."
																														format:      "byte"
																														type:        "string"
																													}
																													text: {
																														description: "Text payload in plain text."
																														type:        "string"
																													}
																													type: {
																														allOf: [{
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}, {
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}]
																														description: "Type defines the type of the payload."
																														type:        "string"
																													}
																												}
																												required: ["type"]
																												type: "object"
																												"x-kubernetes-validations": [{
																													message: "If payload type is Text, text field needs to be set."
																													rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																												}, {
																													message: "If payload type is Binary, binary field needs to be set."
																													rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																												}]
																											}
																											send: {
																												description: "Send defines the request payload."
																												properties: {
																													binary: {
																														description: "Binary payload base64 encoded."
																														format:      "byte"
																														type:        "string"
																													}
																													text: {
																														description: "Text payload in plain text."
																														type:        "string"
																													}
																													type: {
																														allOf: [{
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}, {
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}]
																														description: "Type defines the type of the payload."
																														type:        "string"
																													}
																												}
																												required: ["type"]
																												type: "object"
																												"x-kubernetes-validations": [{
																													message: "If payload type is Text, text field needs to be set."
																													rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																												}, {
																													message: "If payload type is Binary, binary field needs to be set."
																													rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																												}]
																											}
																										}
																										type: "object"
																									}
																									timeout: {
																										default:     "1s"
																										description: "Timeout defines the time to wait for a health check response."
																										format:      "duration"
																										type:        "string"
																									}
																									type: {
																										allOf: [{
																											enum: [
																												"HTTP",
																												"TCP",
																												"GRPC",
																											]
																										}, {
																											enum: [
																												"HTTP",
																												"TCP",
																												"GRPC",
																											]
																										}]
																										description: "Type defines the type of health checker."
																										type:        "string"
																									}
																									unhealthyThreshold: {
																										default:     3
																										description: "UnhealthyThreshold defines the number of unhealthy health checks required before a backend host is marked unhealthy."
																										format:      "int32"
																										minimum:     1
																										type:        "integer"
																									}
																								}
																								required: ["type"]
																								type: "object"
																								"x-kubernetes-validations": [{
																									message: "If Health Checker type is HTTP, http field needs to be set."
																									rule:    "self.type == 'HTTP' ? has(self.http) : !has(self.http)"
																								}, {
																									message: "If Health Checker type is TCP, tcp field needs to be set."
																									rule:    "self.type == 'TCP' ? has(self.tcp) : !has(self.tcp)"
																								}, {
																									message: "The grpc field can only be set if the Health Checker type is GRPC."
																									rule:    "has(self.grpc) ? self.type == 'GRPC' : true"
																								}]
																							}
																							passive: {
																								description: "Passive passive check configuration"
																								properties: {
																									baseEjectionTime: {
																										default:     "30s"
																										description: "BaseEjectionTime defines the base duration for which a host will be ejected on consecutive failures."
																										format:      "duration"
																										type:        "string"
																									}
																									consecutive5XxErrors: {
																										default:     5
																										description: "Consecutive5xxErrors sets the number of consecutive 5xx errors triggering ejection."
																										format:      "int32"
																										type:        "integer"
																									}
																									consecutiveGatewayErrors: {
																										default:     0
																										description: "ConsecutiveGatewayErrors sets the number of consecutive gateway errors triggering ejection."
																										format:      "int32"
																										type:        "integer"
																									}
																									consecutiveLocalOriginFailures: {
																										default: 5
																										description: """
	ConsecutiveLocalOriginFailures sets the number of consecutive local origin failures triggering ejection.
	Parameter takes effect only when split_external_local_origin_errors is set to true.
	"""
																										format: "int32"
																										type:   "integer"
																									}
																									interval: {
																										default:     "3s"
																										description: "Interval defines the time between passive health checks."
																										format:      "duration"
																										type:        "string"
																									}
																									maxEjectionPercent: {
																										default:     10
																										description: "MaxEjectionPercent sets the maximum percentage of hosts in a cluster that can be ejected."
																										format:      "int32"
																										type:        "integer"
																									}
																									splitExternalLocalOriginErrors: {
																										default:     false
																										description: "SplitExternalLocalOriginErrors enables splitting of errors between external and local origin."
																										type:        "boolean"
																									}
																								}
																								type: "object"
																							}
																						}
																						type: "object"
																					}
																					http2: {
																						description: "HTTP2 provides HTTP/2 configuration for backend connections."
																						properties: {
																							initialConnectionWindowSize: {
																								allOf: [{
																									pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																								}, {
																									pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																								}]
																								anyOf: [{
																									type: "integer"
																								}, {
																									type: "string"
																								}]
																								description: """
	InitialConnectionWindowSize sets the initial window size for HTTP/2 connections.
	If not set, the default value is 1 MiB.
	"""
																								"x-kubernetes-int-or-string": true
																							}
																							initialStreamWindowSize: {
																								allOf: [{
																									pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																								}, {
																									pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																								}]
																								anyOf: [{
																									type: "integer"
																								}, {
																									type: "string"
																								}]
																								description: """
	InitialStreamWindowSize sets the initial window size for HTTP/2 streams.
	If not set, the default value is 64 KiB(64*1024).
	"""
																								"x-kubernetes-int-or-string": true
																							}
																							maxConcurrentStreams: {
																								description: """
	MaxConcurrentStreams sets the maximum number of concurrent streams allowed per connection.
	If not set, the default value is 100.
	"""
																								format:  "int32"
																								maximum: 2147483647
																								minimum: 1
																								type:    "integer"
																							}
																							onInvalidMessage: {
																								description: """
	OnInvalidMessage determines if Envoy will terminate the connection or just the offending stream in the event of HTTP messaging error
	It's recommended for L2 Envoy deployments to set this value to TerminateStream.
	https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/level_two
	Default: TerminateConnection
	"""
																								type: "string"
																							}
																						}
																						type: "object"
																					}
																					loadBalancer: {
																						description: """
	LoadBalancer policy to apply when routing traffic from the gateway to
	the backend endpoints. Defaults to `LeastRequest`.
	"""
																						properties: {
																							consistentHash: {
																								description: """
	ConsistentHash defines the configuration when the load balancer type is
	set to ConsistentHash
	"""
																								properties: {
																									cookie: {
																										description: "Cookie configures the cookie hash policy when the consistent hash type is set to Cookie."
																										properties: {
																											attributes: {
																												additionalProperties: type: "string"
																												description: "Additional Attributes to set for the generated cookie."
																												type:        "object"
																											}
																											name: {
																												description: """
	Name of the cookie to hash.
	If this cookie does not exist in the request, Envoy will generate a cookie and set
	the TTL on the response back to the client based on Layer 4
	attributes of the backend endpoint, to ensure that these future requests
	go to the same backend endpoint. Make sure to set the TTL field for this case.
	"""
																												type: "string"
																											}
																											ttl: {
																												description: """
	TTL of the generated cookie if the cookie is not present. This value sets the
	Max-Age attribute value.
	"""
																												type: "string"
																											}
																										}
																										required: ["name"]
																										type: "object"
																									}
																									header: {
																										description: "Header configures the header hash policy when the consistent hash type is set to Header."
																										properties: name: {
																											description: "Name of the header to hash."
																											type:        "string"
																										}
																										required: ["name"]
																										type: "object"
																									}
																									tableSize: {
																										default:     65537
																										description: "The table size for consistent hashing, must be prime number limited to 5000011."
																										format:      "int64"
																										maximum:     5000011
																										minimum:     2
																										type:        "integer"
																									}
																									type: {
																										description: """
	ConsistentHashType defines the type of input to hash on. Valid Type values are
	"SourceIP",
	"Header",
	"Cookie".
	"""
																										enum: [
																											"SourceIP",
																											"Header",
																											"Cookie",
																										]
																										type: "string"
																									}
																								}
																								required: ["type"]
																								type: "object"
																								"x-kubernetes-validations": [{
																									message: "If consistent hash type is header, the header field must be set."
																									rule:    "self.type == 'Header' ? has(self.header) : !has(self.header)"
																								}, {
																									message: "If consistent hash type is cookie, the cookie field must be set."
																									rule:    "self.type == 'Cookie' ? has(self.cookie) : !has(self.cookie)"
																								}]
																							}
																							slowStart: {
																								description: """
	SlowStart defines the configuration related to the slow start load balancer policy.
	If set, during slow start window, traffic sent to the newly added hosts will gradually increase.
	Currently this is only supported for RoundRobin and LeastRequest load balancers
	"""
																								properties: window: {
																									description: """
	Window defines the duration of the warm up period for newly added host.
	During slow start window, traffic sent to the newly added hosts will gradually increase.
	Currently only supports linear growth of traffic. For additional details,
	see https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto#config-cluster-v3-cluster-slowstartconfig
	"""
																									type: "string"
																								}
																								required: ["window"]
																								type: "object"
																							}
																							type: {
																								description: """
	Type decides the type of Load Balancer policy.
	Valid LoadBalancerType values are
	"ConsistentHash",
	"LeastRequest",
	"Random",
	"RoundRobin".
	"""
																								enum: [
																									"ConsistentHash",
																									"LeastRequest",
																									"Random",
																									"RoundRobin",
																								]
																								type: "string"
																							}
																						}
																						required: ["type"]
																						type: "object"
																						"x-kubernetes-validations": [{
																							message: "If LoadBalancer type is consistentHash, consistentHash field needs to be set."
																							rule:    "self.type == 'ConsistentHash' ? has(self.consistentHash) : !has(self.consistentHash)"
																						}, {
																							message: "Currently SlowStart is only supported for RoundRobin and LeastRequest load balancers."
																							rule:    "self.type in ['Random', 'ConsistentHash'] ? !has(self.slowStart) : true "
																						}]
																					}
																					proxyProtocol: {
																						description: "ProxyProtocol enables the Proxy Protocol when communicating with the backend."
																						properties: version: {
																							description: """
	Version of ProxyProtol
	Valid ProxyProtocolVersion values are
	"V1"
	"V2"
	"""
																							enum: [
																								"V1",
																								"V2",
																							]
																							type: "string"
																						}
																						required: ["version"]
																						type: "object"
																					}
																					retry: {
																						description: """
	Retry provides more advanced usage, allowing users to customize the number of retries, retry fallback strategy, and retry triggering conditions.
	If not set, retry will be disabled.
	"""
																						properties: {
																							numRetries: {
																								default:     2
																								description: "NumRetries is the number of retries to be attempted. Defaults to 2."
																								format:      "int32"
																								minimum:     0
																								type:        "integer"
																							}
																							perRetry: {
																								description: "PerRetry is the retry policy to be applied per retry attempt."
																								properties: {
																									backOff: {
																										description: """
	Backoff is the backoff policy to be applied per retry attempt. gateway uses a fully jittered exponential
	back-off algorithm for retries. For additional details,
	see https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#config-http-filters-router-x-envoy-max-retries
	"""
																										properties: {
																											baseInterval: {
																												description: "BaseInterval is the base interval between retries."
																												format:      "duration"
																												type:        "string"
																											}
																											maxInterval: {
																												description: """
	MaxInterval is the maximum interval between retries. This parameter is optional, but must be greater than or equal to the base_interval if set.
	The default is 10 times the base_interval
	"""
																												format: "duration"
																												type:   "string"
																											}
																										}
																										type: "object"
																									}
																									timeout: {
																										description: "Timeout is the timeout per retry attempt."
																										format:      "duration"
																										type:        "string"
																									}
																								}
																								type: "object"
																							}
																							retryOn: {
																								description: """
	RetryOn specifies the retry trigger condition.

	If not specified, the default is to retry on connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes(503).
	"""
																								properties: {
																									httpStatusCodes: {
																										description: """
	HttpStatusCodes specifies the http status codes to be retried.
	The retriable-status-codes trigger must also be configured for these status codes to trigger a retry.
	"""
																										items: {
																											description:      "HTTPStatus defines the http status code."
																											exclusiveMaximum: true
																											maximum:          600
																											minimum:          100
																											type:             "integer"
																										}
																										type: "array"
																									}
																									triggers: {
																										description: "Triggers specifies the retry trigger condition(Http/Grpc)."
																										items: {
																											description: "TriggerEnum specifies the conditions that trigger retries."
																											enum: [
																												"5xx",
																												"gateway-error",
																												"reset",
																												"connect-failure",
																												"retriable-4xx",
																												"refused-stream",
																												"retriable-status-codes",
																												"cancelled",
																												"deadline-exceeded",
																												"internal",
																												"resource-exhausted",
																												"unavailable",
																											]
																											type: "string"
																										}
																										type: "array"
																									}
																								}
																								type: "object"
																							}
																						}
																						type: "object"
																					}
																					tcpKeepalive: {
																						description: """
	TcpKeepalive settings associated with the upstream client connection.
	Disabled by default.
	"""
																						properties: {
																							idleTime: {
																								description: """
	The duration a connection needs to be idle before keep-alive
	probes start being sent.
	The duration format is
	Defaults to `7200s`.
	"""
																								pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																								type:    "string"
																							}
																							interval: {
																								description: """
	The duration between keep-alive probes.
	Defaults to `75s`.
	"""
																								pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																								type:    "string"
																							}
																							probes: {
																								description: """
	The total number of unacknowledged probes to send before deciding
	the connection is dead.
	Defaults to 9.
	"""
																								format: "int32"
																								type:   "integer"
																							}
																						}
																						type: "object"
																					}
																					timeout: {
																						description: "Timeout settings for the backend connections."
																						properties: {
																							http: {
																								description: "Timeout settings for HTTP."
																								properties: {
																									connectionIdleTimeout: {
																										description: """
	The idle timeout for an HTTP connection. Idle time is defined as a period in which there are no active requests in the connection.
	Default: 1 hour.
	"""
																										pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																										type:    "string"
																									}
																									maxConnectionDuration: {
																										description: """
	The maximum duration of an HTTP connection.
	Default: unlimited.
	"""
																										pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																										type:    "string"
																									}
																									requestTimeout: {
																										description: "RequestTimeout is the time until which entire response is received from the upstream."
																										pattern:     "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																										type:        "string"
																									}
																								}
																								type: "object"
																							}
																							tcp: {
																								description: "Timeout settings for TCP."
																								properties: connectTimeout: {
																									description: """
	The timeout for network connection establishment, including TCP and TLS handshakes.
	Default: 10 seconds.
	"""
																									pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																									type:    "string"
																								}
																								type: "object"
																							}
																						}
																						type: "object"
																					}
																				}
																				type: "object"
																			}
																			http: {
																				description: "HTTP defines additional configuration specific to HTTP access logs."
																				properties: {
																					requestHeaders: {
																						description: "RequestHeaders defines request headers to include in log entries sent to the access log service."
																						items: type: "string"
																						type: "array"
																					}
																					responseHeaders: {
																						description: "ResponseHeaders defines response headers to include in log entries sent to the access log service."
																						items: type: "string"
																						type: "array"
																					}
																					responseTrailers: {
																						description: "ResponseTrailers defines response trailers to include in log entries sent to the access log service."
																						items: type: "string"
																						type: "array"
																					}
																				}
																				type: "object"
																			}
																			logName: {
																				description: """
	LogName defines the friendly name of the access log to be returned in
	StreamAccessLogsMessage.Identifier. This allows the access log server
	to differentiate between different access logs coming from the same Envoy.
	"""
																				minLength: 1
																				type:      "string"
																			}
																			type: {
																				description: "Type defines the type of accesslog. Supported types are \"HTTP\" and \"TCP\"."
																				enum: [
																					"HTTP",
																					"TCP",
																				]
																				type: "string"
																			}
																		}
																		required: ["type"]
																		type: "object"
																		"x-kubernetes-validations": [{
																			message: "The http field may only be set when type is HTTP."
																			rule:    "self.type == 'HTTP' || !has(self.http)"
																		}, {
																			message: "BackendRefs must be used, backendRef is not supported."
																			rule:    "!has(self.backendRef)"
																		}, {
																			message: "must have at least one backend in backendRefs"
																			rule:    "has(self.backendRefs) && self.backendRefs.size() > 0"
																		}, {
																			message: "BackendRefs only supports Service kind."
																			rule:    "has(self.backendRefs) ? self.backendRefs.all(f, f.kind == 'Service') : true"
																		}, {
																			message: "BackendRefs only supports Core group."
																			rule:    "has(self.backendRefs) ? (self.backendRefs.all(f, f.group == \"\")) : true"
																		}]
																	}
																	file: {
																		description: "File defines the file accesslog sink."
																		properties: path: {
																			description: "Path defines the file path used to expose envoy access log(e.g. /dev/stdout)."
																			minLength:   1
																			type:        "string"
																		}
																		type: "object"
																	}
																	openTelemetry: {
																		description: "OpenTelemetry defines the OpenTelemetry accesslog sink."
																		properties: {
																			backendRef: {
																				description: """
	BackendRef references a Kubernetes object that represents the
	backend server to which the authorization request will be sent.

	Deprecated: Use BackendRefs instead.
	"""
																				properties: {
																					group: {
																						default: ""
																						description: """
	Group is the group of the referent. For example, "gateway.networking.k8s.io".
	When unspecified or empty string, core API group is inferred.
	"""
																						maxLength: 253
																						pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																						type:      "string"
																					}
																					kind: {
																						default: "Service"
																						description: """
	Kind is the Kubernetes resource kind of the referent. For example
	"Service".

	Defaults to "Service" when not specified.

	ExternalName services can refer to CNAME DNS records that may live
	outside of the cluster and as such are difficult to reason about in
	terms of conformance. They also may not be safe to forward to (see
	CVE-2021-25740 for more information). Implementations SHOULD NOT
	support ExternalName Services.

	Support: Core (Services with a type other than ExternalName)

	Support: Implementation-specific (Services with type ExternalName)
	"""
																						maxLength: 63
																						minLength: 1
																						pattern:   "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
																						type:      "string"
																					}
																					name: {
																						description: "Name is the name of the referent."
																						maxLength:   253
																						minLength:   1
																						type:        "string"
																					}
																					namespace: {
																						description: """
	Namespace is the namespace of the backend. When unspecified, the local
	namespace is inferred.

	Note that when a namespace different than the local namespace is specified,
	a ReferenceGrant object is required in the referent namespace to allow that
	namespace's owner to accept the reference. See the ReferenceGrant
	documentation for details.

	Support: Core
	"""
																						maxLength: 63
																						minLength: 1
																						pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
																						type:      "string"
																					}
																					port: {
																						description: """
	Port specifies the destination port number to use for this resource.
	Port is required when the referent is a Kubernetes Service. In this
	case, the port number is the service port number, not the target port.
	For other resources, destination port might be derived from the referent
	resource or this field.
	"""
																						format:  "int32"
																						maximum: 65535
																						minimum: 1
																						type:    "integer"
																					}
																				}
																				required: ["name"]
																				type: "object"
																				"x-kubernetes-validations": [{
																					message: "Must have port for Service reference"
																					rule:    "(size(self.group) == 0 && self.kind == 'Service') ? has(self.port) : true"
																				}]
																			}
																			backendRefs: {
																				description: """
	BackendRefs references a Kubernetes object that represents the
	backend server to which the authorization request will be sent.
	"""
																				items: {
																					description: "BackendRef defines how an ObjectReference that is specific to BackendRef."
																					properties: {
																						fallback: {
																							description: """
	Fallback indicates whether the backend is designated as a fallback.
	Multiple fallback backends can be configured.
	It is highly recommended to configure active or passive health checks to ensure that failover can be detected
	when the active backends become unhealthy and to automatically readjust once the primary backends are healthy again.
	The overprovisioning factor is set to 1.4, meaning the fallback backends will only start receiving traffic when
	the health of the active backends falls below 72%.
	"""
																							type: "boolean"
																						}
																						group: {
																							default: ""
																							description: """
	Group is the group of the referent. For example, "gateway.networking.k8s.io".
	When unspecified or empty string, core API group is inferred.
	"""
																							maxLength: 253
																							pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																							type:      "string"
																						}
																						kind: {
																							default: "Service"
																							description: """
	Kind is the Kubernetes resource kind of the referent. For example
	"Service".

	Defaults to "Service" when not specified.

	ExternalName services can refer to CNAME DNS records that may live
	outside of the cluster and as such are difficult to reason about in
	terms of conformance. They also may not be safe to forward to (see
	CVE-2021-25740 for more information). Implementations SHOULD NOT
	support ExternalName Services.

	Support: Core (Services with a type other than ExternalName)

	Support: Implementation-specific (Services with type ExternalName)
	"""
																							maxLength: 63
																							minLength: 1
																							pattern:   "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
																							type:      "string"
																						}
																						name: {
																							description: "Name is the name of the referent."
																							maxLength:   253
																							minLength:   1
																							type:        "string"
																						}
																						namespace: {
																							description: """
	Namespace is the namespace of the backend. When unspecified, the local
	namespace is inferred.

	Note that when a namespace different than the local namespace is specified,
	a ReferenceGrant object is required in the referent namespace to allow that
	namespace's owner to accept the reference. See the ReferenceGrant
	documentation for details.

	Support: Core
	"""
																							maxLength: 63
																							minLength: 1
																							pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
																							type:      "string"
																						}
																						port: {
																							description: """
	Port specifies the destination port number to use for this resource.
	Port is required when the referent is a Kubernetes Service. In this
	case, the port number is the service port number, not the target port.
	For other resources, destination port might be derived from the referent
	resource or this field.
	"""
																							format:  "int32"
																							maximum: 65535
																							minimum: 1
																							type:    "integer"
																						}
																					}
																					required: ["name"]
																					type: "object"
																					"x-kubernetes-validations": [{
																						message: "Must have port for Service reference"
																						rule:    "(size(self.group) == 0 && self.kind == 'Service') ? has(self.port) : true"
																					}]
																				}
																				maxItems: 16
																				type:     "array"
																			}
																			backendSettings: {
																				description: """
	BackendSettings holds configuration for managing the connection
	to the backend.
	"""
																				properties: {
																					circuitBreaker: {
																						description: """
	Circuit Breaker settings for the upstream connections and requests.
	If not set, circuit breakers will be enabled with the default thresholds
	"""
																						properties: {
																							maxConnections: {
																								default:     1024
																								description: "The maximum number of connections that Envoy will establish to the referenced backend defined within a xRoute rule."
																								format:      "int64"
																								maximum:     4294967295
																								minimum:     0
																								type:        "integer"
																							}
																							maxParallelRequests: {
																								default:     1024
																								description: "The maximum number of parallel requests that Envoy will make to the referenced backend defined within a xRoute rule."
																								format:      "int64"
																								maximum:     4294967295
																								minimum:     0
																								type:        "integer"
																							}
																							maxParallelRetries: {
																								default:     1024
																								description: "The maximum number of parallel retries that Envoy will make to the referenced backend defined within a xRoute rule."
																								format:      "int64"
																								maximum:     4294967295
																								minimum:     0
																								type:        "integer"
																							}
																							maxPendingRequests: {
																								default:     1024
																								description: "The maximum number of pending requests that Envoy will queue to the referenced backend defined within a xRoute rule."
																								format:      "int64"
																								maximum:     4294967295
																								minimum:     0
																								type:        "integer"
																							}
																							maxRequestsPerConnection: {
																								description: """
	The maximum number of requests that Envoy will make over a single connection to the referenced backend defined within a xRoute rule.
	Default: unlimited.
	"""
																								format:  "int64"
																								maximum: 4294967295
																								minimum: 0
																								type:    "integer"
																							}
																						}
																						type: "object"
																					}
																					connection: {
																						description: "Connection includes backend connection settings."
																						properties: {
																							bufferLimit: {
																								allOf: [{
																									pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																								}, {
																									pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																								}]
																								anyOf: [{
																									type: "integer"
																								}, {
																									type: "string"
																								}]
																								description: """
	BufferLimit Soft limit on size of the cluster’s connections read and write buffers.
	BufferLimit applies to connection streaming (maybe non-streaming) channel between processes, it's in user space.
	If unspecified, an implementation defined default is applied (32768 bytes).
	For example, 20Mi, 1Gi, 256Ki etc.
	Note: that when the suffix is not provided, the value is interpreted as bytes.
	"""
																								"x-kubernetes-int-or-string": true
																							}
																							socketBufferLimit: {
																								allOf: [{
																									pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																								}, {
																									pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																								}]
																								anyOf: [{
																									type: "integer"
																								}, {
																									type: "string"
																								}]
																								description: """
	SocketBufferLimit provides configuration for the maximum buffer size in bytes for each socket
	to backend.
	SocketBufferLimit applies to socket streaming channel between TCP/IP stacks, it's in kernel space.
	For example, 20Mi, 1Gi, 256Ki etc.
	Note that when the suffix is not provided, the value is interpreted as bytes.
	"""
																								"x-kubernetes-int-or-string": true
																							}
																						}
																						type: "object"
																					}
																					dns: {
																						description: "DNS includes dns resolution settings."
																						properties: {
																							dnsRefreshRate: {
																								description: """
	DNSRefreshRate specifies the rate at which DNS records should be refreshed.
	Defaults to 30 seconds.
	"""
																								type: "string"
																							}
																							respectDnsTtl: {
																								description: """
	RespectDNSTTL indicates whether the DNS Time-To-Live (TTL) should be respected.
	If the value is set to true, the DNS refresh rate will be set to the resource record’s TTL.
	Defaults to true.
	"""
																								type: "boolean"
																							}
																						}
																						type: "object"
																					}
																					healthCheck: {
																						description: "HealthCheck allows gateway to perform active health checking on backends."
																						properties: {
																							active: {
																								description: "Active health check configuration"
																								properties: {
																									grpc: {
																										description: """
	GRPC defines the configuration of the GRPC health checker.
	It's optional, and can only be used if the specified type is GRPC.
	"""
																										properties: service: {
																											description: """
	Service to send in the health check request.
	If this is not specified, then the health check request applies to the entire
	server and not to a specific service.
	"""
																											type: "string"
																										}
																										type: "object"
																									}
																									healthyThreshold: {
																										default:     1
																										description: "HealthyThreshold defines the number of healthy health checks required before a backend host is marked healthy."
																										format:      "int32"
																										minimum:     1
																										type:        "integer"
																									}
																									http: {
																										description: """
	HTTP defines the configuration of http health checker.
	It's required while the health checker type is HTTP.
	"""
																										properties: {
																											expectedResponse: {
																												description: "ExpectedResponse defines a list of HTTP expected responses to match."
																												properties: {
																													binary: {
																														description: "Binary payload base64 encoded."
																														format:      "byte"
																														type:        "string"
																													}
																													text: {
																														description: "Text payload in plain text."
																														type:        "string"
																													}
																													type: {
																														allOf: [{
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}, {
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}]
																														description: "Type defines the type of the payload."
																														type:        "string"
																													}
																												}
																												required: ["type"]
																												type: "object"
																												"x-kubernetes-validations": [{
																													message: "If payload type is Text, text field needs to be set."
																													rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																												}, {
																													message: "If payload type is Binary, binary field needs to be set."
																													rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																												}]
																											}
																											expectedStatuses: {
																												description: """
	ExpectedStatuses defines a list of HTTP response statuses considered healthy.
	Defaults to 200 only
	"""
																												items: {
																													description:      "HTTPStatus defines the http status code."
																													exclusiveMaximum: true
																													maximum:          600
																													minimum:          100
																													type:             "integer"
																												}
																												type: "array"
																											}
																											method: {
																												description: """
	Method defines the HTTP method used for health checking.
	Defaults to GET
	"""
																												type: "string"
																											}
																											path: {
																												description: "Path defines the HTTP path that will be requested during health checking."
																												maxLength:   1024
																												minLength:   1
																												type:        "string"
																											}
																										}
																										required: ["path"]
																										type: "object"
																									}
																									interval: {
																										default:     "3s"
																										description: "Interval defines the time between active health checks."
																										format:      "duration"
																										type:        "string"
																									}
																									tcp: {
																										description: """
	TCP defines the configuration of tcp health checker.
	It's required while the health checker type is TCP.
	"""
																										properties: {
																											receive: {
																												description: "Receive defines the expected response payload."
																												properties: {
																													binary: {
																														description: "Binary payload base64 encoded."
																														format:      "byte"
																														type:        "string"
																													}
																													text: {
																														description: "Text payload in plain text."
																														type:        "string"
																													}
																													type: {
																														allOf: [{
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}, {
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}]
																														description: "Type defines the type of the payload."
																														type:        "string"
																													}
																												}
																												required: ["type"]
																												type: "object"
																												"x-kubernetes-validations": [{
																													message: "If payload type is Text, text field needs to be set."
																													rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																												}, {
																													message: "If payload type is Binary, binary field needs to be set."
																													rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																												}]
																											}
																											send: {
																												description: "Send defines the request payload."
																												properties: {
																													binary: {
																														description: "Binary payload base64 encoded."
																														format:      "byte"
																														type:        "string"
																													}
																													text: {
																														description: "Text payload in plain text."
																														type:        "string"
																													}
																													type: {
																														allOf: [{
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}, {
																															enum: [
																																"Text",
																																"Binary",
																															]
																														}]
																														description: "Type defines the type of the payload."
																														type:        "string"
																													}
																												}
																												required: ["type"]
																												type: "object"
																												"x-kubernetes-validations": [{
																													message: "If payload type is Text, text field needs to be set."
																													rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																												}, {
																													message: "If payload type is Binary, binary field needs to be set."
																													rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																												}]
																											}
																										}
																										type: "object"
																									}
																									timeout: {
																										default:     "1s"
																										description: "Timeout defines the time to wait for a health check response."
																										format:      "duration"
																										type:        "string"
																									}
																									type: {
																										allOf: [{
																											enum: [
																												"HTTP",
																												"TCP",
																												"GRPC",
																											]
																										}, {
																											enum: [
																												"HTTP",
																												"TCP",
																												"GRPC",
																											]
																										}]
																										description: "Type defines the type of health checker."
																										type:        "string"
																									}
																									unhealthyThreshold: {
																										default:     3
																										description: "UnhealthyThreshold defines the number of unhealthy health checks required before a backend host is marked unhealthy."
																										format:      "int32"
																										minimum:     1
																										type:        "integer"
																									}
																								}
																								required: ["type"]
																								type: "object"
																								"x-kubernetes-validations": [{
																									message: "If Health Checker type is HTTP, http field needs to be set."
																									rule:    "self.type == 'HTTP' ? has(self.http) : !has(self.http)"
																								}, {
																									message: "If Health Checker type is TCP, tcp field needs to be set."
																									rule:    "self.type == 'TCP' ? has(self.tcp) : !has(self.tcp)"
																								}, {
																									message: "The grpc field can only be set if the Health Checker type is GRPC."
																									rule:    "has(self.grpc) ? self.type == 'GRPC' : true"
																								}]
																							}
																							passive: {
																								description: "Passive passive check configuration"
																								properties: {
																									baseEjectionTime: {
																										default:     "30s"
																										description: "BaseEjectionTime defines the base duration for which a host will be ejected on consecutive failures."
																										format:      "duration"
																										type:        "string"
																									}
																									consecutive5XxErrors: {
																										default:     5
																										description: "Consecutive5xxErrors sets the number of consecutive 5xx errors triggering ejection."
																										format:      "int32"
																										type:        "integer"
																									}
																									consecutiveGatewayErrors: {
																										default:     0
																										description: "ConsecutiveGatewayErrors sets the number of consecutive gateway errors triggering ejection."
																										format:      "int32"
																										type:        "integer"
																									}
																									consecutiveLocalOriginFailures: {
																										default: 5
																										description: """
	ConsecutiveLocalOriginFailures sets the number of consecutive local origin failures triggering ejection.
	Parameter takes effect only when split_external_local_origin_errors is set to true.
	"""
																										format: "int32"
																										type:   "integer"
																									}
																									interval: {
																										default:     "3s"
																										description: "Interval defines the time between passive health checks."
																										format:      "duration"
																										type:        "string"
																									}
																									maxEjectionPercent: {
																										default:     10
																										description: "MaxEjectionPercent sets the maximum percentage of hosts in a cluster that can be ejected."
																										format:      "int32"
																										type:        "integer"
																									}
																									splitExternalLocalOriginErrors: {
																										default:     false
																										description: "SplitExternalLocalOriginErrors enables splitting of errors between external and local origin."
																										type:        "boolean"
																									}
																								}
																								type: "object"
																							}
																						}
																						type: "object"
																					}
																					http2: {
																						description: "HTTP2 provides HTTP/2 configuration for backend connections."
																						properties: {
																							initialConnectionWindowSize: {
																								allOf: [{
																									pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																								}, {
																									pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																								}]
																								anyOf: [{
																									type: "integer"
																								}, {
																									type: "string"
																								}]
																								description: """
	InitialConnectionWindowSize sets the initial window size for HTTP/2 connections.
	If not set, the default value is 1 MiB.
	"""
																								"x-kubernetes-int-or-string": true
																							}
																							initialStreamWindowSize: {
																								allOf: [{
																									pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																								}, {
																									pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																								}]
																								anyOf: [{
																									type: "integer"
																								}, {
																									type: "string"
																								}]
																								description: """
	InitialStreamWindowSize sets the initial window size for HTTP/2 streams.
	If not set, the default value is 64 KiB(64*1024).
	"""
																								"x-kubernetes-int-or-string": true
																							}
																							maxConcurrentStreams: {
																								description: """
	MaxConcurrentStreams sets the maximum number of concurrent streams allowed per connection.
	If not set, the default value is 100.
	"""
																								format:  "int32"
																								maximum: 2147483647
																								minimum: 1
																								type:    "integer"
																							}
																							onInvalidMessage: {
																								description: """
	OnInvalidMessage determines if Envoy will terminate the connection or just the offending stream in the event of HTTP messaging error
	It's recommended for L2 Envoy deployments to set this value to TerminateStream.
	https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/level_two
	Default: TerminateConnection
	"""
																								type: "string"
																							}
																						}
																						type: "object"
																					}
																					loadBalancer: {
																						description: """
	LoadBalancer policy to apply when routing traffic from the gateway to
	the backend endpoints. Defaults to `LeastRequest`.
	"""
																						properties: {
																							consistentHash: {
																								description: """
	ConsistentHash defines the configuration when the load balancer type is
	set to ConsistentHash
	"""
																								properties: {
																									cookie: {
																										description: "Cookie configures the cookie hash policy when the consistent hash type is set to Cookie."
																										properties: {
																											attributes: {
																												additionalProperties: type: "string"
																												description: "Additional Attributes to set for the generated cookie."
																												type:        "object"
																											}
																											name: {
																												description: """
	Name of the cookie to hash.
	If this cookie does not exist in the request, Envoy will generate a cookie and set
	the TTL on the response back to the client based on Layer 4
	attributes of the backend endpoint, to ensure that these future requests
	go to the same backend endpoint. Make sure to set the TTL field for this case.
	"""
																												type: "string"
																											}
																											ttl: {
																												description: """
	TTL of the generated cookie if the cookie is not present. This value sets the
	Max-Age attribute value.
	"""
																												type: "string"
																											}
																										}
																										required: ["name"]
																										type: "object"
																									}
																									header: {
																										description: "Header configures the header hash policy when the consistent hash type is set to Header."
																										properties: name: {
																											description: "Name of the header to hash."
																											type:        "string"
																										}
																										required: ["name"]
																										type: "object"
																									}
																									tableSize: {
																										default:     65537
																										description: "The table size for consistent hashing, must be prime number limited to 5000011."
																										format:      "int64"
																										maximum:     5000011
																										minimum:     2
																										type:        "integer"
																									}
																									type: {
																										description: """
	ConsistentHashType defines the type of input to hash on. Valid Type values are
	"SourceIP",
	"Header",
	"Cookie".
	"""
																										enum: [
																											"SourceIP",
																											"Header",
																											"Cookie",
																										]
																										type: "string"
																									}
																								}
																								required: ["type"]
																								type: "object"
																								"x-kubernetes-validations": [{
																									message: "If consistent hash type is header, the header field must be set."
																									rule:    "self.type == 'Header' ? has(self.header) : !has(self.header)"
																								}, {
																									message: "If consistent hash type is cookie, the cookie field must be set."
																									rule:    "self.type == 'Cookie' ? has(self.cookie) : !has(self.cookie)"
																								}]
																							}
																							slowStart: {
																								description: """
	SlowStart defines the configuration related to the slow start load balancer policy.
	If set, during slow start window, traffic sent to the newly added hosts will gradually increase.
	Currently this is only supported for RoundRobin and LeastRequest load balancers
	"""
																								properties: window: {
																									description: """
	Window defines the duration of the warm up period for newly added host.
	During slow start window, traffic sent to the newly added hosts will gradually increase.
	Currently only supports linear growth of traffic. For additional details,
	see https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto#config-cluster-v3-cluster-slowstartconfig
	"""
																									type: "string"
																								}
																								required: ["window"]
																								type: "object"
																							}
																							type: {
																								description: """
	Type decides the type of Load Balancer policy.
	Valid LoadBalancerType values are
	"ConsistentHash",
	"LeastRequest",
	"Random",
	"RoundRobin".
	"""
																								enum: [
																									"ConsistentHash",
																									"LeastRequest",
																									"Random",
																									"RoundRobin",
																								]
																								type: "string"
																							}
																						}
																						required: ["type"]
																						type: "object"
																						"x-kubernetes-validations": [{
																							message: "If LoadBalancer type is consistentHash, consistentHash field needs to be set."
																							rule:    "self.type == 'ConsistentHash' ? has(self.consistentHash) : !has(self.consistentHash)"
																						}, {
																							message: "Currently SlowStart is only supported for RoundRobin and LeastRequest load balancers."
																							rule:    "self.type in ['Random', 'ConsistentHash'] ? !has(self.slowStart) : true "
																						}]
																					}
																					proxyProtocol: {
																						description: "ProxyProtocol enables the Proxy Protocol when communicating with the backend."
																						properties: version: {
																							description: """
	Version of ProxyProtol
	Valid ProxyProtocolVersion values are
	"V1"
	"V2"
	"""
																							enum: [
																								"V1",
																								"V2",
																							]
																							type: "string"
																						}
																						required: ["version"]
																						type: "object"
																					}
																					retry: {
																						description: """
	Retry provides more advanced usage, allowing users to customize the number of retries, retry fallback strategy, and retry triggering conditions.
	If not set, retry will be disabled.
	"""
																						properties: {
																							numRetries: {
																								default:     2
																								description: "NumRetries is the number of retries to be attempted. Defaults to 2."
																								format:      "int32"
																								minimum:     0
																								type:        "integer"
																							}
																							perRetry: {
																								description: "PerRetry is the retry policy to be applied per retry attempt."
																								properties: {
																									backOff: {
																										description: """
	Backoff is the backoff policy to be applied per retry attempt. gateway uses a fully jittered exponential
	back-off algorithm for retries. For additional details,
	see https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#config-http-filters-router-x-envoy-max-retries
	"""
																										properties: {
																											baseInterval: {
																												description: "BaseInterval is the base interval between retries."
																												format:      "duration"
																												type:        "string"
																											}
																											maxInterval: {
																												description: """
	MaxInterval is the maximum interval between retries. This parameter is optional, but must be greater than or equal to the base_interval if set.
	The default is 10 times the base_interval
	"""
																												format: "duration"
																												type:   "string"
																											}
																										}
																										type: "object"
																									}
																									timeout: {
																										description: "Timeout is the timeout per retry attempt."
																										format:      "duration"
																										type:        "string"
																									}
																								}
																								type: "object"
																							}
																							retryOn: {
																								description: """
	RetryOn specifies the retry trigger condition.

	If not specified, the default is to retry on connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes(503).
	"""
																								properties: {
																									httpStatusCodes: {
																										description: """
	HttpStatusCodes specifies the http status codes to be retried.
	The retriable-status-codes trigger must also be configured for these status codes to trigger a retry.
	"""
																										items: {
																											description:      "HTTPStatus defines the http status code."
																											exclusiveMaximum: true
																											maximum:          600
																											minimum:          100
																											type:             "integer"
																										}
																										type: "array"
																									}
																									triggers: {
																										description: "Triggers specifies the retry trigger condition(Http/Grpc)."
																										items: {
																											description: "TriggerEnum specifies the conditions that trigger retries."
																											enum: [
																												"5xx",
																												"gateway-error",
																												"reset",
																												"connect-failure",
																												"retriable-4xx",
																												"refused-stream",
																												"retriable-status-codes",
																												"cancelled",
																												"deadline-exceeded",
																												"internal",
																												"resource-exhausted",
																												"unavailable",
																											]
																											type: "string"
																										}
																										type: "array"
																									}
																								}
																								type: "object"
																							}
																						}
																						type: "object"
																					}
																					tcpKeepalive: {
																						description: """
	TcpKeepalive settings associated with the upstream client connection.
	Disabled by default.
	"""
																						properties: {
																							idleTime: {
																								description: """
	The duration a connection needs to be idle before keep-alive
	probes start being sent.
	The duration format is
	Defaults to `7200s`.
	"""
																								pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																								type:    "string"
																							}
																							interval: {
																								description: """
	The duration between keep-alive probes.
	Defaults to `75s`.
	"""
																								pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																								type:    "string"
																							}
																							probes: {
																								description: """
	The total number of unacknowledged probes to send before deciding
	the connection is dead.
	Defaults to 9.
	"""
																								format: "int32"
																								type:   "integer"
																							}
																						}
																						type: "object"
																					}
																					timeout: {
																						description: "Timeout settings for the backend connections."
																						properties: {
																							http: {
																								description: "Timeout settings for HTTP."
																								properties: {
																									connectionIdleTimeout: {
																										description: """
	The idle timeout for an HTTP connection. Idle time is defined as a period in which there are no active requests in the connection.
	Default: 1 hour.
	"""
																										pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																										type:    "string"
																									}
																									maxConnectionDuration: {
																										description: """
	The maximum duration of an HTTP connection.
	Default: unlimited.
	"""
																										pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																										type:    "string"
																									}
																									requestTimeout: {
																										description: "RequestTimeout is the time until which entire response is received from the upstream."
																										pattern:     "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																										type:        "string"
																									}
																								}
																								type: "object"
																							}
																							tcp: {
																								description: "Timeout settings for TCP."
																								properties: connectTimeout: {
																									description: """
	The timeout for network connection establishment, including TCP and TLS handshakes.
	Default: 10 seconds.
	"""
																									pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																									type:    "string"
																								}
																								type: "object"
																							}
																						}
																						type: "object"
																					}
																				}
																				type: "object"
																			}
																			host: {
																				description: """
	Host define the extension service hostname.
	Deprecated: Use BackendRefs instead.
	"""
																				type: "string"
																			}
																			port: {
																				default: 4317
																				description: """
	Port defines the port the extension service is exposed on.
	Deprecated: Use BackendRefs instead.
	"""
																				format:  "int32"
																				minimum: 0
																				type:    "integer"
																			}
																			resources: {
																				additionalProperties: type: "string"
																				description: """
	Resources is a set of labels that describe the source of a log entry, including envoy node info.
	It's recommended to follow [semantic conventions](https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/).
	"""
																				type: "object"
																			}
																		}
																		type: "object"
																		"x-kubernetes-validations": [{
																			message: "host or backendRefs needs to be set"
																			rule:    "has(self.host) || self.backendRefs.size() > 0"
																		}, {
																			message: "BackendRefs must be used, backendRef is not supported."
																			rule:    "!has(self.backendRef)"
																		}, {
																			message: "BackendRefs only supports Service kind."
																			rule:    "has(self.backendRefs) ? self.backendRefs.all(f, f.kind == 'Service') : true"
																		}, {
																			message: "BackendRefs only supports Core group."
																			rule:    "has(self.backendRefs) ? (self.backendRefs.all(f, f.group == \"\")) : true"
																		}]
																	}
																	type: {
																		description: "Type defines the type of accesslog sink."
																		enum: [
																			"ALS",
																			"File",
																			"OpenTelemetry",
																		]
																		type: "string"
																	}
																}
																type: "object"
																"x-kubernetes-validations": [{
																	message: "If AccessLogSink type is ALS, als field needs to be set."
																	rule:    "self.type == 'ALS' ? has(self.als) : !has(self.als)"
																}, {
																	message: "If AccessLogSink type is File, file field needs to be set."
																	rule:    "self.type == 'File' ? has(self.file) : !has(self.file)"
																}, {
																	message: "If AccessLogSink type is OpenTelemetry, openTelemetry field needs to be set."
																	rule:    "self.type == 'OpenTelemetry' ? has(self.openTelemetry) : !has(self.openTelemetry)"
																}]
															}
															maxItems: 50
															minItems: 1
															type:     "array"
														}
														type: {
															description: """
	Type defines the component emitting the accesslog, such as Listener and Route.
	If type not defined, the setting would apply to:
	(1) All Routes.
	(2) Listeners if and only if Envoy does not find a matching route for a request.
	If type is defined, the accesslog settings would apply to the relevant component (as-is).
	"""
															enum: [
																"Listener",
																"Route",
															]
															type: "string"
														}
													}
													required: ["sinks"]
													type: "object"
												}
												maxItems: 50
												minItems: 1
												type:     "array"
											}
										}
										type: "object"
									}
									metrics: {
										description: "Metrics defines metrics configuration for managed proxies."
										properties: {
											enablePerEndpointStats: {
												description: """
	EnablePerEndpointStats enables per endpoint envoy stats metrics.
	Please use with caution.
	"""
												type: "boolean"
											}
											enableRequestResponseSizesStats: {
												description: "EnableRequestResponseSizesStats enables publishing of histograms tracking header and body sizes of requests and responses."
												type:        "boolean"
											}
											enableVirtualHostStats: {
												description: "EnableVirtualHostStats enables envoy stat metrics for virtual hosts."
												type:        "boolean"
											}
											matches: {
												description: """
	Matches defines configuration for selecting specific metrics instead of generating all metrics stats
	that are enabled by default. This helps reduce CPU and memory overhead in Envoy, but eliminating some stats
	may after critical functionality. Here are the stats that we strongly recommend not disabling:
	`cluster_manager.warming_clusters`, `cluster.<cluster_name>.membership_total`,`cluster.<cluster_name>.membership_healthy`,
	`cluster.<cluster_name>.membership_degraded`，reference  https://github.com/envoyproxy/envoy/issues/9856,
	https://github.com/envoyproxy/envoy/issues/14610
	"""
												items: {
													description: """
	StringMatch defines how to match any strings.
	This is a general purpose match condition that can be used by other EG APIs
	that need to match against a string.
	"""
													properties: {
														type: {
															default:     "Exact"
															description: "Type specifies how to match against a string."
															enum: [
																"Exact",
																"Prefix",
																"Suffix",
																"RegularExpression",
															]
															type: "string"
														}
														value: {
															description: "Value specifies the string value that the match must have."
															maxLength:   1024
															minLength:   1
															type:        "string"
														}
													}
													required: ["value"]
													type: "object"
												}
												type: "array"
											}
											prometheus: {
												description: "Prometheus defines the configuration for Admin endpoint `/stats/prometheus`."
												properties: {
													compression: {
														description: "Configure the compression on Prometheus endpoint. Compression is useful in situations when bandwidth is scarce and large payloads can be effectively compressed at the expense of higher CPU load."
														properties: {
															gzip: {
																description: "The configuration for GZIP compressor."
																type:        "object"
															}
															type: {
																description: "CompressorType defines the compressor type to use for compression."
																enum: ["Gzip"]
																type: "string"
															}
														}
														required: ["type"]
														type: "object"
													}
													disable: {
														description: "Disable the Prometheus endpoint."
														type:        "boolean"
													}
												}
												type: "object"
											}
											sinks: {
												description: "Sinks defines the metric sinks where metrics are sent to."
												items: {
													description: """
	ProxyMetricSink defines the sink of metrics.
	Default metrics sink is OpenTelemetry.
	"""
													properties: {
														openTelemetry: {
															description: """
	OpenTelemetry defines the configuration for OpenTelemetry sink.
	It's required if the sink type is OpenTelemetry.
	"""
															properties: {
																backendRef: {
																	description: """
	BackendRef references a Kubernetes object that represents the
	backend server to which the authorization request will be sent.

	Deprecated: Use BackendRefs instead.
	"""
																	properties: {
																		group: {
																			default: ""
																			description: """
	Group is the group of the referent. For example, "gateway.networking.k8s.io".
	When unspecified or empty string, core API group is inferred.
	"""
																			maxLength: 253
																			pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																			type:      "string"
																		}
																		kind: {
																			default: "Service"
																			description: """
	Kind is the Kubernetes resource kind of the referent. For example
	"Service".

	Defaults to "Service" when not specified.

	ExternalName services can refer to CNAME DNS records that may live
	outside of the cluster and as such are difficult to reason about in
	terms of conformance. They also may not be safe to forward to (see
	CVE-2021-25740 for more information). Implementations SHOULD NOT
	support ExternalName Services.

	Support: Core (Services with a type other than ExternalName)

	Support: Implementation-specific (Services with type ExternalName)
	"""
																			maxLength: 63
																			minLength: 1
																			pattern:   "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
																			type:      "string"
																		}
																		name: {
																			description: "Name is the name of the referent."
																			maxLength:   253
																			minLength:   1
																			type:        "string"
																		}
																		namespace: {
																			description: """
	Namespace is the namespace of the backend. When unspecified, the local
	namespace is inferred.

	Note that when a namespace different than the local namespace is specified,
	a ReferenceGrant object is required in the referent namespace to allow that
	namespace's owner to accept the reference. See the ReferenceGrant
	documentation for details.

	Support: Core
	"""
																			maxLength: 63
																			minLength: 1
																			pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
																			type:      "string"
																		}
																		port: {
																			description: """
	Port specifies the destination port number to use for this resource.
	Port is required when the referent is a Kubernetes Service. In this
	case, the port number is the service port number, not the target port.
	For other resources, destination port might be derived from the referent
	resource or this field.
	"""
																			format:  "int32"
																			maximum: 65535
																			minimum: 1
																			type:    "integer"
																		}
																	}
																	required: ["name"]
																	type: "object"
																	"x-kubernetes-validations": [{
																		message: "Must have port for Service reference"
																		rule:    "(size(self.group) == 0 && self.kind == 'Service') ? has(self.port) : true"
																	}]
																}
																backendRefs: {
																	description: """
	BackendRefs references a Kubernetes object that represents the
	backend server to which the authorization request will be sent.
	"""
																	items: {
																		description: "BackendRef defines how an ObjectReference that is specific to BackendRef."
																		properties: {
																			fallback: {
																				description: """
	Fallback indicates whether the backend is designated as a fallback.
	Multiple fallback backends can be configured.
	It is highly recommended to configure active or passive health checks to ensure that failover can be detected
	when the active backends become unhealthy and to automatically readjust once the primary backends are healthy again.
	The overprovisioning factor is set to 1.4, meaning the fallback backends will only start receiving traffic when
	the health of the active backends falls below 72%.
	"""
																				type: "boolean"
																			}
																			group: {
																				default: ""
																				description: """
	Group is the group of the referent. For example, "gateway.networking.k8s.io".
	When unspecified or empty string, core API group is inferred.
	"""
																				maxLength: 253
																				pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																				type:      "string"
																			}
																			kind: {
																				default: "Service"
																				description: """
	Kind is the Kubernetes resource kind of the referent. For example
	"Service".

	Defaults to "Service" when not specified.

	ExternalName services can refer to CNAME DNS records that may live
	outside of the cluster and as such are difficult to reason about in
	terms of conformance. They also may not be safe to forward to (see
	CVE-2021-25740 for more information). Implementations SHOULD NOT
	support ExternalName Services.

	Support: Core (Services with a type other than ExternalName)

	Support: Implementation-specific (Services with type ExternalName)
	"""
																				maxLength: 63
																				minLength: 1
																				pattern:   "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
																				type:      "string"
																			}
																			name: {
																				description: "Name is the name of the referent."
																				maxLength:   253
																				minLength:   1
																				type:        "string"
																			}
																			namespace: {
																				description: """
	Namespace is the namespace of the backend. When unspecified, the local
	namespace is inferred.

	Note that when a namespace different than the local namespace is specified,
	a ReferenceGrant object is required in the referent namespace to allow that
	namespace's owner to accept the reference. See the ReferenceGrant
	documentation for details.

	Support: Core
	"""
																				maxLength: 63
																				minLength: 1
																				pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
																				type:      "string"
																			}
																			port: {
																				description: """
	Port specifies the destination port number to use for this resource.
	Port is required when the referent is a Kubernetes Service. In this
	case, the port number is the service port number, not the target port.
	For other resources, destination port might be derived from the referent
	resource or this field.
	"""
																				format:  "int32"
																				maximum: 65535
																				minimum: 1
																				type:    "integer"
																			}
																		}
																		required: ["name"]
																		type: "object"
																		"x-kubernetes-validations": [{
																			message: "Must have port for Service reference"
																			rule:    "(size(self.group) == 0 && self.kind == 'Service') ? has(self.port) : true"
																		}]
																	}
																	maxItems: 16
																	type:     "array"
																}
																backendSettings: {
																	description: """
	BackendSettings holds configuration for managing the connection
	to the backend.
	"""
																	properties: {
																		circuitBreaker: {
																			description: """
	Circuit Breaker settings for the upstream connections and requests.
	If not set, circuit breakers will be enabled with the default thresholds
	"""
																			properties: {
																				maxConnections: {
																					default:     1024
																					description: "The maximum number of connections that Envoy will establish to the referenced backend defined within a xRoute rule."
																					format:      "int64"
																					maximum:     4294967295
																					minimum:     0
																					type:        "integer"
																				}
																				maxParallelRequests: {
																					default:     1024
																					description: "The maximum number of parallel requests that Envoy will make to the referenced backend defined within a xRoute rule."
																					format:      "int64"
																					maximum:     4294967295
																					minimum:     0
																					type:        "integer"
																				}
																				maxParallelRetries: {
																					default:     1024
																					description: "The maximum number of parallel retries that Envoy will make to the referenced backend defined within a xRoute rule."
																					format:      "int64"
																					maximum:     4294967295
																					minimum:     0
																					type:        "integer"
																				}
																				maxPendingRequests: {
																					default:     1024
																					description: "The maximum number of pending requests that Envoy will queue to the referenced backend defined within a xRoute rule."
																					format:      "int64"
																					maximum:     4294967295
																					minimum:     0
																					type:        "integer"
																				}
																				maxRequestsPerConnection: {
																					description: """
	The maximum number of requests that Envoy will make over a single connection to the referenced backend defined within a xRoute rule.
	Default: unlimited.
	"""
																					format:  "int64"
																					maximum: 4294967295
																					minimum: 0
																					type:    "integer"
																				}
																			}
																			type: "object"
																		}
																		connection: {
																			description: "Connection includes backend connection settings."
																			properties: {
																				bufferLimit: {
																					allOf: [{
																						pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					}, {
																						pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																					}]
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	BufferLimit Soft limit on size of the cluster’s connections read and write buffers.
	BufferLimit applies to connection streaming (maybe non-streaming) channel between processes, it's in user space.
	If unspecified, an implementation defined default is applied (32768 bytes).
	For example, 20Mi, 1Gi, 256Ki etc.
	Note: that when the suffix is not provided, the value is interpreted as bytes.
	"""
																					"x-kubernetes-int-or-string": true
																				}
																				socketBufferLimit: {
																					allOf: [{
																						pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					}, {
																						pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																					}]
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	SocketBufferLimit provides configuration for the maximum buffer size in bytes for each socket
	to backend.
	SocketBufferLimit applies to socket streaming channel between TCP/IP stacks, it's in kernel space.
	For example, 20Mi, 1Gi, 256Ki etc.
	Note that when the suffix is not provided, the value is interpreted as bytes.
	"""
																					"x-kubernetes-int-or-string": true
																				}
																			}
																			type: "object"
																		}
																		dns: {
																			description: "DNS includes dns resolution settings."
																			properties: {
																				dnsRefreshRate: {
																					description: """
	DNSRefreshRate specifies the rate at which DNS records should be refreshed.
	Defaults to 30 seconds.
	"""
																					type: "string"
																				}
																				respectDnsTtl: {
																					description: """
	RespectDNSTTL indicates whether the DNS Time-To-Live (TTL) should be respected.
	If the value is set to true, the DNS refresh rate will be set to the resource record’s TTL.
	Defaults to true.
	"""
																					type: "boolean"
																				}
																			}
																			type: "object"
																		}
																		healthCheck: {
																			description: "HealthCheck allows gateway to perform active health checking on backends."
																			properties: {
																				active: {
																					description: "Active health check configuration"
																					properties: {
																						grpc: {
																							description: """
	GRPC defines the configuration of the GRPC health checker.
	It's optional, and can only be used if the specified type is GRPC.
	"""
																							properties: service: {
																								description: """
	Service to send in the health check request.
	If this is not specified, then the health check request applies to the entire
	server and not to a specific service.
	"""
																								type: "string"
																							}
																							type: "object"
																						}
																						healthyThreshold: {
																							default:     1
																							description: "HealthyThreshold defines the number of healthy health checks required before a backend host is marked healthy."
																							format:      "int32"
																							minimum:     1
																							type:        "integer"
																						}
																						http: {
																							description: """
	HTTP defines the configuration of http health checker.
	It's required while the health checker type is HTTP.
	"""
																							properties: {
																								expectedResponse: {
																									description: "ExpectedResponse defines a list of HTTP expected responses to match."
																									properties: {
																										binary: {
																											description: "Binary payload base64 encoded."
																											format:      "byte"
																											type:        "string"
																										}
																										text: {
																											description: "Text payload in plain text."
																											type:        "string"
																										}
																										type: {
																											allOf: [{
																												enum: [
																													"Text",
																													"Binary",
																												]
																											}, {
																												enum: [
																													"Text",
																													"Binary",
																												]
																											}]
																											description: "Type defines the type of the payload."
																											type:        "string"
																										}
																									}
																									required: ["type"]
																									type: "object"
																									"x-kubernetes-validations": [{
																										message: "If payload type is Text, text field needs to be set."
																										rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																									}, {
																										message: "If payload type is Binary, binary field needs to be set."
																										rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																									}]
																								}
																								expectedStatuses: {
																									description: """
	ExpectedStatuses defines a list of HTTP response statuses considered healthy.
	Defaults to 200 only
	"""
																									items: {
																										description:      "HTTPStatus defines the http status code."
																										exclusiveMaximum: true
																										maximum:          600
																										minimum:          100
																										type:             "integer"
																									}
																									type: "array"
																								}
																								method: {
																									description: """
	Method defines the HTTP method used for health checking.
	Defaults to GET
	"""
																									type: "string"
																								}
																								path: {
																									description: "Path defines the HTTP path that will be requested during health checking."
																									maxLength:   1024
																									minLength:   1
																									type:        "string"
																								}
																							}
																							required: ["path"]
																							type: "object"
																						}
																						interval: {
																							default:     "3s"
																							description: "Interval defines the time between active health checks."
																							format:      "duration"
																							type:        "string"
																						}
																						tcp: {
																							description: """
	TCP defines the configuration of tcp health checker.
	It's required while the health checker type is TCP.
	"""
																							properties: {
																								receive: {
																									description: "Receive defines the expected response payload."
																									properties: {
																										binary: {
																											description: "Binary payload base64 encoded."
																											format:      "byte"
																											type:        "string"
																										}
																										text: {
																											description: "Text payload in plain text."
																											type:        "string"
																										}
																										type: {
																											allOf: [{
																												enum: [
																													"Text",
																													"Binary",
																												]
																											}, {
																												enum: [
																													"Text",
																													"Binary",
																												]
																											}]
																											description: "Type defines the type of the payload."
																											type:        "string"
																										}
																									}
																									required: ["type"]
																									type: "object"
																									"x-kubernetes-validations": [{
																										message: "If payload type is Text, text field needs to be set."
																										rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																									}, {
																										message: "If payload type is Binary, binary field needs to be set."
																										rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																									}]
																								}
																								send: {
																									description: "Send defines the request payload."
																									properties: {
																										binary: {
																											description: "Binary payload base64 encoded."
																											format:      "byte"
																											type:        "string"
																										}
																										text: {
																											description: "Text payload in plain text."
																											type:        "string"
																										}
																										type: {
																											allOf: [{
																												enum: [
																													"Text",
																													"Binary",
																												]
																											}, {
																												enum: [
																													"Text",
																													"Binary",
																												]
																											}]
																											description: "Type defines the type of the payload."
																											type:        "string"
																										}
																									}
																									required: ["type"]
																									type: "object"
																									"x-kubernetes-validations": [{
																										message: "If payload type is Text, text field needs to be set."
																										rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																									}, {
																										message: "If payload type is Binary, binary field needs to be set."
																										rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																									}]
																								}
																							}
																							type: "object"
																						}
																						timeout: {
																							default:     "1s"
																							description: "Timeout defines the time to wait for a health check response."
																							format:      "duration"
																							type:        "string"
																						}
																						type: {
																							allOf: [{
																								enum: [
																									"HTTP",
																									"TCP",
																									"GRPC",
																								]
																							}, {
																								enum: [
																									"HTTP",
																									"TCP",
																									"GRPC",
																								]
																							}]
																							description: "Type defines the type of health checker."
																							type:        "string"
																						}
																						unhealthyThreshold: {
																							default:     3
																							description: "UnhealthyThreshold defines the number of unhealthy health checks required before a backend host is marked unhealthy."
																							format:      "int32"
																							minimum:     1
																							type:        "integer"
																						}
																					}
																					required: ["type"]
																					type: "object"
																					"x-kubernetes-validations": [{
																						message: "If Health Checker type is HTTP, http field needs to be set."
																						rule:    "self.type == 'HTTP' ? has(self.http) : !has(self.http)"
																					}, {
																						message: "If Health Checker type is TCP, tcp field needs to be set."
																						rule:    "self.type == 'TCP' ? has(self.tcp) : !has(self.tcp)"
																					}, {
																						message: "The grpc field can only be set if the Health Checker type is GRPC."
																						rule:    "has(self.grpc) ? self.type == 'GRPC' : true"
																					}]
																				}
																				passive: {
																					description: "Passive passive check configuration"
																					properties: {
																						baseEjectionTime: {
																							default:     "30s"
																							description: "BaseEjectionTime defines the base duration for which a host will be ejected on consecutive failures."
																							format:      "duration"
																							type:        "string"
																						}
																						consecutive5XxErrors: {
																							default:     5
																							description: "Consecutive5xxErrors sets the number of consecutive 5xx errors triggering ejection."
																							format:      "int32"
																							type:        "integer"
																						}
																						consecutiveGatewayErrors: {
																							default:     0
																							description: "ConsecutiveGatewayErrors sets the number of consecutive gateway errors triggering ejection."
																							format:      "int32"
																							type:        "integer"
																						}
																						consecutiveLocalOriginFailures: {
																							default: 5
																							description: """
	ConsecutiveLocalOriginFailures sets the number of consecutive local origin failures triggering ejection.
	Parameter takes effect only when split_external_local_origin_errors is set to true.
	"""
																							format: "int32"
																							type:   "integer"
																						}
																						interval: {
																							default:     "3s"
																							description: "Interval defines the time between passive health checks."
																							format:      "duration"
																							type:        "string"
																						}
																						maxEjectionPercent: {
																							default:     10
																							description: "MaxEjectionPercent sets the maximum percentage of hosts in a cluster that can be ejected."
																							format:      "int32"
																							type:        "integer"
																						}
																						splitExternalLocalOriginErrors: {
																							default:     false
																							description: "SplitExternalLocalOriginErrors enables splitting of errors between external and local origin."
																							type:        "boolean"
																						}
																					}
																					type: "object"
																				}
																			}
																			type: "object"
																		}
																		http2: {
																			description: "HTTP2 provides HTTP/2 configuration for backend connections."
																			properties: {
																				initialConnectionWindowSize: {
																					allOf: [{
																						pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					}, {
																						pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																					}]
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	InitialConnectionWindowSize sets the initial window size for HTTP/2 connections.
	If not set, the default value is 1 MiB.
	"""
																					"x-kubernetes-int-or-string": true
																				}
																				initialStreamWindowSize: {
																					allOf: [{
																						pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																					}, {
																						pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																					}]
																					anyOf: [{
																						type: "integer"
																					}, {
																						type: "string"
																					}]
																					description: """
	InitialStreamWindowSize sets the initial window size for HTTP/2 streams.
	If not set, the default value is 64 KiB(64*1024).
	"""
																					"x-kubernetes-int-or-string": true
																				}
																				maxConcurrentStreams: {
																					description: """
	MaxConcurrentStreams sets the maximum number of concurrent streams allowed per connection.
	If not set, the default value is 100.
	"""
																					format:  "int32"
																					maximum: 2147483647
																					minimum: 1
																					type:    "integer"
																				}
																				onInvalidMessage: {
																					description: """
	OnInvalidMessage determines if Envoy will terminate the connection or just the offending stream in the event of HTTP messaging error
	It's recommended for L2 Envoy deployments to set this value to TerminateStream.
	https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/level_two
	Default: TerminateConnection
	"""
																					type: "string"
																				}
																			}
																			type: "object"
																		}
																		loadBalancer: {
																			description: """
	LoadBalancer policy to apply when routing traffic from the gateway to
	the backend endpoints. Defaults to `LeastRequest`.
	"""
																			properties: {
																				consistentHash: {
																					description: """
	ConsistentHash defines the configuration when the load balancer type is
	set to ConsistentHash
	"""
																					properties: {
																						cookie: {
																							description: "Cookie configures the cookie hash policy when the consistent hash type is set to Cookie."
																							properties: {
																								attributes: {
																									additionalProperties: type: "string"
																									description: "Additional Attributes to set for the generated cookie."
																									type:        "object"
																								}
																								name: {
																									description: """
	Name of the cookie to hash.
	If this cookie does not exist in the request, Envoy will generate a cookie and set
	the TTL on the response back to the client based on Layer 4
	attributes of the backend endpoint, to ensure that these future requests
	go to the same backend endpoint. Make sure to set the TTL field for this case.
	"""
																									type: "string"
																								}
																								ttl: {
																									description: """
	TTL of the generated cookie if the cookie is not present. This value sets the
	Max-Age attribute value.
	"""
																									type: "string"
																								}
																							}
																							required: ["name"]
																							type: "object"
																						}
																						header: {
																							description: "Header configures the header hash policy when the consistent hash type is set to Header."
																							properties: name: {
																								description: "Name of the header to hash."
																								type:        "string"
																							}
																							required: ["name"]
																							type: "object"
																						}
																						tableSize: {
																							default:     65537
																							description: "The table size for consistent hashing, must be prime number limited to 5000011."
																							format:      "int64"
																							maximum:     5000011
																							minimum:     2
																							type:        "integer"
																						}
																						type: {
																							description: """
	ConsistentHashType defines the type of input to hash on. Valid Type values are
	"SourceIP",
	"Header",
	"Cookie".
	"""
																							enum: [
																								"SourceIP",
																								"Header",
																								"Cookie",
																							]
																							type: "string"
																						}
																					}
																					required: ["type"]
																					type: "object"
																					"x-kubernetes-validations": [{
																						message: "If consistent hash type is header, the header field must be set."
																						rule:    "self.type == 'Header' ? has(self.header) : !has(self.header)"
																					}, {
																						message: "If consistent hash type is cookie, the cookie field must be set."
																						rule:    "self.type == 'Cookie' ? has(self.cookie) : !has(self.cookie)"
																					}]
																				}
																				slowStart: {
																					description: """
	SlowStart defines the configuration related to the slow start load balancer policy.
	If set, during slow start window, traffic sent to the newly added hosts will gradually increase.
	Currently this is only supported for RoundRobin and LeastRequest load balancers
	"""
																					properties: window: {
																						description: """
	Window defines the duration of the warm up period for newly added host.
	During slow start window, traffic sent to the newly added hosts will gradually increase.
	Currently only supports linear growth of traffic. For additional details,
	see https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto#config-cluster-v3-cluster-slowstartconfig
	"""
																						type: "string"
																					}
																					required: ["window"]
																					type: "object"
																				}
																				type: {
																					description: """
	Type decides the type of Load Balancer policy.
	Valid LoadBalancerType values are
	"ConsistentHash",
	"LeastRequest",
	"Random",
	"RoundRobin".
	"""
																					enum: [
																						"ConsistentHash",
																						"LeastRequest",
																						"Random",
																						"RoundRobin",
																					]
																					type: "string"
																				}
																			}
																			required: ["type"]
																			type: "object"
																			"x-kubernetes-validations": [{
																				message: "If LoadBalancer type is consistentHash, consistentHash field needs to be set."
																				rule:    "self.type == 'ConsistentHash' ? has(self.consistentHash) : !has(self.consistentHash)"
																			}, {
																				message: "Currently SlowStart is only supported for RoundRobin and LeastRequest load balancers."
																				rule:    "self.type in ['Random', 'ConsistentHash'] ? !has(self.slowStart) : true "
																			}]
																		}
																		proxyProtocol: {
																			description: "ProxyProtocol enables the Proxy Protocol when communicating with the backend."
																			properties: version: {
																				description: """
	Version of ProxyProtol
	Valid ProxyProtocolVersion values are
	"V1"
	"V2"
	"""
																				enum: [
																					"V1",
																					"V2",
																				]
																				type: "string"
																			}
																			required: ["version"]
																			type: "object"
																		}
																		retry: {
																			description: """
	Retry provides more advanced usage, allowing users to customize the number of retries, retry fallback strategy, and retry triggering conditions.
	If not set, retry will be disabled.
	"""
																			properties: {
																				numRetries: {
																					default:     2
																					description: "NumRetries is the number of retries to be attempted. Defaults to 2."
																					format:      "int32"
																					minimum:     0
																					type:        "integer"
																				}
																				perRetry: {
																					description: "PerRetry is the retry policy to be applied per retry attempt."
																					properties: {
																						backOff: {
																							description: """
	Backoff is the backoff policy to be applied per retry attempt. gateway uses a fully jittered exponential
	back-off algorithm for retries. For additional details,
	see https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#config-http-filters-router-x-envoy-max-retries
	"""
																							properties: {
																								baseInterval: {
																									description: "BaseInterval is the base interval between retries."
																									format:      "duration"
																									type:        "string"
																								}
																								maxInterval: {
																									description: """
	MaxInterval is the maximum interval between retries. This parameter is optional, but must be greater than or equal to the base_interval if set.
	The default is 10 times the base_interval
	"""
																									format: "duration"
																									type:   "string"
																								}
																							}
																							type: "object"
																						}
																						timeout: {
																							description: "Timeout is the timeout per retry attempt."
																							format:      "duration"
																							type:        "string"
																						}
																					}
																					type: "object"
																				}
																				retryOn: {
																					description: """
	RetryOn specifies the retry trigger condition.

	If not specified, the default is to retry on connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes(503).
	"""
																					properties: {
																						httpStatusCodes: {
																							description: """
	HttpStatusCodes specifies the http status codes to be retried.
	The retriable-status-codes trigger must also be configured for these status codes to trigger a retry.
	"""
																							items: {
																								description:      "HTTPStatus defines the http status code."
																								exclusiveMaximum: true
																								maximum:          600
																								minimum:          100
																								type:             "integer"
																							}
																							type: "array"
																						}
																						triggers: {
																							description: "Triggers specifies the retry trigger condition(Http/Grpc)."
																							items: {
																								description: "TriggerEnum specifies the conditions that trigger retries."
																								enum: [
																									"5xx",
																									"gateway-error",
																									"reset",
																									"connect-failure",
																									"retriable-4xx",
																									"refused-stream",
																									"retriable-status-codes",
																									"cancelled",
																									"deadline-exceeded",
																									"internal",
																									"resource-exhausted",
																									"unavailable",
																								]
																								type: "string"
																							}
																							type: "array"
																						}
																					}
																					type: "object"
																				}
																			}
																			type: "object"
																		}
																		tcpKeepalive: {
																			description: """
	TcpKeepalive settings associated with the upstream client connection.
	Disabled by default.
	"""
																			properties: {
																				idleTime: {
																					description: """
	The duration a connection needs to be idle before keep-alive
	probes start being sent.
	The duration format is
	Defaults to `7200s`.
	"""
																					pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																					type:    "string"
																				}
																				interval: {
																					description: """
	The duration between keep-alive probes.
	Defaults to `75s`.
	"""
																					pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																					type:    "string"
																				}
																				probes: {
																					description: """
	The total number of unacknowledged probes to send before deciding
	the connection is dead.
	Defaults to 9.
	"""
																					format: "int32"
																					type:   "integer"
																				}
																			}
																			type: "object"
																		}
																		timeout: {
																			description: "Timeout settings for the backend connections."
																			properties: {
																				http: {
																					description: "Timeout settings for HTTP."
																					properties: {
																						connectionIdleTimeout: {
																							description: """
	The idle timeout for an HTTP connection. Idle time is defined as a period in which there are no active requests in the connection.
	Default: 1 hour.
	"""
																							pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																							type:    "string"
																						}
																						maxConnectionDuration: {
																							description: """
	The maximum duration of an HTTP connection.
	Default: unlimited.
	"""
																							pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																							type:    "string"
																						}
																						requestTimeout: {
																							description: "RequestTimeout is the time until which entire response is received from the upstream."
																							pattern:     "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																							type:        "string"
																						}
																					}
																					type: "object"
																				}
																				tcp: {
																					description: "Timeout settings for TCP."
																					properties: connectTimeout: {
																						description: """
	The timeout for network connection establishment, including TCP and TLS handshakes.
	Default: 10 seconds.
	"""
																						pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																						type:    "string"
																					}
																					type: "object"
																				}
																			}
																			type: "object"
																		}
																	}
																	type: "object"
																}
																host: {
																	description: """
	Host define the service hostname.
	Deprecated: Use BackendRefs instead.
	"""
																	type: "string"
																}
																port: {
																	default: 4317
																	description: """
	Port defines the port the service is exposed on.
	Deprecated: Use BackendRefs instead.
	"""
																	format:  "int32"
																	maximum: 65535
																	minimum: 0
																	type:    "integer"
																}
															}
															type: "object"
															"x-kubernetes-validations": [{
																message: "host or backendRefs needs to be set"
																rule:    "has(self.host) || self.backendRefs.size() > 0"
															}, {
																message: "BackendRefs must be used, backendRef is not supported."
																rule:    "!has(self.backendRef)"
															}, {
																message: "only supports Service kind."
																rule:    "has(self.backendRefs) ? self.backendRefs.all(f, f.kind == 'Service') : true"
															}, {
																message: "BackendRefs only supports Core group."
																rule:    "has(self.backendRefs) ? (self.backendRefs.all(f, f.group == \"\")) : true"
															}]
														}
														type: {
															default: "OpenTelemetry"
															description: """
	Type defines the metric sink type.
	EG currently only supports OpenTelemetry.
	"""
															enum: ["OpenTelemetry"]
															type: "string"
														}
													}
													required: ["type"]
													type: "object"
													"x-kubernetes-validations": [{
														message: "If MetricSink type is OpenTelemetry, openTelemetry field needs to be set."
														rule:    "self.type == 'OpenTelemetry' ? has(self.openTelemetry) : !has(self.openTelemetry)"
													}]
												}
												maxItems: 16
												type:     "array"
											}
										}
										type: "object"
									}
									tracing: {
										description: """
	Tracing defines tracing configuration for managed proxies.
	If unspecified, will not send tracing data.
	"""
										properties: {
											customTags: {
												additionalProperties: {
													properties: {
														environment: {
															description: """
	Environment adds value from environment variable to each span.
	It's required when the type is "Environment".
	"""
															properties: {
																defaultValue: {
																	description: "DefaultValue defines the default value to use if the environment variable is not set."
																	type:        "string"
																}
																name: {
																	description: "Name defines the name of the environment variable which to extract the value from."
																	type:        "string"
																}
															}
															required: ["name"]
															type: "object"
														}
														literal: {
															description: """
	Literal adds hard-coded value to each span.
	It's required when the type is "Literal".
	"""
															properties: value: {
																description: "Value defines the hard-coded value to add to each span."
																type:        "string"
															}
															required: ["value"]
															type: "object"
														}
														requestHeader: {
															description: """
	RequestHeader adds value from request header to each span.
	It's required when the type is "RequestHeader".
	"""
															properties: {
																defaultValue: {
																	description: "DefaultValue defines the default value to use if the request header is not set."
																	type:        "string"
																}
																name: {
																	description: "Name defines the name of the request header which to extract the value from."
																	type:        "string"
																}
															}
															required: ["name"]
															type: "object"
														}
														type: {
															default:     "Literal"
															description: "Type defines the type of custom tag."
															enum: [
																"Literal",
																"Environment",
																"RequestHeader",
															]
															type: "string"
														}
													}
													required: ["type"]
													type: "object"
												}
												description: """
	CustomTags defines the custom tags to add to each span.
	If provider is kubernetes, pod name and namespace are added by default.
	"""
												type: "object"
											}
											provider: {
												description: "Provider defines the tracing provider."
												properties: {
													backendRef: {
														description: """
	BackendRef references a Kubernetes object that represents the
	backend server to which the authorization request will be sent.

	Deprecated: Use BackendRefs instead.
	"""
														properties: {
															group: {
																default: ""
																description: """
	Group is the group of the referent. For example, "gateway.networking.k8s.io".
	When unspecified or empty string, core API group is inferred.
	"""
																maxLength: 253
																pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																type:      "string"
															}
															kind: {
																default: "Service"
																description: """
	Kind is the Kubernetes resource kind of the referent. For example
	"Service".

	Defaults to "Service" when not specified.

	ExternalName services can refer to CNAME DNS records that may live
	outside of the cluster and as such are difficult to reason about in
	terms of conformance. They also may not be safe to forward to (see
	CVE-2021-25740 for more information). Implementations SHOULD NOT
	support ExternalName Services.

	Support: Core (Services with a type other than ExternalName)

	Support: Implementation-specific (Services with type ExternalName)
	"""
																maxLength: 63
																minLength: 1
																pattern:   "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
																type:      "string"
															}
															name: {
																description: "Name is the name of the referent."
																maxLength:   253
																minLength:   1
																type:        "string"
															}
															namespace: {
																description: """
	Namespace is the namespace of the backend. When unspecified, the local
	namespace is inferred.

	Note that when a namespace different than the local namespace is specified,
	a ReferenceGrant object is required in the referent namespace to allow that
	namespace's owner to accept the reference. See the ReferenceGrant
	documentation for details.

	Support: Core
	"""
																maxLength: 63
																minLength: 1
																pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
																type:      "string"
															}
															port: {
																description: """
	Port specifies the destination port number to use for this resource.
	Port is required when the referent is a Kubernetes Service. In this
	case, the port number is the service port number, not the target port.
	For other resources, destination port might be derived from the referent
	resource or this field.
	"""
																format:  "int32"
																maximum: 65535
																minimum: 1
																type:    "integer"
															}
														}
														required: ["name"]
														type: "object"
														"x-kubernetes-validations": [{
															message: "Must have port for Service reference"
															rule:    "(size(self.group) == 0 && self.kind == 'Service') ? has(self.port) : true"
														}]
													}
													backendRefs: {
														description: """
	BackendRefs references a Kubernetes object that represents the
	backend server to which the authorization request will be sent.
	"""
														items: {
															description: "BackendRef defines how an ObjectReference that is specific to BackendRef."
															properties: {
																fallback: {
																	description: """
	Fallback indicates whether the backend is designated as a fallback.
	Multiple fallback backends can be configured.
	It is highly recommended to configure active or passive health checks to ensure that failover can be detected
	when the active backends become unhealthy and to automatically readjust once the primary backends are healthy again.
	The overprovisioning factor is set to 1.4, meaning the fallback backends will only start receiving traffic when
	the health of the active backends falls below 72%.
	"""
																	type: "boolean"
																}
																group: {
																	default: ""
																	description: """
	Group is the group of the referent. For example, "gateway.networking.k8s.io".
	When unspecified or empty string, core API group is inferred.
	"""
																	maxLength: 253
																	pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																	type:      "string"
																}
																kind: {
																	default: "Service"
																	description: """
	Kind is the Kubernetes resource kind of the referent. For example
	"Service".

	Defaults to "Service" when not specified.

	ExternalName services can refer to CNAME DNS records that may live
	outside of the cluster and as such are difficult to reason about in
	terms of conformance. They also may not be safe to forward to (see
	CVE-2021-25740 for more information). Implementations SHOULD NOT
	support ExternalName Services.

	Support: Core (Services with a type other than ExternalName)

	Support: Implementation-specific (Services with type ExternalName)
	"""
																	maxLength: 63
																	minLength: 1
																	pattern:   "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
																	type:      "string"
																}
																name: {
																	description: "Name is the name of the referent."
																	maxLength:   253
																	minLength:   1
																	type:        "string"
																}
																namespace: {
																	description: """
	Namespace is the namespace of the backend. When unspecified, the local
	namespace is inferred.

	Note that when a namespace different than the local namespace is specified,
	a ReferenceGrant object is required in the referent namespace to allow that
	namespace's owner to accept the reference. See the ReferenceGrant
	documentation for details.

	Support: Core
	"""
																	maxLength: 63
																	minLength: 1
																	pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
																	type:      "string"
																}
																port: {
																	description: """
	Port specifies the destination port number to use for this resource.
	Port is required when the referent is a Kubernetes Service. In this
	case, the port number is the service port number, not the target port.
	For other resources, destination port might be derived from the referent
	resource or this field.
	"""
																	format:  "int32"
																	maximum: 65535
																	minimum: 1
																	type:    "integer"
																}
															}
															required: ["name"]
															type: "object"
															"x-kubernetes-validations": [{
																message: "Must have port for Service reference"
																rule:    "(size(self.group) == 0 && self.kind == 'Service') ? has(self.port) : true"
															}]
														}
														maxItems: 16
														type:     "array"
													}
													backendSettings: {
														description: """
	BackendSettings holds configuration for managing the connection
	to the backend.
	"""
														properties: {
															circuitBreaker: {
																description: """
	Circuit Breaker settings for the upstream connections and requests.
	If not set, circuit breakers will be enabled with the default thresholds
	"""
																properties: {
																	maxConnections: {
																		default:     1024
																		description: "The maximum number of connections that Envoy will establish to the referenced backend defined within a xRoute rule."
																		format:      "int64"
																		maximum:     4294967295
																		minimum:     0
																		type:        "integer"
																	}
																	maxParallelRequests: {
																		default:     1024
																		description: "The maximum number of parallel requests that Envoy will make to the referenced backend defined within a xRoute rule."
																		format:      "int64"
																		maximum:     4294967295
																		minimum:     0
																		type:        "integer"
																	}
																	maxParallelRetries: {
																		default:     1024
																		description: "The maximum number of parallel retries that Envoy will make to the referenced backend defined within a xRoute rule."
																		format:      "int64"
																		maximum:     4294967295
																		minimum:     0
																		type:        "integer"
																	}
																	maxPendingRequests: {
																		default:     1024
																		description: "The maximum number of pending requests that Envoy will queue to the referenced backend defined within a xRoute rule."
																		format:      "int64"
																		maximum:     4294967295
																		minimum:     0
																		type:        "integer"
																	}
																	maxRequestsPerConnection: {
																		description: """
	The maximum number of requests that Envoy will make over a single connection to the referenced backend defined within a xRoute rule.
	Default: unlimited.
	"""
																		format:  "int64"
																		maximum: 4294967295
																		minimum: 0
																		type:    "integer"
																	}
																}
																type: "object"
															}
															connection: {
																description: "Connection includes backend connection settings."
																properties: {
																	bufferLimit: {
																		allOf: [{
																			pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																		}, {
																			pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																		}]
																		anyOf: [{
																			type: "integer"
																		}, {
																			type: "string"
																		}]
																		description: """
	BufferLimit Soft limit on size of the cluster’s connections read and write buffers.
	BufferLimit applies to connection streaming (maybe non-streaming) channel between processes, it's in user space.
	If unspecified, an implementation defined default is applied (32768 bytes).
	For example, 20Mi, 1Gi, 256Ki etc.
	Note: that when the suffix is not provided, the value is interpreted as bytes.
	"""
																		"x-kubernetes-int-or-string": true
																	}
																	socketBufferLimit: {
																		allOf: [{
																			pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																		}, {
																			pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																		}]
																		anyOf: [{
																			type: "integer"
																		}, {
																			type: "string"
																		}]
																		description: """
	SocketBufferLimit provides configuration for the maximum buffer size in bytes for each socket
	to backend.
	SocketBufferLimit applies to socket streaming channel between TCP/IP stacks, it's in kernel space.
	For example, 20Mi, 1Gi, 256Ki etc.
	Note that when the suffix is not provided, the value is interpreted as bytes.
	"""
																		"x-kubernetes-int-or-string": true
																	}
																}
																type: "object"
															}
															dns: {
																description: "DNS includes dns resolution settings."
																properties: {
																	dnsRefreshRate: {
																		description: """
	DNSRefreshRate specifies the rate at which DNS records should be refreshed.
	Defaults to 30 seconds.
	"""
																		type: "string"
																	}
																	respectDnsTtl: {
																		description: """
	RespectDNSTTL indicates whether the DNS Time-To-Live (TTL) should be respected.
	If the value is set to true, the DNS refresh rate will be set to the resource record’s TTL.
	Defaults to true.
	"""
																		type: "boolean"
																	}
																}
																type: "object"
															}
															healthCheck: {
																description: "HealthCheck allows gateway to perform active health checking on backends."
																properties: {
																	active: {
																		description: "Active health check configuration"
																		properties: {
																			grpc: {
																				description: """
	GRPC defines the configuration of the GRPC health checker.
	It's optional, and can only be used if the specified type is GRPC.
	"""
																				properties: service: {
																					description: """
	Service to send in the health check request.
	If this is not specified, then the health check request applies to the entire
	server and not to a specific service.
	"""
																					type: "string"
																				}
																				type: "object"
																			}
																			healthyThreshold: {
																				default:     1
																				description: "HealthyThreshold defines the number of healthy health checks required before a backend host is marked healthy."
																				format:      "int32"
																				minimum:     1
																				type:        "integer"
																			}
																			http: {
																				description: """
	HTTP defines the configuration of http health checker.
	It's required while the health checker type is HTTP.
	"""
																				properties: {
																					expectedResponse: {
																						description: "ExpectedResponse defines a list of HTTP expected responses to match."
																						properties: {
																							binary: {
																								description: "Binary payload base64 encoded."
																								format:      "byte"
																								type:        "string"
																							}
																							text: {
																								description: "Text payload in plain text."
																								type:        "string"
																							}
																							type: {
																								allOf: [{
																									enum: [
																										"Text",
																										"Binary",
																									]
																								}, {
																									enum: [
																										"Text",
																										"Binary",
																									]
																								}]
																								description: "Type defines the type of the payload."
																								type:        "string"
																							}
																						}
																						required: ["type"]
																						type: "object"
																						"x-kubernetes-validations": [{
																							message: "If payload type is Text, text field needs to be set."
																							rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																						}, {
																							message: "If payload type is Binary, binary field needs to be set."
																							rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																						}]
																					}
																					expectedStatuses: {
																						description: """
	ExpectedStatuses defines a list of HTTP response statuses considered healthy.
	Defaults to 200 only
	"""
																						items: {
																							description:      "HTTPStatus defines the http status code."
																							exclusiveMaximum: true
																							maximum:          600
																							minimum:          100
																							type:             "integer"
																						}
																						type: "array"
																					}
																					method: {
																						description: """
	Method defines the HTTP method used for health checking.
	Defaults to GET
	"""
																						type: "string"
																					}
																					path: {
																						description: "Path defines the HTTP path that will be requested during health checking."
																						maxLength:   1024
																						minLength:   1
																						type:        "string"
																					}
																				}
																				required: ["path"]
																				type: "object"
																			}
																			interval: {
																				default:     "3s"
																				description: "Interval defines the time between active health checks."
																				format:      "duration"
																				type:        "string"
																			}
																			tcp: {
																				description: """
	TCP defines the configuration of tcp health checker.
	It's required while the health checker type is TCP.
	"""
																				properties: {
																					receive: {
																						description: "Receive defines the expected response payload."
																						properties: {
																							binary: {
																								description: "Binary payload base64 encoded."
																								format:      "byte"
																								type:        "string"
																							}
																							text: {
																								description: "Text payload in plain text."
																								type:        "string"
																							}
																							type: {
																								allOf: [{
																									enum: [
																										"Text",
																										"Binary",
																									]
																								}, {
																									enum: [
																										"Text",
																										"Binary",
																									]
																								}]
																								description: "Type defines the type of the payload."
																								type:        "string"
																							}
																						}
																						required: ["type"]
																						type: "object"
																						"x-kubernetes-validations": [{
																							message: "If payload type is Text, text field needs to be set."
																							rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																						}, {
																							message: "If payload type is Binary, binary field needs to be set."
																							rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																						}]
																					}
																					send: {
																						description: "Send defines the request payload."
																						properties: {
																							binary: {
																								description: "Binary payload base64 encoded."
																								format:      "byte"
																								type:        "string"
																							}
																							text: {
																								description: "Text payload in plain text."
																								type:        "string"
																							}
																							type: {
																								allOf: [{
																									enum: [
																										"Text",
																										"Binary",
																									]
																								}, {
																									enum: [
																										"Text",
																										"Binary",
																									]
																								}]
																								description: "Type defines the type of the payload."
																								type:        "string"
																							}
																						}
																						required: ["type"]
																						type: "object"
																						"x-kubernetes-validations": [{
																							message: "If payload type is Text, text field needs to be set."
																							rule:    "self.type == 'Text' ? has(self.text) : !has(self.text)"
																						}, {
																							message: "If payload type is Binary, binary field needs to be set."
																							rule:    "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
																						}]
																					}
																				}
																				type: "object"
																			}
																			timeout: {
																				default:     "1s"
																				description: "Timeout defines the time to wait for a health check response."
																				format:      "duration"
																				type:        "string"
																			}
																			type: {
																				allOf: [{
																					enum: [
																						"HTTP",
																						"TCP",
																						"GRPC",
																					]
																				}, {
																					enum: [
																						"HTTP",
																						"TCP",
																						"GRPC",
																					]
																				}]
																				description: "Type defines the type of health checker."
																				type:        "string"
																			}
																			unhealthyThreshold: {
																				default:     3
																				description: "UnhealthyThreshold defines the number of unhealthy health checks required before a backend host is marked unhealthy."
																				format:      "int32"
																				minimum:     1
																				type:        "integer"
																			}
																		}
																		required: ["type"]
																		type: "object"
																		"x-kubernetes-validations": [{
																			message: "If Health Checker type is HTTP, http field needs to be set."
																			rule:    "self.type == 'HTTP' ? has(self.http) : !has(self.http)"
																		}, {
																			message: "If Health Checker type is TCP, tcp field needs to be set."
																			rule:    "self.type == 'TCP' ? has(self.tcp) : !has(self.tcp)"
																		}, {
																			message: "The grpc field can only be set if the Health Checker type is GRPC."
																			rule:    "has(self.grpc) ? self.type == 'GRPC' : true"
																		}]
																	}
																	passive: {
																		description: "Passive passive check configuration"
																		properties: {
																			baseEjectionTime: {
																				default:     "30s"
																				description: "BaseEjectionTime defines the base duration for which a host will be ejected on consecutive failures."
																				format:      "duration"
																				type:        "string"
																			}
																			consecutive5XxErrors: {
																				default:     5
																				description: "Consecutive5xxErrors sets the number of consecutive 5xx errors triggering ejection."
																				format:      "int32"
																				type:        "integer"
																			}
																			consecutiveGatewayErrors: {
																				default:     0
																				description: "ConsecutiveGatewayErrors sets the number of consecutive gateway errors triggering ejection."
																				format:      "int32"
																				type:        "integer"
																			}
																			consecutiveLocalOriginFailures: {
																				default: 5
																				description: """
	ConsecutiveLocalOriginFailures sets the number of consecutive local origin failures triggering ejection.
	Parameter takes effect only when split_external_local_origin_errors is set to true.
	"""
																				format: "int32"
																				type:   "integer"
																			}
																			interval: {
																				default:     "3s"
																				description: "Interval defines the time between passive health checks."
																				format:      "duration"
																				type:        "string"
																			}
																			maxEjectionPercent: {
																				default:     10
																				description: "MaxEjectionPercent sets the maximum percentage of hosts in a cluster that can be ejected."
																				format:      "int32"
																				type:        "integer"
																			}
																			splitExternalLocalOriginErrors: {
																				default:     false
																				description: "SplitExternalLocalOriginErrors enables splitting of errors between external and local origin."
																				type:        "boolean"
																			}
																		}
																		type: "object"
																	}
																}
																type: "object"
															}
															http2: {
																description: "HTTP2 provides HTTP/2 configuration for backend connections."
																properties: {
																	initialConnectionWindowSize: {
																		allOf: [{
																			pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																		}, {
																			pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																		}]
																		anyOf: [{
																			type: "integer"
																		}, {
																			type: "string"
																		}]
																		description: """
	InitialConnectionWindowSize sets the initial window size for HTTP/2 connections.
	If not set, the default value is 1 MiB.
	"""
																		"x-kubernetes-int-or-string": true
																	}
																	initialStreamWindowSize: {
																		allOf: [{
																			pattern: "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																		}, {
																			pattern: "^[1-9]+[0-9]*([EPTGMK]i|[EPTGMk])?$"
																		}]
																		anyOf: [{
																			type: "integer"
																		}, {
																			type: "string"
																		}]
																		description: """
	InitialStreamWindowSize sets the initial window size for HTTP/2 streams.
	If not set, the default value is 64 KiB(64*1024).
	"""
																		"x-kubernetes-int-or-string": true
																	}
																	maxConcurrentStreams: {
																		description: """
	MaxConcurrentStreams sets the maximum number of concurrent streams allowed per connection.
	If not set, the default value is 100.
	"""
																		format:  "int32"
																		maximum: 2147483647
																		minimum: 1
																		type:    "integer"
																	}
																	onInvalidMessage: {
																		description: """
	OnInvalidMessage determines if Envoy will terminate the connection or just the offending stream in the event of HTTP messaging error
	It's recommended for L2 Envoy deployments to set this value to TerminateStream.
	https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/level_two
	Default: TerminateConnection
	"""
																		type: "string"
																	}
																}
																type: "object"
															}
															loadBalancer: {
																description: """
	LoadBalancer policy to apply when routing traffic from the gateway to
	the backend endpoints. Defaults to `LeastRequest`.
	"""
																properties: {
																	consistentHash: {
																		description: """
	ConsistentHash defines the configuration when the load balancer type is
	set to ConsistentHash
	"""
																		properties: {
																			cookie: {
																				description: "Cookie configures the cookie hash policy when the consistent hash type is set to Cookie."
																				properties: {
																					attributes: {
																						additionalProperties: type: "string"
																						description: "Additional Attributes to set for the generated cookie."
																						type:        "object"
																					}
																					name: {
																						description: """
	Name of the cookie to hash.
	If this cookie does not exist in the request, Envoy will generate a cookie and set
	the TTL on the response back to the client based on Layer 4
	attributes of the backend endpoint, to ensure that these future requests
	go to the same backend endpoint. Make sure to set the TTL field for this case.
	"""
																						type: "string"
																					}
																					ttl: {
																						description: """
	TTL of the generated cookie if the cookie is not present. This value sets the
	Max-Age attribute value.
	"""
																						type: "string"
																					}
																				}
																				required: ["name"]
																				type: "object"
																			}
																			header: {
																				description: "Header configures the header hash policy when the consistent hash type is set to Header."
																				properties: name: {
																					description: "Name of the header to hash."
																					type:        "string"
																				}
																				required: ["name"]
																				type: "object"
																			}
																			tableSize: {
																				default:     65537
																				description: "The table size for consistent hashing, must be prime number limited to 5000011."
																				format:      "int64"
																				maximum:     5000011
																				minimum:     2
																				type:        "integer"
																			}
																			type: {
																				description: """
	ConsistentHashType defines the type of input to hash on. Valid Type values are
	"SourceIP",
	"Header",
	"Cookie".
	"""
																				enum: [
																					"SourceIP",
																					"Header",
																					"Cookie",
																				]
																				type: "string"
																			}
																		}
																		required: ["type"]
																		type: "object"
																		"x-kubernetes-validations": [{
																			message: "If consistent hash type is header, the header field must be set."
																			rule:    "self.type == 'Header' ? has(self.header) : !has(self.header)"
																		}, {
																			message: "If consistent hash type is cookie, the cookie field must be set."
																			rule:    "self.type == 'Cookie' ? has(self.cookie) : !has(self.cookie)"
																		}]
																	}
																	slowStart: {
																		description: """
	SlowStart defines the configuration related to the slow start load balancer policy.
	If set, during slow start window, traffic sent to the newly added hosts will gradually increase.
	Currently this is only supported for RoundRobin and LeastRequest load balancers
	"""
																		properties: window: {
																			description: """
	Window defines the duration of the warm up period for newly added host.
	During slow start window, traffic sent to the newly added hosts will gradually increase.
	Currently only supports linear growth of traffic. For additional details,
	see https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto#config-cluster-v3-cluster-slowstartconfig
	"""
																			type: "string"
																		}
																		required: ["window"]
																		type: "object"
																	}
																	type: {
																		description: """
	Type decides the type of Load Balancer policy.
	Valid LoadBalancerType values are
	"ConsistentHash",
	"LeastRequest",
	"Random",
	"RoundRobin".
	"""
																		enum: [
																			"ConsistentHash",
																			"LeastRequest",
																			"Random",
																			"RoundRobin",
																		]
																		type: "string"
																	}
																}
																required: ["type"]
																type: "object"
																"x-kubernetes-validations": [{
																	message: "If LoadBalancer type is consistentHash, consistentHash field needs to be set."
																	rule:    "self.type == 'ConsistentHash' ? has(self.consistentHash) : !has(self.consistentHash)"
																}, {
																	message: "Currently SlowStart is only supported for RoundRobin and LeastRequest load balancers."
																	rule:    "self.type in ['Random', 'ConsistentHash'] ? !has(self.slowStart) : true "
																}]
															}
															proxyProtocol: {
																description: "ProxyProtocol enables the Proxy Protocol when communicating with the backend."
																properties: version: {
																	description: """
	Version of ProxyProtol
	Valid ProxyProtocolVersion values are
	"V1"
	"V2"
	"""
																	enum: [
																		"V1",
																		"V2",
																	]
																	type: "string"
																}
																required: ["version"]
																type: "object"
															}
															retry: {
																description: """
	Retry provides more advanced usage, allowing users to customize the number of retries, retry fallback strategy, and retry triggering conditions.
	If not set, retry will be disabled.
	"""
																properties: {
																	numRetries: {
																		default:     2
																		description: "NumRetries is the number of retries to be attempted. Defaults to 2."
																		format:      "int32"
																		minimum:     0
																		type:        "integer"
																	}
																	perRetry: {
																		description: "PerRetry is the retry policy to be applied per retry attempt."
																		properties: {
																			backOff: {
																				description: """
	Backoff is the backoff policy to be applied per retry attempt. gateway uses a fully jittered exponential
	back-off algorithm for retries. For additional details,
	see https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#config-http-filters-router-x-envoy-max-retries
	"""
																				properties: {
																					baseInterval: {
																						description: "BaseInterval is the base interval between retries."
																						format:      "duration"
																						type:        "string"
																					}
																					maxInterval: {
																						description: """
	MaxInterval is the maximum interval between retries. This parameter is optional, but must be greater than or equal to the base_interval if set.
	The default is 10 times the base_interval
	"""
																						format: "duration"
																						type:   "string"
																					}
																				}
																				type: "object"
																			}
																			timeout: {
																				description: "Timeout is the timeout per retry attempt."
																				format:      "duration"
																				type:        "string"
																			}
																		}
																		type: "object"
																	}
																	retryOn: {
																		description: """
	RetryOn specifies the retry trigger condition.

	If not specified, the default is to retry on connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes(503).
	"""
																		properties: {
																			httpStatusCodes: {
																				description: """
	HttpStatusCodes specifies the http status codes to be retried.
	The retriable-status-codes trigger must also be configured for these status codes to trigger a retry.
	"""
																				items: {
																					description:      "HTTPStatus defines the http status code."
																					exclusiveMaximum: true
																					maximum:          600
																					minimum:          100
																					type:             "integer"
																				}
																				type: "array"
																			}
																			triggers: {
																				description: "Triggers specifies the retry trigger condition(Http/Grpc)."
																				items: {
																					description: "TriggerEnum specifies the conditions that trigger retries."
																					enum: [
																						"5xx",
																						"gateway-error",
																						"reset",
																						"connect-failure",
																						"retriable-4xx",
																						"refused-stream",
																						"retriable-status-codes",
																						"cancelled",
																						"deadline-exceeded",
																						"internal",
																						"resource-exhausted",
																						"unavailable",
																					]
																					type: "string"
																				}
																				type: "array"
																			}
																		}
																		type: "object"
																	}
																}
																type: "object"
															}
															tcpKeepalive: {
																description: """
	TcpKeepalive settings associated with the upstream client connection.
	Disabled by default.
	"""
																properties: {
																	idleTime: {
																		description: """
	The duration a connection needs to be idle before keep-alive
	probes start being sent.
	The duration format is
	Defaults to `7200s`.
	"""
																		pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																		type:    "string"
																	}
																	interval: {
																		description: """
	The duration between keep-alive probes.
	Defaults to `75s`.
	"""
																		pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																		type:    "string"
																	}
																	probes: {
																		description: """
	The total number of unacknowledged probes to send before deciding
	the connection is dead.
	Defaults to 9.
	"""
																		format: "int32"
																		type:   "integer"
																	}
																}
																type: "object"
															}
															timeout: {
																description: "Timeout settings for the backend connections."
																properties: {
																	http: {
																		description: "Timeout settings for HTTP."
																		properties: {
																			connectionIdleTimeout: {
																				description: """
	The idle timeout for an HTTP connection. Idle time is defined as a period in which there are no active requests in the connection.
	Default: 1 hour.
	"""
																				pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																				type:    "string"
																			}
																			maxConnectionDuration: {
																				description: """
	The maximum duration of an HTTP connection.
	Default: unlimited.
	"""
																				pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																				type:    "string"
																			}
																			requestTimeout: {
																				description: "RequestTimeout is the time until which entire response is received from the upstream."
																				pattern:     "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																				type:        "string"
																			}
																		}
																		type: "object"
																	}
																	tcp: {
																		description: "Timeout settings for TCP."
																		properties: connectTimeout: {
																			description: """
	The timeout for network connection establishment, including TCP and TLS handshakes.
	Default: 10 seconds.
	"""
																			pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
																			type:    "string"
																		}
																		type: "object"
																	}
																}
																type: "object"
															}
														}
														type: "object"
													}
													host: {
														description: """
	Host define the provider service hostname.
	Deprecated: Use BackendRefs instead.
	"""
														type: "string"
													}
													port: {
														default: 4317
														description: """
	Port defines the port the provider service is exposed on.
	Deprecated: Use BackendRefs instead.
	"""
														format:  "int32"
														minimum: 0
														type:    "integer"
													}
													type: {
														default:     "OpenTelemetry"
														description: "Type defines the tracing provider type."
														enum: [
															"OpenTelemetry",
															"Zipkin",
															"Datadog",
														]
														type: "string"
													}
													zipkin: {
														description: "Zipkin defines the Zipkin tracing provider configuration"
														properties: {
															disableSharedSpanContext: {
																description: """
	DisableSharedSpanContext determines whether the default Envoy behaviour of
	client and server spans sharing the same span context should be disabled.
	"""
																type: "boolean"
															}
															enable128BitTraceId: {
																description: """
	Enable128BitTraceID determines whether a 128bit trace id will be used
	when creating a new trace instance. If set to false, a 64bit trace
	id will be used.
	"""
																type: "boolean"
															}
														}
														type: "object"
													}
												}
												required: ["type"]
												type: "object"
												"x-kubernetes-validations": [{
													message: "host or backendRefs needs to be set"
													rule:    "has(self.host) || self.backendRefs.size() > 0"
												}, {
													message: "BackendRefs must be used, backendRef is not supported."
													rule:    "!has(self.backendRef)"
												}, {
													message: "only supports Service kind."
													rule:    "has(self.backendRefs) ? self.backendRefs.all(f, f.kind == 'Service') : true"
												}, {
													message: "BackendRefs only supports Core group."
													rule:    "has(self.backendRefs) ? (self.backendRefs.all(f, f.group == \"\")) : true"
												}]
											}
											samplingRate: {
												default: 100
												description: """
	SamplingRate controls the rate at which traffic will be
	selected for tracing if no prior sampling decision has been made.
	Defaults to 100, valid values [0-100]. 100 indicates 100% sampling.
	"""
												format:  "int32"
												maximum: 100
												minimum: 0
												type:    "integer"
											}
										}
										required: ["provider"]
										type: "object"
									}
								}
								type: "object"
							}
						}
						type: "object"
					}
					status: {
						description: "EnvoyProxyStatus defines the actual state of EnvoyProxy."
						type:        "object"
					}
				}
				type: "object"
			}
			served:  true
			storage: true
			subresources: status: {}
		}]
	}
}
