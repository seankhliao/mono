// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/envoyproxy/gateway/api/v1alpha1

package v1alpha1

// JWT defines the configuration for JSON Web Token (JWT) authentication.
#JWT: {
	// Optional determines whether a missing JWT is acceptable, defaulting to false if not specified.
	// Note: Even if optional is set to true, JWT authentication will still fail if an invalid JWT is presented.
	optional?: null | bool @go(Optional,*bool)

	// Providers defines the JSON Web Token (JWT) authentication provider type.
	// When multiple JWT providers are specified, the JWT is considered valid if
	// any of the providers successfully validate the JWT. For additional details,
	// see https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/jwt_authn_filter.html.
	//
	// +kubebuilder:validation:MinItems=1
	// +kubebuilder:validation:MaxItems=4
	providers: [...#JWTProvider] @go(Providers,[]JWTProvider)
}

// JWTProvider defines how a JSON Web Token (JWT) can be verified.
// +kubebuilder:validation:XValidation:rule="(has(self.recomputeRoute) && self.recomputeRoute) ? size(self.claimToHeaders) > 0 : true", message="claimToHeaders must be specified if recomputeRoute is enabled"
#JWTProvider: {
	// Name defines a unique name for the JWT provider. A name can have a variety of forms,
	// including RFC1123 subdomains, RFC 1123 labels, or RFC 1035 labels.
	//
	// +kubebuilder:validation:MinLength=1
	// +kubebuilder:validation:MaxLength=253
	name: string @go(Name)

	// Issuer is the principal that issued the JWT and takes the form of a URL or email address.
	// For additional details, see https://tools.ietf.org/html/rfc7519#section-4.1.1 for
	// URL format and https://rfc-editor.org/rfc/rfc5322.html for email format. If not provided,
	// the JWT issuer is not checked.
	//
	// +kubebuilder:validation:MaxLength=253
	// +optional
	issuer?: string @go(Issuer)

	// Audiences is a list of JWT audiences allowed access. For additional details, see
	// https://tools.ietf.org/html/rfc7519#section-4.1.3. If not provided, JWT audiences
	// are not checked.
	//
	// +kubebuilder:validation:MaxItems=8
	// +optional
	audiences?: [...string] @go(Audiences,[]string)

	// RemoteJWKS defines how to fetch and cache JSON Web Key Sets (JWKS) from a remote
	// HTTP/HTTPS endpoint.
	remoteJWKS: #RemoteJWKS @go(RemoteJWKS)

	// ClaimToHeaders is a list of JWT claims that must be extracted into HTTP request headers
	// For examples, following config:
	// The claim must be of type; string, int, double, bool. Array type claims are not supported
	//
	// +optional
	claimToHeaders?: [...#ClaimToHeader] @go(ClaimToHeaders,[]ClaimToHeader)

	// RecomputeRoute clears the route cache and recalculates the routing decision.
	// This field must be enabled if the headers generated from the claim are used for
	// route matching decisions. If the recomputation selects a new route, features targeting
	// the new matched route will be applied.
	//
	// +optional
	recomputeRoute?: null | bool @go(RecomputeRoute,*bool)

	// ExtractFrom defines different ways to extract the JWT token from HTTP request.
	// If empty, it defaults to extract JWT token from the Authorization HTTP request header using Bearer schema
	// or access_token from query parameters.
	//
	// +optional
	extractFrom?: null | #JWTExtractor @go(ExtractFrom,*JWTExtractor)
}

// RemoteJWKS defines how to fetch and cache JSON Web Key Sets (JWKS) from a remote
// HTTP/HTTPS endpoint.
#RemoteJWKS: {
	// URI is the HTTPS URI to fetch the JWKS. Envoy's system trust bundle is used to
	// validate the server certificate.
	//
	// +kubebuilder:validation:MinLength=1
	// +kubebuilder:validation:MaxLength=253
	uri: string @go(URI)
}

// ClaimToHeader defines a configuration to convert JWT claims into HTTP headers
#ClaimToHeader: {
	// Header defines the name of the HTTP request header that the JWT Claim will be saved into.
	header: string @go(Header)

	// Claim is the JWT Claim that should be saved into the header : it can be a nested claim of type
	// (eg. "claim.nested.key", "sub"). The nested claim name must use dot "."
	// to separate the JSON name path.
	claim: string @go(Claim)
}

// JWTExtractor defines a custom JWT token extraction from HTTP request.
// If specified, Envoy will extract the JWT token from the listed extractors (headers, cookies, or params) and validate each of them.
// If any value extracted is found to be an invalid JWT, a 401 error will be returned.
#JWTExtractor: {
	// Headers represents a list of HTTP request headers to extract the JWT token from.
	//
	// +optional
	headers?: [...#JWTHeaderExtractor] @go(Headers,[]JWTHeaderExtractor)

	// Cookies represents a list of cookie names to extract the JWT token from.
	//
	// +optional
	cookies?: [...string] @go(Cookies,[]string)

	// Params represents a list of query parameters to extract the JWT token from.
	//
	// +optional
	params?: [...string] @go(Params,[]string)
}

// JWTHeaderExtractor defines an HTTP header location to extract JWT token
#JWTHeaderExtractor: {
	// Name is the HTTP header name to retrieve the token
	//
	// +kubebuilder:validation:Required
	name: string @go(Name)

	// ValuePrefix is the prefix that should be stripped before extracting the token.
	// The format would be used by Envoy like "{ValuePrefix}<TOKEN>".
	// For example, "Authorization: Bearer <TOKEN>", then the ValuePrefix="Bearer " with a space at the end.
	//
	// +optional
	valuePrefix?: null | string @go(ValuePrefix,*string)
}