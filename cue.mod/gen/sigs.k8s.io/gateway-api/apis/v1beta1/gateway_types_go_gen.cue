// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go sigs.k8s.io/gateway-api/apis/v1beta1

package v1beta1

import (
	"sigs.k8s.io/gateway-api/apis/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Gateway represents an instance of a service-traffic handling infrastructure
// by binding Listeners to a set of IP addresses.
#Gateway: v1.#Gateway

// GatewayList contains a list of Gateways.
#GatewayList: {
	metav1.#TypeMeta
	metadata?: metav1.#ListMeta @go(ListMeta)
	items: [...#Gateway] @go(Items,[]Gateway)
}

// GatewaySpec defines the desired state of Gateway.
//
// Not all possible combinations of options specified in the Spec are
// valid. Some invalid configurations can be caught synchronously via a
// webhook, but there are many cases that will require asynchronous
// signaling via the GatewayStatus block.
// +k8s:deepcopy-gen=false
#GatewaySpec: v1.#GatewaySpec

// Listener embodies the concept of a logical endpoint where a Gateway accepts
// network connections.
// +k8s:deepcopy-gen=false
#Listener: v1.#Listener

// ProtocolType defines the application protocol accepted by a Listener.
// Implementations are not required to accept all the defined protocols. If an
// implementation does not support a specified protocol, it MUST set the
// "Accepted" condition to False for the affected Listener with a reason of
// "UnsupportedProtocol".
//
// Core ProtocolType values are listed in the table below.
//
// Implementations can define their own protocols if a core ProtocolType does not
// exist. Such definitions must use prefixed name, such as
// `mycompany.com/my-custom-protocol`. Un-prefixed names are reserved for core
// protocols. Any protocol defined by implementations will fall under
// implementation-specific conformance.
//
// Valid values include:
//
// * "HTTP" - Core support
// * "example.com/bar" - Implementation-specific support
//
// Invalid values include:
//
// * "example.com" - must include path if domain is used
// * "foo.example.com" - must include path if domain is used
//
// +kubebuilder:validation:MinLength=1
// +kubebuilder:validation:MaxLength=255
// +kubebuilder:validation:Pattern=`^[a-zA-Z0-9]([-a-zSA-Z0-9]*[a-zA-Z0-9])?$|[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*\/[A-Za-z0-9]+$`
// +k8s:deepcopy-gen=false
#ProtocolType: v1.#ProtocolType

// GatewayTLSConfig describes a TLS configuration.
// +k8s:deepcopy-gen=false
#GatewayTLSConfig: v1.#GatewayTLSConfig

// TLSModeType type defines how a Gateway handles TLS sessions.
//
// Note that values may be added to this enum, implementations
// must ensure that unknown values will not cause a crash.
//
// Unknown values here must result in the implementation setting the
// Ready Condition for the Listener to `status: False`, with a
// Reason of `Invalid`.
//
// +kubebuilder:validation:Enum=Terminate;Passthrough
// +k8s:deepcopy-gen=false
#TLSModeType: v1.#TLSModeType

// AllowedRoutes defines which Routes may be attached to this Listener.
// +k8s:deepcopy-gen=false
#AllowedRoutes: v1.#AllowedRoutes

// FromNamespaces specifies namespace from which Routes may be attached to a
// Gateway.
//
// Note that values may be added to this enum, implementations
// must ensure that unknown values will not cause a crash.
//
// Unknown values here must result in the implementation setting the
// Ready Condition for the Listener to `status: False`, with a
// Reason of `Invalid`.
//
// +kubebuilder:validation:Enum=All;Selector;Same
// +k8s:deepcopy-gen=false
#FromNamespaces: v1.#FromNamespaces

// RouteNamespaces indicate which namespaces Routes should be selected from.
// +k8s:deepcopy-gen=false
#RouteNamespaces: v1.#RouteNamespaces

// RouteGroupKind indicates the group and kind of a Route resource.
// +k8s:deepcopy-gen=false
#RouteGroupKind: v1.#RouteGroupKind

// GatewayAddress describes an address that can be bound to a Gateway.
// +k8s:deepcopy-gen=false
#GatewayAddress: v1.#GatewayAddress

// GatewayStatus defines the observed state of Gateway.
// +k8s:deepcopy-gen=false
#GatewayStatus: v1.#GatewayStatus

// GatewayConditionType is a type of condition associated with a
// Gateway. This type should be used with the GatewayStatus.Conditions
// field.
// +k8s:deepcopy-gen=false
#GatewayConditionType: v1.#GatewayConditionType

// GatewayConditionReason defines the set of reasons that explain why a
// particular Gateway condition type has been raised.
// +k8s:deepcopy-gen=false
#GatewayConditionReason: v1.#GatewayConditionReason

// ListenerStatus is the status associated with a Listener.
// +k8s:deepcopy-gen=false
#ListenerStatus: v1.#ListenerStatus

// ListenerConditionType is a type of condition associated with the
// listener. This type should be used with the ListenerStatus.Conditions
// field.
// +k8s:deepcopy-gen=false
#ListenerConditionType: v1.#ListenerConditionType

// ListenerConditionReason defines the set of reasons that explain
// why a particular Listener condition type has been raised.
// +k8s:deepcopy-gen=false
#ListenerConditionReason: v1.#ListenerConditionReason
