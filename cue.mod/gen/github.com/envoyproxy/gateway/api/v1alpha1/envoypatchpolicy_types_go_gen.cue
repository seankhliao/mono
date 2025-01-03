// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/envoyproxy/gateway/api/v1alpha1

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	gwapiv1a2 "sigs.k8s.io/gateway-api/apis/v1alpha2"
	apiextensionsv1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
)

// KindEnvoyPatchPolicy is the name of the EnvoyPatchPolicy kind.
#KindEnvoyPatchPolicy: "EnvoyPatchPolicy"

// EnvoyPatchPolicy allows the user to modify the generated Envoy xDS
// resources by Envoy Gateway using this patch API
#EnvoyPatchPolicy: {
	metav1.#TypeMeta
	metadata?: metav1.#ObjectMeta @go(ObjectMeta)

	// Spec defines the desired state of EnvoyPatchPolicy.
	spec: #EnvoyPatchPolicySpec @go(Spec)

	// Status defines the current status of EnvoyPatchPolicy.
	status?: gwapiv1a2.#PolicyStatus @go(Status)
}

// EnvoyPatchPolicySpec defines the desired state of EnvoyPatchPolicy.
// +union
#EnvoyPatchPolicySpec: {
	// Type decides the type of patch.
	// Valid EnvoyPatchType values are "JSONPatch".
	//
	// +unionDiscriminator
	type: #EnvoyPatchType @go(Type)

	// JSONPatch defines the JSONPatch configuration.
	//
	// +optional
	jsonPatches?: [...#EnvoyJSONPatchConfig] @go(JSONPatches,[]EnvoyJSONPatchConfig)

	// TargetRef is the name of the Gateway API resource this policy
	// is being attached to.
	// By default, attaching to Gateway is supported and
	// when mergeGateways is enabled it should attach to GatewayClass.
	// This Policy and the TargetRef MUST be in the same namespace
	// for this Policy to have effect and be applied to the Gateway
	// TargetRef
	targetRef: gwapiv1a2.#LocalPolicyTargetReference @go(TargetRef)

	// Priority of the EnvoyPatchPolicy.
	// If multiple EnvoyPatchPolicies are applied to the same
	// TargetRef, they will be applied in the ascending order of
	// the priority i.e. int32.min has the highest priority and
	// int32.max has the lowest priority.
	// Defaults to 0.
	priority?: int32 @go(Priority)
}

// EnvoyPatchType specifies the types of Envoy patching mechanisms.
// +kubebuilder:validation:Enum=JSONPatch
#EnvoyPatchType: string // #enumEnvoyPatchType

#enumEnvoyPatchType:
	#JSONPatchEnvoyPatchType

// JSONPatchEnvoyPatchType allows the user to patch the generated xDS resources using JSONPatch semantics.
// For more details on the semantics, please refer to https://datatracker.ietf.org/doc/html/rfc6902
#JSONPatchEnvoyPatchType: #EnvoyPatchType & "JSONPatch"

// EnvoyJSONPatchConfig defines the configuration for patching a Envoy xDS Resource
// using JSONPatch semantic
#EnvoyJSONPatchConfig: {
	// Type is the typed URL of the Envoy xDS Resource
	type: #EnvoyResourceType @go(Type)

	// Name is the name of the resource
	name: string @go(Name)

	// Patch defines the JSON Patch Operation
	operation: #JSONPatchOperation @go(Operation)
}

// EnvoyResourceType specifies the type URL of the Envoy resource.
// +kubebuilder:validation:Enum=type.googleapis.com/envoy.config.listener.v3.Listener;type.googleapis.com/envoy.config.route.v3.RouteConfiguration;type.googleapis.com/envoy.config.cluster.v3.Cluster;type.googleapis.com/envoy.config.endpoint.v3.ClusterLoadAssignment;type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.Secret
#EnvoyResourceType: string // #enumEnvoyResourceType

#enumEnvoyResourceType:
	#ListenerEnvoyResourceType |
	#RouteConfigurationEnvoyResourceType |
	#ClusterEnvoyResourceType |
	#ClusterLoadAssignmentEnvoyResourceType

// ListenerEnvoyResourceType defines the Type URL of the Listener resource
#ListenerEnvoyResourceType: #EnvoyResourceType & "type.googleapis.com/envoy.config.listener.v3.Listener"

// RouteConfigurationEnvoyResourceType defines the Type URL of the RouteConfiguration resource
#RouteConfigurationEnvoyResourceType: #EnvoyResourceType & "type.googleapis.com/envoy.config.route.v3.RouteConfiguration"

// ClusterEnvoyResourceType defines the Type URL of the Cluster resource
#ClusterEnvoyResourceType: #EnvoyResourceType & "type.googleapis.com/envoy.config.cluster.v3.Cluster"

// ClusterLoadAssignmentEnvoyResourceType defines the Type URL of the ClusterLoadAssignment resource
#ClusterLoadAssignmentEnvoyResourceType: #EnvoyResourceType & "type.googleapis.com/envoy.config.endpoint.v3.ClusterLoadAssignment"

// JSONPatchOperationType specifies the JSON Patch operations that can be performed.
// +kubebuilder:validation:Enum=add;remove;replace;move;copy;test
#JSONPatchOperationType: string

// JSONPatchOperation defines the JSON Patch Operation as defined in
// https://datatracker.ietf.org/doc/html/rfc6902
#JSONPatchOperation: {
	// Op is the type of operation to perform
	op: #JSONPatchOperationType @go(Op)

	// Path is a JSONPointer expression. Refer to https://datatracker.ietf.org/doc/html/rfc6901 for more details.
	// It specifies the location of the target document/field where the operation will be performed
	// +optional
	path?: null | string @go(Path,*string)

	// JSONPath is a JSONPath expression. Refer to https://datatracker.ietf.org/doc/rfc9535/ for more details.
	// It produces one or more JSONPointer expressions based on the given JSON document.
	// If no JSONPointer is found, it will result in an error.
	// If the 'Path' property is also set, it will be appended to the resulting JSONPointer expressions from the JSONPath evaluation.
	// This is useful when creating a property that does not yet exist in the JSON document.
	// The final JSONPointer expressions specifies the locations in the target document/field where the operation will be applied.
	// +optional
	jsonPath?: null | string @go(JSONPath,*string)

	// From is the source location of the value to be copied or moved. Only valid
	// for move or copy operations
	// Refer to https://datatracker.ietf.org/doc/html/rfc6901 for more details.
	// +optional
	from?: null | string @go(From,*string)

	// Value is the new value of the path location. The value is only used by
	// the `add` and `replace` operations.
	// +optional
	value?: null | apiextensionsv1.#JSON @go(Value,*apiextensionsv1.JSON)
}

// PolicyConditionProgrammed indicates whether the policy has been translated
// and ready to be programmed into the data plane.
//
// Possible reasons for this condition to be True are:
//
// * "Programmed"
//
// Possible reasons for this condition to be False are:
//
// * "Invalid"
// * "ResourceNotFound"
//
#PolicyConditionProgrammed: gwapiv1a2.#PolicyConditionType & "Programmed"

// PolicyReasonProgrammed is used with the "Programmed" condition when the policy
// is ready to be programmed into the data plane.
#PolicyReasonProgrammed: gwapiv1a2.#PolicyConditionReason & "Programmed"

// PolicyReasonInvalid is used with the "Programmed" condition when the patch
// is syntactically or semantically invalid.
#PolicyReasonInvalid: gwapiv1a2.#PolicyConditionReason & "Invalid"

// PolicyReasonResourceNotFound is used with the "Programmed" condition when the
// policy cannot find the resource type to patch to.
#PolicyReasonResourceNotFound: gwapiv1a2.#PolicyConditionReason & "ResourceNotFound"

// PolicyReasonDisabled is used with the "Accepted" condition when the policy
// feature is disabled by the configuration.
#PolicyReasonDisabled: gwapiv1a2.#PolicyConditionReason & "Disabled"

// EnvoyPatchPolicyList contains a list of EnvoyPatchPolicy resources.
#EnvoyPatchPolicyList: {
	metav1.#TypeMeta
	metadata?: metav1.#ListMeta @go(ListMeta)
	items: [...#EnvoyPatchPolicy] @go(Items,[]EnvoyPatchPolicy)
}
