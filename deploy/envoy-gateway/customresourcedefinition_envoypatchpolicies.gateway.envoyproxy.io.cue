package deploy

k8s: "apiextensions.k8s.io": v1: CustomResourceDefinition: "": "envoypatchpolicies.gateway.envoyproxy.io": {
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: {
		annotations: "controller-gen.kubebuilder.io/version": "v0.16.1"
		name: "envoypatchpolicies.gateway.envoyproxy.io"
	}
	spec: {
		group: "gateway.envoyproxy.io"
		names: {
			categories: ["envoy-gateway"]
			kind:     "EnvoyPatchPolicy"
			listKind: "EnvoyPatchPolicyList"
			plural:   "envoypatchpolicies"
			shortNames: ["epp"]
			singular: "envoypatchpolicy"
		}
		scope: "Namespaced"
		versions: [{
			additionalPrinterColumns: [{
				jsonPath: ".status.conditions[?(@.type==\"Programmed\")].reason"
				name:     "Status"
				type:     "string"
			}, {
				jsonPath: ".metadata.creationTimestamp"
				name:     "Age"
				type:     "date"
			}]
			name: "v1alpha1"
			schema: openAPIV3Schema: {
				description: """
					EnvoyPatchPolicy allows the user to modify the generated Envoy xDS
					resources by Envoy Gateway using this patch API
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
						description: "Spec defines the desired state of EnvoyPatchPolicy."
						properties: {
							jsonPatches: {
								description: "JSONPatch defines the JSONPatch configuration."
								items: {
									description: """
	EnvoyJSONPatchConfig defines the configuration for patching a Envoy xDS Resource
	using JSONPatch semantic
	"""
									properties: {
										name: {
											description: "Name is the name of the resource"
											type:        "string"
										}
										operation: {
											description: "Patch defines the JSON Patch Operation"
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
										type: {
											description: "Type is the typed URL of the Envoy xDS Resource"
											enum: [
												"type.googleapis.com/envoy.config.listener.v3.Listener",
												"type.googleapis.com/envoy.config.route.v3.RouteConfiguration",
												"type.googleapis.com/envoy.config.cluster.v3.Cluster",
												"type.googleapis.com/envoy.config.endpoint.v3.ClusterLoadAssignment",
												"type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.Secret",
											]
											type: "string"
										}
									}
									required: [
										"name",
										"operation",
										"type",
									]
									type: "object"
								}
								type: "array"
							}
							priority: {
								description: """
	Priority of the EnvoyPatchPolicy.
	If multiple EnvoyPatchPolicies are applied to the same
	TargetRef, they will be applied in the ascending order of
	the priority i.e. int32.min has the highest priority and
	int32.max has the lowest priority.
	Defaults to 0.
	"""
								format: "int32"
								type:   "integer"
							}
							targetRef: {
								description: """
	TargetRef is the name of the Gateway API resource this policy
	is being attached to.
	By default, attaching to Gateway is supported and
	when mergeGateways is enabled it should attach to GatewayClass.
	This Policy and the TargetRef MUST be in the same namespace
	for this Policy to have effect and be applied to the Gateway
	TargetRef
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
								}
								required: [
									"group",
									"kind",
									"name",
								]
								type: "object"
							}
							type: {
								description: """
	Type decides the type of patch.
	Valid EnvoyPatchType values are "JSONPatch".
	"""
								enum: ["JSONPatch"]
								type: "string"
							}
						}
						required: [
							"targetRef",
							"type",
						]
						type: "object"
					}
					status: {
						description: "Status defines the current status of EnvoyPatchPolicy."
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
