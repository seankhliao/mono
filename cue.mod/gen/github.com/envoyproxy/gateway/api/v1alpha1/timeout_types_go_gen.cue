// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/envoyproxy/gateway/api/v1alpha1

package v1alpha1

import gwapiv1 "sigs.k8s.io/gateway-api/apis/v1"

// Timeout defines configuration for timeouts related to connections.
#Timeout: {
	// Timeout settings for TCP.
	//
	// +optional
	tcp?: null | #TCPTimeout @go(TCP,*TCPTimeout)

	// Timeout settings for HTTP.
	//
	// +optional
	http?: null | #HTTPTimeout @go(HTTP,*HTTPTimeout)
}

#TCPTimeout: {
	// The timeout for network connection establishment, including TCP and TLS handshakes.
	// Default: 10 seconds.
	//
	// +optional
	connectTimeout?: null | gwapiv1.#Duration @go(ConnectTimeout,*gwapiv1.Duration)
}

#HTTPTimeout: {
	// The idle timeout for an HTTP connection. Idle time is defined as a period in which there are no active requests in the connection.
	// Default: 1 hour.
	//
	// +optional
	connectionIdleTimeout?: null | gwapiv1.#Duration @go(ConnectionIdleTimeout,*gwapiv1.Duration)

	// The maximum duration of an HTTP connection.
	// Default: unlimited.
	//
	// +optional
	maxConnectionDuration?: null | gwapiv1.#Duration @go(MaxConnectionDuration,*gwapiv1.Duration)

	// RequestTimeout is the time until which entire response is received from the upstream.
	//
	// +optional
	requestTimeout?: null | gwapiv1.#Duration @go(RequestTimeout,*gwapiv1.Duration)
}

#ClientTimeout: {
	// Timeout settings for TCP.
	//
	// +optional
	tcp?: null | #TCPClientTimeout @go(TCP,*TCPClientTimeout)

	// Timeout settings for HTTP.
	//
	// +optional
	http?: null | #HTTPClientTimeout @go(HTTP,*HTTPClientTimeout)
}

// TCPClientTimeout only provides timeout configuration on the listener whose protocol is TCP or TLS.
#TCPClientTimeout: {
	// IdleTimeout for a TCP connection. Idle time is defined as a period in which there are no
	// bytes sent or received on either the upstream or downstream connection.
	// Default: 1 hour.
	//
	// +optional
	idleTimeout?: null | gwapiv1.#Duration @go(IdleTimeout,*gwapiv1.Duration)
}

#HTTPClientTimeout: {
	// RequestReceivedTimeout is the duration envoy waits for the complete request reception. This timer starts upon request
	// initiation and stops when either the last byte of the request is sent upstream or when the response begins.
	//
	// +optional
	requestReceivedTimeout?: null | gwapiv1.#Duration @go(RequestReceivedTimeout,*gwapiv1.Duration)

	// IdleTimeout for an HTTP connection. Idle time is defined as a period in which there are no active requests in the connection.
	// Default: 1 hour.
	//
	// +optional
	idleTimeout?: null | gwapiv1.#Duration @go(IdleTimeout,*gwapiv1.Duration)
}