#HTTPConfig: {
	Address: string
}
// #gRPCConfig: {
// 	Address: string
// }

HTTP: #HTTPConfig & {
	Address: string | *":8080"
}
Debug: #HTTPConfig & {
	Address: string | *":8081"
}
// GRPC: #gRPCConfig & {
// 	Address: string | *":8000"
// }
