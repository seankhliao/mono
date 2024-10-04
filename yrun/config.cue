#ConfigHTTP: {
	Address: string
}
#ConfiggRPC: {
	Address: string
}
HTTP: #ConfigHTTP & {
	Address: string | *":8080"
}
Debug: #ConfigHTTP & {
	Address: string | *":8081"
}
GRPC: #ConfiggRPC & {
	Address: string | *":8000"
}
