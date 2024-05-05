package deploy

k8s: "apiextensions.k8s.io": v1: CustomResourceDefinition: "": "certificates.cert-manager.io": {
	spec: {
		group: "cert-manager.io"
		names: {
			kind:     "Certificate"
			listKind: "CertificateList"
			plural:   "certificates"
			shortNames: [
				"cert",
				"certs",
			]
			singular: "certificate"
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
				jsonPath: ".spec.secretName"
				name:     "Secret"
				type:     "string"
			}, {
				jsonPath: ".spec.issuerRef.name"
				name:     "Issuer"
				priority: 1
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
				description: """
					A Certificate resource should be created to ensure an up to date and signed X.509 certificate is stored in the Kubernetes Secret resource named in `spec.secretName`. 
					 The stored certificate will be renewed before it expires (as configured by `spec.renewBefore`).
					"""
				type: "object"
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
						description: "Specification of the desired state of the Certificate resource. https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status"
						type:        "object"
						required: [
							"issuerRef",
							"secretName",
						]
						properties: {
							additionalOutputFormats: {
								description: """
		Defines extra output formats of the private key and signed certificate chain to be written to this Certificate's target Secret. 
		 This is an Alpha Feature and is only enabled with the `--feature-gates=AdditionalCertificateOutputFormats=true` option set on both the controller and webhook components.
		"""
								type: "array"
								items: {
									description: "CertificateAdditionalOutputFormat defines an additional output format of a Certificate resource. These contain supplementary data formats of the signed certificate chain and paired private key."
									type:        "object"
									required: ["type"]
									properties: type: {
										description: "Type is the name of the format type that should be written to the Certificate's target Secret."
										type:        "string"
										enum: [
											"DER",
											"CombinedPEM",
										]
									}
								}
							}
							commonName: {
								description: """
		Requested common name X509 certificate subject attribute. More info: https://datatracker.ietf.org/doc/html/rfc5280#section-4.1.2.6 NOTE: TLS clients will ignore this value when any subject alternative name is set (see https://tools.ietf.org/html/rfc6125#section-6.4.4). 
		 Should have a length of 64 characters or fewer to avoid generating invalid CSRs. Cannot be set if the `literalSubject` field is set.
		"""
								type: "string"
							}
							dnsNames: {
								description: "Requested DNS subject alternative names."
								type:        "array"
								items: type: "string"
							}
							duration: {
								description: """
		Requested 'duration' (i.e. lifetime) of the Certificate. Note that the issuer may choose to ignore the requested duration, just like any other requested attribute. 
		 If unset, this defaults to 90 days. Minimum accepted duration is 1 hour. Value must be in units accepted by Go time.ParseDuration https://golang.org/pkg/time/#ParseDuration.
		"""
								type: "string"
							}
							emailAddresses: {
								description: "Requested email subject alternative names."
								type:        "array"
								items: type: "string"
							}
							encodeUsagesInRequest: {
								description: """
		Whether the KeyUsage and ExtKeyUsage extensions should be set in the encoded CSR. 
		 This option defaults to true, and should only be disabled if the target issuer does not support CSRs with these X509 KeyUsage/ ExtKeyUsage extensions.
		"""
								type: "boolean"
							}
							ipAddresses: {
								description: "Requested IP address subject alternative names."
								type:        "array"
								items: type: "string"
							}
							isCA: {
								description: """
		Requested basic constraints isCA value. The isCA value is used to set the `isCA` field on the created CertificateRequest resources. Note that the issuer may choose to ignore the requested isCA value, just like any other requested attribute. 
		 If true, this will automatically add the `cert sign` usage to the list of requested `usages`.
		"""
								type: "boolean"
							}
							issuerRef: {
								description: """
		Reference to the issuer responsible for issuing the certificate. If the issuer is namespace-scoped, it must be in the same namespace as the Certificate. If the issuer is cluster-scoped, it can be used from any namespace. 
		 The `name` field of the reference must always be specified.
		"""
								type: "object"
								required: ["name"]
								properties: {
									group: {
										description: "Group of the resource being referred to."
										type:        "string"
									}
									kind: {
										description: "Kind of the resource being referred to."
										type:        "string"
									}
									name: {
										description: "Name of the resource being referred to."
										type:        "string"
									}
								}
							}
							keystores: {
								description: "Additional keystore output formats to be stored in the Certificate's Secret."
								type:        "object"
								properties: {
									jks: {
										description: "JKS configures options for storing a JKS keystore in the `spec.secretName` Secret resource."
										type:        "object"
										required: [
											"create",
											"passwordSecretRef",
										]
										properties: {
											create: {
												description: "Create enables JKS keystore creation for the Certificate. If true, a file named `keystore.jks` will be created in the target Secret resource, encrypted using the password stored in `passwordSecretRef`. The keystore file will be updated immediately. If the issuer provided a CA certificate, a file named `truststore.jks` will also be created in the target Secret resource, encrypted using the password stored in `passwordSecretRef` containing the issuing Certificate Authority"
												type:        "boolean"
											}
											passwordSecretRef: {
												description: "PasswordSecretRef is a reference to a key in a Secret resource containing the password used to encrypt the JKS keystore."
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
									pkcs12: {
										description: "PKCS12 configures options for storing a PKCS12 keystore in the `spec.secretName` Secret resource."
										type:        "object"
										required: [
											"create",
											"passwordSecretRef",
										]
										properties: {
											create: {
												description: "Create enables PKCS12 keystore creation for the Certificate. If true, a file named `keystore.p12` will be created in the target Secret resource, encrypted using the password stored in `passwordSecretRef`. The keystore file will be updated immediately. If the issuer provided a CA certificate, a file named `truststore.p12` will also be created in the target Secret resource, encrypted using the password stored in `passwordSecretRef` containing the issuing Certificate Authority"
												type:        "boolean"
											}
											passwordSecretRef: {
												description: "PasswordSecretRef is a reference to a key in a Secret resource containing the password used to encrypt the PKCS12 keystore."
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
								}
							}
							literalSubject: {
								description: """
		Requested X.509 certificate subject, represented using the LDAP \"String Representation of a Distinguished Name\" [1]. Important: the LDAP string format also specifies the order of the attributes in the subject, this is important when issuing certs for LDAP authentication. Example: `CN=foo,DC=corp,DC=example,DC=com` More info [1]: https://datatracker.ietf.org/doc/html/rfc4514 More info: https://github.com/cert-manager/cert-manager/issues/3203 More info: https://github.com/cert-manager/cert-manager/issues/4424 
		 Cannot be set if the `subject` or `commonName` field is set. This is an Alpha Feature and is only enabled with the `--feature-gates=LiteralCertificateSubject=true` option set on both the controller and webhook components.
		"""
								type: "string"
							}
							privateKey: {
								description: "Private key options. These include the key algorithm and size, the used encoding and the rotation policy."
								type:        "object"
								properties: {
									algorithm: {
										description: """
		Algorithm is the private key algorithm of the corresponding private key for this certificate. 
		 If provided, allowed values are either `RSA`, `ECDSA` or `Ed25519`. If `algorithm` is specified and `size` is not provided, key size of 2048 will be used for `RSA` key algorithm and key size of 256 will be used for `ECDSA` key algorithm. key size is ignored when using the `Ed25519` key algorithm.
		"""
										type: "string"
										enum: [
											"RSA",
											"ECDSA",
											"Ed25519",
										]
									}
									encoding: {
										description: """
		The private key cryptography standards (PKCS) encoding for this certificate's private key to be encoded in. 
		 If provided, allowed values are `PKCS1` and `PKCS8` standing for PKCS#1 and PKCS#8, respectively. Defaults to `PKCS1` if not specified.
		"""
										type: "string"
										enum: [
											"PKCS1",
											"PKCS8",
										]
									}
									rotationPolicy: {
										description: """
		RotationPolicy controls how private keys should be regenerated when a re-issuance is being processed. 
		 If set to `Never`, a private key will only be generated if one does not already exist in the target `spec.secretName`. If one does exists but it does not have the correct algorithm or size, a warning will be raised to await user intervention. If set to `Always`, a private key matching the specified requirements will be generated whenever a re-issuance occurs. Default is `Never` for backward compatibility.
		"""
										type: "string"
										enum: [
											"Never",
											"Always",
										]
									}
									size: {
										description: """
		Size is the key bit size of the corresponding private key for this certificate. 
		 If `algorithm` is set to `RSA`, valid values are `2048`, `4096` or `8192`, and will default to `2048` if not specified. If `algorithm` is set to `ECDSA`, valid values are `256`, `384` or `521`, and will default to `256` if not specified. If `algorithm` is set to `Ed25519`, Size is ignored. No other values are allowed.
		"""
										type: "integer"
									}
								}
							}
							renewBefore: {
								description: """
		How long before the currently issued certificate's expiry cert-manager should renew the certificate. For example, if a certificate is valid for 60 minutes, and `renewBefore=10m`, cert-manager will begin to attempt to renew the certificate 50 minutes after it was issued (i.e. when there are 10 minutes remaining until the certificate is no longer valid). 
		 NOTE: The actual lifetime of the issued certificate is used to determine the renewal time. If an issuer returns a certificate with a different lifetime than the one requested, cert-manager will use the lifetime of the issued certificate. 
		 If unset, this defaults to 1/3 of the issued certificate's lifetime. Minimum accepted value is 5 minutes. Value must be in units accepted by Go time.ParseDuration https://golang.org/pkg/time/#ParseDuration.
		"""
								type: "string"
							}
							revisionHistoryLimit: {
								description: """
		The maximum number of CertificateRequest revisions that are maintained in the Certificate's history. Each revision represents a single `CertificateRequest` created by this Certificate, either when it was created, renewed, or Spec was changed. Revisions will be removed by oldest first if the number of revisions exceeds this number. 
		 If set, revisionHistoryLimit must be a value of `1` or greater. If unset (`nil`), revisions will not be garbage collected. Default value is `nil`.
		"""
								type:   "integer"
								format: "int32"
							}
							secretName: {
								description: "Name of the Secret resource that will be automatically created and managed by this Certificate resource. It will be populated with a private key and certificate, signed by the denoted issuer. The Secret resource lives in the same namespace as the Certificate resource."
								type:        "string"
							}
							secretTemplate: {
								description: "Defines annotations and labels to be copied to the Certificate's Secret. Labels and annotations on the Secret will be changed as they appear on the SecretTemplate when added or removed. SecretTemplate annotations are added in conjunction with, and cannot overwrite, the base set of annotations cert-manager sets on the Certificate's Secret."
								type:        "object"
								properties: {
									annotations: {
										description: "Annotations is a key value map to be copied to the target Kubernetes Secret."
										type:        "object"
										additionalProperties: type: "string"
									}
									labels: {
										description: "Labels is a key value map to be copied to the target Kubernetes Secret."
										type:        "object"
										additionalProperties: type: "string"
									}
								}
							}
							subject: {
								description: """
		Requested set of X509 certificate subject attributes. More info: https://datatracker.ietf.org/doc/html/rfc5280#section-4.1.2.6 
		 The common name attribute is specified separately in the `commonName` field. Cannot be set if the `literalSubject` field is set.
		"""
								type: "object"
								properties: {
									countries: {
										description: "Countries to be used on the Certificate."
										type:        "array"
										items: type: "string"
									}
									localities: {
										description: "Cities to be used on the Certificate."
										type:        "array"
										items: type: "string"
									}
									organizationalUnits: {
										description: "Organizational Units to be used on the Certificate."
										type:        "array"
										items: type: "string"
									}
									organizations: {
										description: "Organizations to be used on the Certificate."
										type:        "array"
										items: type: "string"
									}
									postalCodes: {
										description: "Postal codes to be used on the Certificate."
										type:        "array"
										items: type: "string"
									}
									provinces: {
										description: "State/Provinces to be used on the Certificate."
										type:        "array"
										items: type: "string"
									}
									serialNumber: {
										description: "Serial number to be used on the Certificate."
										type:        "string"
									}
									streetAddresses: {
										description: "Street addresses to be used on the Certificate."
										type:        "array"
										items: type: "string"
									}
								}
							}
							uris: {
								description: "Requested URI subject alternative names."
								type:        "array"
								items: type: "string"
							}
							usages: {
								description: """
		Requested key usages and extended key usages. These usages are used to set the `usages` field on the created CertificateRequest resources. If `encodeUsagesInRequest` is unset or set to `true`, the usages will additionally be encoded in the `request` field which contains the CSR blob. 
		 If unset, defaults to `digital signature` and `key encipherment`.
		"""
								type: "array"
								items: {
									description: """
		KeyUsage specifies valid usage contexts for keys. See: https://tools.ietf.org/html/rfc5280#section-4.2.1.3 https://tools.ietf.org/html/rfc5280#section-4.2.1.12 
		 Valid KeyUsage values are as follows: \"signing\", \"digital signature\", \"content commitment\", \"key encipherment\", \"key agreement\", \"data encipherment\", \"cert sign\", \"crl sign\", \"encipher only\", \"decipher only\", \"any\", \"server auth\", \"client auth\", \"code signing\", \"email protection\", \"s/mime\", \"ipsec end system\", \"ipsec tunnel\", \"ipsec user\", \"timestamping\", \"ocsp signing\", \"microsoft sgc\", \"netscape sgc\"
		"""
									type: "string"
									enum: [
										"signing",
										"digital signature",
										"content commitment",
										"key encipherment",
										"key agreement",
										"data encipherment",
										"cert sign",
										"crl sign",
										"encipher only",
										"decipher only",
										"any",
										"server auth",
										"client auth",
										"code signing",
										"email protection",
										"s/mime",
										"ipsec end system",
										"ipsec tunnel",
										"ipsec user",
										"timestamping",
										"ocsp signing",
										"microsoft sgc",
										"netscape sgc",
									]
								}
							}
						}
					}
					status: {
						description: "Status of the Certificate. This is set and managed automatically. Read-only. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status"
						type:        "object"
						properties: {
							conditions: {
								description: "List of status conditions to indicate the status of certificates. Known condition types are `Ready` and `Issuing`."
								type:        "array"
								items: {
									description: "CertificateCondition contains condition information for an Certificate."
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
											description: "If set, this represents the .metadata.generation that the condition was set based upon. For instance, if .metadata.generation is currently 12, but the .status.condition[x].observedGeneration is 9, the condition is out of date with respect to the current state of the Certificate."
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
											description: "Type of the condition, known values are (`Ready`, `Issuing`)."
											type:        "string"
										}
									}
								}
								"x-kubernetes-list-map-keys": ["type"]
								"x-kubernetes-list-type": "map"
							}
							failedIssuanceAttempts: {
								description: "The number of continuous failed issuance attempts up till now. This field gets removed (if set) on a successful issuance and gets set to 1 if unset and an issuance has failed. If an issuance has failed, the delay till the next issuance will be calculated using formula time.Hour * 2 ^ (failedIssuanceAttempts - 1)."
								type:        "integer"
							}
							lastFailureTime: {
								description: "LastFailureTime is set only if the lastest issuance for this Certificate failed and contains the time of the failure. If an issuance has failed, the delay till the next issuance will be calculated using formula time.Hour * 2 ^ (failedIssuanceAttempts - 1). If the latest issuance has succeeded this field will be unset."
								type:        "string"
								format:      "date-time"
							}
							nextPrivateKeySecretName: {
								description: "The name of the Secret resource containing the private key to be used for the next certificate iteration. The keymanager controller will automatically set this field if the `Issuing` condition is set to `True`. It will automatically unset this field when the Issuing condition is not set or False."
								type:        "string"
							}
							notAfter: {
								description: "The expiration time of the certificate stored in the secret named by this resource in `spec.secretName`."
								type:        "string"
								format:      "date-time"
							}
							notBefore: {
								description: "The time after which the certificate stored in the secret named by this resource in `spec.secretName` is valid."
								type:        "string"
								format:      "date-time"
							}
							renewalTime: {
								description: "RenewalTime is the time at which the certificate will be next renewed. If not set, no upcoming renewal is scheduled."
								type:        "string"
								format:      "date-time"
							}
							revision: {
								description: """
		The current 'revision' of the certificate as issued. 
		 When a CertificateRequest resource is created, it will have the `cert-manager.io/certificate-revision` set to one greater than the current value of this field. 
		 Upon issuance, this field will be set to the value of the annotation on the CertificateRequest resource used to issue the certificate. 
		 Persisting the value on the CertificateRequest resource allows the certificates controller to know whether a request is part of an old issuance or if it is part of the ongoing revision's issuance by checking if the revision value in the annotation is greater than this field.
		"""
								type: "integer"
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
