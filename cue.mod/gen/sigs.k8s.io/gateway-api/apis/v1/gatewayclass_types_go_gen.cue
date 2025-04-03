// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go sigs.k8s.io/gateway-api/apis/v1

package v1

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

// GatewayClass describes a class of Gateways available to the user for creating
// Gateway resources.
//
// It is recommended that this resource be used as a template for Gateways. This
// means that a Gateway is based on the state of the GatewayClass at the time it
// was created and changes to the GatewayClass or associated parameters are not
// propagated down to existing Gateways. This recommendation is intended to
// limit the blast radius of changes to GatewayClass or associated parameters.
// If implementations choose to propagate GatewayClass changes to existing
// Gateways, that MUST be clearly documented by the implementation.
//
// Whenever one or more Gateways are using a GatewayClass, implementations SHOULD
// add the `gateway-exists-finalizer.gateway.networking.k8s.io` finalizer on the
// associated GatewayClass. This ensures that a GatewayClass associated with a
// Gateway is not deleted while in use.
//
// GatewayClass is a Cluster level resource.
#GatewayClass: {
	metav1.#TypeMeta
	metadata?: metav1.#ObjectMeta @go(ObjectMeta)

	// Spec defines the desired state of GatewayClass.
	spec: #GatewayClassSpec @go(Spec)

	// Status defines the current state of GatewayClass.
	//
	// Implementations MUST populate status on all GatewayClass resources which
	// specify their controller name.
	//
	// +kubebuilder:default={conditions: {{type: "Accepted", status: "Unknown", message: "Waiting for controller", reason: "Pending", lastTransitionTime: "1970-01-01T00:00:00Z"}}}
	status?: #GatewayClassStatus @go(Status)
}

// GatewayClassFinalizerGatewaysExist should be added as a finalizer to the
// GatewayClass whenever there are provisioned Gateways using a
// GatewayClass.
#GatewayClassFinalizerGatewaysExist: "gateway-exists-finalizer.gateway.networking.k8s.io"

// GatewayClassSpec reflects the configuration of a class of Gateways.
#GatewayClassSpec: {
	// ControllerName is the name of the controller that is managing Gateways of
	// this class. The value of this field MUST be a domain prefixed path.
	//
	// Example: "example.net/gateway-controller".
	//
	// This field is not mutable and cannot be empty.
	//
	// Support: Core
	//
	// +kubebuilder:validation:XValidation:message="Value is immutable",rule="self == oldSelf"
	controllerName: #GatewayController @go(ControllerName)

	// ParametersRef is a reference to a resource that contains the configuration
	// parameters corresponding to the GatewayClass. This is optional if the
	// controller does not require any additional configuration.
	//
	// ParametersRef can reference a standard Kubernetes resource, i.e. ConfigMap,
	// or an implementation-specific custom resource. The resource can be
	// cluster-scoped or namespace-scoped.
	//
	// If the referent cannot be found, refers to an unsupported kind, or when
	// the data within that resource is malformed, the GatewayClass SHOULD be
	// rejected with the "Accepted" status condition set to "False" and an
	// "InvalidParameters" reason.
	//
	// A Gateway for this GatewayClass may provide its own `parametersRef`. When both are specified,
	// the merging behavior is implementation specific.
	// It is generally recommended that GatewayClass provides defaults that can be overridden by a Gateway.
	//
	// Support: Implementation-specific
	//
	// +optional
	parametersRef?: null | #ParametersReference @go(ParametersRef,*ParametersReference)

	// Description helps describe a GatewayClass with more details.
	//
	// +kubebuilder:validation:MaxLength=64
	// +optional
	description?: null | string @go(Description,*string)
}

// ParametersReference identifies an API object containing controller-specific
// configuration resource within the cluster.
#ParametersReference: {
	// Group is the group of the referent.
	group: #Group @go(Group)

	// Kind is kind of the referent.
	kind: #Kind @go(Kind)

	// Name is the name of the referent.
	//
	// +kubebuilder:validation:MinLength=1
	// +kubebuilder:validation:MaxLength=253
	name: string @go(Name)

	// Namespace is the namespace of the referent.
	// This field is required when referring to a Namespace-scoped resource and
	// MUST be unset when referring to a Cluster-scoped resource.
	//
	// +optional
	namespace?: null | #Namespace @go(Namespace,*Namespace)
}

// GatewayClassConditionType is the type for status conditions on
// Gateway resources. This type should be used with the
// GatewayClassStatus.Conditions field.
#GatewayClassConditionType: string // #enumGatewayClassConditionType

#enumGatewayClassConditionType:
	#GatewayClassConditionStatusAccepted |
	#GatewayClassConditionStatusSupportedVersion

// GatewayClassConditionReason defines the set of reasons that explain why a
// particular GatewayClass condition type has been raised.
#GatewayClassConditionReason: string // #enumGatewayClassConditionReason

#enumGatewayClassConditionReason:
	#GatewayClassReasonAccepted |
	#GatewayClassReasonInvalidParameters |
	#GatewayClassReasonPending |
	#GatewayClassReasonUnsupported |
	#GatewayClassReasonWaiting |
	#GatewayClassReasonSupportedVersion |
	#GatewayClassReasonUnsupportedVersion

// This condition indicates whether the GatewayClass has been accepted by
// the controller requested in the `spec.controller` field.
//
// This condition defaults to Unknown, and MUST be set by a controller when
// it sees a GatewayClass using its controller string. The status of this
// condition MUST be set to True if the controller will support provisioning
// Gateways using this class. Otherwise, this status MUST be set to False.
// If the status is set to False, the controller SHOULD set a Message and
// Reason as an explanation.
//
// Possible reasons for this condition to be true are:
//
// * "Accepted"
//
// Possible reasons for this condition to be False are:
//
// * "InvalidParameters"
// * "Unsupported"
// * "UnsupportedVersion"
//
// Possible reasons for this condition to be Unknown are:
//
// * "Pending"
//
// Controllers should prefer to use the values of GatewayClassConditionReason
// for the corresponding Reason, where appropriate.
#GatewayClassConditionStatusAccepted: #GatewayClassConditionType & "Accepted"

// This reason is used with the "Accepted" condition when the condition is
// true.
#GatewayClassReasonAccepted: #GatewayClassConditionReason & "Accepted"

// This reason is used with the "Accepted" condition when the GatewayClass
// was not accepted because the parametersRef field refers to a nonexistent
// or unsupported resource or kind, or when the data within that resource is
// malformed.
#GatewayClassReasonInvalidParameters: #GatewayClassConditionReason & "InvalidParameters"

// This reason is used with the "Accepted" condition when the
// requested controller has not yet made a decision about whether
// to admit the GatewayClass. It is the default Reason on a new
// GatewayClass.
#GatewayClassReasonPending: #GatewayClassConditionReason & "Pending"

// This reason is used with the "Accepted" condition when the GatewayClass
// was not accepted because the implementation does not support a
// user-defined GatewayClass.
#GatewayClassReasonUnsupported: #GatewayClassConditionReason & "Unsupported"

// Deprecated: Use "Pending" instead.
#GatewayClassReasonWaiting: #GatewayClassConditionReason & "Waiting"

// This condition indicates whether the GatewayClass supports the version(s)
// of Gateway API CRDs present in the cluster. This condition MUST be set by
// a controller when it marks a GatewayClass "Accepted".
//
// The version of a Gateway API CRD is defined by the
// gateway.networking.k8s.io/bundle-version annotation on the CRD. If
// implementations detect any Gateway API CRDs that either do not have this
// annotation set, or have it set to a version that is not recognized or
// supported by the implementation, this condition MUST be set to false.
//
// Implementations MAY choose to either provide "best effort" support when
// an unrecognized CRD version is present. This would be communicated by
// setting the "Accepted" condition to true and the "SupportedVersion"
// condition to false.
//
// Alternatively, implementations MAY choose not to support CRDs with
// unrecognized versions. This would be communicated by setting the
// "Accepted" condition to false with the reason "UnsupportedVersions".
//
// Possible reasons for this condition to be true are:
//
// * "SupportedVersion"
//
// Possible reasons for this condition to be False are:
//
// * "UnsupportedVersion"
//
// Controllers should prefer to use the values of GatewayClassConditionReason
// for the corresponding Reason, where appropriate.
//
// <gateway:experimental>
#GatewayClassConditionStatusSupportedVersion: #GatewayClassConditionType & "SupportedVersion"

// This reason is used with the "SupportedVersion" condition when the
// condition is true.
#GatewayClassReasonSupportedVersion: #GatewayClassConditionReason & "SupportedVersion"

// This reason is used with the "SupportedVersion" or "Accepted" condition
// when the condition is false. A message SHOULD be included in this
// condition that includes the detected CRD version(s) present in the
// cluster and the CRD version(s) that are supported by the GatewayClass.
#GatewayClassReasonUnsupportedVersion: #GatewayClassConditionReason & "UnsupportedVersion"

// GatewayClassStatus is the current status for the GatewayClass.
#GatewayClassStatus: {
	// Conditions is the current status from the controller for
	// this GatewayClass.
	//
	// Controllers should prefer to publish conditions using values
	// of GatewayClassConditionType for the type of each Condition.
	//
	// +optional
	// +listType=map
	// +listMapKey=type
	// +kubebuilder:validation:MaxItems=8
	// +kubebuilder:default={{type: "Accepted", status: "Unknown", message: "Waiting for controller", reason: "Pending", lastTransitionTime: "1970-01-01T00:00:00Z"}}
	conditions?: [...metav1.#Condition] @go(Conditions,[]metav1.Condition)

	// SupportedFeatures is the set of features the GatewayClass support.
	// It MUST be sorted in ascending alphabetical order by the Name key.
	// +optional
	// +listType=map
	// +listMapKey=name
	// <gateway:experimental>
	// +kubebuilder:validation:MaxItems=64
	supportedFeatures?: [...#SupportedFeature] @go(SupportedFeatures,[]SupportedFeature)
}

// GatewayClassList contains a list of GatewayClass
#GatewayClassList: {
	metav1.#TypeMeta
	metadata?: metav1.#ListMeta @go(ListMeta)
	items: [...#GatewayClass] @go(Items,[]GatewayClass)
}

// FeatureName is used to describe distinct features that are covered by
// conformance tests.
#FeatureName: string

#SupportedFeature: _
