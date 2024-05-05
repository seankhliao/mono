package deploy

k8s: "apiextensions.k8s.io": v1: CustomResourceDefinition: "": "issuers.cert-manager.io": {
	spec: {
		group: "cert-manager.io"
		names: {
			kind:     "Issuer"
			listKind: "IssuerList"
			plural:   "issuers"
			singular: "issuer"
			categories: ["cert-manager"]
		}
		scope: "Namespaced"
		versions: [{
			name: "v1"
			subresources: status: {}
			additionalPrinterColumns: [{
				jsonPath: ".status.conditions[?(@.type==\"Ready\")].status"
				name:     "Ready"
				type:     "string"
			}, {
				jsonPath: ".status.conditions[?(@.type==\"Ready\")].message"
				name:     "Status"
				priority: 1
				type:     "string"
			}, {
				jsonPath:    ".metadata.creationTimestamp"
				description: "CreationTimestamp is a timestamp representing the server time when this object was created. It is not guaranteed to be set in happens-before order across separate operations. Clients may not set this value. It is represented in RFC3339 form and is in UTC."
				name:        "Age"
				type:        "date"
			}]
			schema: openAPIV3Schema: {
				description: "An Issuer represents a certificate issuing authority which can be referenced as part of `issuerRef` fields. It is scoped to a single namespace and can therefore only be referenced by resources within the same namespace."
				type:        "object"
				required: ["spec"]
				properties: {
					apiVersion: {
						description: "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources"
						type:        "string"
					}
					kind: {
						description: "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds"
						type:        "string"
					}
					metadata: type: "object"
					spec: {
						description: "Desired state of the Issuer resource."
						type:        "object"
						properties: {
							acme: {
								description: "ACME configures this issuer to communicate with a RFC8555 (ACME) server to obtain signed x509 certificates."
								type:        "object"
								required: [
									"privateKeySecretRef",
									"server",
								]
								properties: {
									caBundle: {
										description: "Base64-encoded bundle of PEM CAs which can be used to validate the certificate chain presented by the ACME server. Mutually exclusive with SkipTLSVerify; prefer using CABundle to prevent various kinds of security vulnerabilities. If CABundle and SkipTLSVerify are unset, the system certificate bundle inside the container is used to validate the TLS connection."
										type:        "string"
										format:      "byte"
									}
									disableAccountKeyGeneration: {
										description: "Enables or disables generating a new ACME account key. If true, the Issuer resource will *not* request a new account but will expect the account key to be supplied via an existing secret. If false, the cert-manager system will generate a new ACME account key for the Issuer. Defaults to false."
										type:        "boolean"
									}
									email: {
										description: "Email is the email address to be associated with the ACME account. This field is optional, but it is strongly recommended to be set. It will be used to contact you in case of issues with your account or certificates, including expiry notification emails. This field may be updated after the account is initially registered."
										type:        "string"
									}
									enableDurationFeature: {
										description: "Enables requesting a Not After date on certificates that matches the duration of the certificate. This is not supported by all ACME servers like Let's Encrypt. If set to true when the ACME server does not support it it will create an error on the Order. Defaults to false."
										type:        "boolean"
									}
									externalAccountBinding: {
										description: "ExternalAccountBinding is a reference to a CA external account of the ACME server. If set, upon registration cert-manager will attempt to associate the given external account credentials with the registered ACME account."
										type:        "object"
										required: [
											"keyID",
											"keySecretRef",
										]
										properties: {
											keyAlgorithm: {
												description: "Deprecated: keyAlgorithm field exists for historical compatibility reasons and should not be used. The algorithm is now hardcoded to HS256 in golang/x/crypto/acme."
												type:        "string"
												enum: [
													"HS256",
													"HS384",
													"HS512",
												]
											}
											keyID: {
												description: "keyID is the ID of the CA key that the External Account is bound to."
												type:        "string"
											}
											keySecretRef: {
												description: "keySecretRef is a Secret Key Selector referencing a data item in a Kubernetes Secret which holds the symmetric MAC key of the External Account Binding. The `key` is the index string that is paired with the key data in the Secret and should not be confused with the key data itself, or indeed with the External Account Binding keyID above. The secret key stored in the Secret **must** be un-padded, base64 URL encoded data."
												type:        "object"
												required: ["name"]
												properties: {
													key: {
														description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
														type:        "string"
													}
													name: {
														description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
														type:        "string"
													}
												}
											}
										}
									}
									preferredChain: {
										description: "PreferredChain is the chain to use if the ACME server outputs multiple. PreferredChain is no guarantee that this one gets delivered by the ACME endpoint. For example, for Let's Encrypt's DST crosssign you would use: \"DST Root CA X3\" or \"ISRG Root X1\" for the newer Let's Encrypt root CA. This value picks the first certificate bundle in the ACME alternative chains that has a certificate with this value as its issuer's CN"
										type:        "string"
										maxLength:   64
									}
									privateKeySecretRef: {
										description: "PrivateKey is the name of a Kubernetes Secret resource that will be used to store the automatically generated ACME account private key. Optionally, a `key` may be specified to select a specific entry within the named Secret resource. If `key` is not specified, a default of `tls.key` will be used."
										type:        "object"
										required: ["name"]
										properties: {
											key: {
												description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
												type:        "string"
											}
											name: {
												description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
												type:        "string"
											}
										}
									}
									server: {
										description: "Server is the URL used to access the ACME server's 'directory' endpoint. For example, for Let's Encrypt's staging endpoint, you would use: \"https://acme-staging-v02.api.letsencrypt.org/directory\". Only ACME v2 endpoints (i.e. RFC 8555) are supported."
										type:        "string"
									}
									skipTLSVerify: {
										description: "INSECURE: Enables or disables validation of the ACME server TLS certificate. If true, requests to the ACME server will not have the TLS certificate chain validated. Mutually exclusive with CABundle; prefer using CABundle to prevent various kinds of security vulnerabilities. Only enable this option in development environments. If CABundle and SkipTLSVerify are unset, the system certificate bundle inside the container is used to validate the TLS connection. Defaults to false."
										type:        "boolean"
									}
									solvers: {
										description: "Solvers is a list of challenge solvers that will be used to solve ACME challenges for the matching domains. Solver configurations must be provided in order to obtain certificates from an ACME server. For more information, see: https://cert-manager.io/docs/configuration/acme/"
										type:        "array"
										items: {
											description: "An ACMEChallengeSolver describes how to solve ACME challenges for the issuer it is part of. A selector may be provided to use different solving strategies for different DNS names. Only one of HTTP01 or DNS01 must be provided."
											type:        "object"
											properties: {
												dns01: {
													description: "Configures cert-manager to attempt to complete authorizations by performing the DNS01 challenge flow."
													type:        "object"
													properties: {
														acmeDNS: {
															description: "Use the 'ACME DNS' (https://github.com/joohoi/acme-dns) API to manage DNS01 challenge records."
															type:        "object"
															required: [
																"accountSecretRef",
																"host",
															]
															properties: {
																accountSecretRef: {
																	description: "A reference to a specific 'key' within a Secret resource. In some instances, `key` is a required field."
																	type:        "object"
																	required: ["name"]
																	properties: {
																		key: {
																			description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																			type:        "string"
																		}
																		name: {
																			description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																			type:        "string"
																		}
																	}
																}
																host: type: "string"
															}
														}
														akamai: {
															description: "Use the Akamai DNS zone management API to manage DNS01 challenge records."
															type:        "object"
															required: [
																"accessTokenSecretRef",
																"clientSecretSecretRef",
																"clientTokenSecretRef",
																"serviceConsumerDomain",
															]
															properties: {
																accessTokenSecretRef: {
																	description: "A reference to a specific 'key' within a Secret resource. In some instances, `key` is a required field."
																	type:        "object"
																	required: ["name"]
																	properties: {
																		key: {
																			description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																			type:        "string"
																		}
																		name: {
																			description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																			type:        "string"
																		}
																	}
																}
																clientSecretSecretRef: {
																	description: "A reference to a specific 'key' within a Secret resource. In some instances, `key` is a required field."
																	type:        "object"
																	required: ["name"]
																	properties: {
																		key: {
																			description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																			type:        "string"
																		}
																		name: {
																			description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																			type:        "string"
																		}
																	}
																}
																clientTokenSecretRef: {
																	description: "A reference to a specific 'key' within a Secret resource. In some instances, `key` is a required field."
																	type:        "object"
																	required: ["name"]
																	properties: {
																		key: {
																			description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																			type:        "string"
																		}
																		name: {
																			description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																			type:        "string"
																		}
																	}
																}
																serviceConsumerDomain: type: "string"
															}
														}
														azureDNS: {
															description: "Use the Microsoft Azure DNS API to manage DNS01 challenge records."
															type:        "object"
															required: [
																"resourceGroupName",
																"subscriptionID",
															]
															properties: {
																clientID: {
																	description: "if both this and ClientSecret are left unset MSI will be used"
																	type:        "string"
																}
																clientSecretSecretRef: {
																	description: "if both this and ClientID are left unset MSI will be used"
																	type:        "object"
																	required: ["name"]
																	properties: {
																		key: {
																			description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																			type:        "string"
																		}
																		name: {
																			description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																			type:        "string"
																		}
																	}
																}
																environment: {
																	description: "name of the Azure environment (default AzurePublicCloud)"
																	type:        "string"
																	enum: [
																		"AzurePublicCloud",
																		"AzureChinaCloud",
																		"AzureGermanCloud",
																		"AzureUSGovernmentCloud",
																	]
																}
																hostedZoneName: {
																	description: "name of the DNS zone that should be used"
																	type:        "string"
																}
																managedIdentity: {
																	description: "managed identity configuration, can not be used at the same time as clientID, clientSecretSecretRef or tenantID"
																	type:        "object"
																	properties: {
																		clientID: {
																			description: "client ID of the managed identity, can not be used at the same time as resourceID"
																			type:        "string"
																		}
																		resourceID: {
																			description: "resource ID of the managed identity, can not be used at the same time as clientID"
																			type:        "string"
																		}
																	}
																}
																resourceGroupName: {
																	description: "resource group the DNS zone is located in"
																	type:        "string"
																}
																subscriptionID: {
																	description: "ID of the Azure subscription"
																	type:        "string"
																}
																tenantID: {
																	description: "when specifying ClientID and ClientSecret then this field is also needed"
																	type:        "string"
																}
															}
														}
														cloudDNS: {
															description: "Use the Google Cloud DNS API to manage DNS01 challenge records."
															type:        "object"
															required: ["project"]
															properties: {
																hostedZoneName: {
																	description: "HostedZoneName is an optional field that tells cert-manager in which Cloud DNS zone the challenge record has to be created. If left empty cert-manager will automatically choose a zone."
																	type:        "string"
																}
																project: type: "string"
																serviceAccountSecretRef: {
																	description: "A reference to a specific 'key' within a Secret resource. In some instances, `key` is a required field."
																	type:        "object"
																	required: ["name"]
																	properties: {
																		key: {
																			description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																			type:        "string"
																		}
																		name: {
																			description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																			type:        "string"
																		}
																	}
																}
															}
														}
														cloudflare: {
															description: "Use the Cloudflare API to manage DNS01 challenge records."
															type:        "object"
															properties: {
																apiKeySecretRef: {
																	description: "API key to use to authenticate with Cloudflare. Note: using an API token to authenticate is now the recommended method as it allows greater control of permissions."
																	type:        "object"
																	required: ["name"]
																	properties: {
																		key: {
																			description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																			type:        "string"
																		}
																		name: {
																			description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																			type:        "string"
																		}
																	}
																}
																apiTokenSecretRef: {
																	description: "API token used to authenticate with Cloudflare."
																	type:        "object"
																	required: ["name"]
																	properties: {
																		key: {
																			description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																			type:        "string"
																		}
																		name: {
																			description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																			type:        "string"
																		}
																	}
																}
																email: {
																	description: "Email of the account, only required when using API key based authentication."
																	type:        "string"
																}
															}
														}
														cnameStrategy: {
															description: "CNAMEStrategy configures how the DNS01 provider should handle CNAME records when found in DNS zones."
															type:        "string"
															enum: [
																"None",
																"Follow",
															]
														}
														digitalocean: {
															description: "Use the DigitalOcean DNS API to manage DNS01 challenge records."
															type:        "object"
															required: ["tokenSecretRef"]
															properties: tokenSecretRef: {
																description: "A reference to a specific 'key' within a Secret resource. In some instances, `key` is a required field."
																type:        "object"
																required: ["name"]
																properties: {
																	key: {
																		description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																		type:        "string"
																	}
																	name: {
																		description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																		type:        "string"
																	}
																}
															}
														}
														rfc2136: {
															description: "Use RFC2136 (\"Dynamic Updates in the Domain Name System\") (https://datatracker.ietf.org/doc/rfc2136/) to manage DNS01 challenge records."
															type:        "object"
															required: ["nameserver"]
															properties: {
																nameserver: {
																	description: "The IP address or hostname of an authoritative DNS server supporting RFC2136 in the form host:port. If the host is an IPv6 address it must be enclosed in square brackets (e.g [2001:db8::1])\u00a0; port is optional. This field is required."
																	type:        "string"
																}
																tsigAlgorithm: {
																	description: "The TSIG Algorithm configured in the DNS supporting RFC2136. Used only when ``tsigSecretSecretRef`` and ``tsigKeyName`` are defined. Supported values are (case-insensitive): ``HMACMD5`` (default), ``HMACSHA1``, ``HMACSHA256`` or ``HMACSHA512``."
																	type:        "string"
																}
																tsigKeyName: {
																	description: "The TSIG Key name configured in the DNS. If ``tsigSecretSecretRef`` is defined, this field is required."
																	type:        "string"
																}
																tsigSecretSecretRef: {
																	description: "The name of the secret containing the TSIG value. If ``tsigKeyName`` is defined, this field is required."
																	type:        "object"
																	required: ["name"]
																	properties: {
																		key: {
																			description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																			type:        "string"
																		}
																		name: {
																			description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																			type:        "string"
																		}
																	}
																}
															}
														}
														route53: {
															description: "Use the AWS Route53 API to manage DNS01 challenge records."
															type:        "object"
															required: ["region"]
															properties: {
																accessKeyID: {
																	description: "The AccessKeyID is used for authentication. Cannot be set when SecretAccessKeyID is set. If neither the Access Key nor Key ID are set, we fall-back to using env vars, shared credentials file or AWS Instance metadata, see: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials"
																	type:        "string"
																}
																accessKeyIDSecretRef: {
																	description: "The SecretAccessKey is used for authentication. If set, pull the AWS access key ID from a key within a Kubernetes Secret. Cannot be set when AccessKeyID is set. If neither the Access Key nor Key ID are set, we fall-back to using env vars, shared credentials file or AWS Instance metadata, see: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials"
																	type:        "object"
																	required: ["name"]
																	properties: {
																		key: {
																			description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																			type:        "string"
																		}
																		name: {
																			description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																			type:        "string"
																		}
																	}
																}
																hostedZoneID: {
																	description: "If set, the provider will manage only this zone in Route53 and will not do an lookup using the route53:ListHostedZonesByName api call."
																	type:        "string"
																}
																region: {
																	description: "Always set the region when using AccessKeyID and SecretAccessKey"
																	type:        "string"
																}
																role: {
																	description: "Role is a Role ARN which the Route53 provider will assume using either the explicit credentials AccessKeyID/SecretAccessKey or the inferred credentials from environment variables, shared credentials file or AWS Instance metadata"
																	type:        "string"
																}
																secretAccessKeySecretRef: {
																	description: "The SecretAccessKey is used for authentication. If neither the Access Key nor Key ID are set, we fall-back to using env vars, shared credentials file or AWS Instance metadata, see: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials"
																	type:        "object"
																	required: ["name"]
																	properties: {
																		key: {
																			description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																			type:        "string"
																		}
																		name: {
																			description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																			type:        "string"
																		}
																	}
																}
															}
														}
														webhook: {
															description: "Configure an external webhook based DNS01 challenge solver to manage DNS01 challenge records."
															type:        "object"
															required: [
																"groupName",
																"solverName",
															]
															properties: {
																config: {
																	description:                            "Additional configuration that should be passed to the webhook apiserver when challenges are processed. This can contain arbitrary JSON data. Secret values should not be specified in this stanza. If secret values are needed (e.g. credentials for a DNS service), you should use a SecretKeySelector to reference a Secret resource. For details on the schema of this field, consult the webhook provider implementation's documentation."
																	"x-kubernetes-preserve-unknown-fields": true
																}
																groupName: {
																	description: "The API group name that should be used when POSTing ChallengePayload resources to the webhook apiserver. This should be the same as the GroupName specified in the webhook provider implementation."
																	type:        "string"
																}
																solverName: {
																	description: "The name of the solver to use, as defined in the webhook provider implementation. This will typically be the name of the provider, e.g. 'cloudflare'."
																	type:        "string"
																}
															}
														}
													}
												}
												http01: {
													description: "Configures cert-manager to attempt to complete authorizations by performing the HTTP01 challenge flow. It is not possible to obtain certificates for wildcard domain names (e.g. `*.example.com`) using the HTTP01 challenge mechanism."
													type:        "object"
													properties: {
														gatewayHTTPRoute: {
															description: "The Gateway API is a sig-network community API that models service networking in Kubernetes (https://gateway-api.sigs.k8s.io/). The Gateway solver will create HTTPRoutes with the specified labels in the same namespace as the challenge. This solver is experimental, and fields / behaviour may change in the future."
															type:        "object"
															properties: {
																labels: {
																	description: "Custom labels that will be applied to HTTPRoutes created by cert-manager while solving HTTP-01 challenges."
																	type:        "object"
																	additionalProperties: type: "string"
																}
																parentRefs: {
																	description: "When solving an HTTP-01 challenge, cert-manager creates an HTTPRoute. cert-manager needs to know which parentRefs should be used when creating the HTTPRoute. Usually, the parentRef references a Gateway. See: https://gateway-api.sigs.k8s.io/api-types/httproute/#attaching-to-gateways"
																	type:        "array"
																	items: {
																		description: """
		ParentReference identifies an API object (usually a Gateway) that can be considered a parent of this resource (usually a route). There are two kinds of parent resources with \"Core\" support: 
		 * Gateway (Gateway conformance profile) * Service (Mesh conformance profile, experimental, ClusterIP Services only) 
		 This API may be extended in the future to support additional kinds of parent resources. 
		 The API object must be valid in the cluster; the Group and Kind must be registered in the cluster for this reference to be valid.
		"""
																		type: "object"
																		required: ["name"]
																		properties: {
																			group: {
																				description: """
		Group is the group of the referent. When unspecified, \"gateway.networking.k8s.io\" is inferred. To set the core API group (such as for a \"Service\" kind referent), Group must be explicitly set to \"\" (empty string). 
		 Support: Core
		"""
																				type:      "string"
																				default:   "gateway.networking.k8s.io"
																				maxLength: 253
																				pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																			}
																			kind: {
																				description: """
		Kind is kind of the referent. 
		 There are two kinds of parent resources with \"Core\" support: 
		 * Gateway (Gateway conformance profile) * Service (Mesh conformance profile, experimental, ClusterIP Services only) 
		 Support for other resources is Implementation-Specific.
		"""
																				type:      "string"
																				default:   "Gateway"
																				maxLength: 63
																				minLength: 1
																				pattern:   "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
																			}
																			name: {
																				description: """
		Name is the name of the referent. 
		 Support: Core
		"""
																				type:      "string"
																				maxLength: 253
																				minLength: 1
																			}
																			namespace: {
																				description: """
		Namespace is the namespace of the referent. When unspecified, this refers to the local namespace of the Route. 
		 Note that there are specific rules for ParentRefs which cross namespace boundaries. Cross-namespace references are only valid if they are explicitly allowed by something in the namespace they are referring to. For example: Gateway has the AllowedRoutes field, and ReferenceGrant provides a generic way to enable any other kind of cross-namespace reference. 
		 ParentRefs from a Route to a Service in the same namespace are \"producer\" routes, which apply default routing rules to inbound connections from any namespace to the Service. 
		 ParentRefs from a Route to a Service in a different namespace are \"consumer\" routes, and these routing rules are only applied to outbound connections originating from the same namespace as the Route, for which the intended destination of the connections are a Service targeted as a ParentRef of the Route. 
		 Support: Core
		"""
																				type:      "string"
																				maxLength: 63
																				minLength: 1
																				pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
																			}
																			port: {
																				description: """
		Port is the network port this Route targets. It can be interpreted differently based on the type of parent resource. 
		 When the parent resource is a Gateway, this targets all listeners listening on the specified port that also support this kind of Route(and select this Route). It's not recommended to set `Port` unless the networking behaviors specified in a Route must apply to a specific port as opposed to a listener(s) whose port(s) may be changed. When both Port and SectionName are specified, the name and port of the selected listener must match both specified values. 
		 When the parent resource is a Service, this targets a specific port in the Service spec. When both Port (experimental) and SectionName are specified, the name and port of the selected port must match both specified values. 
		 Implementations MAY choose to support other parent resources. Implementations supporting other types of parent resources MUST clearly document how/if Port is interpreted. 
		 For the purpose of status, an attachment is considered successful as long as the parent resource accepts it partially. For example, Gateway listeners can restrict which Routes can attach to them by Route kind, namespace, or hostname. If 1 of 2 Gateway listeners accept attachment from the referencing Route, the Route MUST be considered successfully attached. If no Gateway listeners accept attachment from this Route, the Route MUST be considered detached from the Gateway. 
		 Support: Extended 
		 <gateway:experimental>
		"""
																				type:    "integer"
																				format:  "int32"
																				maximum: 65535
																				minimum: 1
																			}
																			sectionName: {
																				description: """
		SectionName is the name of a section within the target resource. In the following resources, SectionName is interpreted as the following: 
		 * Gateway: Listener Name. When both Port (experimental) and SectionName are specified, the name and port of the selected listener must match both specified values. * Service: Port Name. When both Port (experimental) and SectionName are specified, the name and port of the selected listener must match both specified values. Note that attaching Routes to Services as Parents is part of experimental Mesh support and is not supported for any other purpose. 
		 Implementations MAY choose to support attaching Routes to other resources. If that is the case, they MUST clearly document how SectionName is interpreted. 
		 When unspecified (empty string), this will reference the entire resource. For the purpose of status, an attachment is considered successful if at least one section in the parent resource accepts it. For example, Gateway listeners can restrict which Routes can attach to them by Route kind, namespace, or hostname. If 1 of 2 Gateway listeners accept attachment from the referencing Route, the Route MUST be considered successfully attached. If no Gateway listeners accept attachment from this Route, the Route MUST be considered detached from the Gateway. 
		 Support: Core
		"""
																				type:      "string"
																				maxLength: 253
																				minLength: 1
																				pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																			}
																		}
																	}
																}
																serviceType: {
																	description: "Optional service type for Kubernetes solver service. Supported values are NodePort or ClusterIP. If unset, defaults to NodePort."
																	type:        "string"
																}
															}
														}
														ingress: {
															description: "The ingress based HTTP01 challenge solver will solve challenges by creating or modifying Ingress resources in order to route requests for '/.well-known/acme-challenge/XYZ' to 'challenge solver' pods that are provisioned by cert-manager for each Challenge to be completed."
															type:        "object"
															properties: {
																class: {
																	description: "This field configures the annotation `kubernetes.io/ingress.class` when creating Ingress resources to solve ACME challenges that use this challenge solver. Only one of `class`, `name` or `ingressClassName` may be specified."
																	type:        "string"
																}
																ingressClassName: {
																	description: "This field configures the field `ingressClassName` on the created Ingress resources used to solve ACME challenges that use this challenge solver. This is the recommended way of configuring the ingress class. Only one of `class`, `name` or `ingressClassName` may be specified."
																	type:        "string"
																}
																ingressTemplate: {
																	description: "Optional ingress template used to configure the ACME challenge solver ingress used for HTTP01 challenges."
																	type:        "object"
																	properties: metadata: {
																		description: "ObjectMeta overrides for the ingress used to solve HTTP01 challenges. Only the 'labels' and 'annotations' fields may be set. If labels or annotations overlap with in-built values, the values here will override the in-built values."
																		type:        "object"
																		properties: {
																			annotations: {
																				description: "Annotations that should be added to the created ACME HTTP01 solver ingress."
																				type:        "object"
																				additionalProperties: type: "string"
																			}
																			labels: {
																				description: "Labels that should be added to the created ACME HTTP01 solver ingress."
																				type:        "object"
																				additionalProperties: type: "string"
																			}
																		}
																	}
																}
																name: {
																	description: "The name of the ingress resource that should have ACME challenge solving routes inserted into it in order to solve HTTP01 challenges. This is typically used in conjunction with ingress controllers like ingress-gce, which maintains a 1:1 mapping between external IPs and ingress resources. Only one of `class`, `name` or `ingressClassName` may be specified."
																	type:        "string"
																}
																podTemplate: {
																	description: "Optional pod template used to configure the ACME challenge solver pods used for HTTP01 challenges."
																	type:        "object"
																	properties: {
																		metadata: {
																			description: "ObjectMeta overrides for the pod used to solve HTTP01 challenges. Only the 'labels' and 'annotations' fields may be set. If labels or annotations overlap with in-built values, the values here will override the in-built values."
																			type:        "object"
																			properties: {
																				annotations: {
																					description: "Annotations that should be added to the create ACME HTTP01 solver pods."
																					type:        "object"
																					additionalProperties: type: "string"
																				}
																				labels: {
																					description: "Labels that should be added to the created ACME HTTP01 solver pods."
																					type:        "object"
																					additionalProperties: type: "string"
																				}
																			}
																		}
																		spec: {
																			description: "PodSpec defines overrides for the HTTP01 challenge solver pod. Check ACMEChallengeSolverHTTP01IngressPodSpec to find out currently supported fields. All other fields will be ignored."
																			type:        "object"
																			properties: {
																				affinity: {
																					description: "If specified, the pod's scheduling constraints"
																					type:        "object"
																					properties: {
																						nodeAffinity: {
																							description: "Describes node affinity scheduling rules for the pod."
																							type:        "object"
																							properties: {
																								preferredDuringSchedulingIgnoredDuringExecution: {
																									description: "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node matches the corresponding matchExpressions; the node(s) with the highest sum are the most preferred."
																									type:        "array"
																									items: {
																										description: "An empty preferred scheduling term matches all objects with implicit weight 0 (i.e. it's a no-op). A null preferred scheduling term matches no objects (i.e. is also a no-op)."
																										type:        "object"
																										required: [
																											"preference",
																											"weight",
																										]
																										properties: {
																											preference: {
																												description: "A node selector term, associated with the corresponding weight."
																												type:        "object"
																												properties: {
																													matchExpressions: {
																														description: "A list of node selector requirements by node's labels."
																														type:        "array"
																														items: {
																															description: "A node selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																															type:        "object"
																															required: [
																																"key",
																																"operator",
																															]
																															properties: {
																																key: {
																																	description: "The label key that the selector applies to."
																																	type:        "string"
																																}
																																operator: {
																																	description: "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt."
																																	type:        "string"
																																}
																																values: {
																																	description: "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch."
																																	type:        "array"
																																	items: type: "string"
																																}
																															}
																														}
																													}
																													matchFields: {
																														description: "A list of node selector requirements by node's fields."
																														type:        "array"
																														items: {
																															description: "A node selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																															type:        "object"
																															required: [
																																"key",
																																"operator",
																															]
																															properties: {
																																key: {
																																	description: "The label key that the selector applies to."
																																	type:        "string"
																																}
																																operator: {
																																	description: "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt."
																																	type:        "string"
																																}
																																values: {
																																	description: "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch."
																																	type:        "array"
																																	items: type: "string"
																																}
																															}
																														}
																													}
																												}
																												"x-kubernetes-map-type": "atomic"
																											}
																											weight: {
																												description: "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100."
																												type:        "integer"
																												format:      "int32"
																											}
																										}
																									}
																								}
																								requiredDuringSchedulingIgnoredDuringExecution: {
																									description: "If the affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to an update), the system may or may not try to eventually evict the pod from its node."
																									type:        "object"
																									required: ["nodeSelectorTerms"]
																									properties: nodeSelectorTerms: {
																										description: "Required. A list of node selector terms. The terms are ORed."
																										type:        "array"
																										items: {
																											description: "A null or empty node selector term matches no objects. The requirements of them are ANDed. The TopologySelectorTerm type implements a subset of the NodeSelectorTerm."
																											type:        "object"
																											properties: {
																												matchExpressions: {
																													description: "A list of node selector requirements by node's labels."
																													type:        "array"
																													items: {
																														description: "A node selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																														type:        "object"
																														required: [
																															"key",
																															"operator",
																														]
																														properties: {
																															key: {
																																description: "The label key that the selector applies to."
																																type:        "string"
																															}
																															operator: {
																																description: "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt."
																																type:        "string"
																															}
																															values: {
																																description: "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch."
																																type:        "array"
																																items: type: "string"
																															}
																														}
																													}
																												}
																												matchFields: {
																													description: "A list of node selector requirements by node's fields."
																													type:        "array"
																													items: {
																														description: "A node selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																														type:        "object"
																														required: [
																															"key",
																															"operator",
																														]
																														properties: {
																															key: {
																																description: "The label key that the selector applies to."
																																type:        "string"
																															}
																															operator: {
																																description: "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt."
																																type:        "string"
																															}
																															values: {
																																description: "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch."
																																type:        "array"
																																items: type: "string"
																															}
																														}
																													}
																												}
																											}
																											"x-kubernetes-map-type": "atomic"
																										}
																									}
																									"x-kubernetes-map-type": "atomic"
																								}
																							}
																						}
																						podAffinity: {
																							description: "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s))."
																							type:        "object"
																							properties: {
																								preferredDuringSchedulingIgnoredDuringExecution: {
																									description: "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred."
																									type:        "array"
																									items: {
																										description: "The weights of all of the matched WeightedPodAffinityTerm fields are added per-node to find the most preferred node(s)"
																										type:        "object"
																										required: [
																											"podAffinityTerm",
																											"weight",
																										]
																										properties: {
																											podAffinityTerm: {
																												description: "Required. A pod affinity term, associated with the corresponding weight."
																												type:        "object"
																												required: ["topologyKey"]
																												properties: {
																													labelSelector: {
																														description: "A label query over a set of resources, in this case pods."
																														type:        "object"
																														properties: {
																															matchExpressions: {
																																description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																																type:        "array"
																																items: {
																																	description: "A label selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																																	type:        "object"
																																	required: [
																																		"key",
																																		"operator",
																																	]
																																	properties: {
																																		key: {
																																			description: "key is the label key that the selector applies to."
																																			type:        "string"
																																		}
																																		operator: {
																																			description: "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist."
																																			type:        "string"
																																		}
																																		values: {
																																			description: "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch."
																																			type:        "array"
																																			items: type: "string"
																																		}
																																	}
																																}
																															}
																															matchLabels: {
																																description: "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed."
																																type:        "object"
																																additionalProperties: type: "string"
																															}
																														}
																														"x-kubernetes-map-type": "atomic"
																													}
																													namespaceSelector: {
																														description: "A label query over the set of namespaces that the term applies to. The term is applied to the union of the namespaces selected by this field and the ones listed in the namespaces field. null selector and null or empty namespaces list means \"this pod's namespace\". An empty selector ({}) matches all namespaces."
																														type:        "object"
																														properties: {
																															matchExpressions: {
																																description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																																type:        "array"
																																items: {
																																	description: "A label selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																																	type:        "object"
																																	required: [
																																		"key",
																																		"operator",
																																	]
																																	properties: {
																																		key: {
																																			description: "key is the label key that the selector applies to."
																																			type:        "string"
																																		}
																																		operator: {
																																			description: "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist."
																																			type:        "string"
																																		}
																																		values: {
																																			description: "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch."
																																			type:        "array"
																																			items: type: "string"
																																		}
																																	}
																																}
																															}
																															matchLabels: {
																																description: "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed."
																																type:        "object"
																																additionalProperties: type: "string"
																															}
																														}
																														"x-kubernetes-map-type": "atomic"
																													}
																													namespaces: {
																														description: "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\"."
																														type:        "array"
																														items: type: "string"
																													}
																													topologyKey: {
																														description: "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed."
																														type:        "string"
																													}
																												}
																											}
																											weight: {
																												description: "weight associated with matching the corresponding podAffinityTerm, in the range 1-100."
																												type:        "integer"
																												format:      "int32"
																											}
																										}
																									}
																								}
																								requiredDuringSchedulingIgnoredDuringExecution: {
																									description: "If the affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied."
																									type:        "array"
																									items: {
																										description: "Defines a set of pods (namely those matching the labelSelector relative to the given namespace(s)) that this pod should be co-located (affinity) or not co-located (anti-affinity) with, where co-located is defined as running on a node whose value of the label with key <topologyKey> matches that of any node on which a pod of the set of pods is running"
																										type:        "object"
																										required: ["topologyKey"]
																										properties: {
																											labelSelector: {
																												description: "A label query over a set of resources, in this case pods."
																												type:        "object"
																												properties: {
																													matchExpressions: {
																														description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																														type:        "array"
																														items: {
																															description: "A label selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																															type:        "object"
																															required: [
																																"key",
																																"operator",
																															]
																															properties: {
																																key: {
																																	description: "key is the label key that the selector applies to."
																																	type:        "string"
																																}
																																operator: {
																																	description: "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist."
																																	type:        "string"
																																}
																																values: {
																																	description: "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch."
																																	type:        "array"
																																	items: type: "string"
																																}
																															}
																														}
																													}
																													matchLabels: {
																														description: "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed."
																														type:        "object"
																														additionalProperties: type: "string"
																													}
																												}
																												"x-kubernetes-map-type": "atomic"
																											}
																											namespaceSelector: {
																												description: "A label query over the set of namespaces that the term applies to. The term is applied to the union of the namespaces selected by this field and the ones listed in the namespaces field. null selector and null or empty namespaces list means \"this pod's namespace\". An empty selector ({}) matches all namespaces."
																												type:        "object"
																												properties: {
																													matchExpressions: {
																														description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																														type:        "array"
																														items: {
																															description: "A label selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																															type:        "object"
																															required: [
																																"key",
																																"operator",
																															]
																															properties: {
																																key: {
																																	description: "key is the label key that the selector applies to."
																																	type:        "string"
																																}
																																operator: {
																																	description: "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist."
																																	type:        "string"
																																}
																																values: {
																																	description: "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch."
																																	type:        "array"
																																	items: type: "string"
																																}
																															}
																														}
																													}
																													matchLabels: {
																														description: "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed."
																														type:        "object"
																														additionalProperties: type: "string"
																													}
																												}
																												"x-kubernetes-map-type": "atomic"
																											}
																											namespaces: {
																												description: "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\"."
																												type:        "array"
																												items: type: "string"
																											}
																											topologyKey: {
																												description: "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed."
																												type:        "string"
																											}
																										}
																									}
																								}
																							}
																						}
																						podAntiAffinity: {
																							description: "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s))."
																							type:        "object"
																							properties: {
																								preferredDuringSchedulingIgnoredDuringExecution: {
																									description: "The scheduler will prefer to schedule pods to nodes that satisfy the anti-affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling anti-affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred."
																									type:        "array"
																									items: {
																										description: "The weights of all of the matched WeightedPodAffinityTerm fields are added per-node to find the most preferred node(s)"
																										type:        "object"
																										required: [
																											"podAffinityTerm",
																											"weight",
																										]
																										properties: {
																											podAffinityTerm: {
																												description: "Required. A pod affinity term, associated with the corresponding weight."
																												type:        "object"
																												required: ["topologyKey"]
																												properties: {
																													labelSelector: {
																														description: "A label query over a set of resources, in this case pods."
																														type:        "object"
																														properties: {
																															matchExpressions: {
																																description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																																type:        "array"
																																items: {
																																	description: "A label selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																																	type:        "object"
																																	required: [
																																		"key",
																																		"operator",
																																	]
																																	properties: {
																																		key: {
																																			description: "key is the label key that the selector applies to."
																																			type:        "string"
																																		}
																																		operator: {
																																			description: "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist."
																																			type:        "string"
																																		}
																																		values: {
																																			description: "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch."
																																			type:        "array"
																																			items: type: "string"
																																		}
																																	}
																																}
																															}
																															matchLabels: {
																																description: "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed."
																																type:        "object"
																																additionalProperties: type: "string"
																															}
																														}
																														"x-kubernetes-map-type": "atomic"
																													}
																													namespaceSelector: {
																														description: "A label query over the set of namespaces that the term applies to. The term is applied to the union of the namespaces selected by this field and the ones listed in the namespaces field. null selector and null or empty namespaces list means \"this pod's namespace\". An empty selector ({}) matches all namespaces."
																														type:        "object"
																														properties: {
																															matchExpressions: {
																																description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																																type:        "array"
																																items: {
																																	description: "A label selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																																	type:        "object"
																																	required: [
																																		"key",
																																		"operator",
																																	]
																																	properties: {
																																		key: {
																																			description: "key is the label key that the selector applies to."
																																			type:        "string"
																																		}
																																		operator: {
																																			description: "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist."
																																			type:        "string"
																																		}
																																		values: {
																																			description: "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch."
																																			type:        "array"
																																			items: type: "string"
																																		}
																																	}
																																}
																															}
																															matchLabels: {
																																description: "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed."
																																type:        "object"
																																additionalProperties: type: "string"
																															}
																														}
																														"x-kubernetes-map-type": "atomic"
																													}
																													namespaces: {
																														description: "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\"."
																														type:        "array"
																														items: type: "string"
																													}
																													topologyKey: {
																														description: "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed."
																														type:        "string"
																													}
																												}
																											}
																											weight: {
																												description: "weight associated with matching the corresponding podAffinityTerm, in the range 1-100."
																												type:        "integer"
																												format:      "int32"
																											}
																										}
																									}
																								}
																								requiredDuringSchedulingIgnoredDuringExecution: {
																									description: "If the anti-affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the anti-affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied."
																									type:        "array"
																									items: {
																										description: "Defines a set of pods (namely those matching the labelSelector relative to the given namespace(s)) that this pod should be co-located (affinity) or not co-located (anti-affinity) with, where co-located is defined as running on a node whose value of the label with key <topologyKey> matches that of any node on which a pod of the set of pods is running"
																										type:        "object"
																										required: ["topologyKey"]
																										properties: {
																											labelSelector: {
																												description: "A label query over a set of resources, in this case pods."
																												type:        "object"
																												properties: {
																													matchExpressions: {
																														description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																														type:        "array"
																														items: {
																															description: "A label selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																															type:        "object"
																															required: [
																																"key",
																																"operator",
																															]
																															properties: {
																																key: {
																																	description: "key is the label key that the selector applies to."
																																	type:        "string"
																																}
																																operator: {
																																	description: "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist."
																																	type:        "string"
																																}
																																values: {
																																	description: "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch."
																																	type:        "array"
																																	items: type: "string"
																																}
																															}
																														}
																													}
																													matchLabels: {
																														description: "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed."
																														type:        "object"
																														additionalProperties: type: "string"
																													}
																												}
																												"x-kubernetes-map-type": "atomic"
																											}
																											namespaceSelector: {
																												description: "A label query over the set of namespaces that the term applies to. The term is applied to the union of the namespaces selected by this field and the ones listed in the namespaces field. null selector and null or empty namespaces list means \"this pod's namespace\". An empty selector ({}) matches all namespaces."
																												type:        "object"
																												properties: {
																													matchExpressions: {
																														description: "matchExpressions is a list of label selector requirements. The requirements are ANDed."
																														type:        "array"
																														items: {
																															description: "A label selector requirement is a selector that contains values, a key, and an operator that relates the key and values."
																															type:        "object"
																															required: [
																																"key",
																																"operator",
																															]
																															properties: {
																																key: {
																																	description: "key is the label key that the selector applies to."
																																	type:        "string"
																																}
																																operator: {
																																	description: "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist."
																																	type:        "string"
																																}
																																values: {
																																	description: "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch."
																																	type:        "array"
																																	items: type: "string"
																																}
																															}
																														}
																													}
																													matchLabels: {
																														description: "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed."
																														type:        "object"
																														additionalProperties: type: "string"
																													}
																												}
																												"x-kubernetes-map-type": "atomic"
																											}
																											namespaces: {
																												description: "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\"."
																												type:        "array"
																												items: type: "string"
																											}
																											topologyKey: {
																												description: "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed."
																												type:        "string"
																											}
																										}
																									}
																								}
																							}
																						}
																					}
																				}
																				imagePullSecrets: {
																					description: "If specified, the pod's imagePullSecrets"
																					type:        "array"
																					items: {
																						description: "LocalObjectReference contains enough information to let you locate the referenced object inside the same namespace."
																						type:        "object"
																						properties: name: {
																							description: "Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names TODO: Add other useful fields. apiVersion, kind, uid?"
																							type:        "string"
																						}
																						"x-kubernetes-map-type": "atomic"
																					}
																				}
																				nodeSelector: {
																					description: "NodeSelector is a selector which must be true for the pod to fit on a node. Selector which must match a node's labels for the pod to be scheduled on that node. More info: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/"
																					type:        "object"
																					additionalProperties: type: "string"
																				}
																				priorityClassName: {
																					description: "If specified, the pod's priorityClassName."
																					type:        "string"
																				}
																				serviceAccountName: {
																					description: "If specified, the pod's service account"
																					type:        "string"
																				}
																				tolerations: {
																					description: "If specified, the pod's tolerations."
																					type:        "array"
																					items: {
																						description: "The pod this Toleration is attached to tolerates any taint that matches the triple <key,value,effect> using the matching operator <operator>."
																						type:        "object"
																						properties: {
																							effect: {
																								description: "Effect indicates the taint effect to match. Empty means match all taint effects. When specified, allowed values are NoSchedule, PreferNoSchedule and NoExecute."
																								type:        "string"
																							}
																							key: {
																								description: "Key is the taint key that the toleration applies to. Empty means match all taint keys. If the key is empty, operator must be Exists; this combination means to match all values and all keys."
																								type:        "string"
																							}
																							operator: {
																								description: "Operator represents a key's relationship to the value. Valid operators are Exists and Equal. Defaults to Equal. Exists is equivalent to wildcard for value, so that a pod can tolerate all taints of a particular category."
																								type:        "string"
																							}
																							tolerationSeconds: {
																								description: "TolerationSeconds represents the period of time the toleration (which must be of effect NoExecute, otherwise this field is ignored) tolerates the taint. By default, it is not set, which means tolerate the taint forever (do not evict). Zero and negative values will be treated as 0 (evict immediately) by the system."
																								type:        "integer"
																								format:      "int64"
																							}
																							value: {
																								description: "Value is the taint value the toleration matches to. If the operator is Exists, the value should be empty, otherwise just a regular string."
																								type:        "string"
																							}
																						}
																					}
																				}
																			}
																		}
																	}
																}
																serviceType: {
																	description: "Optional service type for Kubernetes solver service. Supported values are NodePort or ClusterIP. If unset, defaults to NodePort."
																	type:        "string"
																}
															}
														}
													}
												}
												selector: {
													description: "Selector selects a set of DNSNames on the Certificate resource that should be solved using this challenge solver. If not specified, the solver will be treated as the 'default' solver with the lowest priority, i.e. if any other solver has a more specific match, it will be used instead."
													type:        "object"
													properties: {
														dnsNames: {
															description: "List of DNSNames that this solver will be used to solve. If specified and a match is found, a dnsNames selector will take precedence over a dnsZones selector. If multiple solvers match with the same dnsNames value, the solver with the most matching labels in matchLabels will be selected. If neither has more matches, the solver defined earlier in the list will be selected."
															type:        "array"
															items: type: "string"
														}
														dnsZones: {
															description: "List of DNSZones that this solver will be used to solve. The most specific DNS zone match specified here will take precedence over other DNS zone matches, so a solver specifying sys.example.com will be selected over one specifying example.com for the domain www.sys.example.com. If multiple solvers match with the same dnsZones value, the solver with the most matching labels in matchLabels will be selected. If neither has more matches, the solver defined earlier in the list will be selected."
															type:        "array"
															items: type: "string"
														}
														matchLabels: {
															description: "A label selector that is used to refine the set of certificate's that this challenge solver will apply to."
															type:        "object"
															additionalProperties: type: "string"
														}
													}
												}
											}
										}
									}
								}
							}
							ca: {
								description: "CA configures this issuer to sign certificates using a signing CA keypair stored in a Secret resource. This is used to build internal PKIs that are managed by cert-manager."
								type:        "object"
								required: ["secretName"]
								properties: {
									crlDistributionPoints: {
										description: "The CRL distribution points is an X.509 v3 certificate extension which identifies the location of the CRL from which the revocation of this certificate can be checked. If not set, certificates will be issued without distribution points set."
										type:        "array"
										items: type: "string"
									}
									ocspServers: {
										description: "The OCSP server list is an X.509 v3 extension that defines a list of URLs of OCSP responders. The OCSP responders can be queried for the revocation status of an issued certificate. If not set, the certificate will be issued with no OCSP servers set. For example, an OCSP server URL could be \"http://ocsp.int-x3.letsencrypt.org\"."
										type:        "array"
										items: type: "string"
									}
									secretName: {
										description: "SecretName is the name of the secret used to sign Certificates issued by this Issuer."
										type:        "string"
									}
								}
							}
							selfSigned: {
								description: "SelfSigned configures this issuer to 'self sign' certificates using the private key used to create the CertificateRequest object."
								type:        "object"
								properties: crlDistributionPoints: {
									description: "The CRL distribution points is an X.509 v3 certificate extension which identifies the location of the CRL from which the revocation of this certificate can be checked. If not set certificate will be issued without CDP. Values are strings."
									type:        "array"
									items: type: "string"
								}
							}
							vault: {
								description: "Vault configures this issuer to sign certificates using a HashiCorp Vault PKI backend."
								type:        "object"
								required: [
									"auth",
									"path",
									"server",
								]
								properties: {
									auth: {
										description: "Auth configures how cert-manager authenticates with the Vault server."
										type:        "object"
										properties: {
											appRole: {
												description: "AppRole authenticates with Vault using the App Role auth mechanism, with the role and secret stored in a Kubernetes Secret resource."
												type:        "object"
												required: [
													"path",
													"roleId",
													"secretRef",
												]
												properties: {
													path: {
														description: "Path where the App Role authentication backend is mounted in Vault, e.g: \"approle\""
														type:        "string"
													}
													roleId: {
														description: "RoleID configured in the App Role authentication backend when setting up the authentication backend in Vault."
														type:        "string"
													}
													secretRef: {
														description: "Reference to a key in a Secret that contains the App Role secret used to authenticate with Vault. The `key` field must be specified and denotes which entry within the Secret resource is used as the app role secret."
														type:        "object"
														required: ["name"]
														properties: {
															key: {
																description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																type:        "string"
															}
															name: {
																description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																type:        "string"
															}
														}
													}
												}
											}
											kubernetes: {
												description: "Kubernetes authenticates with Vault by passing the ServiceAccount token stored in the named Secret resource to the Vault server."
												type:        "object"
												required: ["role"]
												properties: {
													mountPath: {
														description: "The Vault mountPath here is the mount path to use when authenticating with Vault. For example, setting a value to `/v1/auth/foo`, will use the path `/v1/auth/foo/login` to authenticate with Vault. If unspecified, the default value \"/v1/auth/kubernetes\" will be used."
														type:        "string"
													}
													role: {
														description: "A required field containing the Vault Role to assume. A Role binds a Kubernetes ServiceAccount with a set of Vault policies."
														type:        "string"
													}
													secretRef: {
														description: "The required Secret field containing a Kubernetes ServiceAccount JWT used for authenticating with Vault. Use of 'ambient credentials' is not supported."
														type:        "object"
														required: ["name"]
														properties: {
															key: {
																description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
																type:        "string"
															}
															name: {
																description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
																type:        "string"
															}
														}
													}
													serviceAccountRef: {
														description: "A reference to a service account that will be used to request a bound token (also known as \"projected token\"). Compared to using \"secretRef\", using this field means that you don't rely on statically bound tokens. To use this field, you must configure an RBAC rule to let cert-manager request a token."
														type:        "object"
														required: ["name"]
														properties: name: {
															description: "Name of the ServiceAccount used to request a token."
															type:        "string"
														}
													}
												}
											}
											tokenSecretRef: {
												description: "TokenSecretRef authenticates with Vault by presenting a token."
												type:        "object"
												required: ["name"]
												properties: {
													key: {
														description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
														type:        "string"
													}
													name: {
														description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
														type:        "string"
													}
												}
											}
										}
									}
									caBundle: {
										description: "Base64-encoded bundle of PEM CAs which will be used to validate the certificate chain presented by Vault. Only used if using HTTPS to connect to Vault and ignored for HTTP connections. Mutually exclusive with CABundleSecretRef. If neither CABundle nor CABundleSecretRef are defined, the certificate bundle in the cert-manager controller container is used to validate the TLS connection."
										type:        "string"
										format:      "byte"
									}
									caBundleSecretRef: {
										description: "Reference to a Secret containing a bundle of PEM-encoded CAs to use when verifying the certificate chain presented by Vault when using HTTPS. Mutually exclusive with CABundle. If neither CABundle nor CABundleSecretRef are defined, the certificate bundle in the cert-manager controller container is used to validate the TLS connection. If no key for the Secret is specified, cert-manager will default to 'ca.crt'."
										type:        "object"
										required: ["name"]
										properties: {
											key: {
												description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
												type:        "string"
											}
											name: {
												description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
												type:        "string"
											}
										}
									}
									namespace: {
										description: "Name of the vault namespace. Namespaces is a set of features within Vault Enterprise that allows Vault environments to support Secure Multi-tenancy. e.g: \"ns1\" More about namespaces can be found here https://www.vaultproject.io/docs/enterprise/namespaces"
										type:        "string"
									}
									path: {
										description: "Path is the mount path of the Vault PKI backend's `sign` endpoint, e.g: \"my_pki_mount/sign/my-role-name\"."
										type:        "string"
									}
									server: {
										description: "Server is the connection address for the Vault server, e.g: \"https://vault.example.com:8200\"."
										type:        "string"
									}
								}
							}
							venafi: {
								description: "Venafi configures this issuer to sign certificates using a Venafi TPP or Venafi Cloud policy zone."
								type:        "object"
								required: ["zone"]
								properties: {
									cloud: {
										description: "Cloud specifies the Venafi cloud configuration settings. Only one of TPP or Cloud may be specified."
										type:        "object"
										required: ["apiTokenSecretRef"]
										properties: {
											apiTokenSecretRef: {
												description: "APITokenSecretRef is a secret key selector for the Venafi Cloud API token."
												type:        "object"
												required: ["name"]
												properties: {
													key: {
														description: "The key of the entry in the Secret resource's `data` field to be used. Some instances of this field may be defaulted, in others it may be required."
														type:        "string"
													}
													name: {
														description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
														type:        "string"
													}
												}
											}
											url: {
												description: "URL is the base URL for Venafi Cloud. Defaults to \"https://api.venafi.cloud/v1\"."
												type:        "string"
											}
										}
									}
									tpp: {
										description: "TPP specifies Trust Protection Platform configuration settings. Only one of TPP or Cloud may be specified."
										type:        "object"
										required: [
											"credentialsRef",
											"url",
										]
										properties: {
											caBundle: {
												description: "Base64-encoded bundle of PEM CAs which will be used to validate the certificate chain presented by the TPP server. Only used if using HTTPS; ignored for HTTP. If undefined, the certificate bundle in the cert-manager controller container is used to validate the chain."
												type:        "string"
												format:      "byte"
											}
											credentialsRef: {
												description: "CredentialsRef is a reference to a Secret containing the username and password for the TPP server. The secret must contain two keys, 'username' and 'password'."
												type:        "object"
												required: ["name"]
												properties: name: {
													description: "Name of the resource being referred to. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"
													type:        "string"
												}
											}
											url: {
												description: "URL is the base URL for the vedsdk endpoint of the Venafi TPP instance, for example: \"https://tpp.example.com/vedsdk\"."
												type:        "string"
											}
										}
									}
									zone: {
										description: "Zone is the Venafi Policy Zone to use for this issuer. All requests made to the Venafi platform will be restricted by the named zone policy. This field is required."
										type:        "string"
									}
								}
							}
						}
					}
					status: {
						description: "Status of the Issuer. This is set and managed automatically."
						type:        "object"
						properties: {
							acme: {
								description: "ACME specific status options. This field should only be set if the Issuer is configured to use an ACME server to issue certificates."
								type:        "object"
								properties: {
									lastPrivateKeyHash: {
										description: "LastPrivateKeyHash is a hash of the private key associated with the latest registered ACME account, in order to track changes made to registered account associated with the Issuer"
										type:        "string"
									}
									lastRegisteredEmail: {
										description: "LastRegisteredEmail is the email associated with the latest registered ACME account, in order to track changes made to registered account associated with the  Issuer"
										type:        "string"
									}
									uri: {
										description: "URI is the unique account identifier, which can also be used to retrieve account details from the CA"
										type:        "string"
									}
								}
							}
							conditions: {
								description: "List of status conditions to indicate the status of a CertificateRequest. Known condition types are `Ready`."
								type:        "array"
								items: {
									description: "IssuerCondition contains condition information for an Issuer."
									type:        "object"
									required: [
										"status",
										"type",
									]
									properties: {
										lastTransitionTime: {
											description: "LastTransitionTime is the timestamp corresponding to the last status change of this condition."
											type:        "string"
											format:      "date-time"
										}
										message: {
											description: "Message is a human readable description of the details of the last transition, complementing reason."
											type:        "string"
										}
										observedGeneration: {
											description: "If set, this represents the .metadata.generation that the condition was set based upon. For instance, if .metadata.generation is currently 12, but the .status.condition[x].observedGeneration is 9, the condition is out of date with respect to the current state of the Issuer."
											type:        "integer"
											format:      "int64"
										}
										reason: {
											description: "Reason is a brief machine readable explanation for the condition's last transition."
											type:        "string"
										}
										status: {
											description: "Status of the condition, one of (`True`, `False`, `Unknown`)."
											type:        "string"
											enum: [
												"True",
												"False",
												"Unknown",
											]
										}
										type: {
											description: "Type of the condition, known values are (`Ready`)."
											type:        "string"
										}
									}
								}
								"x-kubernetes-list-map-keys": ["type"]
								"x-kubernetes-list-type": "map"
							}
						}
					}
				}
			}
			served:  true
			storage: true
		}]
	}
}
