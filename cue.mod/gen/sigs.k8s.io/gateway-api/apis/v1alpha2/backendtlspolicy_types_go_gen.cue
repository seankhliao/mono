// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go sigs.k8s.io/gateway-api/apis/v1alpha2

package v1alpha2

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/gateway-api/apis/v1"
)

// BackendTLSPolicy provides a way to configure how a Gateway
// connects to a Backend via TLS.
#BackendTLSPolicy: {
	metav1.#TypeMeta
	metadata?: metav1.#ObjectMeta @go(ObjectMeta)

	// Spec defines the desired state of BackendTLSPolicy.
	spec: #BackendTLSPolicySpec @go(Spec)

	// Status defines the current state of BackendTLSPolicy.
	status?: #PolicyStatus @go(Status)
}

// +kubebuilder:object:root=true
// BackendTLSPolicyList contains a list of BackendTLSPolicies
#BackendTLSPolicyList: {
	metav1.#TypeMeta
	metadata?: metav1.#ListMeta @go(ListMeta)
	items: [...#BackendTLSPolicy] @go(Items,[]BackendTLSPolicy)
}

// BackendTLSPolicySpec defines the desired state of BackendTLSPolicy.
//
// Support: Extended
#BackendTLSPolicySpec: {
	// TargetRef identifies an API object to apply the policy to.
	// Only Services have Extended support. Implementations MAY support
	// additional objects, with Implementation Specific support.
	// Note that this config applies to the entire referenced resource
	// by default, but this default may change in the future to provide
	// a more granular application of the policy.
	//
	// Support: Extended for Kubernetes Service
	//
	// Support: Implementation-specific for any other resource
	//
	targetRef: #PolicyTargetReferenceWithSectionName @go(TargetRef)

	// TLS contains backend TLS policy configuration.
	tls: #BackendTLSPolicyConfig @go(TLS)
}

// BackendTLSPolicyConfig contains backend TLS policy configuration.
// +kubebuilder:validation:XValidation:message="must not contain both CACertRefs and WellKnownCACerts",rule="!(has(self.caCertRefs) && size(self.caCertRefs) > 0 && has(self.wellKnownCACerts) && self.wellKnownCACerts != \"\")"
// +kubebuilder:validation:XValidation:message="must specify either CACertRefs or WellKnownCACerts",rule="(has(self.caCertRefs) && size(self.caCertRefs) > 0 || has(self.wellKnownCACerts) && self.wellKnownCACerts != \"\")"
#BackendTLSPolicyConfig: {
	// CACertRefs contains one or more references to Kubernetes objects that
	// contain a PEM-encoded TLS CA certificate bundle, which is used to
	// validate a TLS handshake between the Gateway and backend Pod.
	//
	// If CACertRefs is empty or unspecified, then WellKnownCACerts must be
	// specified. Only one of CACertRefs or WellKnownCACerts may be specified,
	// not both. If CACertRefs is empty or unspecified, the configuration for
	// WellKnownCACerts MUST be honored instead.
	//
	// References to a resource in a different namespace are invalid for the
	// moment, although we will revisit this in the future.
	//
	// A single CACertRef to a Kubernetes ConfigMap kind has "Core" support.
	// Implementations MAY choose to support attaching multiple certificates to
	// a backend, but this behavior is implementation-specific.
	//
	// Support: Core - An optional single reference to a Kubernetes ConfigMap,
	// with the CA certificate in a key named `ca.crt`.
	//
	// Support: Implementation-specific (More than one reference, or other kinds
	// of resources).
	//
	// +kubebuilder:validation:MaxItems=8
	// +optional
	caCertRefs?: [...v1.#LocalObjectReference] @go(CACertRefs,[]sigs.k8s.io/gateway-api/apis/v1.LocalObjectReference)

	// WellKnownCACerts specifies whether system CA certificates may be used in
	// the TLS handshake between the gateway and backend pod.
	//
	// If WellKnownCACerts is unspecified or empty (""), then CACertRefs must be
	// specified with at least one entry for a valid configuration. Only one of
	// CACertRefs or WellKnownCACerts may be specified, not both.
	//
	// Support: Core for "System"
	//
	// +optional
	wellKnownCACerts?: null | #WellKnownCACertType @go(WellKnownCACerts,*WellKnownCACertType)

	// Hostname is used for two purposes in the connection between Gateways and
	// backends:
	//
	// 1. Hostname MUST be used as the SNI to connect to the backend (RFC 6066).
	// 2. Hostname MUST be used for authentication and MUST match the certificate
	//    served by the matching backend.
	//
	// Support: Core
	hostname: v1.#PreciseHostname @go(Hostname,sigs.k8s.io/gateway-api/apis/v1.PreciseHostname)
}

// WellKnownCACertType is the type of CA certificate that will be used when
// the TLS.caCertRefs is unspecified.
// +kubebuilder:validation:Enum=System
#WellKnownCACertType: string // #enumWellKnownCACertType

#enumWellKnownCACertType:
	#WellKnownCACertSystem

// Indicates that well known system CA certificates should be used.
#WellKnownCACertSystem: #WellKnownCACertType & "System"