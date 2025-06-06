// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/envoyproxy/gateway/api/v1alpha1

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	gwapiv1a2 "sigs.k8s.io/gateway-api/apis/v1alpha2"
)

// KindSecurityPolicy is the name of the SecurityPolicy kind.
#KindSecurityPolicy: "SecurityPolicy"

// SecurityPolicy allows the user to configure various security settings for a
// Gateway.
#SecurityPolicy: {
	metav1.#TypeMeta
	metadata?: metav1.#ObjectMeta @go(ObjectMeta)

	// Spec defines the desired state of SecurityPolicy.
	spec: #SecurityPolicySpec @go(Spec)

	// Status defines the current status of SecurityPolicy.
	status?: gwapiv1a2.#PolicyStatus @go(Status)
}

// +kubebuilder:validation:XValidation:rule="(has(self.targetRef) && !has(self.targetRefs)) || (!has(self.targetRef) && has(self.targetRefs)) || (has(self.targetSelectors) && self.targetSelectors.size() > 0) ", message="either targetRef or targetRefs must be used"
//
// +kubebuilder:validation:XValidation:rule="has(self.targetRef) ? self.targetRef.group == 'gateway.networking.k8s.io' : true", message="this policy can only have a targetRef.group of gateway.networking.k8s.io"
// +kubebuilder:validation:XValidation:rule="has(self.targetRef) ? self.targetRef.kind in ['Gateway', 'HTTPRoute', 'GRPCRoute'] : true", message="this policy can only have a targetRef.kind of Gateway/HTTPRoute/GRPCRoute"
// +kubebuilder:validation:XValidation:rule="has(self.targetRef) ? !has(self.targetRef.sectionName) : true",message="this policy does not yet support the sectionName field"
// +kubebuilder:validation:XValidation:rule="has(self.targetRefs) ? self.targetRefs.all(ref, ref.group == 'gateway.networking.k8s.io') : true ", message="this policy can only have a targetRefs[*].group of gateway.networking.k8s.io"
// +kubebuilder:validation:XValidation:rule="has(self.targetRefs) ? self.targetRefs.all(ref, ref.kind in ['Gateway', 'HTTPRoute', 'GRPCRoute']) : true ", message="this policy can only have a targetRefs[*].kind of Gateway/HTTPRoute/GRPCRoute"
// +kubebuilder:validation:XValidation:rule="has(self.targetRefs) ? self.targetRefs.all(ref, !has(ref.sectionName)) : true",message="this policy does not yet support the sectionName field"
// +kubebuilder:validation:XValidation:rule="(has(self.authorization) && has(self.authorization.rules) && self.authorization.rules.exists(r, has(r.principal.jwt))) ? has(self.jwt) : true", message="if authorization.rules.principal.jwt is used, jwt must be defined"
//
// SecurityPolicySpec defines the desired state of SecurityPolicy.
#SecurityPolicySpec: {
	#PolicyTargetReferences

	// APIKeyAuth defines the configuration for the API Key Authentication.
	//
	// +optional
	apiKeyAuth?: null | #APIKeyAuth @go(APIKeyAuth,*APIKeyAuth)

	// CORS defines the configuration for Cross-Origin Resource Sharing (CORS).
	//
	// +optional
	cors?: null | #CORS @go(CORS,*CORS)

	// BasicAuth defines the configuration for the HTTP Basic Authentication.
	//
	// +optional
	basicAuth?: null | #BasicAuth @go(BasicAuth,*BasicAuth)

	// JWT defines the configuration for JSON Web Token (JWT) authentication.
	//
	// +optional
	jwt?: null | #JWT @go(JWT,*JWT)

	// OIDC defines the configuration for the OpenID Connect (OIDC) authentication.
	//
	// +optional
	oidc?: null | #OIDC @go(OIDC,*OIDC)

	// ExtAuth defines the configuration for External Authorization.
	//
	// +optional
	extAuth?: null | #ExtAuth @go(ExtAuth,*ExtAuth)

	// Authorization defines the authorization configuration.
	//
	// +optional
	authorization?: null | #Authorization @go(Authorization,*Authorization)
}

// SecurityPolicyList contains a list of SecurityPolicy resources.
#SecurityPolicyList: {
	metav1.#TypeMeta
	metadata?: metav1.#ListMeta @go(ListMeta)
	items: [...#SecurityPolicy] @go(Items,[]SecurityPolicy)
}
