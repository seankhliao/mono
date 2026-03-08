package main

import (
	"net"
	"net/http"
	"net/netip"
)

var (
	tsPrivate4 = netip.MustParsePrefix("100.64.0.0/10")
	tsPrivate6 = netip.MustParsePrefix("fd7a:115c:a1e0::/48")
)

func privateOnly(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		remoteHost, _, _ := net.SplitHostPort(r.RemoteAddr)
		remoteAddr, err := netip.ParseAddr(remoteHost)
		if err != nil {
			http.Error(w, "failed to parse remote addr", http.StatusUnauthorized)
			return
		}
		if !remoteAddr.IsLoopback() && !tsPrivate4.Contains(remoteAddr) && !tsPrivate6.Contains(remoteAddr) {
			http.Error(w, "request not from private address", http.StatusUnauthorized)
			return
		}

		h.ServeHTTP(w, r)
	})
}
