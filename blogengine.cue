render: {
	baseUrl: "https://liao.dev"
	gtm:     "GTM-TLVN7D6"
}

firebase: {
	site: "liaodev"
	redirects: [{
	    code: 307
	    glob: "/.well-known/nodeinfo"
	    location: "https://estherian.liao.dev/.well-known/nodeinfo"
	},{
	    code: 307
	    glob: "/.well-known/webfinger"
	    location: "https://estherian.liao.dev/.well-known/webfinger"
	}]
}
