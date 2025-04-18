// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/envoyproxy/gateway/api/v1alpha1

package v1alpha1

import gwapiv1 "sigs.k8s.io/gateway-api/apis/v1"

#APIKeysSecretKey: "credentials"

// APIKeyAuth defines the configuration for the API Key Authentication.
#APIKeyAuth: {
	// CredentialRefs is the Kubernetes secret which contains the API keys.
	// This is an Opaque secret.
	// Each API key is stored in the key representing the client id.
	// If the secrets have a key for a duplicated client, the first one will be used.
	credentialRefs: [...gwapiv1.#SecretObjectReference] @go(CredentialRefs,[]gwapiv1.SecretObjectReference)

	// ExtractFrom is where to fetch the key from the coming request.
	// The value from the first source that has a key will be used.
	extractFrom: [...null | #ExtractFrom] @go(ExtractFrom,[]*ExtractFrom)
}

// ExtractFrom is where to fetch the key from the coming request.
// Only one of header, param or cookie is supposed to be specified.
#ExtractFrom: {
	// Headers is the names of the header to fetch the key from.
	// If multiple headers are specified, envoy will look for the api key in the order of the list.
	// This field is optional, but only one of headers, params or cookies is supposed to be specified.
	//
	// +optional
	headers?: [...string] @go(Headers,[]string)

	// Params is the names of the query parameter to fetch the key from.
	// If multiple params are specified, envoy will look for the api key in the order of the list.
	// This field is optional, but only one of headers, params or cookies is supposed to be specified.
	//
	// +optional
	params?: [...string] @go(Params,[]string)

	// Cookies is the names of the cookie to fetch the key from.
	// If multiple cookies are specified, envoy will look for the api key in the order of the list.
	// This field is optional, but only one of headers, params or cookies is supposed to be specified.
	//
	// +optional
	cookies?: [...string] @go(Cookies,[]string)
}
