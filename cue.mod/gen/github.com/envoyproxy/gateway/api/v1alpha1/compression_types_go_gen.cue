// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/envoyproxy/gateway/api/v1alpha1

package v1alpha1

// CompressorType defines the types of compressor library supported by Envoy Gateway.
//
// +kubebuilder:validation:Enum=Gzip;Brotli
#CompressorType: string // #enumCompressorType

#enumCompressorType:
	#GzipCompressorType |
	#BrotliCompressorType

#GzipCompressorType:   #CompressorType & "Gzip"
#BrotliCompressorType: #CompressorType & "Brotli"

// GzipCompressor defines the config for the Gzip compressor.
// The default values can be found here:
// https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/compression/gzip/compressor/v3/gzip.proto#extension-envoy-compression-gzip-compressor
#GzipCompressor: {}

// BrotliCompressor defines the config for the Brotli compressor.
// The default values can be found here:
// https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/compression/brotli/compressor/v3/brotli.proto#extension-envoy-compression-brotli-compressor
#BrotliCompressor: {}

// Compression defines the config of enabling compression.
// This can help reduce the bandwidth at the expense of higher CPU.
#Compression: {
	// CompressorType defines the compressor type to use for compression.
	//
	// +required
	type: #CompressorType @go(Type)

	// The configuration for Brotli compressor.
	//
	// +optional
	brotli?: null | #BrotliCompressor @go(Brotli,*BrotliCompressor)

	// The configuration for GZIP compressor.
	//
	// +optional
	gzip?: null | #GzipCompressor @go(Gzip,*GzipCompressor)
}
