// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/envoyproxy/gateway/api/v1alpha1

package v1alpha1

import (
	gwapiv1 "sigs.k8s.io/gateway-api/apis/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

#OIDCClientSecretKey: "client-secret"

// OIDC defines the configuration for the OpenID Connect (OIDC) authentication.
#OIDC: {
	// The OIDC Provider configuration.
	provider: #OIDCProvider @go(Provider)

	// The client ID to be used in the OIDC
	// [Authentication Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest).
	//
	// +kubebuilder:validation:MinLength=1
	clientID: string @go(ClientID)

	// The Kubernetes secret which contains the OIDC client secret to be used in the
	// [Authentication Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest).
	//
	// This is an Opaque secret. The client secret should be stored in the key
	// "client-secret".
	// +kubebuilder:validation:Required
	clientSecret: gwapiv1.#SecretObjectReference @go(ClientSecret)

	// The optional cookie name overrides to be used for Bearer and IdToken cookies in the
	// [Authentication Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest).
	// If not specified, uses a randomly generated suffix
	// +optional
	cookieNames?: null | #OIDCCookieNames @go(CookieNames,*OIDCCookieNames)

	// The optional domain to set the access and ID token cookies on.
	// If not set, the cookies will default to the host of the request, not including the subdomains.
	// If set, the cookies will be set on the specified domain and all subdomains.
	// This means that requests to any subdomain will not require reauthentication after users log in to the parent domain.
	// +optional
	// +kubebuilder:validation:Pattern=`^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9]))*$`
	cookieDomain?: null | string @go(CookieDomain,*string)

	// The OIDC scopes to be used in the
	// [Authentication Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest).
	// The "openid" scope is always added to the list of scopes if not already
	// specified.
	// +optional
	scopes?: [...string] @go(Scopes,[]string)

	// The OIDC resources to be used in the
	// [Authentication Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest).
	// +optional
	resources?: [...string] @go(Resources,[]string)

	// The redirect URL to be used in the OIDC
	// [Authentication Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest).
	// If not specified, uses the default redirect URI "%REQ(x-forwarded-proto)%://%REQ(:authority)%/oauth2/callback"
	redirectURL?: null | string @go(RedirectURL,*string)

	// The path to log a user out, clearing their credential cookies.
	//
	// If not specified, uses a default logout path "/logout"
	logoutPath?: null | string @go(LogoutPath,*string)

	// ForwardAccessToken indicates whether the Envoy should forward the access token
	// via the Authorization header Bearer scheme to the upstream.
	// If not specified, defaults to false.
	// +optional
	forwardAccessToken?: null | bool @go(ForwardAccessToken,*bool)

	// DefaultTokenTTL is the default lifetime of the id token and access token.
	// Please note that Envoy will always use the expiry time from the response
	// of the authorization server if it is provided. This field is only used when
	// the expiry time is not provided by the authorization.
	//
	// If not specified, defaults to 0. In this case, the "expires_in" field in
	// the authorization response must be set by the authorization server, or the
	// OAuth flow will fail.
	//
	// +optional
	defaultTokenTTL?: null | metav1.#Duration @go(DefaultTokenTTL,*metav1.Duration)

	// RefreshToken indicates whether the Envoy should automatically refresh the
	// id token and access token when they expire.
	// When set to true, the Envoy will use the refresh token to get a new id token
	// and access token when they expire.
	//
	// If not specified, defaults to false.
	// +optional
	refreshToken?: null | bool @go(RefreshToken,*bool)

	// DefaultRefreshTokenTTL is the default lifetime of the refresh token.
	// This field is only used when the exp (expiration time) claim is omitted in
	// the refresh token or the refresh token is not JWT.
	//
	// If not specified, defaults to 604800s (one week).
	// Note: this field is only applicable when the "refreshToken" field is set to true.
	// +optional
	defaultRefreshTokenTTL?: null | metav1.#Duration @go(DefaultRefreshTokenTTL,*metav1.Duration)
}

// OIDCProvider defines the OIDC Provider configuration.
// +kubebuilder:validation:XValidation:rule="!has(self.backendRef)",message="BackendRefs must be used, backendRef is not supported."
// +kubebuilder:validation:XValidation:rule="has(self.backendSettings)? (has(self.backendSettings.retry)?(has(self.backendSettings.retry.perRetry)? !has(self.backendSettings.retry.perRetry.timeout):true):true):true",message="Retry timeout is not supported."
// +kubebuilder:validation:XValidation:rule="has(self.backendSettings)? (has(self.backendSettings.retry)?(has(self.backendSettings.retry.retryOn)? !has(self.backendSettings.retry.retryOn.httpStatusCodes):true):true):true",message="HTTPStatusCodes is not supported."
#OIDCProvider: {
	#BackendCluster

	// The OIDC Provider's [issuer identifier](https://openid.net/specs/openid-connect-discovery-1_0.html#IssuerDiscovery).
	// Issuer MUST be a URI RFC 3986 [RFC3986] with a scheme component that MUST
	// be https, a host component, and optionally, port and path components and
	// no query or fragment components.
	// +kubebuilder:validation:MinLength=1
	issuer: string @go(Issuer)

	// The OIDC Provider's [authorization endpoint](https://openid.net/specs/openid-connect-core-1_0.html#AuthorizationEndpoint).
	// If not provided, EG will try to discover it from the provider's [Well-Known Configuration Endpoint](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfigurationResponse).
	//
	// +optional
	authorizationEndpoint?: null | string @go(AuthorizationEndpoint,*string)

	// The OIDC Provider's [token endpoint](https://openid.net/specs/openid-connect-core-1_0.html#TokenEndpoint).
	// If not provided, EG will try to discover it from the provider's [Well-Known Configuration Endpoint](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfigurationResponse).
	//
	// +optional
	tokenEndpoint?: null | string @go(TokenEndpoint,*string)
}

// OIDCCookieNames defines the names of cookies to use in the Envoy OIDC filter.
#OIDCCookieNames: {
	// The name of the cookie used to store the AccessToken in the
	// [Authentication Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest).
	// If not specified, defaults to "AccessToken-(randomly generated uid)"
	// +optional
	accessToken?: null | string @go(AccessToken,*string)

	// The name of the cookie used to store the IdToken in the
	// [Authentication Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest).
	// If not specified, defaults to "IdToken-(randomly generated uid)"
	// +optional
	idToken?: null | string @go(IDToken,*string)
}
