package deploy

k8s: "apiextensions.k8s.io": v1: CustomResourceDefinition: "": "clienttrafficpolicies.gateway.envoyproxy.io": {
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: {
		annotations: "controller-gen.kubebuilder.io/version": "v0.16.1"
		name: "clienttrafficpolicies.gateway.envoyproxy.io"
	}
	spec: {
		group: "gateway.envoyproxy.io"
		names: {
			categories: ["envoy-gateway"]
			kind:     "ClientTrafficPolicy"
			listKind: "ClientTrafficPolicyList"
			plural:   "clienttrafficpolicies"
			shortNames: ["ctp"]
			singular: "clienttrafficpolicy"
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
				description: """
					ClientTrafficPolicy allows the user to configure the behavior of the connection
					between the downstream client and Envoy Proxy listener.
					"""
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
						description: "Spec defines the desired state of ClientTrafficPolicy."
						properties: {
							clientIPDetection: {
								description: "ClientIPDetectionSettings provides configuration for determining the original client IP address for requests."
								properties: {
									customHeader: {
										description: """
	CustomHeader provides configuration for determining the client IP address for a request based on
	a trusted custom HTTP header. This uses the custom_header original IP detection extension.
	Refer to https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/http/original_ip_detection/custom_header/v3/custom_header.proto
	for more details.
	"""
										properties: {
											failClosed: {
												description: """
	FailClosed is a switch used to control the flow of traffic when client IP detection
	fails. If set to true, the listener will respond with 403 Forbidden when the client
	IP address cannot be determined.
	"""
												type: "boolean"
											}
											name: {
												description: "Name of the header containing the original downstream remote address, if present."
												maxLength:   255
												minLength:   1
												pattern:     "^[A-Za-z0-9-]+$"
												type:        "string"
											}
										}
										required: ["name"]
										type: "object"
									}
									xForwardedFor: {
										description: "XForwardedForSettings provides configuration for using X-Forwarded-For headers for determining the client IP address."
										properties: numTrustedHops: {
											description: """
	NumTrustedHops controls the number of additional ingress proxy hops from the right side of XFF HTTP
	headers to trust when determining the origin client's IP address.
	Refer to https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-for
	for more details.
	"""
											format: "int32"
											type:   "integer"
										}
										type: "object"
									}
								}
								type: "object"
								"x-kubernetes-validations": [{
									message: "customHeader cannot be used in conjunction with xForwardedFor"
									rule:    "!(has(self.xForwardedFor) && has(self.customHeader))"
								}]
							}
							connection: {
								description: "Connection includes client connection settings."
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
	BufferLimit provides configuration for the maximum buffer size in bytes for each incoming connection.
	BufferLimit applies to connection streaming (maybe non-streaming) channel between processes, it's in user space.
	For example, 20Mi, 1Gi, 256Ki etc.
	Note that when the suffix is not provided, the value is interpreted as bytes.
	Default: 32768 bytes.
	"""
										"x-kubernetes-int-or-string": true
									}
									connectionLimit: {
										description: "ConnectionLimit defines limits related to connections"
										properties: {
											closeDelay: {
												description: """
	CloseDelay defines the delay to use before closing connections that are rejected
	once the limit value is reached.
	Default: none.
	"""
												pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
												type:    "string"
											}
											value: {
												description: """
	Value of the maximum concurrent connections limit.
	When the limit is reached, incoming connections will be closed after the CloseDelay duration.
	"""
												format:  "int64"
												minimum: 1
												type:    "integer"
											}
										}
										required: ["value"]
										type: "object"
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
	SocketBufferLimit provides configuration for the maximum buffer size in bytes for each incoming socket.
	SocketBufferLimit applies to socket streaming channel between TCP/IP stacks, it's in kernel space.
	For example, 20Mi, 1Gi, 256Ki etc.
	Note that when the suffix is not provided, the value is interpreted as bytes.
	"""
										"x-kubernetes-int-or-string": true
									}
								}
								type: "object"
							}
							enableProxyProtocol: {
								description: """
	EnableProxyProtocol interprets the ProxyProtocol header and adds the
	Client Address into the X-Forwarded-For header.
	Note Proxy Protocol must be present when this field is set, else the connection
	is closed.
	"""
								type: "boolean"
							}
							headers: {
								description: "HeaderSettings provides configuration for header management."
								properties: {
									disableRateLimitHeaders: {
										description: """
	DisableRateLimitHeaders configures Envoy Proxy to omit the "X-RateLimit-" response headers
	when rate limiting is enabled.
	"""
										type: "boolean"
									}
									earlyRequestHeaders: {
										description: """
	EarlyRequestHeaders defines settings for early request header modification, before envoy performs
	routing, tracing and built-in header manipulation.
	"""
										properties: {
											add: {
												description: """
	Add adds the given header(s) (name, value) to the request
	before the action. It appends to any existing values associated
	with the header name.

	Input:
	  GET /foo HTTP/1.1
	  my-header: foo

	Config:
	  add:
	  - name: "my-header"
	    value: "bar,baz"

	Output:
	  GET /foo HTTP/1.1
	  my-header: foo,bar,baz
	"""
												items: {
													description: "HTTPHeader represents an HTTP Header name and value as defined by RFC 7230."
													properties: {
														name: {
															description: """
	Name is the name of the HTTP Header to be matched. Name matching MUST be
	case insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).

	If multiple entries specify equivalent header names, the first entry with
	an equivalent name MUST be considered for a match. Subsequent entries
	with an equivalent header name MUST be ignored. Due to the
	case-insensitivity of header names, "foo" and "Foo" are considered
	equivalent.
	"""
															maxLength: 256
															minLength: 1
															pattern:   "^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
															type:      "string"
														}
														value: {
															description: "Value is the value of HTTP Header to be matched."
															maxLength:   4096
															minLength:   1
															type:        "string"
														}
													}
													required: [
														"name",
														"value",
													]
													type: "object"
												}
												maxItems: 16
												type:     "array"
												"x-kubernetes-list-map-keys": ["name"]
												"x-kubernetes-list-type": "map"
											}
											remove: {
												description: """
	Remove the given header(s) from the HTTP request before the action. The
	value of Remove is a list of HTTP header names. Note that the header
	names are case-insensitive (see
	https://datatracker.ietf.org/doc/html/rfc2616#section-4.2).

	Input:
	  GET /foo HTTP/1.1
	  my-header1: foo
	  my-header2: bar
	  my-header3: baz

	Config:
	  remove: ["my-header1", "my-header3"]

	Output:
	  GET /foo HTTP/1.1
	  my-header2: bar
	"""
												items: type: "string"
												maxItems:                 16
												type:                     "array"
												"x-kubernetes-list-type": "set"
											}
											set: {
												description: """
	Set overwrites the request with the given header (name, value)
	before the action.

	Input:
	  GET /foo HTTP/1.1
	  my-header: foo

	Config:
	  set:
	  - name: "my-header"
	    value: "bar"

	Output:
	  GET /foo HTTP/1.1
	  my-header: bar
	"""
												items: {
													description: "HTTPHeader represents an HTTP Header name and value as defined by RFC 7230."
													properties: {
														name: {
															description: """
	Name is the name of the HTTP Header to be matched. Name matching MUST be
	case insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).

	If multiple entries specify equivalent header names, the first entry with
	an equivalent name MUST be considered for a match. Subsequent entries
	with an equivalent header name MUST be ignored. Due to the
	case-insensitivity of header names, "foo" and "Foo" are considered
	equivalent.
	"""
															maxLength: 256
															minLength: 1
															pattern:   "^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
															type:      "string"
														}
														value: {
															description: "Value is the value of HTTP Header to be matched."
															maxLength:   4096
															minLength:   1
															type:        "string"
														}
													}
													required: [
														"name",
														"value",
													]
													type: "object"
												}
												maxItems: 16
												type:     "array"
												"x-kubernetes-list-map-keys": ["name"]
												"x-kubernetes-list-type": "map"
											}
										}
										type: "object"
									}
									enableEnvoyHeaders: {
										description: """
	EnableEnvoyHeaders configures Envoy Proxy to add the "X-Envoy-" headers to requests
	and responses.
	"""
										type: "boolean"
									}
									preserveXRequestID: {
										description: """
	PreserveXRequestID configures Envoy to keep the X-Request-ID header if passed for a request that is edge
	(Edge request is the request from external clients to front Envoy) and not reset it, which is the current Envoy behaviour.
	It defaults to false.
	"""
										type: "boolean"
									}
									withUnderscoresAction: {
										description: """
	WithUnderscoresAction configures the action to take when an HTTP header with underscores
	is encountered. The default action is to reject the request.
	"""
										enum: [
											"Allow",
											"RejectRequest",
											"DropHeader",
										]
										type: "string"
									}
									xForwardedClientCert: {
										description: """
	XForwardedClientCert configures how Envoy Proxy handle the x-forwarded-client-cert (XFCC) HTTP header.

	x-forwarded-client-cert (XFCC) is an HTTP header used to forward the certificate
	information of part or all of the clients or proxies that a request has flowed through,
	on its way from the client to the server.

	Envoy proxy may choose to sanitize/append/forward the XFCC header before proxying the request.

	If not set, the default behavior is sanitizing the XFCC header.
	"""
										properties: {
											certDetailsToAdd: {
												description: """
	CertDetailsToAdd specifies the fields in the client certificate to be forwarded in the XFCC header.

	Hash(the SHA 256 digest of the current client certificate) and By(the Subject Alternative Name)
	are always included if the client certificate is forwarded.

	This field is only applicable when the mode is set to `AppendForward` or
	`SanitizeSet` and the client connection is mTLS.
	"""
												items: {
													description: "XFCCCertData specifies the fields in the client certificate to be forwarded in the XFCC header."
													enum: [
														"Subject",
														"Cert",
														"Chain",
														"DNS",
														"URI",
													]
													type: "string"
												}
												maxItems: 5
												type:     "array"
											}
											mode: {
												description: """
	Mode defines how XFCC header is handled by Envoy Proxy.
	If not set, the default mode is `Sanitize`.
	"""
												enum: [
													"Sanitize",
													"ForwardOnly",
													"AppendForward",
													"SanitizeSet",
													"AlwaysForwardOnly",
												]
												type: "string"
											}
										}
										type: "object"
										"x-kubernetes-validations": [{
											message: "certDetailsToAdd can only be set when mode is AppendForward or SanitizeSet"
											rule:    "(has(self.certDetailsToAdd) && self.certDetailsToAdd.size() > 0) ? (self.mode == 'AppendForward' || self.mode == 'SanitizeSet') : true"
										}]
									}
								}
								type: "object"
							}
							healthCheck: {
								description: "HealthCheck provides configuration for determining whether the HTTP/HTTPS listener is healthy."
								properties: path: {
									description: "Path specifies the HTTP path to match on for health check requests."
									maxLength:   1024
									minLength:   1
									type:        "string"
								}
								required: ["path"]
								type: "object"
							}
							http1: {
								description: "HTTP1 provides HTTP/1 configuration on the listener."
								properties: {
									enableTrailers: {
										description: "EnableTrailers defines if HTTP/1 trailers should be proxied by Envoy."
										type:        "boolean"
									}
									http10: {
										description: "HTTP10 turns on support for HTTP/1.0 and HTTP/0.9 requests."
										properties: useDefaultHost: {
											description: """
	UseDefaultHost defines if the HTTP/1.0 request is missing the Host header,
	then the hostname associated with the listener should be injected into the
	request.
	If this is not set and an HTTP/1.0 request arrives without a host, then
	it will be rejected.
	"""
											type: "boolean"
										}
										type: "object"
									}
									preserveHeaderCase: {
										description: """
	PreserveHeaderCase defines if Envoy should preserve the letter case of headers.
	By default, Envoy will lowercase all the headers.
	"""
										type: "boolean"
									}
								}
								type: "object"
							}
							http2: {
								description: "HTTP2 provides HTTP/2 configuration on the listener."
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
							http3: {
								description: "HTTP3 provides HTTP/3 configuration on the listener."
								type:        "object"
							}
							path: {
								description: "Path enables managing how the incoming path set by clients can be normalized."
								properties: {
									disableMergeSlashes: {
										description: """
	DisableMergeSlashes allows disabling the default configuration of merging adjacent
	slashes in the path.
	Note that slash merging is not part of the HTTP spec and is provided for convenience.
	"""
										type: "boolean"
									}
									escapedSlashesAction: {
										description: """
	EscapedSlashesAction determines how %2f, %2F, %5c, or %5C sequences in the path URI
	should be handled.
	The default is UnescapeAndRedirect.
	"""
										enum: [
											"KeepUnchanged",
											"RejectRequest",
											"UnescapeAndForward",
											"UnescapeAndRedirect",
										]
										type: "string"
									}
								}
								type: "object"
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
							tcpKeepalive: {
								description: """
	TcpKeepalive settings associated with the downstream client connection.
	If defined, sets SO_KEEPALIVE on the listener socket to enable TCP Keepalives.
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
								description: "Timeout settings for the client connections."
								properties: {
									http: {
										description: "Timeout settings for HTTP."
										properties: {
											idleTimeout: {
												description: """
	IdleTimeout for an HTTP connection. Idle time is defined as a period in which there are no active requests in the connection.
	Default: 1 hour.
	"""
												pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
												type:    "string"
											}
											requestReceivedTimeout: {
												description: """
	RequestReceivedTimeout is the duration envoy waits for the complete request reception. This timer starts upon request
	initiation and stops when either the last byte of the request is sent upstream or when the response begins.
	"""
												pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
												type:    "string"
											}
										}
										type: "object"
									}
									tcp: {
										description: "Timeout settings for TCP."
										properties: idleTimeout: {
											description: """
	IdleTimeout for a TCP connection. Idle time is defined as a period in which there are no
	bytes sent or received on either the upstream or downstream connection.
	Default: 1 hour.
	"""
											pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
											type:    "string"
										}
										type: "object"
									}
								}
								type: "object"
							}
							tls: {
								description: "TLS settings configure TLS termination settings with the downstream client."
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
									clientValidation: {
										description: """
	ClientValidation specifies the configuration to validate the client
	initiating the TLS connection to the Gateway listener.
	"""
										properties: {
											caCertificateRefs: {
												description: """
	CACertificateRefs contains one or more references to
	Kubernetes objects that contain TLS certificates of
	the Certificate Authorities that can be used
	as a trust anchor to validate the certificates presented by the client.

	A single reference to a Kubernetes ConfigMap or a Kubernetes Secret,
	with the CA certificate in a key named `ca.crt` is currently supported.

	References to a resource in different namespace are invalid UNLESS there
	is a ReferenceGrant in the target namespace that allows the certificate
	to be attached.
	"""
												items: {
													description: """
	SecretObjectReference identifies an API object including its namespace,
	defaulting to Secret.

	The API object must be valid in the cluster; the Group and Kind must
	be registered in the cluster for this reference to be valid.

	References to objects with invalid Group and Kind are not valid, and must
	be rejected by the implementation, with appropriate Conditions set
	on the containing object.
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
												maxItems: 8
												type:     "array"
											}
											optional: {
												description: """
	Optional set to true accepts connections even when a client doesn't present a certificate.
	Defaults to false, which rejects connections without a valid client certificate.
	"""
												type: "boolean"
											}
										}
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
									session: {
										description: "Session defines settings related to TLS session management."
										properties: resumption: {
											description: """
	Resumption determines the proxy's supported TLS session resumption option.
	By default, Envoy Gateway does not enable session resumption. Use sessionResumption to
	enable stateful and stateless session resumption. Users should consider security impacts
	of different resumption methods. Performance gains from resumption are diminished when
	Envoy proxy is deployed with more than one replica.
	"""
											properties: {
												stateful: {
													description: "Stateful defines setting for stateful (session-id based) session resumption"
													type:        "object"
												}
												stateless: {
													description: "Stateless defines setting for stateless (session-ticket based) session resumption"
													type:        "object"
												}
											}
											type: "object"
										}
										type: "object"
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
						}
						type: "object"
						"x-kubernetes-validations": [{
							message: "either targetRef or targetRefs must be used"
							rule:    "(has(self.targetRef) && !has(self.targetRefs)) || (!has(self.targetRef) && has(self.targetRefs)) || (has(self.targetSelectors) && self.targetSelectors.size() > 0) "
						}, {
							message: "this policy can only have a targetRef.group of gateway.networking.k8s.io"
							rule:    "has(self.targetRef) ? self.targetRef.group == 'gateway.networking.k8s.io' : true"
						}, {
							message: "this policy can only have a targetRef.kind of Gateway"
							rule:    "has(self.targetRef) ? self.targetRef.kind == 'Gateway' : true"
						}, {
							message: "this policy can only have a targetRefs[*].group of gateway.networking.k8s.io"
							rule:    "has(self.targetRefs) ? self.targetRefs.all(ref, ref.group == 'gateway.networking.k8s.io') : true"
						}, {
							message: "this policy can only have a targetRefs[*].kind of Gateway"
							rule:    "has(self.targetRefs) ? self.targetRefs.all(ref, ref.kind == 'Gateway') : true"
						}]
					}
					status: {
						description: "Status defines the current status of ClientTrafficPolicy."
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
