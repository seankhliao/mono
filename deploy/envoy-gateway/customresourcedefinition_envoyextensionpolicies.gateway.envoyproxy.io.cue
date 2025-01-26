package deploy

k8s: "apiextensions.k8s.io": v1: CustomResourceDefinition: "": "envoyextensionpolicies.gateway.envoyproxy.io": {
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: {
		annotations: "controller-gen.kubebuilder.io/version": "v0.16.1"
		name: "envoyextensionpolicies.gateway.envoyproxy.io"
	}
	spec: {
		group: "gateway.envoyproxy.io"
		names: {
			kind:     "EnvoyExtensionPolicy"
			listKind: "EnvoyExtensionPolicyList"
			plural:   "envoyextensionpolicies"
			shortNames: ["eep"]
			singular: "envoyextensionpolicy"
		}
		scope: "Namespaced"
		versions: [{
			additionalPrinterColumns: [{
				jsonPath: ".metadata.creationTimestamp"
				name:     "Age"
				type:     "date"
			}]
			name: "v1alpha1"
			schema: openAPIV3Schema: {
				description: "EnvoyExtensionPolicy allows the user to configure various envoy extensibility options for the Gateway."
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
						description: "Spec defines the desired state of EnvoyExtensionPolicy."
						properties: {
							extProc: {
								description: """
	ExtProc is an ordered list of external processing filters
	that should added to the envoy filter chain
	"""
								items: {
									description: "ExtProc defines the configuration for External Processing filter."
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
										failOpen: {
											description: """
	FailOpen defines if requests or responses that cannot be processed due to connectivity to the
	external processor are terminated or passed-through.
	Default: false
	"""
											type: "boolean"
										}
										messageTimeout: {
											description: """
	MessageTimeout is the timeout for a response to be returned from the external processor
	Default: 200ms
	"""
											pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
											type:    "string"
										}
										processingMode: {
											description: """
	ProcessingMode defines how request and response body is processed
	Default: header and body are not sent to the external processor
	"""
											properties: {
												request: {
													description: """
	Defines processing mode for requests. If present, request headers are sent. Request body is processed according
	to the specified mode.
	"""
													properties: body: {
														description: "Defines body processing mode"
														enum: [
															"Streamed",
															"Buffered",
															"BufferedPartial",
														]
														type: "string"
													}
													type: "object"
												}
												response: {
													description: """
	Defines processing mode for responses. If present, response headers are sent. Response body is processed according
	to the specified mode.
	"""
													properties: body: {
														description: "Defines body processing mode"
														enum: [
															"Streamed",
															"Buffered",
															"BufferedPartial",
														]
														type: "string"
													}
													type: "object"
												}
											}
											type: "object"
										}
									}
									type: "object"
									"x-kubernetes-validations": [{
										message: "BackendRefs must be used, backendRef is not supported."
										rule:    "!has(self.backendRef)"
									}, {
										message: "BackendRefs only supports Service and Backend kind."
										rule:    "has(self.backendRefs) ? self.backendRefs.all(f, f.kind == 'Service' || f.kind == 'Backend') : true"
									}, {
										message: "BackendRefs only supports Core and gateway.envoyproxy.io group."
										rule:    "has(self.backendRefs) ? (self.backendRefs.all(f, f.group == \"\" || f.group == 'gateway.envoyproxy.io')) : true"
									}]
								}
								maxItems: 16
								type:     "array"
							}
							targetRef: {
								description: """
	TargetRef is the name of the resource this policy is being attached to.
	This policy and the TargetRef MUST be in the same namespace for this
	Policy to have effect

	Deprecated: use targetRefs/targetSelectors instead
	"""
								properties: {
									group: {
										description: "Group is the group of the target resource."
										maxLength:   253
										pattern:     "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
										type:        "string"
									}
									kind: {
										description: "Kind is kind of the target resource."
										maxLength:   63
										minLength:   1
										pattern:     "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
										type:        "string"
									}
									name: {
										description: "Name is the name of the target resource."
										maxLength:   253
										minLength:   1
										type:        "string"
									}
									sectionName: {
										description: """
	SectionName is the name of a section within the target resource. When
	unspecified, this targetRef targets the entire resource. In the following
	resources, SectionName is interpreted as the following:

	* Gateway: Listener name
	* HTTPRoute: HTTPRouteRule name
	* Service: Port name

	If a SectionName is specified, but does not exist on the targeted object,
	the Policy must fail to attach, and the policy implementation should record
	a `ResolvedRefs` or similar Condition in the Policy's status.
	"""
										maxLength: 253
										minLength: 1
										pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
										type:      "string"
									}
								}
								required: [
									"group",
									"kind",
									"name",
								]
								type: "object"
							}
							targetRefs: {
								description: """
	TargetRefs are the names of the Gateway resources this policy
	is being attached to.
	"""
								items: {
									description: """
	LocalPolicyTargetReferenceWithSectionName identifies an API object to apply a
	direct policy to. This should be used as part of Policy resources that can
	target single resources. For more information on how this policy attachment
	mode works, and a sample Policy resource, refer to the policy attachment
	documentation for Gateway API.

	Note: This should only be used for direct policy attachment when references
	to SectionName are actually needed. In all other cases,
	LocalPolicyTargetReference should be used.
	"""
									properties: {
										group: {
											description: "Group is the group of the target resource."
											maxLength:   253
											pattern:     "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
											type:        "string"
										}
										kind: {
											description: "Kind is kind of the target resource."
											maxLength:   63
											minLength:   1
											pattern:     "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
											type:        "string"
										}
										name: {
											description: "Name is the name of the target resource."
											maxLength:   253
											minLength:   1
											type:        "string"
										}
										sectionName: {
											description: """
	SectionName is the name of a section within the target resource. When
	unspecified, this targetRef targets the entire resource. In the following
	resources, SectionName is interpreted as the following:

	* Gateway: Listener name
	* HTTPRoute: HTTPRouteRule name
	* Service: Port name

	If a SectionName is specified, but does not exist on the targeted object,
	the Policy must fail to attach, and the policy implementation should record
	a `ResolvedRefs` or similar Condition in the Policy's status.
	"""
											maxLength: 253
											minLength: 1
											pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
											type:      "string"
										}
									}
									required: [
										"group",
										"kind",
										"name",
									]
									type: "object"
								}
								type: "array"
							}
							targetSelectors: {
								description: "TargetSelectors allow targeting resources for this policy based on labels"
								items: {
									properties: {
										group: {
											default:     "gateway.networking.k8s.io"
											description: "Group is the group that this selector targets. Defaults to gateway.networking.k8s.io"
											maxLength:   253
											pattern:     "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
											type:        "string"
										}
										kind: {
											description: "Kind is the resource kind that this selector targets."
											maxLength:   63
											minLength:   1
											pattern:     "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
											type:        "string"
										}
										matchLabels: {
											additionalProperties: type: "string"
											description: "MatchLabels are the set of label selectors for identifying the targeted resource"
											type:        "object"
										}
									}
									required: [
										"kind",
										"matchLabels",
									]
									type: "object"
									"x-kubernetes-validations": [{
										message: "group must be gateway.networking.k8s.io"
										rule:    "has(self.group) ? self.group == 'gateway.networking.k8s.io' : true "
									}]
								}
								type: "array"
							}
							wasm: {
								description: """
	Wasm is a list of Wasm extensions to be loaded by the Gateway.
	Order matters, as the extensions will be loaded in the order they are
	defined in this list.
	"""
								items: {
									description: """
	Wasm defines a Wasm extension.

	Note: at the moment, Envoy Gateway does not support configuring Wasm runtime.
	v8 is used as the VM runtime for the Wasm extensions.
	"""
									properties: {
										code: {
											description: "Code is the Wasm code for the extension."
											properties: {
												http: {
													description: """
	HTTP is the HTTP URL containing the Wasm code.

	Note that the HTTP server must be accessible from the Envoy proxy.
	"""
													properties: {
														sha256: {
															description: """
	SHA256 checksum that will be used to verify the Wasm code.

	If not specified, Envoy Gateway will not verify the downloaded Wasm code.
	kubebuilder:validation:Pattern=`^[a-f0-9]{64}$`
	"""
															type: "string"
														}
														url: {
															description: "URL is the URL containing the Wasm code."
															pattern:     "^((https?:)(\\/\\/\\/?)([\\w]*(?::[\\w]*)?@)?([\\d\\w\\.-]+)(?::(\\d+))?)?([\\/\\\\\\w\\.()-]*)?(?:([?][^#]*)?(#.*)?)*"
															type:        "string"
														}
													}
													required: ["url"]
													type: "object"
												}
												image: {
													description: """
	Image is the OCI image containing the Wasm code.

	Note that the image must be accessible from the Envoy Gateway.
	"""
													properties: {
														pullSecretRef: {
															description: """
	PullSecretRef is a reference to the secret containing the credentials to pull the image.
	Only support Kubernetes Secret resource from the same namespace.
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
															"x-kubernetes-validations": [{
																message: "only support Secret kind."
																rule:    "self.kind == 'Secret'"
															}]
														}
														sha256: {
															description: """
	SHA256 checksum that will be used to verify the OCI image.

	It must match the digest of the OCI image.

	If not specified, Envoy Gateway will not verify the downloaded OCI image.
	kubebuilder:validation:Pattern=`^[a-f0-9]{64}$`
	"""
															type: "string"
														}
														url: {
															description: """
	URL is the URL of the OCI image.
	URL can be in the format of `registry/image:tag` or `registry/image@sha256:digest`.
	"""
															type: "string"
														}
													}
													required: ["url"]
													type: "object"
												}
												pullPolicy: {
													description: """
	PullPolicy is the policy to use when pulling the Wasm module by either the HTTP or Image source.
	This field is only applicable when the SHA256 field is not set.

	If not specified, the default policy is IfNotPresent except for OCI images whose tag is latest.

	Note: EG does not update the Wasm module every time an Envoy proxy requests
	the Wasm module even if the pull policy is set to Always.
	It only updates the Wasm module when the EnvoyExtension resource version changes.
	"""
													enum: [
														"IfNotPresent",
														"Always",
													]
													type: "string"
												}
												type: {
													allOf: [{
														enum: [
															"HTTP",
															"Image",
														]
													}, {
														enum: [
															"HTTP",
															"Image",
															"ConfigMap",
														]
													}]
													description: """
	Type is the type of the source of the Wasm code.
	Valid WasmCodeSourceType values are "HTTP" or "Image".
	"""
													type: "string"
												}
											}
											required: ["type"]
											type: "object"
											"x-kubernetes-validations": [{
												message: "If type is HTTP, http field needs to be set."
												rule:    "self.type == 'HTTP' ? has(self.http) : !has(self.http)"
											}, {
												message: "If type is Image, image field needs to be set."
												rule:    "self.type == 'Image' ? has(self.image) : !has(self.image)"
											}]
										}
										config: {
											description: """
	Config is the configuration for the Wasm extension.
	This configuration will be passed as a JSON string to the Wasm extension.
	"""
											"x-kubernetes-preserve-unknown-fields": true
										}
										failOpen: {
											default: false
											description: """
	FailOpen is a switch used to control the behavior when a fatal error occurs
	during the initialization or the execution of the Wasm extension.
	If FailOpen is set to true, the system bypasses the Wasm extension and
	allows the traffic to pass through. Otherwise, if it is set to false or
	not set (defaulting to false), the system blocks the traffic and returns
	an HTTP 5xx error.
	"""
											type: "boolean"
										}
										name: {
											description: """
	Name is a unique name for this Wasm extension. It is used to identify the
	Wasm extension if multiple extensions are handled by the same vm_id and root_id.
	It's also used for logging/debugging.
	If not specified, EG will generate a unique name for the Wasm extension.
	"""
											type: "string"
										}
										rootID: {
											description: """
	RootID is a unique ID for a set of extensions in a VM which will share a
	RootContext and Contexts if applicable (e.g., an Wasm HttpFilter and an Wasm AccessLog).
	If left blank, all extensions with a blank root_id with the same vm_id will share Context(s).

	Note: RootID must match the root_id parameter used to register the Context in the Wasm code.
	"""
											type: "string"
										}
									}
									required: ["code"]
									type: "object"
								}
								maxItems: 16
								type:     "array"
							}
						}
						type: "object"
						"x-kubernetes-validations": [{
							message: "either targetRef or targetRefs must be used"
							rule:    "(has(self.targetRef) && !has(self.targetRefs)) || (!has(self.targetRef) && has(self.targetRefs)) || (has(self.targetSelectors) && self.targetSelectors.size() > 0) "
						}, {
							message: "this policy can only have a targetRef.group of gateway.networking.k8s.io"
							rule:    "has(self.targetRef) ? self.targetRef.group == 'gateway.networking.k8s.io' : true"
						}, {
							message: "this policy can only have a targetRef.kind of Gateway/HTTPRoute/GRPCRoute/TCPRoute/UDPRoute/TLSRoute"
							rule:    "has(self.targetRef) ? self.targetRef.kind in ['Gateway', 'HTTPRoute', 'GRPCRoute', 'UDPRoute', 'TCPRoute', 'TLSRoute'] : true"
						}, {
							message: "this policy does not yet support the sectionName field"
							rule:    "has(self.targetRef) ? !has(self.targetRef.sectionName) : true"
						}, {
							message: "this policy can only have a targetRefs[*].group of gateway.networking.k8s.io"
							rule:    "has(self.targetRefs) ? self.targetRefs.all(ref, ref.group == 'gateway.networking.k8s.io') : true "
						}, {
							message: "this policy can only have a targetRefs[*].kind of Gateway/HTTPRoute/GRPCRoute/TCPRoute/UDPRoute/TLSRoute"
							rule:    "has(self.targetRefs) ? self.targetRefs.all(ref, ref.kind in ['Gateway', 'HTTPRoute', 'GRPCRoute', 'UDPRoute', 'TCPRoute', 'TLSRoute']) : true "
						}, {
							message: "this policy does not yet support the sectionName field"
							rule:    "has(self.targetRefs) ? self.targetRefs.all(ref, !has(ref.sectionName)) : true"
						}]
					}
					status: {
						description: "Status defines the current status of EnvoyExtensionPolicy."
						properties: ancestors: {
							description: """
	Ancestors is a list of ancestor resources (usually Gateways) that are
	associated with the policy, and the status of the policy with respect to
	each ancestor. When this policy attaches to a parent, the controller that
	manages the parent and the ancestors MUST add an entry to this list when
	the controller first sees the policy and SHOULD update the entry as
	appropriate when the relevant ancestor is modified.

	Note that choosing the relevant ancestor is left to the Policy designers;
	an important part of Policy design is designing the right object level at
	which to namespace this status.

	Note also that implementations MUST ONLY populate ancestor status for
	the Ancestor resources they are responsible for. Implementations MUST
	use the ControllerName field to uniquely identify the entries in this list
	that they are responsible for.

	Note that to achieve this, the list of PolicyAncestorStatus structs
	MUST be treated as a map with a composite key, made up of the AncestorRef
	and ControllerName fields combined.

	A maximum of 16 ancestors will be represented in this list. An empty list
	means the Policy is not relevant for any ancestors.

	If this slice is full, implementations MUST NOT add further entries.
	Instead they MUST consider the policy unimplementable and signal that
	on any related resources such as the ancestor that would be referenced
	here. For example, if this list was full on BackendTLSPolicy, no
	additional Gateways would be able to reference the Service targeted by
	the BackendTLSPolicy.
	"""
							items: {
								description: """
	PolicyAncestorStatus describes the status of a route with respect to an
	associated Ancestor.

	Ancestors refer to objects that are either the Target of a policy or above it
	in terms of object hierarchy. For example, if a policy targets a Service, the
	Policy's Ancestors are, in order, the Service, the HTTPRoute, the Gateway, and
	the GatewayClass. Almost always, in this hierarchy, the Gateway will be the most
	useful object to place Policy status on, so we recommend that implementations
	SHOULD use Gateway as the PolicyAncestorStatus object unless the designers
	have a _very_ good reason otherwise.

	In the context of policy attachment, the Ancestor is used to distinguish which
	resource results in a distinct application of this policy. For example, if a policy
	targets a Service, it may have a distinct result per attached Gateway.

	Policies targeting the same resource may have different effects depending on the
	ancestors of those resources. For example, different Gateways targeting the same
	Service may have different capabilities, especially if they have different underlying
	implementations.

	For example, in BackendTLSPolicy, the Policy attaches to a Service that is
	used as a backend in a HTTPRoute that is itself attached to a Gateway.
	In this case, the relevant object for status is the Gateway, and that is the
	ancestor object referred to in this status.

	Note that a parent is also an ancestor, so for objects where the parent is the
	relevant object for status, this struct SHOULD still be used.

	This struct is intended to be used in a slice that's effectively a map,
	with a composite key made up of the AncestorRef and the ControllerName.
	"""
								properties: {
									ancestorRef: {
										description: """
	AncestorRef corresponds with a ParentRef in the spec that this
	PolicyAncestorStatus struct describes the status of.
	"""
										properties: {
											group: {
												default: "gateway.networking.k8s.io"
												description: """
	Group is the group of the referent.
	When unspecified, "gateway.networking.k8s.io" is inferred.
	To set the core API group (such as for a "Service" kind referent),
	Group must be explicitly set to "" (empty string).

	Support: Core
	"""
												maxLength: 253
												pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
												type:      "string"
											}
											kind: {
												default: "Gateway"
												description: """
	Kind is kind of the referent.

	There are two kinds of parent resources with "Core" support:

	* Gateway (Gateway conformance profile)
	* Service (Mesh conformance profile, ClusterIP Services only)

	Support for other resources is Implementation-Specific.
	"""
												maxLength: 63
												minLength: 1
												pattern:   "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
												type:      "string"
											}
											name: {
												description: """
	Name is the name of the referent.

	Support: Core
	"""
												maxLength: 253
												minLength: 1
												type:      "string"
											}
											namespace: {
												description: """
	Namespace is the namespace of the referent. When unspecified, this refers
	to the local namespace of the Route.

	Note that there are specific rules for ParentRefs which cross namespace
	boundaries. Cross-namespace references are only valid if they are explicitly
	allowed by something in the namespace they are referring to. For example:
	Gateway has the AllowedRoutes field, and ReferenceGrant provides a
	generic way to enable any other kind of cross-namespace reference.

	<gateway:experimental:description>
	ParentRefs from a Route to a Service in the same namespace are "producer"
	routes, which apply default routing rules to inbound connections from
	any namespace to the Service.

	ParentRefs from a Route to a Service in a different namespace are
	"consumer" routes, and these routing rules are only applied to outbound
	connections originating from the same namespace as the Route, for which
	the intended destination of the connections are a Service targeted as a
	ParentRef of the Route.
	</gateway:experimental:description>

	Support: Core
	"""
												maxLength: 63
												minLength: 1
												pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
												type:      "string"
											}
											port: {
												description: """
	Port is the network port this Route targets. It can be interpreted
	differently based on the type of parent resource.

	When the parent resource is a Gateway, this targets all listeners
	listening on the specified port that also support this kind of Route(and
	select this Route). It's not recommended to set `Port` unless the
	networking behaviors specified in a Route must apply to a specific port
	as opposed to a listener(s) whose port(s) may be changed. When both Port
	and SectionName are specified, the name and port of the selected listener
	must match both specified values.

	<gateway:experimental:description>
	When the parent resource is a Service, this targets a specific port in the
	Service spec. When both Port (experimental) and SectionName are specified,
	the name and port of the selected port must match both specified values.
	</gateway:experimental:description>

	Implementations MAY choose to support other parent resources.
	Implementations supporting other types of parent resources MUST clearly
	document how/if Port is interpreted.

	For the purpose of status, an attachment is considered successful as
	long as the parent resource accepts it partially. For example, Gateway
	listeners can restrict which Routes can attach to them by Route kind,
	namespace, or hostname. If 1 of 2 Gateway listeners accept attachment
	from the referencing Route, the Route MUST be considered successfully
	attached. If no Gateway listeners accept attachment from this Route,
	the Route MUST be considered detached from the Gateway.

	Support: Extended
	"""
												format:  "int32"
												maximum: 65535
												minimum: 1
												type:    "integer"
											}
											sectionName: {
												description: """
	SectionName is the name of a section within the target resource. In the
	following resources, SectionName is interpreted as the following:

	* Gateway: Listener name. When both Port (experimental) and SectionName
	are specified, the name and port of the selected listener must match
	both specified values.
	* Service: Port name. When both Port (experimental) and SectionName
	are specified, the name and port of the selected listener must match
	both specified values.

	Implementations MAY choose to support attaching Routes to other resources.
	If that is the case, they MUST clearly document how SectionName is
	interpreted.

	When unspecified (empty string), this will reference the entire resource.
	For the purpose of status, an attachment is considered successful if at
	least one section in the parent resource accepts it. For example, Gateway
	listeners can restrict which Routes can attach to them by Route kind,
	namespace, or hostname. If 1 of 2 Gateway listeners accept attachment from
	the referencing Route, the Route MUST be considered successfully
	attached. If no Gateway listeners accept attachment from this Route, the
	Route MUST be considered detached from the Gateway.

	Support: Core
	"""
												maxLength: 253
												minLength: 1
												pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
												type:      "string"
											}
										}
										required: ["name"]
										type: "object"
									}
									conditions: {
										description: "Conditions describes the status of the Policy with respect to the given Ancestor."
										items: {
											description: "Condition contains details for one aspect of the current state of this API Resource."
											properties: {
												lastTransitionTime: {
													description: """
	lastTransitionTime is the last time the condition transitioned from one status to another.
	This should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.
	"""
													format: "date-time"
													type:   "string"
												}
												message: {
													description: """
	message is a human readable message indicating details about the transition.
	This may be an empty string.
	"""
													maxLength: 32768
													type:      "string"
												}
												observedGeneration: {
													description: """
	observedGeneration represents the .metadata.generation that the condition was set based upon.
	For instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date
	with respect to the current state of the instance.
	"""
													format:  "int64"
													minimum: 0
													type:    "integer"
												}
												reason: {
													description: """
	reason contains a programmatic identifier indicating the reason for the condition's last transition.
	Producers of specific condition types may define expected values and meanings for this field,
	and whether the values are considered a guaranteed API.
	The value should be a CamelCase string.
	This field may not be empty.
	"""
													maxLength: 1024
													minLength: 1
													pattern:   "^[A-Za-z]([A-Za-z0-9_,:]*[A-Za-z0-9_])?$"
													type:      "string"
												}
												status: {
													description: "status of the condition, one of True, False, Unknown."
													enum: [
														"True",
														"False",
														"Unknown",
													]
													type: "string"
												}
												type: {
													description: "type of condition in CamelCase or in foo.example.com/CamelCase."
													maxLength:   316
													pattern:     "^([a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*/)?(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])$"
													type:        "string"
												}
											}
											required: [
												"lastTransitionTime",
												"message",
												"reason",
												"status",
												"type",
											]
											type: "object"
										}
										maxItems: 8
										minItems: 1
										type:     "array"
										"x-kubernetes-list-map-keys": ["type"]
										"x-kubernetes-list-type": "map"
									}
									controllerName: {
										description: """
	ControllerName is a domain/path string that indicates the name of the
	controller that wrote this status. This corresponds with the
	controllerName field on GatewayClass.

	Example: "example.net/gateway-controller".

	The format of this field is DOMAIN "/" PATH, where DOMAIN and PATH are
	valid Kubernetes names
	(https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).

	Controllers MUST populate this field when writing status. Controllers should ensure that
	entries to status populated with their ControllerName are cleaned up when they are no
	longer necessary.
	"""
										maxLength: 253
										minLength: 1
										pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*\\/[A-Za-z0-9\\/\\-._~%!$&'()*+,;=:]+$"
										type:      "string"
									}
								}
								required: [
									"ancestorRef",
									"controllerName",
								]
								type: "object"
							}
							maxItems: 16
							type:     "array"
						}
						required: ["ancestors"]
						type: "object"
					}
				}
				required: ["spec"]
				type: "object"
			}
			served:  true
			storage: true
			subresources: status: {}
		}]
	}
}
