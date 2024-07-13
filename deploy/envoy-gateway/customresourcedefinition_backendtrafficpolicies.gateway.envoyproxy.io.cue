package deploy

k8s: "apiextensions.k8s.io": v1: "CustomResourceDefinition": "": "backendtrafficpolicies.gateway.envoyproxy.io": {
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: {
		annotations: "controller-gen.kubebuilder.io/version": "v0.13.0"
		name: "backendtrafficpolicies.gateway.envoyproxy.io"
	}
	spec: {
		group: "gateway.envoyproxy.io"
		names: {
			categories: ["envoy-gateway"]
			kind:     "BackendTrafficPolicy"
			listKind: "BackendTrafficPolicyList"
			plural:   "backendtrafficpolicies"
			shortNames: ["btp"]
			singular: "backendtrafficpolicy"
		}
		scope: "Namespaced"
		versions: [{
			additionalPrinterColumns: [{
				jsonPath: ".status.conditions[?(@.type==\"Accepted\")].reason"
				name:     "Status"
				type:     "string"
			}, {
				jsonPath: ".metadata.creationTimestamp"
				name:     "Age"
				type:     "date"
			}]
			name: "v1alpha1"
			schema: openAPIV3Schema: {
				description: "BackendTrafficPolicy allows the user to configure the behavior of the connection between the Envoy Proxy listener and the backend service."

				properties: {
					apiVersion: {
						description: "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources"

						type: "string"
					}
					kind: {
						description: "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds"

						type: "string"
					}
					metadata: type: "object"
					spec: {
						description: "spec defines the desired state of BackendTrafficPolicy."
						properties: {
							circuitBreaker: {
								description: "Circuit Breaker settings for the upstream connections and requests. If not set, circuit breakers will be enabled with the default thresholds"

								properties: {
									maxConnections: {
										default:     1024
										description: "The maximum number of connections that Envoy will establish to the referenced backend defined within a xRoute rule."

										format:  "int64"
										maximum: 4294967295
										minimum: 0
										type:    "integer"
									}
									maxParallelRequests: {
										default:     1024
										description: "The maximum number of parallel requests that Envoy will make to the referenced backend defined within a xRoute rule."

										format:  "int64"
										maximum: 4294967295
										minimum: 0
										type:    "integer"
									}
									maxParallelRetries: {
										default:     1024
										description: "The maximum number of parallel retries that Envoy will make to the referenced backend defined within a xRoute rule."

										format:  "int64"
										maximum: 4294967295
										minimum: 0
										type:    "integer"
									}
									maxPendingRequests: {
										default:     1024
										description: "The maximum number of pending requests that Envoy will queue to the referenced backend defined within a xRoute rule."

										format:  "int64"
										maximum: 4294967295
										minimum: 0
										type:    "integer"
									}
									maxRequestsPerConnection: {
										description: "The maximum number of requests that Envoy will make over a single connection to the referenced backend defined within a xRoute rule. Default: unlimited."

										format:  "int64"
										maximum: 4294967295
										minimum: 0
										type:    "integer"
									}
								}
								type: "object"
							}
							compression: {
								description: "The compression config for the http streams."
								items: {
									description: "Compression defines the config of enabling compression. This can help reduce the bandwidth at the expense of higher CPU."

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
								type: "array"
							}
							faultInjection: {
								description: "FaultInjection defines the fault injection policy to be applied. This configuration can be used to inject delays and abort requests to mimic failure scenarios such as service failures and overloads"

								properties: {
									abort: {
										description: "If specified, the request will be aborted if it meets the configuration criteria."

										properties: {
											grpcStatus: {
												description: "GrpcStatus specifies the GRPC status code to be returned"

												format: "int32"
												type:   "integer"
											}
											httpStatus: {
												description: "StatusCode specifies the HTTP status code to be returned"

												format:  "int32"
												maximum: 600
												minimum: 200
												type:    "integer"
											}
											percentage: {
												default:     100
												description: "Percentage specifies the percentage of requests to be aborted. Default 100%, if set 0, no requests will be aborted. Accuracy to 0.0001%."

												type: "number"
											}
										}
										type: "object"
										"x-kubernetes-validations": [{
											message: "httpStatus and grpcStatus cannot be simultaneously defined."

											rule: " !(has(self.httpStatus) && has(self.grpcStatus)) "
										}, {
											message: "httpStatus and grpcStatus are set at least one."
											rule:    " has(self.httpStatus) || has(self.grpcStatus) "
										}]
									}
									delay: {
										description: "If specified, a delay will be injected into the request."
										properties: {
											fixedDelay: {
												description: "FixedDelay specifies the fixed delay duration"
												type:        "string"
											}
											percentage: {
												default:     100
												description: "Percentage specifies the percentage of requests to be delayed. Default 100%, if set 0, no requests will be delayed. Accuracy to 0.0001%."

												type: "number"
											}
										}
										required: ["fixedDelay"]
										type: "object"
									}
								}
								type: "object"
								"x-kubernetes-validations": [{
									message: "Delay and abort faults are set at least one."
									rule:    " has(self.delay) || has(self.abort) "
								}]
							}
							healthCheck: {
								description: "HealthCheck allows gateway to perform active health checking on backends."

								properties: {
									active: {
										description: "Active health check configuration"
										properties: {
											healthyThreshold: {
												default:     1
												description: "HealthyThreshold defines the number of healthy health checks required before a backend host is marked healthy."

												format:  "int32"
												minimum: 1
												type:    "integer"
											}
											http: {
												description: "HTTP defines the configuration of http health checker. It's required while the health checker type is HTTP."

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

															rule: "self.type == 'Text' ? has(self.text) : !has(self.text)"
														}, {
															message: "If payload type is Binary, binary field needs to be set."

															rule: "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
														}]
													}

													expectedStatuses: {
														description: "ExpectedStatuses defines a list of HTTP response statuses considered healthy. Defaults to 200 only"

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
														description: "Method defines the HTTP method used for health checking. Defaults to GET"

														type: "string"
													}
													path: {
														description: "Path defines the HTTP path that will be requested during health checking."

														maxLength: 1024
														minLength: 1
														type:      "string"
													}
												}
												required: ["path"]
												type: "object"
											}
											interval: {
												default:     "3s"
												description: "Interval defines the time between active health checks."

												format: "duration"
												type:   "string"
											}
											tcp: {
												description: "TCP defines the configuration of tcp health checker. It's required while the health checker type is TCP."

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

															rule: "self.type == 'Text' ? has(self.text) : !has(self.text)"
														}, {
															message: "If payload type is Binary, binary field needs to be set."

															rule: "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
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

															rule: "self.type == 'Text' ? has(self.text) : !has(self.text)"
														}, {
															message: "If payload type is Binary, binary field needs to be set."

															rule: "self.type == 'Binary' ? has(self.binary) : !has(self.binary)"
														}]
													}
												}

												type: "object"
											}
											timeout: {
												default:     "1s"
												description: "Timeout defines the time to wait for a health check response."

												format: "duration"
												type:   "string"
											}
											type: {
												allOf: [{
													enum: [
														"HTTP",
														"TCP",
													]
												}, {
													enum: [
														"HTTP",
														"TCP",
													]
												}]
												description: "Type defines the type of health checker."
												type:        "string"
											}
											unhealthyThreshold: {
												default:     3
												description: "UnhealthyThreshold defines the number of unhealthy health checks required before a backend host is marked unhealthy."

												format:  "int32"
												minimum: 1
												type:    "integer"
											}
										}
										required: ["type"]
										type: "object"
										"x-kubernetes-validations": [{
											message: "If Health Checker type is HTTP, http field needs to be set."

											rule: "self.type == 'HTTP' ? has(self.http) : !has(self.http)"
										}, {
											message: "If Health Checker type is TCP, tcp field needs to be set."

											rule: "self.type == 'TCP' ? has(self.tcp) : !has(self.tcp)"
										}]
									}
									passive: {
										description: "Passive passive check configuration"
										properties: {
											baseEjectionTime: {
												default:     "30s"
												description: "BaseEjectionTime defines the base duration for which a host will be ejected on consecutive failures."

												format: "duration"
												type:   "string"
											}
											consecutive5XxErrors: {
												default:     5
												description: "Consecutive5xxErrors sets the number of consecutive 5xx errors triggering ejection."

												format: "int32"
												type:   "integer"
											}
											consecutiveGatewayErrors: {
												default:     0
												description: "ConsecutiveGatewayErrors sets the number of consecutive gateway errors triggering ejection."

												format: "int32"
												type:   "integer"
											}
											consecutiveLocalOriginFailures: {
												default:     5
												description: "ConsecutiveLocalOriginFailures sets the number of consecutive local origin failures triggering ejection. Parameter takes effect only when split_external_local_origin_errors is set to true."

												format: "int32"
												type:   "integer"
											}
											interval: {
												default:     "3s"
												description: "Interval defines the time between passive health checks."

												format: "duration"
												type:   "string"
											}
											maxEjectionPercent: {
												default:     10
												description: "MaxEjectionPercent sets the maximum percentage of hosts in a cluster that can be ejected."

												format: "int32"
												type:   "integer"
											}
											splitExternalLocalOriginErrors: {
												default:     false
												description: "SplitExternalLocalOriginErrors enables splitting of errors between external and local origin."

												type: "boolean"
											}
										}
										type: "object"
									}
								}
								type: "object"
							}
							loadBalancer: {
								description: "LoadBalancer policy to apply when routing traffic from the gateway to the backend endpoints"

								properties: {
									consistentHash: {
										description: "ConsistentHash defines the configuration when the load balancer type is set to ConsistentHash"

										properties: type: {
											description: "ConsistentHashType defines the type of input to hash on."

											enum: ["SourceIP"]
											type: "string"
										}
										required: ["type"]
										type: "object"
									}
									slowStart: {
										description: "SlowStart defines the configuration related to the slow start load balancer policy. If set, during slow start window, traffic sent to the newly added hosts will gradually increase. Currently this is only supported for RoundRobin and LeastRequest load balancers"

										properties: window: {
											description: "Window defines the duration of the warm up period for newly added host. During slow start window, traffic sent to the newly added hosts will gradually increase. Currently only supports linear growth of traffic. For additional details, see https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto#config-cluster-v3-cluster-slowstartconfig"

											type: "string"
										}
										required: ["window"]
										type: "object"
									}
									type: {
										description: "Type decides the type of Load Balancer policy. Valid LoadBalancerType values are \"ConsistentHash\", \"LeastRequest\", \"Random\", \"RoundRobin\","

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

									rule: "self.type == 'ConsistentHash' ? has(self.consistentHash) : !has(self.consistentHash)"
								}, {
									message: "Currently SlowStart is only supported for RoundRobin and LeastRequest load balancers."

									rule: "self.type in ['Random', 'ConsistentHash'] ? !has(self.slowStart) : true "
								}]
							}

							proxyProtocol: {
								description: "ProxyProtocol enables the Proxy Protocol when communicating with the backend."

								properties: version: {
									description: "Version of ProxyProtol Valid ProxyProtocolVersion values are \"V1\" \"V2\""

									enum: [
										"V1",
										"V2",
									]
									type: "string"
								}
								required: ["version"]
								type: "object"
							}
							rateLimit: {
								description: "RateLimit allows the user to limit the number of incoming requests to a predefined value based on attributes within the traffic flow."

								properties: {
									global: {
										description: "Global defines global rate limit configuration."
										properties: rules: {
											description: "Rules are a list of RateLimit selectors and limits. Each rule and its associated limit is applied in a mutually exclusive way. If a request matches multiple rules, each of their associated limits get applied, so a single request might increase the rate limit counters for multiple rules if selected. The rate limit service will return a logical OR of the individual rate limit decisions of all matching rules. For example, if a request matches two rules, one rate limited and one not, the final decision will be to rate limit the request."

											items: {
												description: "RateLimitRule defines the semantics for matching attributes from the incoming requests, and setting limits for them."

												properties: {
													clientSelectors: {
														description: """
		ClientSelectors holds the list of select conditions to select specific clients using attributes from the traffic flow. All individual select conditions must hold True for this rule and its limit to be applied. 
		 If no client selectors are specified, the rule applies to all traffic of the targeted Route. 
		 If the policy targets a Gateway, the rule applies to each Route of the Gateway. Please note that each Route has its own rate limit counters. For example, if a Gateway has two Routes, and the policy has a rule with limit 10rps, each Route will have its own 10rps limit.
		"""

														items: {
															description: "RateLimitSelectCondition specifies the attributes within the traffic flow that can be used to select a subset of clients to be ratelimited. All the individual conditions must hold True for the overall condition to hold True."

															properties: {
																headers: {
																	description: "Headers is a list of request headers to match. Multiple header values are ANDed together, meaning, a request MUST match all the specified headers. At least one of headers or sourceCIDR condition must be specified."

																	items: {
																		description: "HeaderMatch defines the match attributes within the HTTP Headers of the request."

																		properties: {
																			name: {
																				description: "Name of the HTTP header."
																				maxLength:   256
																				minLength:   1
																				type:        "string"
																			}
																			type: {
																				default:     "Exact"
																				description: "Type specifies how to match against the value of the header."

																				enum: [
																					"Exact",
																					"RegularExpression",
																					"Distinct",
																				]
																				type: "string"
																			}
																			value: {
																				description: "Value within the HTTP header. Due to the case-insensitivity of header names, \"foo\" and \"Foo\" are considered equivalent. Do not set this field when Type=\"Distinct\", implying matching on any/all unique values within the header."

																				maxLength: 1024
																				type:      "string"
																			}
																		}
																		required: ["name"]
																		type: "object"
																	}
																	maxItems: 16
																	type:     "array"
																	"x-kubernetes-list-map-keys": ["name"]
																	"x-kubernetes-list-type": "map"
																}
																sourceCIDR: {
																	description: "SourceCIDR is the client IP Address range to match on. At least one of headers or sourceCIDR condition must be specified."

																	properties: {
																		type: {
																			default: "Exact"
																			type:    "string"
																		}
																		value: {
																			description: "Value is the IP CIDR that represents the range of Source IP Addresses of the client. These could also be the intermediate addresses through which the request has flown through and is part of the  `X-Forwarded-For` header. For example, `192.168.0.1/32`, `192.168.0.0/24`, `001:db8::/64`."

																			maxLength: 256
																			minLength: 1
																			type:      "string"
																		}
																	}
																	required: ["value"]
																	type: "object"
																}
															}
															type: "object"
														}
														maxItems: 8
														type:     "array"
													}
													limit: {
														description: "Limit holds the rate limit values. This limit is applied for traffic flows when the selectors compute to True, causing the request to be counted towards the limit. The limit is enforced and the request is ratelimited, i.e. a response with 429 HTTP status code is sent back to the client when the selected requests have reached the limit."

														properties: {
															requests: type: "integer"
															unit: {
																description: "RateLimitUnit specifies the intervals for setting rate limits. Valid RateLimitUnit values are \"Second\", \"Minute\", \"Hour\", and \"Day\"."

																enum: [
																	"Second",
																	"Minute",
																	"Hour",
																	"Day",
																]
																type: "string"
															}
														}
														required: [
															"requests",
															"unit",
														]
														type: "object"
													}
												}
												required: ["limit"]
												type: "object"
											}
											maxItems: 16
											type:     "array"
										}
										required: ["rules"]
										type: "object"
									}
									local: {
										description: "Local defines local rate limit configuration."
										properties: rules: {
											description: "Rules are a list of RateLimit selectors and limits. If a request matches multiple rules, the strictest limit is applied. For example, if a request matches two rules, one with 10rps and one with 20rps, the final limit will be based on the rule with 10rps."

											items: {
												description: "RateLimitRule defines the semantics for matching attributes from the incoming requests, and setting limits for them."

												properties: {
													clientSelectors: {
														description: """
		ClientSelectors holds the list of select conditions to select specific clients using attributes from the traffic flow. All individual select conditions must hold True for this rule and its limit to be applied. 
		 If no client selectors are specified, the rule applies to all traffic of the targeted Route. 
		 If the policy targets a Gateway, the rule applies to each Route of the Gateway. Please note that each Route has its own rate limit counters. For example, if a Gateway has two Routes, and the policy has a rule with limit 10rps, each Route will have its own 10rps limit.
		"""

														items: {
															description: "RateLimitSelectCondition specifies the attributes within the traffic flow that can be used to select a subset of clients to be ratelimited. All the individual conditions must hold True for the overall condition to hold True."

															properties: {
																headers: {
																	description: "Headers is a list of request headers to match. Multiple header values are ANDed together, meaning, a request MUST match all the specified headers. At least one of headers or sourceCIDR condition must be specified."

																	items: {
																		description: "HeaderMatch defines the match attributes within the HTTP Headers of the request."

																		properties: {
																			name: {
																				description: "Name of the HTTP header."
																				maxLength:   256
																				minLength:   1
																				type:        "string"
																			}
																			type: {
																				default:     "Exact"
																				description: "Type specifies how to match against the value of the header."

																				enum: [
																					"Exact",
																					"RegularExpression",
																					"Distinct",
																				]
																				type: "string"
																			}
																			value: {
																				description: "Value within the HTTP header. Due to the case-insensitivity of header names, \"foo\" and \"Foo\" are considered equivalent. Do not set this field when Type=\"Distinct\", implying matching on any/all unique values within the header."

																				maxLength: 1024
																				type:      "string"
																			}
																		}
																		required: ["name"]
																		type: "object"
																	}
																	maxItems: 16
																	type:     "array"
																	"x-kubernetes-list-map-keys": ["name"]
																	"x-kubernetes-list-type": "map"
																}
																sourceCIDR: {
																	description: "SourceCIDR is the client IP Address range to match on. At least one of headers or sourceCIDR condition must be specified."

																	properties: {
																		type: {
																			default: "Exact"
																			type:    "string"
																		}
																		value: {
																			description: "Value is the IP CIDR that represents the range of Source IP Addresses of the client. These could also be the intermediate addresses through which the request has flown through and is part of the  `X-Forwarded-For` header. For example, `192.168.0.1/32`, `192.168.0.0/24`, `001:db8::/64`."

																			maxLength: 256
																			minLength: 1
																			type:      "string"
																		}
																	}
																	required: ["value"]
																	type: "object"
																}
															}
															type: "object"
														}
														maxItems: 8
														type:     "array"
													}
													limit: {
														description: "Limit holds the rate limit values. This limit is applied for traffic flows when the selectors compute to True, causing the request to be counted towards the limit. The limit is enforced and the request is ratelimited, i.e. a response with 429 HTTP status code is sent back to the client when the selected requests have reached the limit."

														properties: {
															requests: type: "integer"
															unit: {
																description: "RateLimitUnit specifies the intervals for setting rate limits. Valid RateLimitUnit values are \"Second\", \"Minute\", \"Hour\", and \"Day\"."

																enum: [
																	"Second",
																	"Minute",
																	"Hour",
																	"Day",
																]
																type: "string"
															}
														}
														required: [
															"requests",
															"unit",
														]
														type: "object"
													}
												}
												required: ["limit"]
												type: "object"
											}
											maxItems: 16
											type:     "array"
										}
										type: "object"
									}
									type: {
										description: "Type decides the scope for the RateLimits. Valid RateLimitType values are \"Global\" or \"Local\"."

										enum: [
											"Global",
											"Local",
										]
										type: "string"
									}
								}
								required: ["type"]
								type: "object"
							}
							retry: {
								description: "Retry provides more advanced usage, allowing users to customize the number of retries, retry fallback strategy, and retry triggering conditions. If not set, retry will be disabled."

								properties: {
									numRetries: {
										default:     2
										description: "NumRetries is the number of retries to be attempted. Defaults to 2."

										format:  "int32"
										minimum: 0
										type:    "integer"
									}
									perRetry: {
										description: "PerRetry is the retry policy to be applied per retry attempt."

										properties: {
											backOff: {
												description: "Backoff is the backoff policy to be applied per retry attempt. gateway uses a fully jittered exponential back-off algorithm for retries. For additional details, see https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#config-http-filters-router-x-envoy-max-retries"

												properties: {
													baseInterval: {
														description: "BaseInterval is the base interval between retries."

														format: "duration"
														type:   "string"
													}
													maxInterval: {
														description: "MaxInterval is the maximum interval between retries. This parameter is optional, but must be greater than or equal to the base_interval if set. The default is 10 times the base_interval"

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
												description: "HttpStatusCodes specifies the http status codes to be retried. The retriable-status-codes trigger must also be configured for these status codes to trigger a retry."

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
							targetRef: {
								description: "targetRef is the name of the resource this policy is being attached to. This Policy and the TargetRef MUST be in the same namespace for this Policy to have effect and be applied to the Gateway."

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
									namespace: {
										description: "Namespace is the namespace of the referent. When unspecified, the local namespace is inferred. Even when policy targets a resource in a different namespace, it MUST only apply to traffic originating from the same namespace as the policy."

										maxLength: 63
										minLength: 1
										pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
										type:      "string"
									}
									sectionName: {
										description: """
		SectionName is the name of a section within the target resource. When unspecified, this targetRef targets the entire resource. In the following resources, SectionName is interpreted as the following: 
		 * Gateway: Listener Name * Service: Port Name 
		 If a SectionName is specified, but does not exist on the targeted object, the Policy must fail to attach, and the policy implementation should record a `ResolvedRefs` or similar Condition in the Policy's status.
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
								"x-kubernetes-validations": [{
									message: "this policy can only have a targetRef.group of gateway.networking.k8s.io"
									rule:    "self.group == 'gateway.networking.k8s.io'"
								}, {
									message: "this policy can only have a targetRef.kind of Gateway/HTTPRoute/GRPCRoute/TCPRoute/UDPRoute/TLSRoute"
									rule:    "self.kind in ['Gateway', 'HTTPRoute', 'GRPCRoute', 'UDPRoute', 'TCPRoute', 'TLSRoute']"
								}, {
									message: "this policy does not yet support the sectionName field"
									rule:    "!has(self.sectionName)"
								}]
							}
							tcpKeepalive: {
								description: "TcpKeepalive settings associated with the upstream client connection. Disabled by default."

								properties: {
									idleTime: {
										description: "The duration a connection needs to be idle before keep-alive probes start being sent. The duration format is Defaults to `7200s`."

										pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
										type:    "string"
									}
									interval: {
										description: "The duration between keep-alive probes. Defaults to `75s`."

										pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
										type:    "string"
									}
									probes: {
										description: "The total number of unacknowledged probes to send before deciding the connection is dead. Defaults to 9."

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
												description: "The idle timeout for an HTTP connection. Idle time is defined as a period in which there are no active requests in the connection. Default: 1 hour."

												pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
												type:    "string"
											}
											maxConnectionDuration: {
												description: "The maximum duration of an HTTP connection. Default: unlimited."

												pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
												type:    "string"
											}
										}
										type: "object"
									}
									tcp: {
										description: "Timeout settings for TCP."
										properties: connectTimeout: {
											description: "The timeout for network connection establishment, including TCP and TLS handshakes. Default: 10 seconds."

											pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
											type:    "string"
										}
										type: "object"
									}
								}
								type: "object"
							}
						}
						required: ["targetRef"]
						type: "object"
					}
					status: {
						description: "status defines the current status of BackendTrafficPolicy."
						properties: ancestors: {
							description: """
		Ancestors is a list of ancestor resources (usually Gateways) that are associated with the policy, and the status of the policy with respect to each ancestor. When this policy attaches to a parent, the controller that manages the parent and the ancestors MUST add an entry to this list when the controller first sees the policy and SHOULD update the entry as appropriate when the relevant ancestor is modified. 
		 Note that choosing the relevant ancestor is left to the Policy designers; an important part of Policy design is designing the right object level at which to namespace this status. 
		 Note also that implementations MUST ONLY populate ancestor status for the Ancestor resources they are responsible for. Implementations MUST use the ControllerName field to uniquely identify the entries in this list that they are responsible for. 
		 Note that to achieve this, the list of PolicyAncestorStatus structs MUST be treated as a map with a composite key, made up of the AncestorRef and ControllerName fields combined. 
		 A maximum of 16 ancestors will be represented in this list. An empty list means the Policy is not relevant for any ancestors. 
		 If this slice is full, implementations MUST NOT add further entries. Instead they MUST consider the policy unimplementable and signal that on any related resources such as the ancestor that would be referenced here. For example, if this list was full on BackendTLSPolicy, no additional Gateways would be able to reference the Service targeted by the BackendTLSPolicy.
		"""

							items: {
								description: """
		PolicyAncestorStatus describes the status of a route with respect to an associated Ancestor. 
		 Ancestors refer to objects that are either the Target of a policy or above it in terms of object hierarchy. For example, if a policy targets a Service, the Policy's Ancestors are, in order, the Service, the HTTPRoute, the Gateway, and the GatewayClass. Almost always, in this hierarchy, the Gateway will be the most useful object to place Policy status on, so we recommend that implementations SHOULD use Gateway as the PolicyAncestorStatus object unless the designers have a _very_ good reason otherwise. 
		 In the context of policy attachment, the Ancestor is used to distinguish which resource results in a distinct application of this policy. For example, if a policy targets a Service, it may have a distinct result per attached Gateway. 
		 Policies targeting the same resource may have different effects depending on the ancestors of those resources. For example, different Gateways targeting the same Service may have different capabilities, especially if they have different underlying implementations. 
		 For example, in BackendTLSPolicy, the Policy attaches to a Service that is used as a backend in a HTTPRoute that is itself attached to a Gateway. In this case, the relevant object for status is the Gateway, and that is the ancestor object referred to in this status. 
		 Note that a parent is also an ancestor, so for objects where the parent is the relevant object for status, this struct SHOULD still be used. 
		 This struct is intended to be used in a slice that's effectively a map, with a composite key made up of the AncestorRef and the ControllerName.
		"""

								properties: {
									ancestorRef: {
										description: "AncestorRef corresponds with a ParentRef in the spec that this PolicyAncestorStatus struct describes the status of."

										properties: {
											group: {
												default: "gateway.networking.k8s.io"
												description: """
		Group is the group of the referent. When unspecified, \"gateway.networking.k8s.io\" is inferred. To set the core API group (such as for a \"Service\" kind referent), Group must be explicitly set to \"\" (empty string). 
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
		 There are two kinds of parent resources with \"Core\" support: 
		 * Gateway (Gateway conformance profile) * Service (Mesh conformance profile, experimental, ClusterIP Services only) 
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
		Namespace is the namespace of the referent. When unspecified, this refers to the local namespace of the Route. 
		 Note that there are specific rules for ParentRefs which cross namespace boundaries. Cross-namespace references are only valid if they are explicitly allowed by something in the namespace they are referring to. For example: Gateway has the AllowedRoutes field, and ReferenceGrant provides a generic way to enable any other kind of cross-namespace reference. 
		 <gateway:experimental:description> ParentRefs from a Route to a Service in the same namespace are \"producer\" routes, which apply default routing rules to inbound connections from any namespace to the Service. 
		 ParentRefs from a Route to a Service in a different namespace are \"consumer\" routes, and these routing rules are only applied to outbound connections originating from the same namespace as the Route, for which the intended destination of the connections are a Service targeted as a ParentRef of the Route. </gateway:experimental:description> 
		 Support: Core
		"""

												maxLength: 63
												minLength: 1
												pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
												type:      "string"
											}
											port: {
												description: """
		Port is the network port this Route targets. It can be interpreted differently based on the type of parent resource. 
		 When the parent resource is a Gateway, this targets all listeners listening on the specified port that also support this kind of Route(and select this Route). It's not recommended to set `Port` unless the networking behaviors specified in a Route must apply to a specific port as opposed to a listener(s) whose port(s) may be changed. When both Port and SectionName are specified, the name and port of the selected listener must match both specified values. 
		 <gateway:experimental:description> When the parent resource is a Service, this targets a specific port in the Service spec. When both Port (experimental) and SectionName are specified, the name and port of the selected port must match both specified values. </gateway:experimental:description> 
		 Implementations MAY choose to support other parent resources. Implementations supporting other types of parent resources MUST clearly document how/if Port is interpreted. 
		 For the purpose of status, an attachment is considered successful as long as the parent resource accepts it partially. For example, Gateway listeners can restrict which Routes can attach to them by Route kind, namespace, or hostname. If 1 of 2 Gateway listeners accept attachment from the referencing Route, the Route MUST be considered successfully attached. If no Gateway listeners accept attachment from this Route, the Route MUST be considered detached from the Gateway. 
		 Support: Extended 
		 <gateway:experimental>
		"""

												format:  "int32"
												maximum: 65535
												minimum: 1
												type:    "integer"
											}
											sectionName: {
												description: """
		SectionName is the name of a section within the target resource. In the following resources, SectionName is interpreted as the following: 
		 * Gateway: Listener Name. When both Port (experimental) and SectionName are specified, the name and port of the selected listener must match both specified values. * Service: Port Name. When both Port (experimental) and SectionName are specified, the name and port of the selected listener must match both specified values. Note that attaching Routes to Services as Parents is part of experimental Mesh support and is not supported for any other purpose. 
		 Implementations MAY choose to support attaching Routes to other resources. If that is the case, they MUST clearly document how SectionName is interpreted. 
		 When unspecified (empty string), this will reference the entire resource. For the purpose of status, an attachment is considered successful if at least one section in the parent resource accepts it. For example, Gateway listeners can restrict which Routes can attach to them by Route kind, namespace, or hostname. If 1 of 2 Gateway listeners accept attachment from the referencing Route, the Route MUST be considered successfully attached. If no Gateway listeners accept attachment from this Route, the Route MUST be considered detached from the Gateway. 
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
											description: """
		Condition contains details for one aspect of the current state of this API Resource. --- This struct is intended for direct use as an array at the field path .status.conditions.  For example, 
		 type FooStatus struct{ // Represents the observations of a foo's current state. // Known .status.conditions.type are: \"Available\", \"Progressing\", and \"Degraded\" // +patchMergeKey=type // +patchStrategy=merge // +listType=map // +listMapKey=type Conditions []metav1.Condition `json:\"conditions,omitempty\" patchStrategy:\"merge\" patchMergeKey:\"type\" protobuf:\"bytes,1,rep,name=conditions\"` 
		 // other fields }
		"""

											properties: {
												lastTransitionTime: {
													description: "lastTransitionTime is the last time the condition transitioned from one status to another. This should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable."

													format: "date-time"
													type:   "string"
												}
												message: {
													description: "message is a human readable message indicating details about the transition. This may be an empty string."

													maxLength: 32768
													type:      "string"
												}
												observedGeneration: {
													description: "observedGeneration represents the .metadata.generation that the condition was set based upon. For instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date with respect to the current state of the instance."

													format:  "int64"
													minimum: 0
													type:    "integer"
												}
												reason: {
													description: "reason contains a programmatic identifier indicating the reason for the condition's last transition. Producers of specific condition types may define expected values and meanings for this field, and whether the values are considered a guaranteed API. The value should be a CamelCase string. This field may not be empty."

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
													description: "type of condition in CamelCase or in foo.example.com/CamelCase. --- Many .condition.type values are consistent across resources like Available, but because arbitrary conditions can be useful (see .node.status.conditions), the ability to deconflict is important. The regex it matches is (dns1123SubdomainFmt/)?(qualifiedNameFmt)"

													maxLength: 316
													pattern:   "^([a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*/)?(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])$"
													type:      "string"
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
		ControllerName is a domain/path string that indicates the name of the controller that wrote this status. This corresponds with the controllerName field on GatewayClass. 
		 Example: \"example.net/gateway-controller\". 
		 The format of this field is DOMAIN \"/\" PATH, where DOMAIN and PATH are valid Kubernetes names (https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names). 
		 Controllers MUST populate this field when writing status. Controllers should ensure that entries to status populated with their ControllerName are cleaned up when they are no longer necessary.
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
