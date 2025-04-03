// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/envoyproxy/gateway/api/v1alpha1

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	gwapiv1 "sigs.k8s.io/gateway-api/apis/v1"
)

// KindEnvoyProxy is the name of the EnvoyProxy kind.
#KindEnvoyProxy: "EnvoyProxy"

// EnvoyProxy is the schema for the envoyproxies API.
#EnvoyProxy: {
	metav1.#TypeMeta
	metadata?: metav1.#ObjectMeta @go(ObjectMeta)

	// EnvoyProxySpec defines the desired state of EnvoyProxy.
	spec?: #EnvoyProxySpec @go(Spec)

	// EnvoyProxyStatus defines the actual state of EnvoyProxy.
	status?: #EnvoyProxyStatus @go(Status)
}

// EnvoyProxySpec defines the desired state of EnvoyProxy.
#EnvoyProxySpec: {
	// Provider defines the desired resource provider and provider-specific configuration.
	// If unspecified, the "Kubernetes" resource provider is used with default configuration
	// parameters.
	//
	// +optional
	provider?: null | #EnvoyProxyProvider @go(Provider,*EnvoyProxyProvider)

	// Logging defines logging parameters for managed proxies.
	// +kubebuilder:default={level: {default: warn}}
	logging?: #ProxyLogging @go(Logging)

	// Telemetry defines telemetry parameters for managed proxies.
	//
	// +optional
	telemetry?: null | #ProxyTelemetry @go(Telemetry,*ProxyTelemetry)

	// Bootstrap defines the Envoy Bootstrap as a YAML string.
	// Visit https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/bootstrap/v3/bootstrap.proto#envoy-v3-api-msg-config-bootstrap-v3-bootstrap
	// to learn more about the syntax.
	// If set, this is the Bootstrap configuration used for the managed Envoy Proxy fleet instead of the default Bootstrap configuration
	// set by Envoy Gateway.
	// Some fields within the Bootstrap that are required to communicate with the xDS Server (Envoy Gateway) and receive xDS resources
	// from it are not configurable and will result in the `EnvoyProxy` resource being rejected.
	// Backward compatibility across minor versions is not guaranteed.
	// We strongly recommend using `egctl x translate` to generate a `EnvoyProxy` resource with the `Bootstrap` field set to the default
	// Bootstrap configuration used. You can edit this configuration, and rerun `egctl x translate` to ensure there are no validation errors.
	//
	// +optional
	bootstrap?: null | #ProxyBootstrap @go(Bootstrap,*ProxyBootstrap)

	// Concurrency defines the number of worker threads to run. If unset, it defaults to
	// the number of cpuset threads on the platform.
	//
	// +optional
	concurrency?: null | int32 @go(Concurrency,*int32)

	// RoutingType can be set to "Service" to use the Service Cluster IP for routing to the backend,
	// or it can be set to "Endpoint" to use Endpoint routing. The default is "Endpoint".
	// +optional
	routingType?: null | #RoutingType @go(RoutingType,*RoutingType)

	// ExtraArgs defines additional command line options that are provided to Envoy.
	// More info: https://www.envoyproxy.io/docs/envoy/latest/operations/cli#command-line-options
	// Note: some command line options are used internally(e.g. --log-level) so they cannot be provided here.
	//
	// +optional
	extraArgs?: [...string] @go(ExtraArgs,[]string)

	// MergeGateways defines if Gateway resources should be merged onto the same Envoy Proxy Infrastructure.
	// Setting this field to true would merge all Gateway Listeners under the parent Gateway Class.
	// This means that the port, protocol and hostname tuple must be unique for every listener.
	// If a duplicate listener is detected, the newer listener (based on timestamp) will be rejected and its status will be updated with a "Accepted=False" condition.
	//
	// +optional
	mergeGateways?: null | bool @go(MergeGateways,*bool)

	// Shutdown defines configuration for graceful envoy shutdown process.
	//
	// +optional
	shutdown?: null | #ShutdownConfig @go(Shutdown,*ShutdownConfig)

	// FilterOrder defines the order of filters in the Envoy proxy's HTTP filter chain.
	// The FilterPosition in the list will be applied in the order they are defined.
	// If unspecified, the default filter order is applied.
	// Default filter order is:
	//
	// - envoy.filters.http.health_check
	//
	// - envoy.filters.http.fault
	//
	// - envoy.filters.http.cors
	//
	// - envoy.filters.http.ext_authz
	//
	// - envoy.filters.http.basic_auth
	//
	// - envoy.filters.http.oauth2
	//
	// - envoy.filters.http.jwt_authn
	//
	// - envoy.filters.http.stateful_session
	//
	// - envoy.filters.http.ext_proc
	//
	// - envoy.filters.http.wasm
	//
	// - envoy.filters.http.rbac
	//
	// - envoy.filters.http.local_ratelimit
	//
	// - envoy.filters.http.ratelimit
	//
	// - envoy.filters.http.custom_response
	//
	// - envoy.filters.http.router
	//
	// Note: "envoy.filters.http.router" cannot be reordered, it's always the last filter in the chain.
	//
	// +optional
	filterOrder?: [...#FilterPosition] @go(FilterOrder,[]FilterPosition)

	// BackendTLS is the TLS configuration for the Envoy proxy to use when connecting to backends.
	// These settings are applied on backends for which TLS policies are specified.
	// +optional
	backendTLS?: null | #BackendTLSConfig @go(BackendTLS,*BackendTLSConfig)

	// IPFamily specifies the IP family for the EnvoyProxy fleet.
	// This setting only affects the Gateway listener port and does not impact
	// other aspects of the Envoy proxy configuration.
	// If not specified, the system will operate as follows:
	// - It defaults to IPv4 only.
	// - IPv6 and dual-stack environments are not supported in this default configuration.
	// Note: To enable IPv6 or dual-stack functionality, explicit configuration is required.
	// +kubebuilder:validation:Enum=IPv4;IPv6;DualStack
	// +optional
	ipFamily?: null | #IPFamily @go(IPFamily,*IPFamily)

	// PreserveRouteOrder determines if the order of matching for HTTPRoutes is determined by Gateway-API
	// specification (https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRouteRule)
	// or preserves the order defined by users in the HTTPRoute's HTTPRouteRule list.
	// Default: False
	//
	// +optional
	preserveRouteOrder?: null | bool @go(PreserveRouteOrder,*bool)
}

// RoutingType defines the type of routing of this Envoy proxy.
#RoutingType: string // #enumRoutingType

#enumRoutingType:
	#ServiceRoutingType |
	#EndpointRoutingType

// ServiceRoutingType is the RoutingType for Service Cluster IP routing.
#ServiceRoutingType: #RoutingType & "Service"

// EndpointRoutingType is the RoutingType for Endpoint routing.
#EndpointRoutingType: #RoutingType & "Endpoint"

// BackendTLSConfig describes the BackendTLS configuration for Envoy Proxy.
#BackendTLSConfig: {
	// ClientCertificateRef defines the reference to a Kubernetes Secret that contains
	// the client certificate and private key for Envoy to use when connecting to
	// backend services and external services, such as ExtAuth, ALS, OpenTelemetry, etc.
	// This secret should be located within the same namespace as the Envoy proxy resource that references it.
	// +optional
	clientCertificateRef?: null | gwapiv1.#SecretObjectReference @go(ClientCertificateRef,*gwapiv1.SecretObjectReference)

	#TLSSettings
}

// FilterPosition defines the position of an Envoy HTTP filter in the filter chain.
// +kubebuilder:validation:XValidation:rule="(has(self.before) || has(self.after))",message="one of before or after must be specified"
// +kubebuilder:validation:XValidation:rule="(has(self.before) && !has(self.after)) || (!has(self.before) && has(self.after))",message="only one of before or after can be specified"
#FilterPosition: {
	// Name of the filter.
	name: #EnvoyFilter @go(Name)

	// Before defines the filter that should come before the filter.
	// Only one of Before or After must be set.
	before?: null | #EnvoyFilter @go(Before,*EnvoyFilter)

	// After defines the filter that should come after the filter.
	// Only one of Before or After must be set.
	after?: null | #EnvoyFilter @go(After,*EnvoyFilter)
}

// EnvoyFilter defines the type of Envoy HTTP filter.
// +kubebuilder:validation:Enum=envoy.filters.http.health_check;envoy.filters.http.fault;envoy.filters.http.cors;envoy.filters.http.ext_authz;envoy.filters.http.api_key_auth;envoy.filters.http.basic_auth;envoy.filters.http.oauth2;envoy.filters.http.jwt_authn;envoy.filters.http.stateful_session;envoy.filters.http.ext_proc;envoy.filters.http.wasm;envoy.filters.http.rbac;envoy.filters.http.local_ratelimit;envoy.filters.http.ratelimit;envoy.filters.http.custom_response;envoy.filters.http.compressor
#EnvoyFilter: string // #enumEnvoyFilter

#enumEnvoyFilter:
	#EnvoyFilterHealthCheck |
	#EnvoyFilterFault |
	#EnvoyFilterCORS |
	#EnvoyFilterExtAuthz |
	#EnvoyFilterAPIKeyAuth |
	#EnvoyFilterBasicAuth |
	#EnvoyFilterOAuth2 |
	#EnvoyFilterJWTAuthn |
	#EnvoyFilterSessionPersistence |
	#EnvoyFilterExtProc |
	#EnvoyFilterWasm |
	#EnvoyFilterRBAC |
	#EnvoyFilterLocalRateLimit |
	#EnvoyFilterRateLimit |
	#EnvoyFilterCustomResponse |
	#EnvoyFilterCompressor |
	#EnvoyFilterRouter

// EnvoyFilterHealthCheck defines the Envoy HTTP health check filter.
#EnvoyFilterHealthCheck: #EnvoyFilter & "envoy.filters.http.health_check"

// EnvoyFilterFault defines the Envoy HTTP fault filter.
#EnvoyFilterFault: #EnvoyFilter & "envoy.filters.http.fault"

// EnvoyFilterCORS defines the Envoy HTTP CORS filter.
#EnvoyFilterCORS: #EnvoyFilter & "envoy.filters.http.cors"

// EnvoyFilterExtAuthz defines the Envoy HTTP external authorization filter.
#EnvoyFilterExtAuthz: #EnvoyFilter & "envoy.filters.http.ext_authz"

// EnvoyFilterAPIKeyAuth defines the Envoy HTTP api key authentication filter.
//nolint:gosec // this is not an API key credential.
#EnvoyFilterAPIKeyAuth: #EnvoyFilter & "envoy.filters.http.api_key_auth"

// EnvoyFilterBasicAuth defines the Envoy HTTP basic authentication filter.
#EnvoyFilterBasicAuth: #EnvoyFilter & "envoy.filters.http.basic_auth"

// EnvoyFilterOAuth2 defines the Envoy HTTP OAuth2 filter.
#EnvoyFilterOAuth2: #EnvoyFilter & "envoy.filters.http.oauth2"

// EnvoyFilterJWTAuthn defines the Envoy HTTP JWT authentication filter.
#EnvoyFilterJWTAuthn: #EnvoyFilter & "envoy.filters.http.jwt_authn"

// EnvoyFilterSessionPersistence defines the Envoy HTTP session persistence filter.
#EnvoyFilterSessionPersistence: #EnvoyFilter & "envoy.filters.http.stateful_session"

// EnvoyFilterExtProc defines the Envoy HTTP external process filter.
#EnvoyFilterExtProc: #EnvoyFilter & "envoy.filters.http.ext_proc"

// EnvoyFilterWasm defines the Envoy HTTP WebAssembly filter.
#EnvoyFilterWasm: #EnvoyFilter & "envoy.filters.http.wasm"

// EnvoyFilterRBAC defines the Envoy RBAC filter.
#EnvoyFilterRBAC: #EnvoyFilter & "envoy.filters.http.rbac"

// EnvoyFilterLocalRateLimit defines the Envoy HTTP local rate limit filter.
#EnvoyFilterLocalRateLimit: #EnvoyFilter & "envoy.filters.http.local_ratelimit"

// EnvoyFilterRateLimit defines the Envoy HTTP rate limit filter.
#EnvoyFilterRateLimit: #EnvoyFilter & "envoy.filters.http.ratelimit"

// EnvoyFilterCustomResponse defines the Envoy HTTP custom response filter.
#EnvoyFilterCustomResponse: #EnvoyFilter & "envoy.filters.http.custom_response"

// EnvoyFilterCompressor defines the Envoy HTTP compressor filter.
#EnvoyFilterCompressor: #EnvoyFilter & "envoy.filters.http.compressor"

// EnvoyFilterRouter defines the Envoy HTTP router filter.
#EnvoyFilterRouter: #EnvoyFilter & "envoy.filters.http.router"

#ProxyTelemetry: {
	// AccessLogs defines accesslog parameters for managed proxies.
	// If unspecified, will send default format to stdout.
	// +optional
	accessLog?: null | #ProxyAccessLog @go(AccessLog,*ProxyAccessLog)

	// Tracing defines tracing configuration for managed proxies.
	// If unspecified, will not send tracing data.
	// +optional
	tracing?: null | #ProxyTracing @go(Tracing,*ProxyTracing)

	// Metrics defines metrics configuration for managed proxies.
	metrics?: null | #ProxyMetrics @go(Metrics,*ProxyMetrics)
}

// EnvoyProxyProvider defines the desired state of a resource provider.
// +union
#EnvoyProxyProvider: {
	// Type is the type of resource provider to use. A resource provider provides
	// infrastructure resources for running the data plane, e.g. Envoy proxy, and
	// optional auxiliary control planes. Supported types are "Kubernetes".
	//
	// +unionDiscriminator
	type: #ProviderType @go(Type)

	// Kubernetes defines the desired state of the Kubernetes resource provider.
	// Kubernetes provides infrastructure resources for running the data plane,
	// e.g. Envoy proxy. If unspecified and type is "Kubernetes", default settings
	// for managed Kubernetes resources are applied.
	//
	// +optional
	kubernetes?: null | #EnvoyProxyKubernetesProvider @go(Kubernetes,*EnvoyProxyKubernetesProvider)
}

// ShutdownConfig defines configuration for graceful envoy shutdown process.
#ShutdownConfig: {
	// DrainTimeout defines the graceful drain timeout. This should be less than the pod's terminationGracePeriodSeconds.
	// If unspecified, defaults to 60 seconds.
	//
	// +optional
	drainTimeout?: null | metav1.#Duration @go(DrainTimeout,*metav1.Duration)

	// MinDrainDuration defines the minimum drain duration allowing time for endpoint deprogramming to complete.
	// If unspecified, defaults to 10 seconds.
	//
	// +optional
	minDrainDuration?: null | metav1.#Duration @go(MinDrainDuration,*metav1.Duration)
}

// +kubebuilder:validation:XValidation:rule="((has(self.envoyDeployment) && !has(self.envoyDaemonSet)) || (!has(self.envoyDeployment) && has(self.envoyDaemonSet))) || (!has(self.envoyDeployment) && !has(self.envoyDaemonSet))",message="only one of envoyDeployment or envoyDaemonSet can be specified"
// +kubebuilder:validation:XValidation:rule="((has(self.envoyHpa) && !has(self.envoyDaemonSet)) || (!has(self.envoyHpa) && has(self.envoyDaemonSet))) || (!has(self.envoyHpa) && !has(self.envoyDaemonSet))",message="cannot use envoyHpa if envoyDaemonSet is used"
//
// EnvoyProxyKubernetesProvider defines configuration for the Kubernetes resource
// provider.
#EnvoyProxyKubernetesProvider: {
	// EnvoyDeployment defines the desired state of the Envoy deployment resource.
	// If unspecified, default settings for the managed Envoy deployment resource
	// are applied.
	//
	// +optional
	envoyDeployment?: null | #KubernetesDeploymentSpec @go(EnvoyDeployment,*KubernetesDeploymentSpec)

	// EnvoyDaemonSet defines the desired state of the Envoy daemonset resource.
	// Disabled by default, a deployment resource is used instead to provision the Envoy Proxy fleet
	//
	// +optional
	envoyDaemonSet?: null | #KubernetesDaemonSetSpec @go(EnvoyDaemonSet,*KubernetesDaemonSetSpec)

	// EnvoyService defines the desired state of the Envoy service resource.
	// If unspecified, default settings for the managed Envoy service resource
	// are applied.
	//
	// +optional
	envoyService?: null | #KubernetesServiceSpec @go(EnvoyService,*KubernetesServiceSpec)

	// EnvoyHpa defines the Horizontal Pod Autoscaler settings for Envoy Proxy Deployment.
	// Once the HPA is being set, Replicas field from EnvoyDeployment will be ignored.
	//
	// +optional
	envoyHpa?: null | #KubernetesHorizontalPodAutoscalerSpec @go(EnvoyHpa,*KubernetesHorizontalPodAutoscalerSpec)

	// UseListenerPortAsContainerPort disables the port shifting feature in the Envoy Proxy.
	// When set to false (default value), if the service port is a privileged port (1-1023), add a constant to the value converting it into an ephemeral port.
	// This allows the container to bind to the port without needing a CAP_NET_BIND_SERVICE capability.
	//
	// +optional
	useListenerPortAsContainerPort?: null | bool @go(UseListenerPortAsContainerPort,*bool)

	// EnvoyPDB allows to control the pod disruption budget of an Envoy Proxy.
	// +optional
	envoyPDB?: null | #KubernetesPodDisruptionBudgetSpec @go(EnvoyPDB,*KubernetesPodDisruptionBudgetSpec)
}

// ProxyLogging defines logging parameters for managed proxies.
#ProxyLogging: {
	// Level is a map of logging level per component, where the component is the key
	// and the log level is the value. If unspecified, defaults to "default: warn".
	//
	// +kubebuilder:default={default: warn}
	level?: {[string]: #LogLevel} @go(Level,map[ProxyLogComponent]LogLevel)
}

// ProxyLogComponent defines a component that supports a configured logging level.
// +kubebuilder:validation:Enum=system;upstream;http;connection;admin;client;filter;main;router;runtime
#ProxyLogComponent: string // #enumProxyLogComponent

#enumProxyLogComponent:
	#LogComponentDefault |
	#LogComponentUpstream |
	#LogComponentHTTP |
	#LogComponentConnection |
	#LogComponentAdmin |
	#LogComponentClient |
	#LogComponentFilter |
	#LogComponentMain |
	#LogComponentRouter |
	#LogComponentRuntime

// LogComponentDefault defines the default logging component.
// See more details: https://www.envoyproxy.io/docs/envoy/latest/operations/cli#cmdoption-l
#LogComponentDefault: #ProxyLogComponent & "default"

// LogComponentUpstream defines the "upstream" logging component.
#LogComponentUpstream: #ProxyLogComponent & "upstream"

// LogComponentHTTP defines the "http" logging component.
#LogComponentHTTP: #ProxyLogComponent & "http"

// LogComponentConnection defines the "connection" logging component.
#LogComponentConnection: #ProxyLogComponent & "connection"

// LogComponentAdmin defines the "admin" logging component.
#LogComponentAdmin: #ProxyLogComponent & "admin"

// LogComponentClient defines the "client" logging component.
#LogComponentClient: #ProxyLogComponent & "client"

// LogComponentFilter defines the "filter" logging component.
#LogComponentFilter: #ProxyLogComponent & "filter"

// LogComponentMain defines the "main" logging component.
#LogComponentMain: #ProxyLogComponent & "main"

// LogComponentRouter defines the "router" logging component.
#LogComponentRouter: #ProxyLogComponent & "router"

// LogComponentRuntime defines the "runtime" logging component.
#LogComponentRuntime: #ProxyLogComponent & "runtime"

// ProxyBootstrap defines Envoy Bootstrap configuration.
// +union
// +kubebuilder:validation:XValidation:rule="self.type == 'JSONPatch' ? self.jsonPatches.size() > 0 : has(self.value)", message="provided bootstrap patch doesn't match the configured patch type"
#ProxyBootstrap: {
	// Type is the type of the bootstrap configuration, it should be either Replace,  Merge, or JSONPatch.
	// If unspecified, it defaults to Replace.
	// +optional
	// +kubebuilder:default=Replace
	// +unionDiscriminator
	type?: null | #BootstrapType @go(Type,*BootstrapType)

	// Value is a YAML string of the bootstrap.
	// +optional
	value?: null | string @go(Value,*string)

	// JSONPatches is an array of JSONPatches to be applied to the default bootstrap. Patches are
	// applied in the order in which they are defined.
	jsonPatches?: [...#JSONPatchOperation] @go(JSONPatches,[]JSONPatchOperation)
}

// BootstrapType defines the types of bootstrap supported by Envoy Gateway.
// +kubebuilder:validation:Enum=Merge;Replace;JSONPatch
#BootstrapType: string // #enumBootstrapType

#enumBootstrapType:
	#BootstrapTypeMerge |
	#BootstrapTypeReplace |
	#BootstrapTypeJSONPatch

// Merge merges the provided bootstrap with the default one. The provided bootstrap can add or override a value
// within a map, or add a new value to a list.
// Please note that the provided bootstrap can't override a value within a list.
#BootstrapTypeMerge: #BootstrapType & "Merge"

// Replace replaces the default bootstrap with the provided one.
#BootstrapTypeReplace: #BootstrapType & "Replace"

// JSONPatch applies the provided JSONPatches to the default bootstrap.
#BootstrapTypeJSONPatch: #BootstrapType & "JSONPatch"

// EnvoyProxyStatus defines the observed state of EnvoyProxy. This type is not implemented
// until https://github.com/envoyproxy/gateway/issues/1007 is fixed.
#EnvoyProxyStatus: {}

// EnvoyProxyList contains a list of EnvoyProxy
#EnvoyProxyList: {
	metav1.#TypeMeta
	metadata?: metav1.#ListMeta @go(ListMeta)
	items: [...#EnvoyProxy] @go(Items,[]EnvoyProxy)
}

// IPFamily defines the IP family to use for the Envoy proxy.
#IPFamily: string // #enumIPFamily

#enumIPFamily:
	#IPv4 |
	#IPv6 |
	#DualStack

// IPv4 defines the IPv4 family.
#IPv4: #IPFamily & "IPv4"

// IPv6 defines the IPv6 family.
#IPv6: #IPFamily & "IPv6"

// DualStack defines the dual-stack family.
// When set to DualStack, Envoy proxy will listen on both IPv4 and IPv6 addresses
// for incoming client traffic, enabling support for both IP protocol versions.
#DualStack: #IPFamily & "DualStack"
