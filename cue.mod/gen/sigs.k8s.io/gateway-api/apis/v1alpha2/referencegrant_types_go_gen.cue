// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go sigs.k8s.io/gateway-api/apis/v1alpha2

package v1alpha2

import (
	"sigs.k8s.io/gateway-api/apis/v1beta1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// ReferenceGrant identifies kinds of resources in other namespaces that are
// trusted to reference the specified kinds of resources in the same namespace
// as the policy.
//
// Each ReferenceGrant can be used to represent a unique trust relationship.
// Additional Reference Grants can be used to add to the set of trusted
// sources of inbound references for the namespace they are defined within.
//
// A ReferenceGrant is required for all cross-namespace references in Gateway API
// (with the exception of cross-namespace Route-Gateway attachment, which is
// governed by the AllowedRoutes configuration on the Gateway, and cross-namespace
// Service ParentRefs on a "consumer" mesh Route, which defines routing rules
// applicable only to workloads in the Route namespace). ReferenceGrants allowing
// a reference from a Route to a Service are only applicable to BackendRefs.
//
// ReferenceGrant is a form of runtime verification allowing users to assert
// which cross-namespace object references are permitted. Implementations that
// support ReferenceGrant MUST NOT permit cross-namespace references which have
// no grant, and MUST respond to the removal of a grant by revoking the access
// that the grant allowed.
#ReferenceGrant: v1beta1.#ReferenceGrant

// +kubebuilder:object:root=true
// ReferenceGrantList contains a list of ReferenceGrant.
#ReferenceGrantList: {
	metav1.#TypeMeta
	metadata?: metav1.#ListMeta @go(ListMeta)
	items: [...#ReferenceGrant] @go(Items,[]ReferenceGrant)
}

// ReferenceGrantSpec identifies a cross namespace relationship that is trusted
// for Gateway API.
// +k8s:deepcopy-gen=false
#ReferenceGrantSpec: v1beta1.#ReferenceGrantSpec

// ReferenceGrantFrom describes trusted namespaces and kinds.
// +k8s:deepcopy-gen=false
#ReferenceGrantFrom: v1beta1.#ReferenceGrantFrom

// ReferenceGrantTo describes what Kinds are allowed as targets of the
// references.
// +k8s:deepcopy-gen=false
#ReferenceGrantTo: v1beta1.#ReferenceGrantTo
