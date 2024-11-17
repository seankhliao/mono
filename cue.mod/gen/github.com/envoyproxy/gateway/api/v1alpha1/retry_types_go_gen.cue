// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/envoyproxy/gateway/api/v1alpha1

package v1alpha1

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

// Retry defines the retry strategy to be applied.
#Retry: {
	// NumRetries is the number of retries to be attempted. Defaults to 2.
	//
	// +optional
	// +kubebuilder:validation:Minimum=0
	// +kubebuilder:default=2
	numRetries?: null | int32 @go(NumRetries,*int32)

	// RetryOn specifies the retry trigger condition.
	//
	// If not specified, the default is to retry on connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes(503).
	// +optional
	retryOn?: null | #RetryOn @go(RetryOn,*RetryOn)

	// PerRetry is the retry policy to be applied per retry attempt.
	//
	// +optional
	perRetry?: null | #PerRetryPolicy @go(PerRetry,*PerRetryPolicy)
}

#RetryOn: {
	// Triggers specifies the retry trigger condition(Http/Grpc).
	//
	// +optional
	triggers?: [...#TriggerEnum] @go(Triggers,[]TriggerEnum)

	// HttpStatusCodes specifies the http status codes to be retried.
	// The retriable-status-codes trigger must also be configured for these status codes to trigger a retry.
	//
	// +optional
	httpStatusCodes?: [...#HTTPStatus] @go(HTTPStatusCodes,[]HTTPStatus)
}

// TriggerEnum specifies the conditions that trigger retries.
// +kubebuilder:validation:Enum={"5xx","gateway-error","reset","connect-failure","retriable-4xx","refused-stream","retriable-status-codes","cancelled","deadline-exceeded","internal","resource-exhausted","unavailable"}
#TriggerEnum: string // #enumTriggerEnum

#enumTriggerEnum:
	#Error5XX |
	#GatewayError |
	#Reset |
	#ConnectFailure |
	#Retriable4XX |
	#RefusedStream |
	#RetriableStatusCodes |
	#Cancelled |
	#DeadlineExceeded |
	#Internal |
	#ResourceExhausted |
	#Unavailable

// The upstream server responds with any 5xx response code, or does not respond at all (disconnect/reset/read timeout).
// Includes connect-failure and refused-stream.
#Error5XX: #TriggerEnum & "5xx"

// The response is a gateway error (502,503 or 504).
#GatewayError: #TriggerEnum & "gateway-error"

// The upstream server does not respond at all (disconnect/reset/read timeout.)
#Reset: #TriggerEnum & "reset"

// Connection failure to the upstream server (connect timeout, etc.). (Included in *5xx*)
#ConnectFailure: #TriggerEnum & "connect-failure"

// The upstream server responds with a retriable 4xx response code.
// Currently, the only response code in this category is 409.
#Retriable4XX: #TriggerEnum & "retriable-4xx"

// The upstream server resets the stream with a REFUSED_STREAM error code.
#RefusedStream: #TriggerEnum & "refused-stream"

// The upstream server responds with any response code matching one defined in the RetriableStatusCodes.
#RetriableStatusCodes: #TriggerEnum & "retriable-status-codes"

// The gRPC status code in the response headers is “cancelled”.
#Cancelled: #TriggerEnum & "cancelled"

// The gRPC status code in the response headers is “deadline-exceeded”.
#DeadlineExceeded: #TriggerEnum & "deadline-exceeded"

// The gRPC status code in the response headers is “internal”.
#Internal: #TriggerEnum & "internal"

// The gRPC status code in the response headers is “resource-exhausted”.
#ResourceExhausted: #TriggerEnum & "resource-exhausted"

// The gRPC status code in the response headers is “unavailable”.
#Unavailable: #TriggerEnum & "unavailable"

#PerRetryPolicy: {
	// Timeout is the timeout per retry attempt.
	//
	// +optional
	// +kubebuilder:validation:Format=duration
	timeout?: null | metav1.#Duration @go(Timeout,*metav1.Duration)

	// Backoff is the backoff policy to be applied per retry attempt. gateway uses a fully jittered exponential
	// back-off algorithm for retries. For additional details,
	// see https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#config-http-filters-router-x-envoy-max-retries
	//
	// +optional
	backOff?: null | #BackOffPolicy @go(BackOff,*BackOffPolicy)
}

#BackOffPolicy: {
	// BaseInterval is the base interval between retries.
	//
	// +kubebuilder:validation:Format=duration
	baseInterval?: null | metav1.#Duration @go(BaseInterval,*metav1.Duration)

	// MaxInterval is the maximum interval between retries. This parameter is optional, but must be greater than or equal to the base_interval if set.
	// The default is 10 times the base_interval
	//
	// +optional
	// +kubebuilder:validation:Format=duration
	maxInterval?: null | metav1.#Duration @go(MaxInterval,*metav1.Duration)
}