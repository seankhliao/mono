package deploy

k8s: "apiextensions.k8s.io": v1: CustomResourceDefinition: "": "grpcroutes.gateway.networking.k8s.io": {
	//
	// config/crd/experimental/gateway.networking.k8s.io_grpcroutes.yaml
	//
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: {
		annotations: {
			"api-approved.kubernetes.io":               "https://github.com/kubernetes-sigs/gateway-api/pull/3328"
			"gateway.networking.k8s.io/bundle-version": "v1.2.1"
			"gateway.networking.k8s.io/channel":        "experimental"
		}
		name: "grpcroutes.gateway.networking.k8s.io"
	}
	spec: {
		group: "gateway.networking.k8s.io"
		names: {
			categories: ["gateway-api"]
			kind:     "GRPCRoute"
			listKind: "GRPCRouteList"
			plural:   "grpcroutes"
			singular: "grpcroute"
		}
		scope: "Namespaced"
		versions: [{
			additionalPrinterColumns: [{
				jsonPath: ".spec.hostnames"
				name:     "Hostnames"
				type:     "string"
			}, {
				jsonPath: ".metadata.creationTimestamp"
				name:     "Age"
				type:     "date"
			}]
			name: "v1"
			schema: openAPIV3Schema: {
				description: """
					GRPCRoute provides a way to route gRPC requests. This includes the capability
					to match requests by hostname, gRPC service, gRPC method, or HTTP/2 header.
					Filters can be used to specify additional processing steps. Backends specify
					where matching requests will be routed.

					GRPCRoute falls under extended support within the Gateway API. Within the
					following specification, the word "MUST" indicates that an implementation
					supporting GRPCRoute must conform to the indicated requirement, but an
					implementation not supporting this route type need not follow the requirement
					unless explicitly indicated.

					Implementations supporting `GRPCRoute` with the `HTTPS` `ProtocolType` MUST
					accept HTTP/2 connections without an initial upgrade from HTTP/1.1, i.e. via
					ALPN. If the implementation does not support this, then it MUST set the
					"Accepted" condition to "False" for the affected listener with a reason of
					"UnsupportedProtocol".  Implementations MAY also accept HTTP/2 connections
					with an upgrade from HTTP/1.

					Implementations supporting `GRPCRoute` with the `HTTP` `ProtocolType` MUST
					support HTTP/2 over cleartext TCP (h2c,
					https://www.rfc-editor.org/rfc/rfc7540#section-3.1) without an initial
					upgrade from HTTP/1.1, i.e. with prior knowledge
					(https://www.rfc-editor.org/rfc/rfc7540#section-3.4). If the implementation
					does not support this, then it MUST set the "Accepted" condition to "False"
					for the affected listener with a reason of "UnsupportedProtocol".
					Implementations MAY also accept HTTP/2 connections with an upgrade from
					HTTP/1, i.e. without prior knowledge.
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
						description: "Spec defines the desired state of GRPCRoute."
						properties: {
							hostnames: {
								description: """
	Hostnames defines a set of hostnames to match against the GRPC
	Host header to select a GRPCRoute to process the request. This matches
	the RFC 1123 definition of a hostname with 2 notable exceptions:

	1. IPs are not allowed.
	2. A hostname may be prefixed with a wildcard label (`*.`). The wildcard
	   label MUST appear by itself as the first label.

	If a hostname is specified by both the Listener and GRPCRoute, there
	MUST be at least one intersecting hostname for the GRPCRoute to be
	attached to the Listener. For example:

	* A Listener with `test.example.com` as the hostname matches GRPCRoutes
	  that have either not specified any hostnames, or have specified at
	  least one of `test.example.com` or `*.example.com`.
	* A Listener with `*.example.com` as the hostname matches GRPCRoutes
	  that have either not specified any hostnames or have specified at least
	  one hostname that matches the Listener hostname. For example,
	  `test.example.com` and `*.example.com` would both match. On the other
	  hand, `example.com` and `test.example.net` would not match.

	Hostnames that are prefixed with a wildcard label (`*.`) are interpreted
	as a suffix match. That means that a match for `*.example.com` would match
	both `test.example.com`, and `foo.test.example.com`, but not `example.com`.

	If both the Listener and GRPCRoute have specified hostnames, any
	GRPCRoute hostnames that do not match the Listener hostname MUST be
	ignored. For example, if a Listener specified `*.example.com`, and the
	GRPCRoute specified `test.example.com` and `test.example.net`,
	`test.example.net` MUST NOT be considered for a match.

	If both the Listener and GRPCRoute have specified hostnames, and none
	match with the criteria above, then the GRPCRoute MUST NOT be accepted by
	the implementation. The implementation MUST raise an 'Accepted' Condition
	with a status of `False` in the corresponding RouteParentStatus.

	If a Route (A) of type HTTPRoute or GRPCRoute is attached to a
	Listener and that listener already has another Route (B) of the other
	type attached and the intersection of the hostnames of A and B is
	non-empty, then the implementation MUST accept exactly one of these two
	routes, determined by the following criteria, in order:

	* The oldest Route based on creation timestamp.
	* The Route appearing first in alphabetical order by
	  "{namespace}/{name}".

	The rejected Route MUST raise an 'Accepted' condition with a status of
	'False' in the corresponding RouteParentStatus.

	Support: Core
	"""
								items: {
									description: """
	Hostname is the fully qualified domain name of a network host. This matches
	the RFC 1123 definition of a hostname with 2 notable exceptions:

	 1. IPs are not allowed.
	 2. A hostname may be prefixed with a wildcard label (`*.`). The wildcard
	    label must appear by itself as the first label.

	Hostname can be "precise" which is a domain name without the terminating
	dot of a network host (e.g. "foo.example.com") or "wildcard", which is a
	domain name prefixed with a single wildcard label (e.g. `*.example.com`).

	Note that as per RFC1035 and RFC1123, a *label* must consist of lower case
	alphanumeric characters or '-', and must start and end with an alphanumeric
	character. No other punctuation is allowed.
	"""
									maxLength: 253
									minLength: 1
									pattern:   "^(\\*\\.)?[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
									type:      "string"
								}
								maxItems: 16
								type:     "array"
							}
							parentRefs: {
								description: """
	ParentRefs references the resources (usually Gateways) that a Route wants
	to be attached to. Note that the referenced parent resource needs to
	allow this for the attachment to be complete. For Gateways, that means
	the Gateway needs to allow attachment from Routes of this kind and
	namespace. For Services, that means the Service must either be in the same
	namespace for a "producer" route, or the mesh implementation must support
	and allow "consumer" routes for the referenced Service. ReferenceGrant is
	not applicable for governing ParentRefs to Services - it is not possible to
	create a "producer" route for a Service in a different namespace from the
	Route.

	There are two kinds of parent resources with "Core" support:

	* Gateway (Gateway conformance profile)
	* Service (Mesh conformance profile, ClusterIP Services only)

	This API may be extended in the future to support additional kinds of parent
	resources.

	ParentRefs must be _distinct_. This means either that:

	* They select different objects.  If this is the case, then parentRef
	  entries are distinct. In terms of fields, this means that the
	  multi-part key defined by `group`, `kind`, `namespace`, and `name` must
	  be unique across all parentRef entries in the Route.
	* They do not select different objects, but for each optional field used,
	  each ParentRef that selects the same object must set the same set of
	  optional fields to different values. If one ParentRef sets a
	  combination of optional fields, all must set the same combination.

	Some examples:

	* If one ParentRef sets `sectionName`, all ParentRefs referencing the
	  same object must also set `sectionName`.
	* If one ParentRef sets `port`, all ParentRefs referencing the same
	  object must also set `port`.
	* If one ParentRef sets `sectionName` and `port`, all ParentRefs
	  referencing the same object must also set `sectionName` and `port`.

	It is possible to separately reference multiple distinct objects that may
	be collapsed by an implementation. For example, some implementations may
	choose to merge compatible Gateway Listeners together. If that is the
	case, the list of routes attached to those resources should also be
	merged.

	Note that for ParentRefs that cross namespace boundaries, there are specific
	rules. Cross-namespace references are only valid if they are explicitly
	allowed by something in the namespace they are referring to. For example,
	Gateway has the AllowedRoutes field, and ReferenceGrant provides a
	generic way to enable other kinds of cross-namespace reference.


	ParentRefs from a Route to a Service in the same namespace are "producer"
	routes, which apply default routing rules to inbound connections from
	any namespace to the Service.

	ParentRefs from a Route to a Service in a different namespace are
	"consumer" routes, and these routing rules are only applied to outbound
	connections originating from the same namespace as the Route, for which
	the intended destination of the connections are a Service targeted as a
	ParentRef of the Route.






	"""
								items: {
									description: """
	ParentReference identifies an API object (usually a Gateway) that can be considered
	a parent of this resource (usually a route). There are two kinds of parent resources
	with "Core" support:

	* Gateway (Gateway conformance profile)
	* Service (Mesh conformance profile, ClusterIP Services only)

	This API may be extended in the future to support additional kinds of parent
	resources.

	The API object must be valid in the cluster; the Group and Kind must
	be registered in the cluster for this reference to be valid.
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


	ParentRefs from a Route to a Service in the same namespace are "producer"
	routes, which apply default routing rules to inbound connections from
	any namespace to the Service.

	ParentRefs from a Route to a Service in a different namespace are
	"consumer" routes, and these routing rules are only applied to outbound
	connections originating from the same namespace as the Route, for which
	the intended destination of the connections are a Service targeted as a
	ParentRef of the Route.


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


	When the parent resource is a Service, this targets a specific port in the
	Service spec. When both Port (experimental) and SectionName are specified,
	the name and port of the selected port must match both specified values.


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
								maxItems: 32
								type:     "array"
								"x-kubernetes-validations": [{
									message: "sectionName or port must be specified when parentRefs includes 2 or more references to the same parent"
									rule:    "self.all(p1, self.all(p2, p1.group == p2.group && p1.kind == p2.kind && p1.name == p2.name && (((!has(p1.__namespace__) || p1.__namespace__ == '') && (!has(p2.__namespace__) || p2.__namespace__ == '')) || (has(p1.__namespace__) && has(p2.__namespace__) && p1.__namespace__ == p2.__namespace__)) ? ((!has(p1.sectionName) || p1.sectionName == '') == (!has(p2.sectionName) || p2.sectionName == '') && (!has(p1.port) || p1.port == 0) == (!has(p2.port) || p2.port == 0)): true))"
								}, {
									message: "sectionName or port must be unique when parentRefs includes 2 or more references to the same parent"
									rule:    "self.all(p1, self.exists_one(p2, p1.group == p2.group && p1.kind == p2.kind && p1.name == p2.name && (((!has(p1.__namespace__) || p1.__namespace__ == '') && (!has(p2.__namespace__) || p2.__namespace__ == '')) || (has(p1.__namespace__) && has(p2.__namespace__) && p1.__namespace__ == p2.__namespace__ )) && (((!has(p1.sectionName) || p1.sectionName == '') && (!has(p2.sectionName) || p2.sectionName == '')) || ( has(p1.sectionName) && has(p2.sectionName) && p1.sectionName == p2.sectionName)) && (((!has(p1.port) || p1.port == 0) && (!has(p2.port) || p2.port == 0)) || (has(p1.port) && has(p2.port) && p1.port == p2.port))))"
								}]
							}
							rules: {
								description: """
	Rules are a list of GRPC matchers, filters and actions.


	"""
								items: {
									description: """
	GRPCRouteRule defines the semantics for matching a gRPC request based on
	conditions (matches), processing it (filters), and forwarding the request to
	an API object (backendRefs).
	"""
									properties: {
										backendRefs: {
											description: """
	BackendRefs defines the backend(s) where matching requests should be
	sent.

	Failure behavior here depends on how many BackendRefs are specified and
	how many are invalid.

	If *all* entries in BackendRefs are invalid, and there are also no filters
	specified in this route rule, *all* traffic which matches this rule MUST
	receive an `UNAVAILABLE` status.

	See the GRPCBackendRef definition for the rules about what makes a single
	GRPCBackendRef invalid.

	When a GRPCBackendRef is invalid, `UNAVAILABLE` statuses MUST be returned for
	requests that would have otherwise been routed to an invalid backend. If
	multiple backends are specified, and some are invalid, the proportion of
	requests that would otherwise have been routed to an invalid backend
	MUST receive an `UNAVAILABLE` status.

	For example, if two backends are specified with equal weights, and one is
	invalid, 50 percent of traffic MUST receive an `UNAVAILABLE` status.
	Implementations may choose how that 50 percent is determined.

	Support: Core for Kubernetes Service

	Support: Implementation-specific for any other resource

	Support for weight: Core
	"""
											items: {
												description: """
	GRPCBackendRef defines how a GRPCRoute forwards a gRPC request.

	Note that when a namespace different than the local namespace is specified, a
	ReferenceGrant object is required in the referent namespace to allow that
	namespace's owner to accept the reference. See the ReferenceGrant
	documentation for details.

	<gateway:experimental:description>

	When the BackendRef points to a Kubernetes Service, implementations SHOULD
	honor the appProtocol field if it is set for the target Service Port.

	Implementations supporting appProtocol SHOULD recognize the Kubernetes
	Standard Application Protocols defined in KEP-3726.

	If a Service appProtocol isn't specified, an implementation MAY infer the
	backend protocol through its own means. Implementations MAY infer the
	protocol from the Route type referring to the backend Service.

	If a Route is not able to send traffic to the backend using the specified
	protocol then the backend is considered invalid. Implementations MUST set the
	"ResolvedRefs" condition to "False" with the "UnsupportedProtocol" reason.

	</gateway:experimental:description>
	"""
												properties: {
													filters: {
														description: """
	Filters defined at this level MUST be executed if and only if the
	request is being forwarded to the backend defined here.

	Support: Implementation-specific (For broader support of filters, use the
	Filters field in GRPCRouteRule.)
	"""
														items: {
															description: """
	GRPCRouteFilter defines processing steps that must be completed during the
	request or response lifecycle. GRPCRouteFilters are meant as an extension
	point to express processing that may be done in Gateway implementations. Some
	examples include request or response modification, implementing
	authentication strategies, rate-limiting, and traffic shaping. API
	guarantee/conformance is defined based on the type of the filter.
	"""
															properties: {
																extensionRef: {
																	description: """
	ExtensionRef is an optional, implementation-specific extension to the
	"filter" behavior.  For example, resource "myroutefilter" in group
	"networking.example.net"). ExtensionRef MUST NOT be used for core and
	extended filters.

	Support: Implementation-specific

	This filter can be used multiple times within the same rule.
	"""
																	properties: {
																		group: {
																			description: """
	Group is the group of the referent. For example, "gateway.networking.k8s.io".
	When unspecified or empty string, core API group is inferred.
	"""
																			maxLength: 253
																			pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																			type:      "string"
																		}
																		kind: {
																			description: "Kind is kind of the referent. For example \"HTTPRoute\" or \"Service\"."
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
																	}
																	required: [
																		"group",
																		"kind",
																		"name",
																	]
																	type: "object"
																}
																requestHeaderModifier: {
																	description: """
	RequestHeaderModifier defines a schema for a filter that modifies request
	headers.

	Support: Core
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
																requestMirror: {
																	description: """
	RequestMirror defines a schema for a filter that mirrors requests.
	Requests are sent to the specified destination, but responses from
	that destination are ignored.

	This filter can be used multiple times within the same rule. Note that
	not all implementations will be able to support mirroring to multiple
	backends.

	Support: Extended


	"""
																	properties: {
																		backendRef: {
																			description: """
	BackendRef references a resource where mirrored requests are sent.

	Mirrored requests must be sent only to a single destination endpoint
	within this BackendRef, irrespective of how many endpoints are present
	within this BackendRef.

	If the referent cannot be found, this BackendRef is invalid and must be
	dropped from the Gateway. The controller must ensure the "ResolvedRefs"
	condition on the Route status is set to `status: False` and not configure
	this backend in the underlying implementation.

	If there is a cross-namespace reference to an *existing* object
	that is not allowed by a ReferenceGrant, the controller must ensure the
	"ResolvedRefs"  condition on the Route is set to `status: False`,
	with the "RefNotPermitted" reason and not configure this backend in the
	underlying implementation.

	In either error case, the Message of the `ResolvedRefs` Condition
	should be used to provide more detail about the problem.

	Support: Extended for Kubernetes Service

	Support: Implementation-specific for any other resource
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
																		fraction: {
																			description: """
	Fraction represents the fraction of requests that should be
	mirrored to BackendRef.

	Only one of Fraction or Percent may be specified. If neither field
	is specified, 100% of requests will be mirrored.


	"""
																			properties: {
																				denominator: {
																					default: 100
																					format:  "int32"
																					minimum: 1
																					type:    "integer"
																				}
																				numerator: {
																					format:  "int32"
																					minimum: 0
																					type:    "integer"
																				}
																			}
																			required: ["numerator"]
																			type: "object"
																			"x-kubernetes-validations": [{
																				message: "numerator must be less than or equal to denominator"
																				rule:    "self.numerator <= self.denominator"
																			}]
																		}
																		percent: {
																			description: """
	Percent represents the percentage of requests that should be
	mirrored to BackendRef. Its minimum value is 0 (indicating 0% of
	requests) and its maximum value is 100 (indicating 100% of requests).

	Only one of Fraction or Percent may be specified. If neither field
	is specified, 100% of requests will be mirrored.


	"""
																			format:  "int32"
																			maximum: 100
																			minimum: 0
																			type:    "integer"
																		}
																	}
																	required: ["backendRef"]
																	type: "object"
																	"x-kubernetes-validations": [{
																		message: "Only one of percent or fraction may be specified in HTTPRequestMirrorFilter"
																		rule:    "!(has(self.percent) && has(self.fraction))"
																	}]
																}
																responseHeaderModifier: {
																	description: """
	ResponseHeaderModifier defines a schema for a filter that modifies response
	headers.

	Support: Extended
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
																type: {
																	description: """
	Type identifies the type of filter to apply. As with other API fields,
	types are classified into three conformance levels:

	- Core: Filter types and their corresponding configuration defined by
	  "Support: Core" in this package, e.g. "RequestHeaderModifier". All
	  implementations supporting GRPCRoute MUST support core filters.

	- Extended: Filter types and their corresponding configuration defined by
	  "Support: Extended" in this package, e.g. "RequestMirror". Implementers
	  are encouraged to support extended filters.

	- Implementation-specific: Filters that are defined and supported by specific vendors.
	  In the future, filters showing convergence in behavior across multiple
	  implementations will be considered for inclusion in extended or core
	  conformance levels. Filter-specific configuration for such filters
	  is specified using the ExtensionRef field. `Type` MUST be set to
	  "ExtensionRef" for custom filters.

	Implementers are encouraged to define custom implementation types to
	extend the core API with implementation-specific behavior.

	If a reference to a custom filter type cannot be resolved, the filter
	MUST NOT be skipped. Instead, requests that would have been processed by
	that filter MUST receive a HTTP error response.


	"""
																	enum: [
																		"ResponseHeaderModifier",
																		"RequestHeaderModifier",
																		"RequestMirror",
																		"ExtensionRef",
																	]
																	type: "string"
																}
															}
															required: ["type"]
															type: "object"
															"x-kubernetes-validations": [{
																message: "filter.requestHeaderModifier must be nil if the filter.type is not RequestHeaderModifier"
																rule:    "!(has(self.requestHeaderModifier) && self.type != 'RequestHeaderModifier')"
															}, {
																message: "filter.requestHeaderModifier must be specified for RequestHeaderModifier filter.type"
																rule:    "!(!has(self.requestHeaderModifier) && self.type == 'RequestHeaderModifier')"
															}, {
																message: "filter.responseHeaderModifier must be nil if the filter.type is not ResponseHeaderModifier"
																rule:    "!(has(self.responseHeaderModifier) && self.type != 'ResponseHeaderModifier')"
															}, {
																message: "filter.responseHeaderModifier must be specified for ResponseHeaderModifier filter.type"
																rule:    "!(!has(self.responseHeaderModifier) && self.type == 'ResponseHeaderModifier')"
															}, {
																message: "filter.requestMirror must be nil if the filter.type is not RequestMirror"
																rule:    "!(has(self.requestMirror) && self.type != 'RequestMirror')"
															}, {
																message: "filter.requestMirror must be specified for RequestMirror filter.type"
																rule:    "!(!has(self.requestMirror) && self.type == 'RequestMirror')"
															}, {
																message: "filter.extensionRef must be nil if the filter.type is not ExtensionRef"
																rule:    "!(has(self.extensionRef) && self.type != 'ExtensionRef')"
															}, {
																message: "filter.extensionRef must be specified for ExtensionRef filter.type"
																rule:    "!(!has(self.extensionRef) && self.type == 'ExtensionRef')"
															}]
														}
														maxItems: 16
														type:     "array"
														"x-kubernetes-validations": [{
															message: "RequestHeaderModifier filter cannot be repeated"
															rule:    "self.filter(f, f.type == 'RequestHeaderModifier').size() <= 1"
														}, {
															message: "ResponseHeaderModifier filter cannot be repeated"
															rule:    "self.filter(f, f.type == 'ResponseHeaderModifier').size() <= 1"
														}]
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
													weight: {
														default: 1
														description: """
	Weight specifies the proportion of requests forwarded to the referenced
	backend. This is computed as weight/(sum of all weights in this
	BackendRefs list). For non-zero values, there may be some epsilon from
	the exact proportion defined here depending on the precision an
	implementation supports. Weight is not a percentage and the sum of
	weights does not need to equal 100.

	If only one backend is specified and it has a weight greater than 0, 100%
	of the traffic is forwarded to that backend. If weight is set to 0, no
	traffic should be forwarded for this entry. If unspecified, weight
	defaults to 1.

	Support for this field varies based on the context where used.
	"""
														format:  "int32"
														maximum: 1000000
														minimum: 0
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
										filters: {
											description: """
	Filters define the filters that are applied to requests that match
	this rule.

	The effects of ordering of multiple behaviors are currently unspecified.
	This can change in the future based on feedback during the alpha stage.

	Conformance-levels at this level are defined based on the type of filter:

	- ALL core filters MUST be supported by all implementations that support
	  GRPCRoute.
	- Implementers are encouraged to support extended filters.
	- Implementation-specific custom filters have no API guarantees across
	  implementations.

	Specifying the same filter multiple times is not supported unless explicitly
	indicated in the filter.

	If an implementation can not support a combination of filters, it must clearly
	document that limitation. In cases where incompatible or unsupported
	filters are specified and cause the `Accepted` condition to be set to status
	`False`, implementations may use the `IncompatibleFilters` reason to specify
	this configuration error.

	Support: Core
	"""
											items: {
												description: """
	GRPCRouteFilter defines processing steps that must be completed during the
	request or response lifecycle. GRPCRouteFilters are meant as an extension
	point to express processing that may be done in Gateway implementations. Some
	examples include request or response modification, implementing
	authentication strategies, rate-limiting, and traffic shaping. API
	guarantee/conformance is defined based on the type of the filter.
	"""
												properties: {
													extensionRef: {
														description: """
	ExtensionRef is an optional, implementation-specific extension to the
	"filter" behavior.  For example, resource "myroutefilter" in group
	"networking.example.net"). ExtensionRef MUST NOT be used for core and
	extended filters.

	Support: Implementation-specific

	This filter can be used multiple times within the same rule.
	"""
														properties: {
															group: {
																description: """
	Group is the group of the referent. For example, "gateway.networking.k8s.io".
	When unspecified or empty string, core API group is inferred.
	"""
																maxLength: 253
																pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																type:      "string"
															}
															kind: {
																description: "Kind is kind of the referent. For example \"HTTPRoute\" or \"Service\"."
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
														}
														required: [
															"group",
															"kind",
															"name",
														]
														type: "object"
													}
													requestHeaderModifier: {
														description: """
	RequestHeaderModifier defines a schema for a filter that modifies request
	headers.

	Support: Core
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
													requestMirror: {
														description: """
	RequestMirror defines a schema for a filter that mirrors requests.
	Requests are sent to the specified destination, but responses from
	that destination are ignored.

	This filter can be used multiple times within the same rule. Note that
	not all implementations will be able to support mirroring to multiple
	backends.

	Support: Extended


	"""
														properties: {
															backendRef: {
																description: """
	BackendRef references a resource where mirrored requests are sent.

	Mirrored requests must be sent only to a single destination endpoint
	within this BackendRef, irrespective of how many endpoints are present
	within this BackendRef.

	If the referent cannot be found, this BackendRef is invalid and must be
	dropped from the Gateway. The controller must ensure the "ResolvedRefs"
	condition on the Route status is set to `status: False` and not configure
	this backend in the underlying implementation.

	If there is a cross-namespace reference to an *existing* object
	that is not allowed by a ReferenceGrant, the controller must ensure the
	"ResolvedRefs"  condition on the Route is set to `status: False`,
	with the "RefNotPermitted" reason and not configure this backend in the
	underlying implementation.

	In either error case, the Message of the `ResolvedRefs` Condition
	should be used to provide more detail about the problem.

	Support: Extended for Kubernetes Service

	Support: Implementation-specific for any other resource
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
															fraction: {
																description: """
	Fraction represents the fraction of requests that should be
	mirrored to BackendRef.

	Only one of Fraction or Percent may be specified. If neither field
	is specified, 100% of requests will be mirrored.


	"""
																properties: {
																	denominator: {
																		default: 100
																		format:  "int32"
																		minimum: 1
																		type:    "integer"
																	}
																	numerator: {
																		format:  "int32"
																		minimum: 0
																		type:    "integer"
																	}
																}
																required: ["numerator"]
																type: "object"
																"x-kubernetes-validations": [{
																	message: "numerator must be less than or equal to denominator"
																	rule:    "self.numerator <= self.denominator"
																}]
															}
															percent: {
																description: """
	Percent represents the percentage of requests that should be
	mirrored to BackendRef. Its minimum value is 0 (indicating 0% of
	requests) and its maximum value is 100 (indicating 100% of requests).

	Only one of Fraction or Percent may be specified. If neither field
	is specified, 100% of requests will be mirrored.


	"""
																format:  "int32"
																maximum: 100
																minimum: 0
																type:    "integer"
															}
														}
														required: ["backendRef"]
														type: "object"
														"x-kubernetes-validations": [{
															message: "Only one of percent or fraction may be specified in HTTPRequestMirrorFilter"
															rule:    "!(has(self.percent) && has(self.fraction))"
														}]
													}
													responseHeaderModifier: {
														description: """
	ResponseHeaderModifier defines a schema for a filter that modifies response
	headers.

	Support: Extended
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
													type: {
														description: """
	Type identifies the type of filter to apply. As with other API fields,
	types are classified into three conformance levels:

	- Core: Filter types and their corresponding configuration defined by
	  "Support: Core" in this package, e.g. "RequestHeaderModifier". All
	  implementations supporting GRPCRoute MUST support core filters.

	- Extended: Filter types and their corresponding configuration defined by
	  "Support: Extended" in this package, e.g. "RequestMirror". Implementers
	  are encouraged to support extended filters.

	- Implementation-specific: Filters that are defined and supported by specific vendors.
	  In the future, filters showing convergence in behavior across multiple
	  implementations will be considered for inclusion in extended or core
	  conformance levels. Filter-specific configuration for such filters
	  is specified using the ExtensionRef field. `Type` MUST be set to
	  "ExtensionRef" for custom filters.

	Implementers are encouraged to define custom implementation types to
	extend the core API with implementation-specific behavior.

	If a reference to a custom filter type cannot be resolved, the filter
	MUST NOT be skipped. Instead, requests that would have been processed by
	that filter MUST receive a HTTP error response.


	"""
														enum: [
															"ResponseHeaderModifier",
															"RequestHeaderModifier",
															"RequestMirror",
															"ExtensionRef",
														]
														type: "string"
													}
												}
												required: ["type"]
												type: "object"
												"x-kubernetes-validations": [{
													message: "filter.requestHeaderModifier must be nil if the filter.type is not RequestHeaderModifier"
													rule:    "!(has(self.requestHeaderModifier) && self.type != 'RequestHeaderModifier')"
												}, {
													message: "filter.requestHeaderModifier must be specified for RequestHeaderModifier filter.type"
													rule:    "!(!has(self.requestHeaderModifier) && self.type == 'RequestHeaderModifier')"
												}, {
													message: "filter.responseHeaderModifier must be nil if the filter.type is not ResponseHeaderModifier"
													rule:    "!(has(self.responseHeaderModifier) && self.type != 'ResponseHeaderModifier')"
												}, {
													message: "filter.responseHeaderModifier must be specified for ResponseHeaderModifier filter.type"
													rule:    "!(!has(self.responseHeaderModifier) && self.type == 'ResponseHeaderModifier')"
												}, {
													message: "filter.requestMirror must be nil if the filter.type is not RequestMirror"
													rule:    "!(has(self.requestMirror) && self.type != 'RequestMirror')"
												}, {
													message: "filter.requestMirror must be specified for RequestMirror filter.type"
													rule:    "!(!has(self.requestMirror) && self.type == 'RequestMirror')"
												}, {
													message: "filter.extensionRef must be nil if the filter.type is not ExtensionRef"
													rule:    "!(has(self.extensionRef) && self.type != 'ExtensionRef')"
												}, {
													message: "filter.extensionRef must be specified for ExtensionRef filter.type"
													rule:    "!(!has(self.extensionRef) && self.type == 'ExtensionRef')"
												}]
											}
											maxItems: 16
											type:     "array"
											"x-kubernetes-validations": [{
												message: "RequestHeaderModifier filter cannot be repeated"
												rule:    "self.filter(f, f.type == 'RequestHeaderModifier').size() <= 1"
											}, {
												message: "ResponseHeaderModifier filter cannot be repeated"
												rule:    "self.filter(f, f.type == 'ResponseHeaderModifier').size() <= 1"
											}]
										}
										matches: {
											description: """
	Matches define conditions used for matching the rule against incoming
	gRPC requests. Each match is independent, i.e. this rule will be matched
	if **any** one of the matches is satisfied.

	For example, take the following matches configuration:

	```
	matches:
	- method:
	    service: foo.bar
	  headers:
	    values:
	      version: 2
	- method:
	    service: foo.bar.v2
	```

	For a request to match against this rule, it MUST satisfy
	EITHER of the two conditions:

	- service of foo.bar AND contains the header `version: 2`
	- service of foo.bar.v2

	See the documentation for GRPCRouteMatch on how to specify multiple
	match conditions to be ANDed together.

	If no matches are specified, the implementation MUST match every gRPC request.

	Proxy or Load Balancer routing configuration generated from GRPCRoutes
	MUST prioritize rules based on the following criteria, continuing on
	ties. Merging MUST not be done between GRPCRoutes and HTTPRoutes.
	Precedence MUST be given to the rule with the largest number of:

	* Characters in a matching non-wildcard hostname.
	* Characters in a matching hostname.
	* Characters in a matching service.
	* Characters in a matching method.
	* Header matches.

	If ties still exist across multiple Routes, matching precedence MUST be
	determined in order of the following criteria, continuing on ties:

	* The oldest Route based on creation timestamp.
	* The Route appearing first in alphabetical order by
	  "{namespace}/{name}".

	If ties still exist within the Route that has been given precedence,
	matching precedence MUST be granted to the first matching rule meeting
	the above criteria.
	"""
											items: {
												description: """
	GRPCRouteMatch defines the predicate used to match requests to a given
	action. Multiple match types are ANDed together, i.e. the match will
	evaluate to true only if all conditions are satisfied.

	For example, the match below will match a gRPC request only if its service
	is `foo` AND it contains the `version: v1` header:

	```
	matches:
	  - method:
	    type: Exact
	    service: "foo"
	    headers:
	  - name: "version"
	    value "v1"

	```
	"""
												properties: {
													headers: {
														description: """
	Headers specifies gRPC request header matchers. Multiple match values are
	ANDed together, meaning, a request MUST match all the specified headers
	to select the route.
	"""
														items: {
															description: """
	GRPCHeaderMatch describes how to select a gRPC route by matching gRPC request
	headers.
	"""
															properties: {
																name: {
																	description: """
	Name is the name of the gRPC Header to be matched.

	If multiple entries specify equivalent header names, only the first
	entry with an equivalent name MUST be considered for a match. Subsequent
	entries with an equivalent header name MUST be ignored. Due to the
	case-insensitivity of header names, "foo" and "Foo" are considered
	equivalent.
	"""
																	maxLength: 256
																	minLength: 1
																	pattern:   "^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
																	type:      "string"
																}
																type: {
																	default:     "Exact"
																	description: "Type specifies how to match against the value of the header."
																	enum: [
																		"Exact",
																		"RegularExpression",
																	]
																	type: "string"
																}
																value: {
																	description: "Value is the value of the gRPC Header to be matched."
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
													method: {
														description: """
	Method specifies a gRPC request service/method matcher. If this field is
	not specified, all services and methods will match.
	"""
														properties: {
															method: {
																description: """
	Value of the method to match against. If left empty or omitted, will
	match all services.

	At least one of Service and Method MUST be a non-empty string.
	"""
																maxLength: 1024
																type:      "string"
															}
															service: {
																description: """
	Value of the service to match against. If left empty or omitted, will
	match any service.

	At least one of Service and Method MUST be a non-empty string.
	"""
																maxLength: 1024
																type:      "string"
															}
															type: {
																default: "Exact"
																description: """
	Type specifies how to match against the service and/or method.
	Support: Core (Exact with service and method specified)

	Support: Implementation-specific (Exact with method specified but no service specified)

	Support: Implementation-specific (RegularExpression)
	"""
																enum: [
																	"Exact",
																	"RegularExpression",
																]
																type: "string"
															}
														}
														type: "object"
														"x-kubernetes-validations": [{
															message: "One or both of 'service' or 'method' must be specified"
															rule:    "has(self.type) ? has(self.service) || has(self.method) : true"
														}, {
															message: "service must only contain valid characters (matching ^(?i)\\.?[a-z_][a-z_0-9]*(\\.[a-z_][a-z_0-9]*)*$)"
															rule:    "(!has(self.type) || self.type == 'Exact') && has(self.service) ? self.service.matches(r\"\"\"^(?i)\\.?[a-z_][a-z_0-9]*(\\.[a-z_][a-z_0-9]*)*$\"\"\"): true"
														}, {
															message: "method must only contain valid characters (matching ^[A-Za-z_][A-Za-z_0-9]*$)"
															rule:    "(!has(self.type) || self.type == 'Exact') && has(self.method) ? self.method.matches(r\"\"\"^[A-Za-z_][A-Za-z_0-9]*$\"\"\"): true"
														}]
													}
												}
												type: "object"
											}
											maxItems: 8
											type:     "array"
										}
										name: {
											description: """
	Name is the name of the route rule. This name MUST be unique within a Route if it is set.

	Support: Extended

	"""
											maxLength: 253
											minLength: 1
											pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
											type:      "string"
										}
										sessionPersistence: {
											description: """
	SessionPersistence defines and configures session persistence
	for the route rule.

	Support: Extended


	"""
											properties: {
												absoluteTimeout: {
													description: """
	AbsoluteTimeout defines the absolute timeout of the persistent
	session. Once the AbsoluteTimeout duration has elapsed, the
	session becomes invalid.

	Support: Extended
	"""
													pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
													type:    "string"
												}
												cookieConfig: {
													description: """
	CookieConfig provides configuration settings that are specific
	to cookie-based session persistence.

	Support: Core
	"""
													properties: lifetimeType: {
														default: "Session"
														description: """
	LifetimeType specifies whether the cookie has a permanent or
	session-based lifetime. A permanent cookie persists until its
	specified expiry time, defined by the Expires or Max-Age cookie
	attributes, while a session cookie is deleted when the current
	session ends.

	When set to "Permanent", AbsoluteTimeout indicates the
	cookie's lifetime via the Expires or Max-Age cookie attributes
	and is required.

	When set to "Session", AbsoluteTimeout indicates the
	absolute lifetime of the cookie tracked by the gateway and
	is optional.

	Support: Core for "Session" type

	Support: Extended for "Permanent" type
	"""
														enum: [
															"Permanent",
															"Session",
														]
														type: "string"
													}
													type: "object"
												}
												idleTimeout: {
													description: """
	IdleTimeout defines the idle timeout of the persistent session.
	Once the session has been idle for more than the specified
	IdleTimeout duration, the session becomes invalid.

	Support: Extended
	"""
													pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
													type:    "string"
												}
												sessionName: {
													description: """
	SessionName defines the name of the persistent session token
	which may be reflected in the cookie or the header. Users
	should avoid reusing session names to prevent unintended
	consequences, such as rejection or unpredictable behavior.

	Support: Implementation-specific
	"""
													maxLength: 128
													type:      "string"
												}
												type: {
													default: "Cookie"
													description: """
	Type defines the type of session persistence such as through
	the use a header or cookie. Defaults to cookie based session
	persistence.

	Support: Core for "Cookie" type

	Support: Extended for "Header" type
	"""
													enum: [
														"Cookie",
														"Header",
													]
													type: "string"
												}
											}
											type: "object"
											"x-kubernetes-validations": [{
												message: "AbsoluteTimeout must be specified when cookie lifetimeType is Permanent"
												rule:    "!has(self.cookieConfig) || !has(self.cookieConfig.lifetimeType) || self.cookieConfig.lifetimeType != 'Permanent' || has(self.absoluteTimeout)"
											}]
										}
									}
									type: "object"
								}
								maxItems: 16
								type:     "array"
								"x-kubernetes-validations": [{
									message: "While 16 rules and 64 matches per rule are allowed, the total number of matches across all rules in a route must be less than 128"
									rule:    "(self.size() > 0 ? (has(self[0].matches) ? self[0].matches.size() : 0) : 0) + (self.size() > 1 ? (has(self[1].matches) ? self[1].matches.size() : 0) : 0) + (self.size() > 2 ? (has(self[2].matches) ? self[2].matches.size() : 0) : 0) + (self.size() > 3 ? (has(self[3].matches) ? self[3].matches.size() : 0) : 0) + (self.size() > 4 ? (has(self[4].matches) ? self[4].matches.size() : 0) : 0) + (self.size() > 5 ? (has(self[5].matches) ? self[5].matches.size() : 0) : 0) + (self.size() > 6 ? (has(self[6].matches) ? self[6].matches.size() : 0) : 0) + (self.size() > 7 ? (has(self[7].matches) ? self[7].matches.size() : 0) : 0) + (self.size() > 8 ? (has(self[8].matches) ? self[8].matches.size() : 0) : 0) + (self.size() > 9 ? (has(self[9].matches) ? self[9].matches.size() : 0) : 0) + (self.size() > 10 ? (has(self[10].matches) ? self[10].matches.size() : 0) : 0) + (self.size() > 11 ? (has(self[11].matches) ? self[11].matches.size() : 0) : 0) + (self.size() > 12 ? (has(self[12].matches) ? self[12].matches.size() : 0) : 0) + (self.size() > 13 ? (has(self[13].matches) ? self[13].matches.size() : 0) : 0) + (self.size() > 14 ? (has(self[14].matches) ? self[14].matches.size() : 0) : 0) + (self.size() > 15 ? (has(self[15].matches) ? self[15].matches.size() : 0) : 0) <= 128"
								}, {
									message: "Rule name must be unique within the route"
									rule:    "self.all(l1, !has(l1.name) || self.exists_one(l2, has(l2.name) && l1.name == l2.name))"
								}]
							}
						}
						type: "object"
					}
					status: {
						description: "Status defines the current state of GRPCRoute."
						properties: parents: {
							description: """
	Parents is a list of parent resources (usually Gateways) that are
	associated with the route, and the status of the route with respect to
	each parent. When this route attaches to a parent, the controller that
	manages the parent must add an entry to this list when the controller
	first sees the route and should update the entry as appropriate when the
	route or gateway is modified.

	Note that parent references that cannot be resolved by an implementation
	of this API will not be added to this list. Implementations of this API
	can only populate Route status for the Gateways/parent resources they are
	responsible for.

	A maximum of 32 Gateways will be represented in this list. An empty list
	means the route has not been attached to any Gateway.
	"""
							items: {
								description: """
	RouteParentStatus describes the status of a route with respect to an
	associated Parent.
	"""
								properties: {
									conditions: {
										description: """
	Conditions describes the status of the route with respect to the Gateway.
	Note that the route's availability is also subject to the Gateway's own
	status conditions and listener status.

	If the Route's ParentRef specifies an existing Gateway that supports
	Routes of this kind AND that Gateway's controller has sufficient access,
	then that Gateway's controller MUST set the "Accepted" condition on the
	Route, to indicate whether the route has been accepted or rejected by the
	Gateway, and why.

	A Route MUST be considered "Accepted" if at least one of the Route's
	rules is implemented by the Gateway.

	There are a number of cases where the "Accepted" condition may not be set
	due to lack of controller visibility, that includes when:

	* The Route refers to a non-existent parent.
	* The Route is of a type that the controller does not support.
	* The Route is in a namespace the controller does not have access to.
	"""
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
									parentRef: {
										description: """
	ParentRef corresponds with a ParentRef in the spec that this
	RouteParentStatus struct describes the status of.
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


	ParentRefs from a Route to a Service in the same namespace are "producer"
	routes, which apply default routing rules to inbound connections from
	any namespace to the Service.

	ParentRefs from a Route to a Service in a different namespace are
	"consumer" routes, and these routing rules are only applied to outbound
	connections originating from the same namespace as the Route, for which
	the intended destination of the connections are a Service targeted as a
	ParentRef of the Route.


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


	When the parent resource is a Service, this targets a specific port in the
	Service spec. When both Port (experimental) and SectionName are specified,
	the name and port of the selected port must match both specified values.


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
								}
								required: [
									"controllerName",
									"parentRef",
								]
								type: "object"
							}
							maxItems: 32
							type:     "array"
						}
						required: ["parents"]
						type: "object"
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
