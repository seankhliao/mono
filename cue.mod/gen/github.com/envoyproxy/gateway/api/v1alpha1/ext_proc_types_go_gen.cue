// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/envoyproxy/gateway/api/v1alpha1

package v1alpha1

import gwapiv1 "sigs.k8s.io/gateway-api/apis/v1"

// +kubebuilder:validation:Enum=Streamed;Buffered;BufferedPartial
#ExtProcBodyProcessingMode: string // #enumExtProcBodyProcessingMode

#enumExtProcBodyProcessingMode:
	#StreamedExtProcBodyProcessingMode |
	#BufferedExtProcBodyProcessingMode |
	#BufferedPartialExtBodyHeaderProcessingMode

// StreamedExtProcBodyProcessingMode will stream the body to the server in pieces as they arrive at the proxy.
#StreamedExtProcBodyProcessingMode: #ExtProcBodyProcessingMode & "Streamed"

// BufferedExtProcBodyProcessingMode will buffer the message body in memory and send the entire body at once. If the body exceeds the configured buffer limit, then the downstream system will receive an error.
#BufferedExtProcBodyProcessingMode: #ExtProcBodyProcessingMode & "Buffered"

// BufferedPartialExtBodyHeaderProcessingMode will buffer the message body in memory and send the entire body in one chunk. If the body exceeds the configured buffer limit, then the body contents up to the buffer limit will be sent.
#BufferedPartialExtBodyHeaderProcessingMode: #ExtProcBodyProcessingMode & "BufferedPartial"

// ProcessingModeOptions defines if headers or body should be processed by the external service
#ProcessingModeOptions: {
	// Defines body processing mode
	//
	// +optional
	body?: null | #ExtProcBodyProcessingMode @go(Body,*ExtProcBodyProcessingMode)
}

// ExtProcProcessingMode defines if and how headers and bodies are sent to the service.
// https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/ext_proc/v3/processing_mode.proto#envoy-v3-api-msg-extensions-filters-http-ext-proc-v3-processingmode
#ExtProcProcessingMode: {
	// Defines processing mode for requests. If present, request headers are sent. Request body is processed according
	// to the specified mode.
	//
	// +optional
	request?: null | #ProcessingModeOptions @go(Request,*ProcessingModeOptions)

	// Defines processing mode for responses. If present, response headers are sent. Response body is processed according
	// to the specified mode.
	//
	// +optional
	response?: null | #ProcessingModeOptions @go(Response,*ProcessingModeOptions)
}

// ExtProc defines the configuration for External Processing filter.
// +kubebuilder:validation:XValidation:message="BackendRefs must be used, backendRef is not supported.",rule="!has(self.backendRef)"
// +kubebuilder:validation:XValidation:message="BackendRefs only supports Service and Backend kind.",rule="has(self.backendRefs) ? self.backendRefs.all(f, f.kind == 'Service' || f.kind == 'Backend') : true"
// +kubebuilder:validation:XValidation:message="BackendRefs only supports Core and gateway.envoyproxy.io group.",rule="has(self.backendRefs) ? (self.backendRefs.all(f, f.group == \"\" || f.group == 'gateway.envoyproxy.io')) : true"
#ExtProc: {
	#BackendCluster

	// MessageTimeout is the timeout for a response to be returned from the external processor
	// Default: 200ms
	//
	// +optional
	messageTimeout?: null | gwapiv1.#Duration @go(MessageTimeout,*gwapiv1.Duration)

	// FailOpen defines if requests or responses that cannot be processed due to connectivity to the
	// external processor are terminated or passed-through.
	// Default: false
	//
	// +optional
	failOpen?: null | bool @go(FailOpen,*bool)

	// ProcessingMode defines how request and response body is processed
	// Default: header and body are not sent to the external processor
	//
	// +optional
	processingMode?: null | #ExtProcProcessingMode @go(ProcessingMode,*ExtProcProcessingMode)
}
