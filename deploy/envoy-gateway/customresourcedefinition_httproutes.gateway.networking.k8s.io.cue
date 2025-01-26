package deploy

k8s: "apiextensions.k8s.io": v1: CustomResourceDefinition: "": "httproutes.gateway.networking.k8s.io": {
	//
	// config/crd/experimental/gateway.networking.k8s.io_httproutes.yaml
	//
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: {
		annotations: {
			"api-approved.kubernetes.io":               "https://github.com/kubernetes-sigs/gateway-api/pull/3328"
			"gateway.networking.k8s.io/bundle-version": "v1.2.1"
			"gateway.networking.k8s.io/channel":        "experimental"
		}
		name: "httproutes.gateway.networking.k8s.io"
	}
	spec: {
		group: "gateway.networking.k8s.io"
		names: {
			categories: ["gateway-api"]
			kind:     "HTTPRoute"
			listKind: "HTTPRouteList"
			plural:   "httproutes"
			singular: "httproute"
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
					HTTPRoute provides a way to route HTTP requests. This includes the capability
					to match requests by hostname, path, header, or query param. Filters can be
					used to specify additional processing steps. Backends specify where matching
					requests should be routed.
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
						description: "Spec defines the desired state of HTTPRoute."
						properties: {
							hostnames: {
								description: """
	Hostnames defines a set of hostnames that should match against the HTTP Host
	header to select a HTTPRoute used to process the request. Implementations
	MUST ignore any port value specified in the HTTP Host header while
	performing a match and (absent of any applicable header modification
	configuration) MUST forward this header unmodified to the backend.

	Valid values for Hostnames are determined by RFC 1123 definition of a
	hostname with 2 notable exceptions:

	1. IPs are not allowed.
	2. A hostname may be prefixed with a wildcard label (`*.`). The wildcard
	   label must appear by itself as the first label.

	If a hostname is specified by both the Listener and HTTPRoute, there
	must be at least one intersecting hostname for the HTTPRoute to be
	attached to the Listener. For example:

	* A Listener with `test.example.com` as the hostname matches HTTPRoutes
	  that have either not specified any hostnames, or have specified at
	  least one of `test.example.com` or `*.example.com`.
	* A Listener with `*.example.com` as the hostname matches HTTPRoutes
	  that have either not specified any hostnames or have specified at least
	  one hostname that matches the Listener hostname. For example,
	  `*.example.com`, `test.example.com`, and `foo.test.example.com` would
	  all match. On the other hand, `example.com` and `test.example.net` would
	  not match.

	Hostnames that are prefixed with a wildcard label (`*.`) are interpreted
	as a suffix match. That means that a match for `*.example.com` would match
	both `test.example.com`, and `foo.test.example.com`, but not `example.com`.

	If both the Listener and HTTPRoute have specified hostnames, any
	HTTPRoute hostnames that do not match the Listener hostname MUST be
	ignored. For example, if a Listener specified `*.example.com`, and the
	HTTPRoute specified `test.example.com` and `test.example.net`,
	`test.example.net` must not be considered for a match.

	If both the Listener and HTTPRoute have specified hostnames, and none
	match with the criteria above, then the HTTPRoute is not accepted. The
	implementation must raise an 'Accepted' Condition with a status of
	`False` in the corresponding RouteParentStatus.

	In the event that multiple HTTPRoutes specify intersecting hostnames (e.g.
	overlapping wildcard matching and exact matching hostnames), precedence must
	be given to rules from the HTTPRoute with the largest number of:

	* Characters in a matching non-wildcard hostname.
	* Characters in a matching hostname.

	If ties exist across multiple Routes, the matching precedence rules for
	HTTPRouteMatches takes over.

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
								default: [{
									matches: [{
										path: {
											type:  "PathPrefix"
											value: "/"
										}
									}]
								}]
								description: """
	Rules are a list of HTTP matchers, filters and actions.


	"""
								items: {
									description: """
	HTTPRouteRule defines semantics for matching an HTTP request based on
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
	receive a 500 status code.

	See the HTTPBackendRef definition for the rules about what makes a single
	HTTPBackendRef invalid.

	When a HTTPBackendRef is invalid, 500 status codes MUST be returned for
	requests that would have otherwise been routed to an invalid backend. If
	multiple backends are specified, and some are invalid, the proportion of
	requests that would otherwise have been routed to an invalid backend
	MUST receive a 500 status code.

	For example, if two backends are specified with equal weights, and one is
	invalid, 50 percent of traffic must receive a 500. Implementations may
	choose how that 50 percent is determined.

	When a HTTPBackendRef refers to a Service that has no ready endpoints,
	implementations SHOULD return a 503 for requests to that backend instead.
	If an implementation chooses to do this, all of the above rules for 500 responses
	MUST also apply for responses that return a 503.

	Support: Core for Kubernetes Service

	Support: Extended for Kubernetes ServiceImport

	Support: Implementation-specific for any other resource

	Support for weight: Core
	"""
											items: {
												description: """
	HTTPBackendRef defines how a HTTPRoute forwards a HTTP request.

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
	Filters defined at this level should be executed if and only if the
	request is being forwarded to the backend defined here.

	Support: Implementation-specific (For broader support of filters, use the
	Filters field in HTTPRouteRule.)
	"""
														items: {
															description: """
	HTTPRouteFilter defines processing steps that must be completed during the
	request or response lifecycle. HTTPRouteFilters are meant as an extension
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

	This filter can be used multiple times within the same rule.

	Support: Implementation-specific
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
																requestRedirect: {
																	description: """
	RequestRedirect defines a schema for a filter that responds to the
	request with an HTTP redirection.

	Support: Core
	"""
																	properties: {
																		hostname: {
																			description: """
	Hostname is the hostname to be used in the value of the `Location`
	header in the response.
	When empty, the hostname in the `Host` header of the request is used.

	Support: Core
	"""
																			maxLength: 253
																			minLength: 1
																			pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																			type:      "string"
																		}
																		path: {
																			description: """
	Path defines parameters used to modify the path of the incoming request.
	The modified path is then used to construct the `Location` header. When
	empty, the request path is used as-is.

	Support: Extended
	"""
																			properties: {
																				replaceFullPath: {
																					description: """
	ReplaceFullPath specifies the value with which to replace the full path
	of a request during a rewrite or redirect.
	"""
																					maxLength: 1024
																					type:      "string"
																				}
																				replacePrefixMatch: {
																					description: """
	ReplacePrefixMatch specifies the value with which to replace the prefix
	match of a request during a rewrite or redirect. For example, a request
	to "/foo/bar" with a prefix match of "/foo" and a ReplacePrefixMatch
	of "/xyz" would be modified to "/xyz/bar".

	Note that this matches the behavior of the PathPrefix match type. This
	matches full path elements. A path element refers to the list of labels
	in the path split by the `/` separator. When specified, a trailing `/` is
	ignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all
	match the prefix `/abc`, but the path `/abcd` would not.

	ReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.
	Using any other HTTPRouteMatch type on the same HTTPRouteRule will result in
	the implementation setting the Accepted Condition for the Route to `status: False`.

	Request Path | Prefix Match | Replace Prefix | Modified Path
	"""
																					maxLength: 1024
																					type:      "string"
																				}
																				type: {
																					description: """
	Type defines the type of path modifier. Additional types may be
	added in a future release of the API.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
																					enum: [
																						"ReplaceFullPath",
																						"ReplacePrefixMatch",
																					]
																					type: "string"
																				}
																			}
																			required: ["type"]
																			type: "object"
																			"x-kubernetes-validations": [{
																				message: "replaceFullPath must be specified when type is set to 'ReplaceFullPath'"
																				rule:    "self.type == 'ReplaceFullPath' ? has(self.replaceFullPath) : true"
																			}, {
																				message: "type must be 'ReplaceFullPath' when replaceFullPath is set"
																				rule:    "has(self.replaceFullPath) ? self.type == 'ReplaceFullPath' : true"
																			}, {
																				message: "replacePrefixMatch must be specified when type is set to 'ReplacePrefixMatch'"
																				rule:    "self.type == 'ReplacePrefixMatch' ? has(self.replacePrefixMatch) : true"
																			}, {
																				message: "type must be 'ReplacePrefixMatch' when replacePrefixMatch is set"
																				rule:    "has(self.replacePrefixMatch) ? self.type == 'ReplacePrefixMatch' : true"
																			}]
																		}
																		port: {
																			description: """
	Port is the port to be used in the value of the `Location`
	header in the response.

	If no port is specified, the redirect port MUST be derived using the
	following rules:

	* If redirect scheme is not-empty, the redirect port MUST be the well-known
	  port associated with the redirect scheme. Specifically "http" to port 80
	  and "https" to port 443. If the redirect scheme does not have a
	  well-known port, the listener port of the Gateway SHOULD be used.
	* If redirect scheme is empty, the redirect port MUST be the Gateway
	  Listener port.

	Implementations SHOULD NOT add the port number in the 'Location'
	header in the following cases:

	* A Location header that will use HTTP (whether that is determined via
	  the Listener protocol or the Scheme field) _and_ use port 80.
	* A Location header that will use HTTPS (whether that is determined via
	  the Listener protocol or the Scheme field) _and_ use port 443.

	Support: Extended
	"""
																			format:  "int32"
																			maximum: 65535
																			minimum: 1
																			type:    "integer"
																		}
																		scheme: {
																			description: """
	Scheme is the scheme to be used in the value of the `Location` header in
	the response. When empty, the scheme of the request is used.

	Scheme redirects can affect the port of the redirect, for more information,
	refer to the documentation for the port field of this filter.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.

	Support: Extended
	"""
																			enum: [
																				"http",
																				"https",
																			]
																			type: "string"
																		}
																		statusCode: {
																			default: 302
																			description: """
	StatusCode is the HTTP status code to be used in response.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.

	Support: Core
	"""
																			enum: [
																				301,
																				302,
																			]
																			type: "integer"
																		}
																	}
																	type: "object"
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
	  implementations must support core filters.

	- Extended: Filter types and their corresponding configuration defined by
	  "Support: Extended" in this package, e.g. "RequestMirror". Implementers
	  are encouraged to support extended filters.

	- Implementation-specific: Filters that are defined and supported by
	  specific vendors.
	  In the future, filters showing convergence in behavior across multiple
	  implementations will be considered for inclusion in extended or core
	  conformance levels. Filter-specific configuration for such filters
	  is specified using the ExtensionRef field. `Type` should be set to
	  "ExtensionRef" for custom filters.

	Implementers are encouraged to define custom implementation types to
	extend the core API with implementation-specific behavior.

	If a reference to a custom filter type cannot be resolved, the filter
	MUST NOT be skipped. Instead, requests that would have been processed by
	that filter MUST receive a HTTP error response.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
																	enum: [
																		"RequestHeaderModifier",
																		"ResponseHeaderModifier",
																		"RequestMirror",
																		"RequestRedirect",
																		"URLRewrite",
																		"ExtensionRef",
																	]
																	type: "string"
																}
																urlRewrite: {
																	description: """
	URLRewrite defines a schema for a filter that modifies a request during forwarding.

	Support: Extended
	"""
																	properties: {
																		hostname: {
																			description: """
	Hostname is the value to be used to replace the Host header value during
	forwarding.

	Support: Extended
	"""
																			maxLength: 253
																			minLength: 1
																			pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																			type:      "string"
																		}
																		path: {
																			description: """
	Path defines a path rewrite.

	Support: Extended
	"""
																			properties: {
																				replaceFullPath: {
																					description: """
	ReplaceFullPath specifies the value with which to replace the full path
	of a request during a rewrite or redirect.
	"""
																					maxLength: 1024
																					type:      "string"
																				}
																				replacePrefixMatch: {
																					description: """
	ReplacePrefixMatch specifies the value with which to replace the prefix
	match of a request during a rewrite or redirect. For example, a request
	to "/foo/bar" with a prefix match of "/foo" and a ReplacePrefixMatch
	of "/xyz" would be modified to "/xyz/bar".

	Note that this matches the behavior of the PathPrefix match type. This
	matches full path elements. A path element refers to the list of labels
	in the path split by the `/` separator. When specified, a trailing `/` is
	ignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all
	match the prefix `/abc`, but the path `/abcd` would not.

	ReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.
	Using any other HTTPRouteMatch type on the same HTTPRouteRule will result in
	the implementation setting the Accepted Condition for the Route to `status: False`.

	Request Path | Prefix Match | Replace Prefix | Modified Path
	"""
																					maxLength: 1024
																					type:      "string"
																				}
																				type: {
																					description: """
	Type defines the type of path modifier. Additional types may be
	added in a future release of the API.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
																					enum: [
																						"ReplaceFullPath",
																						"ReplacePrefixMatch",
																					]
																					type: "string"
																				}
																			}
																			required: ["type"]
																			type: "object"
																			"x-kubernetes-validations": [{
																				message: "replaceFullPath must be specified when type is set to 'ReplaceFullPath'"
																				rule:    "self.type == 'ReplaceFullPath' ? has(self.replaceFullPath) : true"
																			}, {
																				message: "type must be 'ReplaceFullPath' when replaceFullPath is set"
																				rule:    "has(self.replaceFullPath) ? self.type == 'ReplaceFullPath' : true"
																			}, {
																				message: "replacePrefixMatch must be specified when type is set to 'ReplacePrefixMatch'"
																				rule:    "self.type == 'ReplacePrefixMatch' ? has(self.replacePrefixMatch) : true"
																			}, {
																				message: "type must be 'ReplacePrefixMatch' when replacePrefixMatch is set"
																				rule:    "has(self.replacePrefixMatch) ? self.type == 'ReplacePrefixMatch' : true"
																			}]
																		}
																	}
																	type: "object"
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
																message: "filter.requestRedirect must be nil if the filter.type is not RequestRedirect"
																rule:    "!(has(self.requestRedirect) && self.type != 'RequestRedirect')"
															}, {
																message: "filter.requestRedirect must be specified for RequestRedirect filter.type"
																rule:    "!(!has(self.requestRedirect) && self.type == 'RequestRedirect')"
															}, {
																message: "filter.urlRewrite must be nil if the filter.type is not URLRewrite"
																rule:    "!(has(self.urlRewrite) && self.type != 'URLRewrite')"
															}, {
																message: "filter.urlRewrite must be specified for URLRewrite filter.type"
																rule:    "!(!has(self.urlRewrite) && self.type == 'URLRewrite')"
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
															message: "May specify either httpRouteFilterRequestRedirect or httpRouteFilterRequestRewrite, but not both"
															rule:    "!(self.exists(f, f.type == 'RequestRedirect') && self.exists(f, f.type == 'URLRewrite'))"
														}, {
															message: "May specify either httpRouteFilterRequestRedirect or httpRouteFilterRequestRewrite, but not both"
															rule:    "!(self.exists(f, f.type == 'RequestRedirect') && self.exists(f, f.type == 'URLRewrite'))"
														}, {
															message: "RequestHeaderModifier filter cannot be repeated"
															rule:    "self.filter(f, f.type == 'RequestHeaderModifier').size() <= 1"
														}, {
															message: "ResponseHeaderModifier filter cannot be repeated"
															rule:    "self.filter(f, f.type == 'ResponseHeaderModifier').size() <= 1"
														}, {
															message: "RequestRedirect filter cannot be repeated"
															rule:    "self.filter(f, f.type == 'RequestRedirect').size() <= 1"
														}, {
															message: "URLRewrite filter cannot be repeated"
															rule:    "self.filter(f, f.type == 'URLRewrite').size() <= 1"
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

	Wherever possible, implementations SHOULD implement filters in the order
	they are specified.

	Implementations MAY choose to implement this ordering strictly, rejecting
	any combination or order of filters that can not be supported. If implementations
	choose a strict interpretation of filter ordering, they MUST clearly document
	that behavior.

	To reject an invalid combination or order of filters, implementations SHOULD
	consider the Route Rules with this configuration invalid. If all Route Rules
	in a Route are invalid, the entire Route would be considered invalid. If only
	a portion of Route Rules are invalid, implementations MUST set the
	"PartiallyInvalid" condition for the Route.

	Conformance-levels at this level are defined based on the type of filter:

	- ALL core filters MUST be supported by all implementations.
	- Implementers are encouraged to support extended filters.
	- Implementation-specific custom filters have no API guarantees across
	  implementations.

	Specifying the same filter multiple times is not supported unless explicitly
	indicated in the filter.

	All filters are expected to be compatible with each other except for the
	URLRewrite and RequestRedirect filters, which may not be combined. If an
	implementation can not support other combinations of filters, they must clearly
	document that limitation. In cases where incompatible or unsupported
	filters are specified and cause the `Accepted` condition to be set to status
	`False`, implementations may use the `IncompatibleFilters` reason to specify
	this configuration error.

	Support: Core
	"""
											items: {
												description: """
	HTTPRouteFilter defines processing steps that must be completed during the
	request or response lifecycle. HTTPRouteFilters are meant as an extension
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

	This filter can be used multiple times within the same rule.

	Support: Implementation-specific
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
													requestRedirect: {
														description: """
	RequestRedirect defines a schema for a filter that responds to the
	request with an HTTP redirection.

	Support: Core
	"""
														properties: {
															hostname: {
																description: """
	Hostname is the hostname to be used in the value of the `Location`
	header in the response.
	When empty, the hostname in the `Host` header of the request is used.

	Support: Core
	"""
																maxLength: 253
																minLength: 1
																pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																type:      "string"
															}
															path: {
																description: """
	Path defines parameters used to modify the path of the incoming request.
	The modified path is then used to construct the `Location` header. When
	empty, the request path is used as-is.

	Support: Extended
	"""
																properties: {
																	replaceFullPath: {
																		description: """
	ReplaceFullPath specifies the value with which to replace the full path
	of a request during a rewrite or redirect.
	"""
																		maxLength: 1024
																		type:      "string"
																	}
																	replacePrefixMatch: {
																		description: """
	ReplacePrefixMatch specifies the value with which to replace the prefix
	match of a request during a rewrite or redirect. For example, a request
	to "/foo/bar" with a prefix match of "/foo" and a ReplacePrefixMatch
	of "/xyz" would be modified to "/xyz/bar".

	Note that this matches the behavior of the PathPrefix match type. This
	matches full path elements. A path element refers to the list of labels
	in the path split by the `/` separator. When specified, a trailing `/` is
	ignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all
	match the prefix `/abc`, but the path `/abcd` would not.

	ReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.
	Using any other HTTPRouteMatch type on the same HTTPRouteRule will result in
	the implementation setting the Accepted Condition for the Route to `status: False`.

	Request Path | Prefix Match | Replace Prefix | Modified Path
	"""
																		maxLength: 1024
																		type:      "string"
																	}
																	type: {
																		description: """
	Type defines the type of path modifier. Additional types may be
	added in a future release of the API.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
																		enum: [
																			"ReplaceFullPath",
																			"ReplacePrefixMatch",
																		]
																		type: "string"
																	}
																}
																required: ["type"]
																type: "object"
																"x-kubernetes-validations": [{
																	message: "replaceFullPath must be specified when type is set to 'ReplaceFullPath'"
																	rule:    "self.type == 'ReplaceFullPath' ? has(self.replaceFullPath) : true"
																}, {
																	message: "type must be 'ReplaceFullPath' when replaceFullPath is set"
																	rule:    "has(self.replaceFullPath) ? self.type == 'ReplaceFullPath' : true"
																}, {
																	message: "replacePrefixMatch must be specified when type is set to 'ReplacePrefixMatch'"
																	rule:    "self.type == 'ReplacePrefixMatch' ? has(self.replacePrefixMatch) : true"
																}, {
																	message: "type must be 'ReplacePrefixMatch' when replacePrefixMatch is set"
																	rule:    "has(self.replacePrefixMatch) ? self.type == 'ReplacePrefixMatch' : true"
																}]
															}
															port: {
																description: """
	Port is the port to be used in the value of the `Location`
	header in the response.

	If no port is specified, the redirect port MUST be derived using the
	following rules:

	* If redirect scheme is not-empty, the redirect port MUST be the well-known
	  port associated with the redirect scheme. Specifically "http" to port 80
	  and "https" to port 443. If the redirect scheme does not have a
	  well-known port, the listener port of the Gateway SHOULD be used.
	* If redirect scheme is empty, the redirect port MUST be the Gateway
	  Listener port.

	Implementations SHOULD NOT add the port number in the 'Location'
	header in the following cases:

	* A Location header that will use HTTP (whether that is determined via
	  the Listener protocol or the Scheme field) _and_ use port 80.
	* A Location header that will use HTTPS (whether that is determined via
	  the Listener protocol or the Scheme field) _and_ use port 443.

	Support: Extended
	"""
																format:  "int32"
																maximum: 65535
																minimum: 1
																type:    "integer"
															}
															scheme: {
																description: """
	Scheme is the scheme to be used in the value of the `Location` header in
	the response. When empty, the scheme of the request is used.

	Scheme redirects can affect the port of the redirect, for more information,
	refer to the documentation for the port field of this filter.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.

	Support: Extended
	"""
																enum: [
																	"http",
																	"https",
																]
																type: "string"
															}
															statusCode: {
																default: 302
																description: """
	StatusCode is the HTTP status code to be used in response.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.

	Support: Core
	"""
																enum: [
																	301,
																	302,
																]
																type: "integer"
															}
														}
														type: "object"
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
	  implementations must support core filters.

	- Extended: Filter types and their corresponding configuration defined by
	  "Support: Extended" in this package, e.g. "RequestMirror". Implementers
	  are encouraged to support extended filters.

	- Implementation-specific: Filters that are defined and supported by
	  specific vendors.
	  In the future, filters showing convergence in behavior across multiple
	  implementations will be considered for inclusion in extended or core
	  conformance levels. Filter-specific configuration for such filters
	  is specified using the ExtensionRef field. `Type` should be set to
	  "ExtensionRef" for custom filters.

	Implementers are encouraged to define custom implementation types to
	extend the core API with implementation-specific behavior.

	If a reference to a custom filter type cannot be resolved, the filter
	MUST NOT be skipped. Instead, requests that would have been processed by
	that filter MUST receive a HTTP error response.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
														enum: [
															"RequestHeaderModifier",
															"ResponseHeaderModifier",
															"RequestMirror",
															"RequestRedirect",
															"URLRewrite",
															"ExtensionRef",
														]
														type: "string"
													}
													urlRewrite: {
														description: """
	URLRewrite defines a schema for a filter that modifies a request during forwarding.

	Support: Extended
	"""
														properties: {
															hostname: {
																description: """
	Hostname is the value to be used to replace the Host header value during
	forwarding.

	Support: Extended
	"""
																maxLength: 253
																minLength: 1
																pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																type:      "string"
															}
															path: {
																description: """
	Path defines a path rewrite.

	Support: Extended
	"""
																properties: {
																	replaceFullPath: {
																		description: """
	ReplaceFullPath specifies the value with which to replace the full path
	of a request during a rewrite or redirect.
	"""
																		maxLength: 1024
																		type:      "string"
																	}
																	replacePrefixMatch: {
																		description: """
	ReplacePrefixMatch specifies the value with which to replace the prefix
	match of a request during a rewrite or redirect. For example, a request
	to "/foo/bar" with a prefix match of "/foo" and a ReplacePrefixMatch
	of "/xyz" would be modified to "/xyz/bar".

	Note that this matches the behavior of the PathPrefix match type. This
	matches full path elements. A path element refers to the list of labels
	in the path split by the `/` separator. When specified, a trailing `/` is
	ignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all
	match the prefix `/abc`, but the path `/abcd` would not.

	ReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.
	Using any other HTTPRouteMatch type on the same HTTPRouteRule will result in
	the implementation setting the Accepted Condition for the Route to `status: False`.

	Request Path | Prefix Match | Replace Prefix | Modified Path
	"""
																		maxLength: 1024
																		type:      "string"
																	}
																	type: {
																		description: """
	Type defines the type of path modifier. Additional types may be
	added in a future release of the API.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
																		enum: [
																			"ReplaceFullPath",
																			"ReplacePrefixMatch",
																		]
																		type: "string"
																	}
																}
																required: ["type"]
																type: "object"
																"x-kubernetes-validations": [{
																	message: "replaceFullPath must be specified when type is set to 'ReplaceFullPath'"
																	rule:    "self.type == 'ReplaceFullPath' ? has(self.replaceFullPath) : true"
																}, {
																	message: "type must be 'ReplaceFullPath' when replaceFullPath is set"
																	rule:    "has(self.replaceFullPath) ? self.type == 'ReplaceFullPath' : true"
																}, {
																	message: "replacePrefixMatch must be specified when type is set to 'ReplacePrefixMatch'"
																	rule:    "self.type == 'ReplacePrefixMatch' ? has(self.replacePrefixMatch) : true"
																}, {
																	message: "type must be 'ReplacePrefixMatch' when replacePrefixMatch is set"
																	rule:    "has(self.replacePrefixMatch) ? self.type == 'ReplacePrefixMatch' : true"
																}]
															}
														}
														type: "object"
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
													message: "filter.requestRedirect must be nil if the filter.type is not RequestRedirect"
													rule:    "!(has(self.requestRedirect) && self.type != 'RequestRedirect')"
												}, {
													message: "filter.requestRedirect must be specified for RequestRedirect filter.type"
													rule:    "!(!has(self.requestRedirect) && self.type == 'RequestRedirect')"
												}, {
													message: "filter.urlRewrite must be nil if the filter.type is not URLRewrite"
													rule:    "!(has(self.urlRewrite) && self.type != 'URLRewrite')"
												}, {
													message: "filter.urlRewrite must be specified for URLRewrite filter.type"
													rule:    "!(!has(self.urlRewrite) && self.type == 'URLRewrite')"
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
												message: "May specify either httpRouteFilterRequestRedirect or httpRouteFilterRequestRewrite, but not both"
												rule:    "!(self.exists(f, f.type == 'RequestRedirect') && self.exists(f, f.type == 'URLRewrite'))"
											}, {
												message: "RequestHeaderModifier filter cannot be repeated"
												rule:    "self.filter(f, f.type == 'RequestHeaderModifier').size() <= 1"
											}, {
												message: "ResponseHeaderModifier filter cannot be repeated"
												rule:    "self.filter(f, f.type == 'ResponseHeaderModifier').size() <= 1"
											}, {
												message: "RequestRedirect filter cannot be repeated"
												rule:    "self.filter(f, f.type == 'RequestRedirect').size() <= 1"
											}, {
												message: "URLRewrite filter cannot be repeated"
												rule:    "self.filter(f, f.type == 'URLRewrite').size() <= 1"
											}]
										}
										matches: {
											default: [{
												path: {
													type:  "PathPrefix"
													value: "/"
												}
											}]
											description: """
	Matches define conditions used for matching the rule against incoming
	HTTP requests. Each match is independent, i.e. this rule will be matched
	if **any** one of the matches is satisfied.

	For example, take the following matches configuration:

	```
	matches:
	- path:
	    value: "/foo"
	  headers:
	  - name: "version"
	    value: "v2"
	- path:
	    value: "/v2/foo"
	```

	For a request to match against this rule, a request must satisfy
	EITHER of the two conditions:

	- path prefixed with `/foo` AND contains the header `version: v2`
	- path prefix of `/v2/foo`

	See the documentation for HTTPRouteMatch on how to specify multiple
	match conditions that should be ANDed together.

	If no matches are specified, the default is a prefix
	path match on "/", which has the effect of matching every
	HTTP request.

	Proxy or Load Balancer routing configuration generated from HTTPRoutes
	MUST prioritize matches based on the following criteria, continuing on
	ties. Across all rules specified on applicable Routes, precedence must be
	given to the match having:

	* "Exact" path match.
	* "Prefix" path match with largest number of characters.
	* Method match.
	* Largest number of header matches.
	* Largest number of query param matches.

	Note: The precedence of RegularExpression path matches are implementation-specific.

	If ties still exist across multiple Routes, matching precedence MUST be
	determined in order of the following criteria, continuing on ties:

	* The oldest Route based on creation timestamp.
	* The Route appearing first in alphabetical order by
	  "{namespace}/{name}".

	If ties still exist within an HTTPRoute, matching precedence MUST be granted
	to the FIRST matching rule (in list order) with a match meeting the above
	criteria.

	When no rules matching a request have been successfully attached to the
	parent a request is coming from, a HTTP 404 status code MUST be returned.
	"""
											items: {
												description: """
	HTTPRouteMatch defines the predicate used to match requests to a given
	action. Multiple match types are ANDed together, i.e. the match will
	evaluate to true only if all conditions are satisfied.

	For example, the match below will match a HTTP request only if its path
	starts with `/foo` AND it contains the `version: v1` header:

	```
	match:

	\tpath:
	\t  value: "/foo"
	\theaders:
	\t- name: "version"
	\t  value "v1"

	```
	"""
												properties: {
													headers: {
														description: """
	Headers specifies HTTP request header matchers. Multiple match values are
	ANDed together, meaning, a request must match all the specified headers
	to select the route.
	"""
														items: {
															description: """
	HTTPHeaderMatch describes how to select a HTTP route by matching HTTP request
	headers.
	"""
															properties: {
																name: {
																	description: """
	Name is the name of the HTTP Header to be matched. Name matching MUST be
	case insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).

	If multiple entries specify equivalent header names, only the first
	entry with an equivalent name MUST be considered for a match. Subsequent
	entries with an equivalent header name MUST be ignored. Due to the
	case-insensitivity of header names, "foo" and "Foo" are considered
	equivalent.

	When a header is repeated in an HTTP request, it is
	implementation-specific behavior as to how this is represented.
	Generally, proxies should follow the guidance from the RFC:
	https://www.rfc-editor.org/rfc/rfc7230.html#section-3.2.2 regarding
	processing a repeated header, with special handling for "Set-Cookie".
	"""
																	maxLength: 256
																	minLength: 1
																	pattern:   "^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
																	type:      "string"
																}
																type: {
																	default: "Exact"
																	description: """
	Type specifies how to match against the value of the header.

	Support: Core (Exact)

	Support: Implementation-specific (RegularExpression)

	Since RegularExpression HeaderMatchType has implementation-specific
	conformance, implementations can support POSIX, PCRE or any other dialects
	of regular expressions. Please read the implementation's documentation to
	determine the supported dialect.
	"""
																	enum: [
																		"Exact",
																		"RegularExpression",
																	]
																	type: "string"
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
													method: {
														description: """
	Method specifies HTTP method matcher.
	When specified, this route will be matched only if the request has the
	specified method.

	Support: Extended
	"""
														enum: [
															"GET",
															"HEAD",
															"POST",
															"PUT",
															"DELETE",
															"CONNECT",
															"OPTIONS",
															"TRACE",
															"PATCH",
														]
														type: "string"
													}
													path: {
														default: {
															type:  "PathPrefix"
															value: "/"
														}
														description: """
	Path specifies a HTTP request path matcher. If this field is not
	specified, a default prefix match on the "/" path is provided.
	"""
														properties: {
															type: {
																default: "PathPrefix"
																description: """
	Type specifies how to match against the path Value.

	Support: Core (Exact, PathPrefix)

	Support: Implementation-specific (RegularExpression)
	"""
																enum: [
																	"Exact",
																	"PathPrefix",
																	"RegularExpression",
																]
																type: "string"
															}
															value: {
																default:     "/"
																description: "Value of the HTTP path to match against."
																maxLength:   1024
																type:        "string"
															}
														}
														type: "object"
														"x-kubernetes-validations": [{
															message: "value must be an absolute path and start with '/' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? self.value.startsWith('/') : true"
														}, {
															message: "must not contain '//' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('//') : true"
														}, {
															message: "must not contain '/./' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('/./') : true"
														}, {
															message: "must not contain '/../' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('/../') : true"
														}, {
															message: "must not contain '%2f' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('%2f') : true"
														}, {
															message: "must not contain '%2F' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('%2F') : true"
														}, {
															message: "must not contain '#' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('#') : true"
														}, {
															message: "must not end with '/..' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.endsWith('/..') : true"
														}, {
															message: "must not end with '/.' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.endsWith('/.') : true"
														}, {
															message: "type must be one of ['Exact', 'PathPrefix', 'RegularExpression']"
															rule:    "self.type in ['Exact','PathPrefix'] || self.type == 'RegularExpression'"
														}, {
															message: "must only contain valid characters (matching ^(?:[-A-Za-z0-9/._~!$&'()*+,;=:@]|[%][0-9a-fA-F]{2})+$) for types ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? self.value.matches(r\"\"\"^(?:[-A-Za-z0-9/._~!$&'()*+,;=:@]|[%][0-9a-fA-F]{2})+$\"\"\") : true"
														}]
													}
													queryParams: {
														description: """
	QueryParams specifies HTTP query parameter matchers. Multiple match
	values are ANDed together, meaning, a request must match all the
	specified query parameters to select the route.

	Support: Extended
	"""
														items: {
															description: """
	HTTPQueryParamMatch describes how to select a HTTP route by matching HTTP
	query parameters.
	"""
															properties: {
																name: {
																	description: """
	Name is the name of the HTTP query param to be matched. This must be an
	exact string match. (See
	https://tools.ietf.org/html/rfc7230#section-2.7.3).

	If multiple entries specify equivalent query param names, only the first
	entry with an equivalent name MUST be considered for a match. Subsequent
	entries with an equivalent query param name MUST be ignored.

	If a query param is repeated in an HTTP request, the behavior is
	purposely left undefined, since different data planes have different
	capabilities. However, it is *recommended* that implementations should
	match against the first value of the param if the data plane supports it,
	as this behavior is expected in other load balancing contexts outside of
	the Gateway API.

	Users SHOULD NOT route traffic based on repeated query params to guard
	themselves against potential differences in the implementations.
	"""
																	maxLength: 256
																	minLength: 1
																	pattern:   "^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
																	type:      "string"
																}
																type: {
																	default: "Exact"
																	description: """
	Type specifies how to match against the value of the query parameter.

	Support: Extended (Exact)

	Support: Implementation-specific (RegularExpression)

	Since RegularExpression QueryParamMatchType has Implementation-specific
	conformance, implementations can support POSIX, PCRE or any other
	dialects of regular expressions. Please read the implementation's
	documentation to determine the supported dialect.
	"""
																	enum: [
																		"Exact",
																		"RegularExpression",
																	]
																	type: "string"
																}
																value: {
																	description: "Value is the value of HTTP query param to be matched."
																	maxLength:   1024
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
											maxItems: 64
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
										retry: {
											description: """
	Retry defines the configuration for when to retry an HTTP request.

	Support: Extended


	"""
											properties: {
												attempts: {
													description: """
	Attempts specifies the maxmimum number of times an individual request
	from the gateway to a backend should be retried.

	If the maximum number of retries has been attempted without a successful
	response from the backend, the Gateway MUST return an error.

	When this field is unspecified, the number of times to attempt to retry
	a backend request is implementation-specific.

	Support: Extended
	"""
													type: "integer"
												}
												backoff: {
													description: """
	Backoff specifies the minimum duration a Gateway should wait between
	retry attempts and is represented in Gateway API Duration formatting.

	For example, setting the `rules[].retry.backoff` field to the value
	`100ms` will cause a backend request to first be retried approximately
	100 milliseconds after timing out or receiving a response code configured
	to be retryable.

	An implementation MAY use an exponential or alternative backoff strategy
	for subsequent retry attempts, MAY cap the maximum backoff duration to
	some amount greater than the specified minimum, and MAY add arbitrary
	jitter to stagger requests, as long as unsuccessful backend requests are
	not retried before the configured minimum duration.

	If a Request timeout (`rules[].timeouts.request`) is configured on the
	route, the entire duration of the initial request and any retry attempts
	MUST not exceed the Request timeout duration. If any retry attempts are
	still in progress when the Request timeout duration has been reached,
	these SHOULD be canceled if possible and the Gateway MUST immediately
	return a timeout error.

	If a BackendRequest timeout (`rules[].timeouts.backendRequest`) is
	configured on the route, any retry attempts which reach the configured
	BackendRequest timeout duration without a response SHOULD be canceled if
	possible and the Gateway should wait for at least the specified backoff
	duration before attempting to retry the backend request again.

	If a BackendRequest timeout is _not_ configured on the route, retry
	attempts MAY time out after an implementation default duration, or MAY
	remain pending until a configured Request timeout or implementation
	default duration for total request time is reached.

	When this field is unspecified, the time to wait between retry attempts
	is implementation-specific.

	Support: Extended
	"""
													pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
													type:    "string"
												}
												codes: {
													description: """
	Codes defines the HTTP response status codes for which a backend request
	should be retried.

	Support: Extended
	"""
													items: {
														description: """
	HTTPRouteRetryStatusCode defines an HTTP response status code for
	which a backend request should be retried.

	Implementations MUST support the following status codes as retryable:

	* 500
	* 502
	* 503
	* 504

	Implementations MAY support specifying additional discrete values in the
	500-599 range.

	Implementations MAY support specifying discrete values in the 400-499 range,
	which are often inadvisable to retry.

	<gateway:experimental>
	"""
														maximum: 599
														minimum: 400
														type:    "integer"
													}
													type: "array"
												}
											}
											type: "object"
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
										timeouts: {
											description: """
	Timeouts defines the timeouts that can be configured for an HTTP request.

	Support: Extended
	"""
											properties: {
												backendRequest: {
													description: """
	BackendRequest specifies a timeout for an individual request from the gateway
	to a backend. This covers the time from when the request first starts being
	sent from the gateway to when the full response has been received from the backend.

	Setting a timeout to the zero duration (e.g. "0s") SHOULD disable the timeout
	completely. Implementations that cannot completely disable the timeout MUST
	instead interpret the zero duration as the longest possible value to which
	the timeout can be set.

	An entire client HTTP transaction with a gateway, covered by the Request timeout,
	may result in more than one call from the gateway to the destination backend,
	for example, if automatic retries are supported.

	The value of BackendRequest must be a Gateway API Duration string as defined by
	GEP-2257.  When this field is unspecified, its behavior is implementation-specific;
	when specified, the value of BackendRequest must be no more than the value of the
	Request timeout (since the Request timeout encompasses the BackendRequest timeout).

	Support: Extended
	"""
													pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
													type:    "string"
												}
												request: {
													description: """
	Request specifies the maximum duration for a gateway to respond to an HTTP request.
	If the gateway has not been able to respond before this deadline is met, the gateway
	MUST return a timeout error.

	For example, setting the `rules.timeouts.request` field to the value `10s` in an
	`HTTPRoute` will cause a timeout if a client request is taking longer than 10 seconds
	to complete.

	Setting a timeout to the zero duration (e.g. "0s") SHOULD disable the timeout
	completely. Implementations that cannot completely disable the timeout MUST
	instead interpret the zero duration as the longest possible value to which
	the timeout can be set.

	This timeout is intended to cover as close to the whole request-response transaction
	as possible although an implementation MAY choose to start the timeout after the entire
	request stream has been received instead of immediately after the transaction is
	initiated by the client.

	The value of Request is a Gateway API Duration string as defined by GEP-2257. When this
	field is unspecified, request timeout behavior is implementation-specific.

	Support: Extended
	"""
													pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
													type:    "string"
												}
											}
											type: "object"
											"x-kubernetes-validations": [{
												message: "backendRequest timeout cannot be longer than request timeout"
												rule:    "!(has(self.request) && has(self.backendRequest) && duration(self.request) != duration('0s') && duration(self.backendRequest) > duration(self.request))"
											}]
										}
									}
									type: "object"
									"x-kubernetes-validations": [{
										message: "RequestRedirect filter must not be used together with backendRefs"
										rule:    "(has(self.backendRefs) && size(self.backendRefs) > 0) ? (!has(self.filters) || self.filters.all(f, !has(f.requestRedirect))): true"
									}, {
										message: "When using RequestRedirect filter with path.replacePrefixMatch, exactly one PathPrefix match must be specified"
										rule:    "(has(self.filters) && self.filters.exists_one(f, has(f.requestRedirect) && has(f.requestRedirect.path) && f.requestRedirect.path.type == 'ReplacePrefixMatch' && has(f.requestRedirect.path.replacePrefixMatch))) ? ((size(self.matches) != 1 || !has(self.matches[0].path) || self.matches[0].path.type != 'PathPrefix') ? false : true) : true"
									}, {
										message: "When using URLRewrite filter with path.replacePrefixMatch, exactly one PathPrefix match must be specified"
										rule:    "(has(self.filters) && self.filters.exists_one(f, has(f.urlRewrite) && has(f.urlRewrite.path) && f.urlRewrite.path.type == 'ReplacePrefixMatch' && has(f.urlRewrite.path.replacePrefixMatch))) ? ((size(self.matches) != 1 || !has(self.matches[0].path) || self.matches[0].path.type != 'PathPrefix') ? false : true) : true"
									}, {
										message: "Within backendRefs, when using RequestRedirect filter with path.replacePrefixMatch, exactly one PathPrefix match must be specified"
										rule:    "(has(self.backendRefs) && self.backendRefs.exists_one(b, (has(b.filters) && b.filters.exists_one(f, has(f.requestRedirect) && has(f.requestRedirect.path) && f.requestRedirect.path.type == 'ReplacePrefixMatch' && has(f.requestRedirect.path.replacePrefixMatch))) )) ? ((size(self.matches) != 1 || !has(self.matches[0].path) || self.matches[0].path.type != 'PathPrefix') ? false : true) : true"
									}, {
										message: "Within backendRefs, When using URLRewrite filter with path.replacePrefixMatch, exactly one PathPrefix match must be specified"
										rule:    "(has(self.backendRefs) && self.backendRefs.exists_one(b, (has(b.filters) && b.filters.exists_one(f, has(f.urlRewrite) && has(f.urlRewrite.path) && f.urlRewrite.path.type == 'ReplacePrefixMatch' && has(f.urlRewrite.path.replacePrefixMatch))) )) ? ((size(self.matches) != 1 || !has(self.matches[0].path) || self.matches[0].path.type != 'PathPrefix') ? false : true) : true"
									}]
								}
								maxItems: 16
								type:     "array"
								"x-kubernetes-validations": [{
									message: "While 16 rules and 64 matches per rule are allowed, the total number of matches across all rules in a route must be less than 128"
									rule:    "(self.size() > 0 ? self[0].matches.size() : 0) + (self.size() > 1 ? self[1].matches.size() : 0) + (self.size() > 2 ? self[2].matches.size() : 0) + (self.size() > 3 ? self[3].matches.size() : 0) + (self.size() > 4 ? self[4].matches.size() : 0) + (self.size() > 5 ? self[5].matches.size() : 0) + (self.size() > 6 ? self[6].matches.size() : 0) + (self.size() > 7 ? self[7].matches.size() : 0) + (self.size() > 8 ? self[8].matches.size() : 0) + (self.size() > 9 ? self[9].matches.size() : 0) + (self.size() > 10 ? self[10].matches.size() : 0) + (self.size() > 11 ? self[11].matches.size() : 0) + (self.size() > 12 ? self[12].matches.size() : 0) + (self.size() > 13 ? self[13].matches.size() : 0) + (self.size() > 14 ? self[14].matches.size() : 0) + (self.size() > 15 ? self[15].matches.size() : 0) <= 128"
								}, {
									message: "Rule name must be unique within the route"
									rule:    "self.all(l1, !has(l1.name) || self.exists_one(l2, has(l2.name) && l1.name == l2.name))"
								}]
							}
						}
						type: "object"
					}
					status: {
						description: "Status defines the current state of HTTPRoute."
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
				required: ["spec"]
				type: "object"
			}
			served:  true
			storage: true
			subresources: status: {}
		}, {
			additionalPrinterColumns: [{
				jsonPath: ".spec.hostnames"
				name:     "Hostnames"
				type:     "string"
			}, {
				jsonPath: ".metadata.creationTimestamp"
				name:     "Age"
				type:     "date"
			}]
			name: "v1beta1"
			schema: openAPIV3Schema: {
				description: """
					HTTPRoute provides a way to route HTTP requests. This includes the capability
					to match requests by hostname, path, header, or query param. Filters can be
					used to specify additional processing steps. Backends specify where matching
					requests should be routed.
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
						description: "Spec defines the desired state of HTTPRoute."
						properties: {
							hostnames: {
								description: """
	Hostnames defines a set of hostnames that should match against the HTTP Host
	header to select a HTTPRoute used to process the request. Implementations
	MUST ignore any port value specified in the HTTP Host header while
	performing a match and (absent of any applicable header modification
	configuration) MUST forward this header unmodified to the backend.

	Valid values for Hostnames are determined by RFC 1123 definition of a
	hostname with 2 notable exceptions:

	1. IPs are not allowed.
	2. A hostname may be prefixed with a wildcard label (`*.`). The wildcard
	   label must appear by itself as the first label.

	If a hostname is specified by both the Listener and HTTPRoute, there
	must be at least one intersecting hostname for the HTTPRoute to be
	attached to the Listener. For example:

	* A Listener with `test.example.com` as the hostname matches HTTPRoutes
	  that have either not specified any hostnames, or have specified at
	  least one of `test.example.com` or `*.example.com`.
	* A Listener with `*.example.com` as the hostname matches HTTPRoutes
	  that have either not specified any hostnames or have specified at least
	  one hostname that matches the Listener hostname. For example,
	  `*.example.com`, `test.example.com`, and `foo.test.example.com` would
	  all match. On the other hand, `example.com` and `test.example.net` would
	  not match.

	Hostnames that are prefixed with a wildcard label (`*.`) are interpreted
	as a suffix match. That means that a match for `*.example.com` would match
	both `test.example.com`, and `foo.test.example.com`, but not `example.com`.

	If both the Listener and HTTPRoute have specified hostnames, any
	HTTPRoute hostnames that do not match the Listener hostname MUST be
	ignored. For example, if a Listener specified `*.example.com`, and the
	HTTPRoute specified `test.example.com` and `test.example.net`,
	`test.example.net` must not be considered for a match.

	If both the Listener and HTTPRoute have specified hostnames, and none
	match with the criteria above, then the HTTPRoute is not accepted. The
	implementation must raise an 'Accepted' Condition with a status of
	`False` in the corresponding RouteParentStatus.

	In the event that multiple HTTPRoutes specify intersecting hostnames (e.g.
	overlapping wildcard matching and exact matching hostnames), precedence must
	be given to rules from the HTTPRoute with the largest number of:

	* Characters in a matching non-wildcard hostname.
	* Characters in a matching hostname.

	If ties exist across multiple Routes, the matching precedence rules for
	HTTPRouteMatches takes over.

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
								default: [{
									matches: [{
										path: {
											type:  "PathPrefix"
											value: "/"
										}
									}]
								}]
								description: """
	Rules are a list of HTTP matchers, filters and actions.


	"""
								items: {
									description: """
	HTTPRouteRule defines semantics for matching an HTTP request based on
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
	receive a 500 status code.

	See the HTTPBackendRef definition for the rules about what makes a single
	HTTPBackendRef invalid.

	When a HTTPBackendRef is invalid, 500 status codes MUST be returned for
	requests that would have otherwise been routed to an invalid backend. If
	multiple backends are specified, and some are invalid, the proportion of
	requests that would otherwise have been routed to an invalid backend
	MUST receive a 500 status code.

	For example, if two backends are specified with equal weights, and one is
	invalid, 50 percent of traffic must receive a 500. Implementations may
	choose how that 50 percent is determined.

	When a HTTPBackendRef refers to a Service that has no ready endpoints,
	implementations SHOULD return a 503 for requests to that backend instead.
	If an implementation chooses to do this, all of the above rules for 500 responses
	MUST also apply for responses that return a 503.

	Support: Core for Kubernetes Service

	Support: Extended for Kubernetes ServiceImport

	Support: Implementation-specific for any other resource

	Support for weight: Core
	"""
											items: {
												description: """
	HTTPBackendRef defines how a HTTPRoute forwards a HTTP request.

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
	Filters defined at this level should be executed if and only if the
	request is being forwarded to the backend defined here.

	Support: Implementation-specific (For broader support of filters, use the
	Filters field in HTTPRouteRule.)
	"""
														items: {
															description: """
	HTTPRouteFilter defines processing steps that must be completed during the
	request or response lifecycle. HTTPRouteFilters are meant as an extension
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

	This filter can be used multiple times within the same rule.

	Support: Implementation-specific
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
																requestRedirect: {
																	description: """
	RequestRedirect defines a schema for a filter that responds to the
	request with an HTTP redirection.

	Support: Core
	"""
																	properties: {
																		hostname: {
																			description: """
	Hostname is the hostname to be used in the value of the `Location`
	header in the response.
	When empty, the hostname in the `Host` header of the request is used.

	Support: Core
	"""
																			maxLength: 253
																			minLength: 1
																			pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																			type:      "string"
																		}
																		path: {
																			description: """
	Path defines parameters used to modify the path of the incoming request.
	The modified path is then used to construct the `Location` header. When
	empty, the request path is used as-is.

	Support: Extended
	"""
																			properties: {
																				replaceFullPath: {
																					description: """
	ReplaceFullPath specifies the value with which to replace the full path
	of a request during a rewrite or redirect.
	"""
																					maxLength: 1024
																					type:      "string"
																				}
																				replacePrefixMatch: {
																					description: """
	ReplacePrefixMatch specifies the value with which to replace the prefix
	match of a request during a rewrite or redirect. For example, a request
	to "/foo/bar" with a prefix match of "/foo" and a ReplacePrefixMatch
	of "/xyz" would be modified to "/xyz/bar".

	Note that this matches the behavior of the PathPrefix match type. This
	matches full path elements. A path element refers to the list of labels
	in the path split by the `/` separator. When specified, a trailing `/` is
	ignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all
	match the prefix `/abc`, but the path `/abcd` would not.

	ReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.
	Using any other HTTPRouteMatch type on the same HTTPRouteRule will result in
	the implementation setting the Accepted Condition for the Route to `status: False`.

	Request Path | Prefix Match | Replace Prefix | Modified Path
	"""
																					maxLength: 1024
																					type:      "string"
																				}
																				type: {
																					description: """
	Type defines the type of path modifier. Additional types may be
	added in a future release of the API.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
																					enum: [
																						"ReplaceFullPath",
																						"ReplacePrefixMatch",
																					]
																					type: "string"
																				}
																			}
																			required: ["type"]
																			type: "object"
																			"x-kubernetes-validations": [{
																				message: "replaceFullPath must be specified when type is set to 'ReplaceFullPath'"
																				rule:    "self.type == 'ReplaceFullPath' ? has(self.replaceFullPath) : true"
																			}, {
																				message: "type must be 'ReplaceFullPath' when replaceFullPath is set"
																				rule:    "has(self.replaceFullPath) ? self.type == 'ReplaceFullPath' : true"
																			}, {
																				message: "replacePrefixMatch must be specified when type is set to 'ReplacePrefixMatch'"
																				rule:    "self.type == 'ReplacePrefixMatch' ? has(self.replacePrefixMatch) : true"
																			}, {
																				message: "type must be 'ReplacePrefixMatch' when replacePrefixMatch is set"
																				rule:    "has(self.replacePrefixMatch) ? self.type == 'ReplacePrefixMatch' : true"
																			}]
																		}
																		port: {
																			description: """
	Port is the port to be used in the value of the `Location`
	header in the response.

	If no port is specified, the redirect port MUST be derived using the
	following rules:

	* If redirect scheme is not-empty, the redirect port MUST be the well-known
	  port associated with the redirect scheme. Specifically "http" to port 80
	  and "https" to port 443. If the redirect scheme does not have a
	  well-known port, the listener port of the Gateway SHOULD be used.
	* If redirect scheme is empty, the redirect port MUST be the Gateway
	  Listener port.

	Implementations SHOULD NOT add the port number in the 'Location'
	header in the following cases:

	* A Location header that will use HTTP (whether that is determined via
	  the Listener protocol or the Scheme field) _and_ use port 80.
	* A Location header that will use HTTPS (whether that is determined via
	  the Listener protocol or the Scheme field) _and_ use port 443.

	Support: Extended
	"""
																			format:  "int32"
																			maximum: 65535
																			minimum: 1
																			type:    "integer"
																		}
																		scheme: {
																			description: """
	Scheme is the scheme to be used in the value of the `Location` header in
	the response. When empty, the scheme of the request is used.

	Scheme redirects can affect the port of the redirect, for more information,
	refer to the documentation for the port field of this filter.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.

	Support: Extended
	"""
																			enum: [
																				"http",
																				"https",
																			]
																			type: "string"
																		}
																		statusCode: {
																			default: 302
																			description: """
	StatusCode is the HTTP status code to be used in response.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.

	Support: Core
	"""
																			enum: [
																				301,
																				302,
																			]
																			type: "integer"
																		}
																	}
																	type: "object"
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
	  implementations must support core filters.

	- Extended: Filter types and their corresponding configuration defined by
	  "Support: Extended" in this package, e.g. "RequestMirror". Implementers
	  are encouraged to support extended filters.

	- Implementation-specific: Filters that are defined and supported by
	  specific vendors.
	  In the future, filters showing convergence in behavior across multiple
	  implementations will be considered for inclusion in extended or core
	  conformance levels. Filter-specific configuration for such filters
	  is specified using the ExtensionRef field. `Type` should be set to
	  "ExtensionRef" for custom filters.

	Implementers are encouraged to define custom implementation types to
	extend the core API with implementation-specific behavior.

	If a reference to a custom filter type cannot be resolved, the filter
	MUST NOT be skipped. Instead, requests that would have been processed by
	that filter MUST receive a HTTP error response.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
																	enum: [
																		"RequestHeaderModifier",
																		"ResponseHeaderModifier",
																		"RequestMirror",
																		"RequestRedirect",
																		"URLRewrite",
																		"ExtensionRef",
																	]
																	type: "string"
																}
																urlRewrite: {
																	description: """
	URLRewrite defines a schema for a filter that modifies a request during forwarding.

	Support: Extended
	"""
																	properties: {
																		hostname: {
																			description: """
	Hostname is the value to be used to replace the Host header value during
	forwarding.

	Support: Extended
	"""
																			maxLength: 253
																			minLength: 1
																			pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																			type:      "string"
																		}
																		path: {
																			description: """
	Path defines a path rewrite.

	Support: Extended
	"""
																			properties: {
																				replaceFullPath: {
																					description: """
	ReplaceFullPath specifies the value with which to replace the full path
	of a request during a rewrite or redirect.
	"""
																					maxLength: 1024
																					type:      "string"
																				}
																				replacePrefixMatch: {
																					description: """
	ReplacePrefixMatch specifies the value with which to replace the prefix
	match of a request during a rewrite or redirect. For example, a request
	to "/foo/bar" with a prefix match of "/foo" and a ReplacePrefixMatch
	of "/xyz" would be modified to "/xyz/bar".

	Note that this matches the behavior of the PathPrefix match type. This
	matches full path elements. A path element refers to the list of labels
	in the path split by the `/` separator. When specified, a trailing `/` is
	ignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all
	match the prefix `/abc`, but the path `/abcd` would not.

	ReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.
	Using any other HTTPRouteMatch type on the same HTTPRouteRule will result in
	the implementation setting the Accepted Condition for the Route to `status: False`.

	Request Path | Prefix Match | Replace Prefix | Modified Path
	"""
																					maxLength: 1024
																					type:      "string"
																				}
																				type: {
																					description: """
	Type defines the type of path modifier. Additional types may be
	added in a future release of the API.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
																					enum: [
																						"ReplaceFullPath",
																						"ReplacePrefixMatch",
																					]
																					type: "string"
																				}
																			}
																			required: ["type"]
																			type: "object"
																			"x-kubernetes-validations": [{
																				message: "replaceFullPath must be specified when type is set to 'ReplaceFullPath'"
																				rule:    "self.type == 'ReplaceFullPath' ? has(self.replaceFullPath) : true"
																			}, {
																				message: "type must be 'ReplaceFullPath' when replaceFullPath is set"
																				rule:    "has(self.replaceFullPath) ? self.type == 'ReplaceFullPath' : true"
																			}, {
																				message: "replacePrefixMatch must be specified when type is set to 'ReplacePrefixMatch'"
																				rule:    "self.type == 'ReplacePrefixMatch' ? has(self.replacePrefixMatch) : true"
																			}, {
																				message: "type must be 'ReplacePrefixMatch' when replacePrefixMatch is set"
																				rule:    "has(self.replacePrefixMatch) ? self.type == 'ReplacePrefixMatch' : true"
																			}]
																		}
																	}
																	type: "object"
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
																message: "filter.requestRedirect must be nil if the filter.type is not RequestRedirect"
																rule:    "!(has(self.requestRedirect) && self.type != 'RequestRedirect')"
															}, {
																message: "filter.requestRedirect must be specified for RequestRedirect filter.type"
																rule:    "!(!has(self.requestRedirect) && self.type == 'RequestRedirect')"
															}, {
																message: "filter.urlRewrite must be nil if the filter.type is not URLRewrite"
																rule:    "!(has(self.urlRewrite) && self.type != 'URLRewrite')"
															}, {
																message: "filter.urlRewrite must be specified for URLRewrite filter.type"
																rule:    "!(!has(self.urlRewrite) && self.type == 'URLRewrite')"
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
															message: "May specify either httpRouteFilterRequestRedirect or httpRouteFilterRequestRewrite, but not both"
															rule:    "!(self.exists(f, f.type == 'RequestRedirect') && self.exists(f, f.type == 'URLRewrite'))"
														}, {
															message: "May specify either httpRouteFilterRequestRedirect or httpRouteFilterRequestRewrite, but not both"
															rule:    "!(self.exists(f, f.type == 'RequestRedirect') && self.exists(f, f.type == 'URLRewrite'))"
														}, {
															message: "RequestHeaderModifier filter cannot be repeated"
															rule:    "self.filter(f, f.type == 'RequestHeaderModifier').size() <= 1"
														}, {
															message: "ResponseHeaderModifier filter cannot be repeated"
															rule:    "self.filter(f, f.type == 'ResponseHeaderModifier').size() <= 1"
														}, {
															message: "RequestRedirect filter cannot be repeated"
															rule:    "self.filter(f, f.type == 'RequestRedirect').size() <= 1"
														}, {
															message: "URLRewrite filter cannot be repeated"
															rule:    "self.filter(f, f.type == 'URLRewrite').size() <= 1"
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

	Wherever possible, implementations SHOULD implement filters in the order
	they are specified.

	Implementations MAY choose to implement this ordering strictly, rejecting
	any combination or order of filters that can not be supported. If implementations
	choose a strict interpretation of filter ordering, they MUST clearly document
	that behavior.

	To reject an invalid combination or order of filters, implementations SHOULD
	consider the Route Rules with this configuration invalid. If all Route Rules
	in a Route are invalid, the entire Route would be considered invalid. If only
	a portion of Route Rules are invalid, implementations MUST set the
	"PartiallyInvalid" condition for the Route.

	Conformance-levels at this level are defined based on the type of filter:

	- ALL core filters MUST be supported by all implementations.
	- Implementers are encouraged to support extended filters.
	- Implementation-specific custom filters have no API guarantees across
	  implementations.

	Specifying the same filter multiple times is not supported unless explicitly
	indicated in the filter.

	All filters are expected to be compatible with each other except for the
	URLRewrite and RequestRedirect filters, which may not be combined. If an
	implementation can not support other combinations of filters, they must clearly
	document that limitation. In cases where incompatible or unsupported
	filters are specified and cause the `Accepted` condition to be set to status
	`False`, implementations may use the `IncompatibleFilters` reason to specify
	this configuration error.

	Support: Core
	"""
											items: {
												description: """
	HTTPRouteFilter defines processing steps that must be completed during the
	request or response lifecycle. HTTPRouteFilters are meant as an extension
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

	This filter can be used multiple times within the same rule.

	Support: Implementation-specific
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
													requestRedirect: {
														description: """
	RequestRedirect defines a schema for a filter that responds to the
	request with an HTTP redirection.

	Support: Core
	"""
														properties: {
															hostname: {
																description: """
	Hostname is the hostname to be used in the value of the `Location`
	header in the response.
	When empty, the hostname in the `Host` header of the request is used.

	Support: Core
	"""
																maxLength: 253
																minLength: 1
																pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																type:      "string"
															}
															path: {
																description: """
	Path defines parameters used to modify the path of the incoming request.
	The modified path is then used to construct the `Location` header. When
	empty, the request path is used as-is.

	Support: Extended
	"""
																properties: {
																	replaceFullPath: {
																		description: """
	ReplaceFullPath specifies the value with which to replace the full path
	of a request during a rewrite or redirect.
	"""
																		maxLength: 1024
																		type:      "string"
																	}
																	replacePrefixMatch: {
																		description: """
	ReplacePrefixMatch specifies the value with which to replace the prefix
	match of a request during a rewrite or redirect. For example, a request
	to "/foo/bar" with a prefix match of "/foo" and a ReplacePrefixMatch
	of "/xyz" would be modified to "/xyz/bar".

	Note that this matches the behavior of the PathPrefix match type. This
	matches full path elements. A path element refers to the list of labels
	in the path split by the `/` separator. When specified, a trailing `/` is
	ignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all
	match the prefix `/abc`, but the path `/abcd` would not.

	ReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.
	Using any other HTTPRouteMatch type on the same HTTPRouteRule will result in
	the implementation setting the Accepted Condition for the Route to `status: False`.

	Request Path | Prefix Match | Replace Prefix | Modified Path
	"""
																		maxLength: 1024
																		type:      "string"
																	}
																	type: {
																		description: """
	Type defines the type of path modifier. Additional types may be
	added in a future release of the API.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
																		enum: [
																			"ReplaceFullPath",
																			"ReplacePrefixMatch",
																		]
																		type: "string"
																	}
																}
																required: ["type"]
																type: "object"
																"x-kubernetes-validations": [{
																	message: "replaceFullPath must be specified when type is set to 'ReplaceFullPath'"
																	rule:    "self.type == 'ReplaceFullPath' ? has(self.replaceFullPath) : true"
																}, {
																	message: "type must be 'ReplaceFullPath' when replaceFullPath is set"
																	rule:    "has(self.replaceFullPath) ? self.type == 'ReplaceFullPath' : true"
																}, {
																	message: "replacePrefixMatch must be specified when type is set to 'ReplacePrefixMatch'"
																	rule:    "self.type == 'ReplacePrefixMatch' ? has(self.replacePrefixMatch) : true"
																}, {
																	message: "type must be 'ReplacePrefixMatch' when replacePrefixMatch is set"
																	rule:    "has(self.replacePrefixMatch) ? self.type == 'ReplacePrefixMatch' : true"
																}]
															}
															port: {
																description: """
	Port is the port to be used in the value of the `Location`
	header in the response.

	If no port is specified, the redirect port MUST be derived using the
	following rules:

	* If redirect scheme is not-empty, the redirect port MUST be the well-known
	  port associated with the redirect scheme. Specifically "http" to port 80
	  and "https" to port 443. If the redirect scheme does not have a
	  well-known port, the listener port of the Gateway SHOULD be used.
	* If redirect scheme is empty, the redirect port MUST be the Gateway
	  Listener port.

	Implementations SHOULD NOT add the port number in the 'Location'
	header in the following cases:

	* A Location header that will use HTTP (whether that is determined via
	  the Listener protocol or the Scheme field) _and_ use port 80.
	* A Location header that will use HTTPS (whether that is determined via
	  the Listener protocol or the Scheme field) _and_ use port 443.

	Support: Extended
	"""
																format:  "int32"
																maximum: 65535
																minimum: 1
																type:    "integer"
															}
															scheme: {
																description: """
	Scheme is the scheme to be used in the value of the `Location` header in
	the response. When empty, the scheme of the request is used.

	Scheme redirects can affect the port of the redirect, for more information,
	refer to the documentation for the port field of this filter.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.

	Support: Extended
	"""
																enum: [
																	"http",
																	"https",
																]
																type: "string"
															}
															statusCode: {
																default: 302
																description: """
	StatusCode is the HTTP status code to be used in response.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.

	Support: Core
	"""
																enum: [
																	301,
																	302,
																]
																type: "integer"
															}
														}
														type: "object"
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
	  implementations must support core filters.

	- Extended: Filter types and their corresponding configuration defined by
	  "Support: Extended" in this package, e.g. "RequestMirror". Implementers
	  are encouraged to support extended filters.

	- Implementation-specific: Filters that are defined and supported by
	  specific vendors.
	  In the future, filters showing convergence in behavior across multiple
	  implementations will be considered for inclusion in extended or core
	  conformance levels. Filter-specific configuration for such filters
	  is specified using the ExtensionRef field. `Type` should be set to
	  "ExtensionRef" for custom filters.

	Implementers are encouraged to define custom implementation types to
	extend the core API with implementation-specific behavior.

	If a reference to a custom filter type cannot be resolved, the filter
	MUST NOT be skipped. Instead, requests that would have been processed by
	that filter MUST receive a HTTP error response.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
														enum: [
															"RequestHeaderModifier",
															"ResponseHeaderModifier",
															"RequestMirror",
															"RequestRedirect",
															"URLRewrite",
															"ExtensionRef",
														]
														type: "string"
													}
													urlRewrite: {
														description: """
	URLRewrite defines a schema for a filter that modifies a request during forwarding.

	Support: Extended
	"""
														properties: {
															hostname: {
																description: """
	Hostname is the value to be used to replace the Host header value during
	forwarding.

	Support: Extended
	"""
																maxLength: 253
																minLength: 1
																pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																type:      "string"
															}
															path: {
																description: """
	Path defines a path rewrite.

	Support: Extended
	"""
																properties: {
																	replaceFullPath: {
																		description: """
	ReplaceFullPath specifies the value with which to replace the full path
	of a request during a rewrite or redirect.
	"""
																		maxLength: 1024
																		type:      "string"
																	}
																	replacePrefixMatch: {
																		description: """
	ReplacePrefixMatch specifies the value with which to replace the prefix
	match of a request during a rewrite or redirect. For example, a request
	to "/foo/bar" with a prefix match of "/foo" and a ReplacePrefixMatch
	of "/xyz" would be modified to "/xyz/bar".

	Note that this matches the behavior of the PathPrefix match type. This
	matches full path elements. A path element refers to the list of labels
	in the path split by the `/` separator. When specified, a trailing `/` is
	ignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all
	match the prefix `/abc`, but the path `/abcd` would not.

	ReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.
	Using any other HTTPRouteMatch type on the same HTTPRouteRule will result in
	the implementation setting the Accepted Condition for the Route to `status: False`.

	Request Path | Prefix Match | Replace Prefix | Modified Path
	"""
																		maxLength: 1024
																		type:      "string"
																	}
																	type: {
																		description: """
	Type defines the type of path modifier. Additional types may be
	added in a future release of the API.

	Note that values may be added to this enum, implementations
	must ensure that unknown values will not cause a crash.

	Unknown values here must result in the implementation setting the
	Accepted Condition for the Route to `status: False`, with a
	Reason of `UnsupportedValue`.
	"""
																		enum: [
																			"ReplaceFullPath",
																			"ReplacePrefixMatch",
																		]
																		type: "string"
																	}
																}
																required: ["type"]
																type: "object"
																"x-kubernetes-validations": [{
																	message: "replaceFullPath must be specified when type is set to 'ReplaceFullPath'"
																	rule:    "self.type == 'ReplaceFullPath' ? has(self.replaceFullPath) : true"
																}, {
																	message: "type must be 'ReplaceFullPath' when replaceFullPath is set"
																	rule:    "has(self.replaceFullPath) ? self.type == 'ReplaceFullPath' : true"
																}, {
																	message: "replacePrefixMatch must be specified when type is set to 'ReplacePrefixMatch'"
																	rule:    "self.type == 'ReplacePrefixMatch' ? has(self.replacePrefixMatch) : true"
																}, {
																	message: "type must be 'ReplacePrefixMatch' when replacePrefixMatch is set"
																	rule:    "has(self.replacePrefixMatch) ? self.type == 'ReplacePrefixMatch' : true"
																}]
															}
														}
														type: "object"
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
													message: "filter.requestRedirect must be nil if the filter.type is not RequestRedirect"
													rule:    "!(has(self.requestRedirect) && self.type != 'RequestRedirect')"
												}, {
													message: "filter.requestRedirect must be specified for RequestRedirect filter.type"
													rule:    "!(!has(self.requestRedirect) && self.type == 'RequestRedirect')"
												}, {
													message: "filter.urlRewrite must be nil if the filter.type is not URLRewrite"
													rule:    "!(has(self.urlRewrite) && self.type != 'URLRewrite')"
												}, {
													message: "filter.urlRewrite must be specified for URLRewrite filter.type"
													rule:    "!(!has(self.urlRewrite) && self.type == 'URLRewrite')"
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
												message: "May specify either httpRouteFilterRequestRedirect or httpRouteFilterRequestRewrite, but not both"
												rule:    "!(self.exists(f, f.type == 'RequestRedirect') && self.exists(f, f.type == 'URLRewrite'))"
											}, {
												message: "RequestHeaderModifier filter cannot be repeated"
												rule:    "self.filter(f, f.type == 'RequestHeaderModifier').size() <= 1"
											}, {
												message: "ResponseHeaderModifier filter cannot be repeated"
												rule:    "self.filter(f, f.type == 'ResponseHeaderModifier').size() <= 1"
											}, {
												message: "RequestRedirect filter cannot be repeated"
												rule:    "self.filter(f, f.type == 'RequestRedirect').size() <= 1"
											}, {
												message: "URLRewrite filter cannot be repeated"
												rule:    "self.filter(f, f.type == 'URLRewrite').size() <= 1"
											}]
										}
										matches: {
											default: [{
												path: {
													type:  "PathPrefix"
													value: "/"
												}
											}]
											description: """
	Matches define conditions used for matching the rule against incoming
	HTTP requests. Each match is independent, i.e. this rule will be matched
	if **any** one of the matches is satisfied.

	For example, take the following matches configuration:

	```
	matches:
	- path:
	    value: "/foo"
	  headers:
	  - name: "version"
	    value: "v2"
	- path:
	    value: "/v2/foo"
	```

	For a request to match against this rule, a request must satisfy
	EITHER of the two conditions:

	- path prefixed with `/foo` AND contains the header `version: v2`
	- path prefix of `/v2/foo`

	See the documentation for HTTPRouteMatch on how to specify multiple
	match conditions that should be ANDed together.

	If no matches are specified, the default is a prefix
	path match on "/", which has the effect of matching every
	HTTP request.

	Proxy or Load Balancer routing configuration generated from HTTPRoutes
	MUST prioritize matches based on the following criteria, continuing on
	ties. Across all rules specified on applicable Routes, precedence must be
	given to the match having:

	* "Exact" path match.
	* "Prefix" path match with largest number of characters.
	* Method match.
	* Largest number of header matches.
	* Largest number of query param matches.

	Note: The precedence of RegularExpression path matches are implementation-specific.

	If ties still exist across multiple Routes, matching precedence MUST be
	determined in order of the following criteria, continuing on ties:

	* The oldest Route based on creation timestamp.
	* The Route appearing first in alphabetical order by
	  "{namespace}/{name}".

	If ties still exist within an HTTPRoute, matching precedence MUST be granted
	to the FIRST matching rule (in list order) with a match meeting the above
	criteria.

	When no rules matching a request have been successfully attached to the
	parent a request is coming from, a HTTP 404 status code MUST be returned.
	"""
											items: {
												description: """
	HTTPRouteMatch defines the predicate used to match requests to a given
	action. Multiple match types are ANDed together, i.e. the match will
	evaluate to true only if all conditions are satisfied.

	For example, the match below will match a HTTP request only if its path
	starts with `/foo` AND it contains the `version: v1` header:

	```
	match:

	\tpath:
	\t  value: "/foo"
	\theaders:
	\t- name: "version"
	\t  value "v1"

	```
	"""
												properties: {
													headers: {
														description: """
	Headers specifies HTTP request header matchers. Multiple match values are
	ANDed together, meaning, a request must match all the specified headers
	to select the route.
	"""
														items: {
															description: """
	HTTPHeaderMatch describes how to select a HTTP route by matching HTTP request
	headers.
	"""
															properties: {
																name: {
																	description: """
	Name is the name of the HTTP Header to be matched. Name matching MUST be
	case insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).

	If multiple entries specify equivalent header names, only the first
	entry with an equivalent name MUST be considered for a match. Subsequent
	entries with an equivalent header name MUST be ignored. Due to the
	case-insensitivity of header names, "foo" and "Foo" are considered
	equivalent.

	When a header is repeated in an HTTP request, it is
	implementation-specific behavior as to how this is represented.
	Generally, proxies should follow the guidance from the RFC:
	https://www.rfc-editor.org/rfc/rfc7230.html#section-3.2.2 regarding
	processing a repeated header, with special handling for "Set-Cookie".
	"""
																	maxLength: 256
																	minLength: 1
																	pattern:   "^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
																	type:      "string"
																}
																type: {
																	default: "Exact"
																	description: """
	Type specifies how to match against the value of the header.

	Support: Core (Exact)

	Support: Implementation-specific (RegularExpression)

	Since RegularExpression HeaderMatchType has implementation-specific
	conformance, implementations can support POSIX, PCRE or any other dialects
	of regular expressions. Please read the implementation's documentation to
	determine the supported dialect.
	"""
																	enum: [
																		"Exact",
																		"RegularExpression",
																	]
																	type: "string"
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
													method: {
														description: """
	Method specifies HTTP method matcher.
	When specified, this route will be matched only if the request has the
	specified method.

	Support: Extended
	"""
														enum: [
															"GET",
															"HEAD",
															"POST",
															"PUT",
															"DELETE",
															"CONNECT",
															"OPTIONS",
															"TRACE",
															"PATCH",
														]
														type: "string"
													}
													path: {
														default: {
															type:  "PathPrefix"
															value: "/"
														}
														description: """
	Path specifies a HTTP request path matcher. If this field is not
	specified, a default prefix match on the "/" path is provided.
	"""
														properties: {
															type: {
																default: "PathPrefix"
																description: """
	Type specifies how to match against the path Value.

	Support: Core (Exact, PathPrefix)

	Support: Implementation-specific (RegularExpression)
	"""
																enum: [
																	"Exact",
																	"PathPrefix",
																	"RegularExpression",
																]
																type: "string"
															}
															value: {
																default:     "/"
																description: "Value of the HTTP path to match against."
																maxLength:   1024
																type:        "string"
															}
														}
														type: "object"
														"x-kubernetes-validations": [{
															message: "value must be an absolute path and start with '/' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? self.value.startsWith('/') : true"
														}, {
															message: "must not contain '//' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('//') : true"
														}, {
															message: "must not contain '/./' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('/./') : true"
														}, {
															message: "must not contain '/../' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('/../') : true"
														}, {
															message: "must not contain '%2f' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('%2f') : true"
														}, {
															message: "must not contain '%2F' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('%2F') : true"
														}, {
															message: "must not contain '#' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.contains('#') : true"
														}, {
															message: "must not end with '/..' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.endsWith('/..') : true"
														}, {
															message: "must not end with '/.' when type one of ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? !self.value.endsWith('/.') : true"
														}, {
															message: "type must be one of ['Exact', 'PathPrefix', 'RegularExpression']"
															rule:    "self.type in ['Exact','PathPrefix'] || self.type == 'RegularExpression'"
														}, {
															message: "must only contain valid characters (matching ^(?:[-A-Za-z0-9/._~!$&'()*+,;=:@]|[%][0-9a-fA-F]{2})+$) for types ['Exact', 'PathPrefix']"
															rule:    "(self.type in ['Exact','PathPrefix']) ? self.value.matches(r\"\"\"^(?:[-A-Za-z0-9/._~!$&'()*+,;=:@]|[%][0-9a-fA-F]{2})+$\"\"\") : true"
														}]
													}
													queryParams: {
														description: """
	QueryParams specifies HTTP query parameter matchers. Multiple match
	values are ANDed together, meaning, a request must match all the
	specified query parameters to select the route.

	Support: Extended
	"""
														items: {
															description: """
	HTTPQueryParamMatch describes how to select a HTTP route by matching HTTP
	query parameters.
	"""
															properties: {
																name: {
																	description: """
	Name is the name of the HTTP query param to be matched. This must be an
	exact string match. (See
	https://tools.ietf.org/html/rfc7230#section-2.7.3).

	If multiple entries specify equivalent query param names, only the first
	entry with an equivalent name MUST be considered for a match. Subsequent
	entries with an equivalent query param name MUST be ignored.

	If a query param is repeated in an HTTP request, the behavior is
	purposely left undefined, since different data planes have different
	capabilities. However, it is *recommended* that implementations should
	match against the first value of the param if the data plane supports it,
	as this behavior is expected in other load balancing contexts outside of
	the Gateway API.

	Users SHOULD NOT route traffic based on repeated query params to guard
	themselves against potential differences in the implementations.
	"""
																	maxLength: 256
																	minLength: 1
																	pattern:   "^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
																	type:      "string"
																}
																type: {
																	default: "Exact"
																	description: """
	Type specifies how to match against the value of the query parameter.

	Support: Extended (Exact)

	Support: Implementation-specific (RegularExpression)

	Since RegularExpression QueryParamMatchType has Implementation-specific
	conformance, implementations can support POSIX, PCRE or any other
	dialects of regular expressions. Please read the implementation's
	documentation to determine the supported dialect.
	"""
																	enum: [
																		"Exact",
																		"RegularExpression",
																	]
																	type: "string"
																}
																value: {
																	description: "Value is the value of HTTP query param to be matched."
																	maxLength:   1024
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
											maxItems: 64
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
										retry: {
											description: """
	Retry defines the configuration for when to retry an HTTP request.

	Support: Extended


	"""
											properties: {
												attempts: {
													description: """
	Attempts specifies the maxmimum number of times an individual request
	from the gateway to a backend should be retried.

	If the maximum number of retries has been attempted without a successful
	response from the backend, the Gateway MUST return an error.

	When this field is unspecified, the number of times to attempt to retry
	a backend request is implementation-specific.

	Support: Extended
	"""
													type: "integer"
												}
												backoff: {
													description: """
	Backoff specifies the minimum duration a Gateway should wait between
	retry attempts and is represented in Gateway API Duration formatting.

	For example, setting the `rules[].retry.backoff` field to the value
	`100ms` will cause a backend request to first be retried approximately
	100 milliseconds after timing out or receiving a response code configured
	to be retryable.

	An implementation MAY use an exponential or alternative backoff strategy
	for subsequent retry attempts, MAY cap the maximum backoff duration to
	some amount greater than the specified minimum, and MAY add arbitrary
	jitter to stagger requests, as long as unsuccessful backend requests are
	not retried before the configured minimum duration.

	If a Request timeout (`rules[].timeouts.request`) is configured on the
	route, the entire duration of the initial request and any retry attempts
	MUST not exceed the Request timeout duration. If any retry attempts are
	still in progress when the Request timeout duration has been reached,
	these SHOULD be canceled if possible and the Gateway MUST immediately
	return a timeout error.

	If a BackendRequest timeout (`rules[].timeouts.backendRequest`) is
	configured on the route, any retry attempts which reach the configured
	BackendRequest timeout duration without a response SHOULD be canceled if
	possible and the Gateway should wait for at least the specified backoff
	duration before attempting to retry the backend request again.

	If a BackendRequest timeout is _not_ configured on the route, retry
	attempts MAY time out after an implementation default duration, or MAY
	remain pending until a configured Request timeout or implementation
	default duration for total request time is reached.

	When this field is unspecified, the time to wait between retry attempts
	is implementation-specific.

	Support: Extended
	"""
													pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
													type:    "string"
												}
												codes: {
													description: """
	Codes defines the HTTP response status codes for which a backend request
	should be retried.

	Support: Extended
	"""
													items: {
														description: """
	HTTPRouteRetryStatusCode defines an HTTP response status code for
	which a backend request should be retried.

	Implementations MUST support the following status codes as retryable:

	* 500
	* 502
	* 503
	* 504

	Implementations MAY support specifying additional discrete values in the
	500-599 range.

	Implementations MAY support specifying discrete values in the 400-499 range,
	which are often inadvisable to retry.

	<gateway:experimental>
	"""
														maximum: 599
														minimum: 400
														type:    "integer"
													}
													type: "array"
												}
											}
											type: "object"
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
										timeouts: {
											description: """
	Timeouts defines the timeouts that can be configured for an HTTP request.

	Support: Extended
	"""
											properties: {
												backendRequest: {
													description: """
	BackendRequest specifies a timeout for an individual request from the gateway
	to a backend. This covers the time from when the request first starts being
	sent from the gateway to when the full response has been received from the backend.

	Setting a timeout to the zero duration (e.g. "0s") SHOULD disable the timeout
	completely. Implementations that cannot completely disable the timeout MUST
	instead interpret the zero duration as the longest possible value to which
	the timeout can be set.

	An entire client HTTP transaction with a gateway, covered by the Request timeout,
	may result in more than one call from the gateway to the destination backend,
	for example, if automatic retries are supported.

	The value of BackendRequest must be a Gateway API Duration string as defined by
	GEP-2257.  When this field is unspecified, its behavior is implementation-specific;
	when specified, the value of BackendRequest must be no more than the value of the
	Request timeout (since the Request timeout encompasses the BackendRequest timeout).

	Support: Extended
	"""
													pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
													type:    "string"
												}
												request: {
													description: """
	Request specifies the maximum duration for a gateway to respond to an HTTP request.
	If the gateway has not been able to respond before this deadline is met, the gateway
	MUST return a timeout error.

	For example, setting the `rules.timeouts.request` field to the value `10s` in an
	`HTTPRoute` will cause a timeout if a client request is taking longer than 10 seconds
	to complete.

	Setting a timeout to the zero duration (e.g. "0s") SHOULD disable the timeout
	completely. Implementations that cannot completely disable the timeout MUST
	instead interpret the zero duration as the longest possible value to which
	the timeout can be set.

	This timeout is intended to cover as close to the whole request-response transaction
	as possible although an implementation MAY choose to start the timeout after the entire
	request stream has been received instead of immediately after the transaction is
	initiated by the client.

	The value of Request is a Gateway API Duration string as defined by GEP-2257. When this
	field is unspecified, request timeout behavior is implementation-specific.

	Support: Extended
	"""
													pattern: "^([0-9]{1,5}(h|m|s|ms)){1,4}$"
													type:    "string"
												}
											}
											type: "object"
											"x-kubernetes-validations": [{
												message: "backendRequest timeout cannot be longer than request timeout"
												rule:    "!(has(self.request) && has(self.backendRequest) && duration(self.request) != duration('0s') && duration(self.backendRequest) > duration(self.request))"
											}]
										}
									}
									type: "object"
									"x-kubernetes-validations": [{
										message: "RequestRedirect filter must not be used together with backendRefs"
										rule:    "(has(self.backendRefs) && size(self.backendRefs) > 0) ? (!has(self.filters) || self.filters.all(f, !has(f.requestRedirect))): true"
									}, {
										message: "When using RequestRedirect filter with path.replacePrefixMatch, exactly one PathPrefix match must be specified"
										rule:    "(has(self.filters) && self.filters.exists_one(f, has(f.requestRedirect) && has(f.requestRedirect.path) && f.requestRedirect.path.type == 'ReplacePrefixMatch' && has(f.requestRedirect.path.replacePrefixMatch))) ? ((size(self.matches) != 1 || !has(self.matches[0].path) || self.matches[0].path.type != 'PathPrefix') ? false : true) : true"
									}, {
										message: "When using URLRewrite filter with path.replacePrefixMatch, exactly one PathPrefix match must be specified"
										rule:    "(has(self.filters) && self.filters.exists_one(f, has(f.urlRewrite) && has(f.urlRewrite.path) && f.urlRewrite.path.type == 'ReplacePrefixMatch' && has(f.urlRewrite.path.replacePrefixMatch))) ? ((size(self.matches) != 1 || !has(self.matches[0].path) || self.matches[0].path.type != 'PathPrefix') ? false : true) : true"
									}, {
										message: "Within backendRefs, when using RequestRedirect filter with path.replacePrefixMatch, exactly one PathPrefix match must be specified"
										rule:    "(has(self.backendRefs) && self.backendRefs.exists_one(b, (has(b.filters) && b.filters.exists_one(f, has(f.requestRedirect) && has(f.requestRedirect.path) && f.requestRedirect.path.type == 'ReplacePrefixMatch' && has(f.requestRedirect.path.replacePrefixMatch))) )) ? ((size(self.matches) != 1 || !has(self.matches[0].path) || self.matches[0].path.type != 'PathPrefix') ? false : true) : true"
									}, {
										message: "Within backendRefs, When using URLRewrite filter with path.replacePrefixMatch, exactly one PathPrefix match must be specified"
										rule:    "(has(self.backendRefs) && self.backendRefs.exists_one(b, (has(b.filters) && b.filters.exists_one(f, has(f.urlRewrite) && has(f.urlRewrite.path) && f.urlRewrite.path.type == 'ReplacePrefixMatch' && has(f.urlRewrite.path.replacePrefixMatch))) )) ? ((size(self.matches) != 1 || !has(self.matches[0].path) || self.matches[0].path.type != 'PathPrefix') ? false : true) : true"
									}]
								}
								maxItems: 16
								type:     "array"
								"x-kubernetes-validations": [{
									message: "While 16 rules and 64 matches per rule are allowed, the total number of matches across all rules in a route must be less than 128"
									rule:    "(self.size() > 0 ? self[0].matches.size() : 0) + (self.size() > 1 ? self[1].matches.size() : 0) + (self.size() > 2 ? self[2].matches.size() : 0) + (self.size() > 3 ? self[3].matches.size() : 0) + (self.size() > 4 ? self[4].matches.size() : 0) + (self.size() > 5 ? self[5].matches.size() : 0) + (self.size() > 6 ? self[6].matches.size() : 0) + (self.size() > 7 ? self[7].matches.size() : 0) + (self.size() > 8 ? self[8].matches.size() : 0) + (self.size() > 9 ? self[9].matches.size() : 0) + (self.size() > 10 ? self[10].matches.size() : 0) + (self.size() > 11 ? self[11].matches.size() : 0) + (self.size() > 12 ? self[12].matches.size() : 0) + (self.size() > 13 ? self[13].matches.size() : 0) + (self.size() > 14 ? self[14].matches.size() : 0) + (self.size() > 15 ? self[15].matches.size() : 0) <= 128"
								}, {
									message: "Rule name must be unique within the route"
									rule:    "self.all(l1, !has(l1.name) || self.exists_one(l2, has(l2.name) && l1.name == l2.name))"
								}]
							}
						}
						type: "object"
					}
					status: {
						description: "Status defines the current state of HTTPRoute."
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
				required: ["spec"]
				type: "object"
			}
			served:  true
			storage: false
			subresources: status: {}
		}]
	}
}
