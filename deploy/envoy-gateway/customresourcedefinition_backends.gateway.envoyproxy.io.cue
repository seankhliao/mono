package deploy

k8s: "apiextensions.k8s.io": v1: CustomResourceDefinition: "": "backends.gateway.envoyproxy.io": {
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: {
		annotations: "controller-gen.kubebuilder.io/version": "v0.16.1"
		name: "backends.gateway.envoyproxy.io"
	}
	spec: {
		group: "gateway.envoyproxy.io"
		names: {
			categories: ["envoy-gateway"]
			kind:     "Backend"
			listKind: "BackendList"
			plural:   "backends"
			shortNames: ["be"]
			singular: "backend"
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
				description: """
					Backend allows the user to configure the endpoints of a backend and
					the behavior of the connection from Envoy Proxy to the backend.
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
						description: "Spec defines the desired state of Backend."
						properties: {
							appProtocols: {
								description: "AppProtocols defines the application protocols to be supported when connecting to the backend."
								items: {
									description: "AppProtocolType defines various backend applications protocols supported by Envoy Gateway"
									enum: [
										"gateway.envoyproxy.io/h2c",
										"gateway.envoyproxy.io/ws",
										"gateway.envoyproxy.io/wss",
									]
									type: "string"
								}
								type: "array"
							}
							endpoints: {
								description: "Endpoints defines the endpoints to be used when connecting to the backend."
								items: {
									description: """
	BackendEndpoint describes a backend endpoint, which can be either a fully-qualified domain name, IP address or unix domain socket
	corresponding to Envoy's Address: https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/address.proto#config-core-v3-address
	"""
									properties: {
										fqdn: {
											description: "FQDN defines a FQDN endpoint"
											properties: {
												hostname: {
													description: "Hostname defines the FQDN hostname of the backend endpoint."
													maxLength:   253
													minLength:   1
													pattern:     "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9]))*$"
													type:        "string"
												}
												port: {
													description: "Port defines the port of the backend endpoint."
													format:      "int32"
													maximum:     65535
													minimum:     0
													type:        "integer"
												}
											}
											required: [
												"hostname",
												"port",
											]
											type: "object"
										}
										ip: {
											description: "IP defines an IP endpoint. Supports both IPv4 and IPv6 addresses."
											properties: {
												address: {
													description: """
	Address defines the IP address of the backend endpoint.
	Supports both IPv4 and IPv6 addresses.
	"""
													maxLength: 45
													minLength: 3
													pattern:   "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$|^(([0-9a-fA-F]{1,4}:){1,7}[0-9a-fA-F]{1,4}|::|(([0-9a-fA-F]{1,4}:){0,5})?(:[0-9a-fA-F]{1,4}){1,2})$"
													type:      "string"
												}
												port: {
													description: "Port defines the port of the backend endpoint."
													format:      "int32"
													maximum:     65535
													minimum:     0
													type:        "integer"
												}
											}
											required: [
												"address",
												"port",
											]
											type: "object"
										}
										unix: {
											description: "Unix defines the unix domain socket endpoint"
											properties: path: {
												description: "Path defines the unix domain socket path of the backend endpoint."
												type:        "string"
											}
											required: ["path"]
											type: "object"
										}
									}
									type: "object"
									"x-kubernetes-validations": [{
										message: "one of fqdn, ip or unix must be specified"
										rule:    "(has(self.fqdn) || has(self.ip) || has(self.unix))"
									}, {
										message: "only one of fqdn, ip or unix can be specified"
										rule:    "((has(self.fqdn) && !(has(self.ip) || has(self.unix))) || (has(self.ip) && !(has(self.fqdn) || has(self.unix))) || (has(self.unix) && !(has(self.ip) || has(self.fqdn))))"
									}]
								}
								maxItems: 4
								minItems: 1
								type:     "array"
								"x-kubernetes-validations": [{
									message: "fqdn addresses cannot be mixed with other address types"
									rule:    "self.all(f, has(f.fqdn)) || !self.exists(f, has(f.fqdn))"
								}]
							}
							fallback: {
								description: """
	Fallback indicates whether the backend is designated as a fallback.
	It is highly recommended to configure active or passive health checks to ensure that failover can be detected
	when the active backends become unhealthy and to automatically readjust once the primary backends are healthy again.
	The overprovisioning factor is set to 1.4, meaning the fallback backends will only start receiving traffic when
	the health of the active backends falls below 72%.
	"""
								type: "boolean"
							}
						}
						type: "object"
					}
					status: {
						description: "Status defines the current status of Backend."
						properties: conditions: {
							description: "Conditions describe the current conditions of the Backend."
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
							type:     "array"
							"x-kubernetes-list-map-keys": ["type"]
							"x-kubernetes-list-type": "map"
						}
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
