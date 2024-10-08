package deploy

k8s: "apiextensions.k8s.io": v1: CustomResourceDefinition: "": "envoyextensionpolicies.gateway.envoyproxy.io": {
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: {
		annotations: "controller-gen.kubebuilder.io/version": "v0.15.0"
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
										backendRefs: {
											description: "BackendRefs defines the configuration of the external processing service"
											items: {
												description: "BackendRef defines how an ObjectReference that is specific to BackendRef."
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
											maxItems: 1
											minItems: 1
											type:     "array"
											"x-kubernetes-validations": [{
												message: "BackendRefs only supports Service and Backend kind."
												rule:    "self.all(f, f.kind == 'Service' || f.kind == 'Backend')"
											}, {
												message: "BackendRefs only supports Core and gateway.envoyproxy.io group."
												rule:    "self.all(f, f.group == '' || f.group == 'gateway.envoyproxy.io')"
											}]
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
									required: ["backendRefs"]
									type: "object"
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
											description: """
	Condition contains details for one aspect of the current state of this API Resource.
	---
	This struct is intended for direct use as an array at the field path .status.conditions.  For example,


	\ttype FooStatus struct{
	\t    // Represents the observations of a foo's current state.
	\t    // Known .status.conditions.type are: "Available", "Progressing", and "Degraded"
	\t    // +patchMergeKey=type
	\t    // +patchStrategy=merge
	\t    // +listType=map
	\t    // +listMapKey=type
	\t    Conditions []metav1.Condition `json:"conditions,omitempty" patchStrategy:"merge" patchMergeKey:"type" protobuf:"bytes,1,rep,name=conditions"`


	\t    // other fields
	\t}
	"""
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
													description: """
	type of condition in CamelCase or in foo.example.com/CamelCase.
	---
	Many .condition.type values are consistent across resources like Available, but because arbitrary conditions can be
	useful (see .node.status.conditions), the ability to deconflict is important.
	The regex it matches is (dns1123SubdomainFmt/)?(qualifiedNameFmt)
	"""
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
