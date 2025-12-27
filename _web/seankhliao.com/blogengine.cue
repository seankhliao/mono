render: {
	baseUrl: "https://seankhliao.com"
	gtm:     "G-9GLEE4YLNC"
	// dst:     "out"
}

firebase: {
	site: "com-seankhliao"
	headers: [{
		glob: "/static/*.woff2"
		headers: "Access-Control-Allow-Origin": "*"
	}, {
		glob: "/(icon*|favicon.ico)"
		headers: "Access-Control-Allow-Origin": "*"
	}]
	_redirects: [
		["/ac-p-s", "/?utm_campaign=seankhliao&utm_medium=profile&utm_source=angelco"],
		["/cv-p-s", "/?utm_campaign=seankhliao&utm_medium=profile&utm_source=cv"],
		["/fb-p-s", "/?utm_campaign=seankhliao&utm_medium=profile&utm_source=facebook"],
		["/gh-p-er", "/?utm_campaign=erred&utm_medium=profile&utm_source=github"],
		["/gh-p-sd", "/?utm_campaign=sean-dbk&utm_medium=profile&utm_source=github"],
		["/gh-p-s", "/?utm_campaign=seankhliao&utm_medium=profile&utm_source=github"],
		["/gh-p-ss", "/?utm_campaign=sean-snyk&utm_medium=profile&utm_source=github"],
		["/gh-r-er", "/?utm_campaign=erred&utm_medium=readme&utm_source=github"],
		["/gh-r-sd", "/?utm_campaign=sean-dbk&utm_medium=readme&utm_source=github"],
		["/gh-r-s", "/?utm_campaign=seankhliao&utm_medium=readme&utm_source=github"],
		["/gh-s-er", "/?utm_campaign=erred&utm_medium=site&utm_source=github"],
		["/gh-s-sd", "/?utm_campaign=sean-dbk&utm_medium=site&utm_source=github"],
		["/gh-s-s", "/?utm_campaign=seankhliao&utm_medium=site&utm_source=github"],
		["/g-p-s", "/?utm_campaign=seankhliao&utm_medium=profile&utm_source=google"],
		["/ig-p-s", "/?utm_campaign=seankhliao&utm_medium=profile&utm_source=instagram"],
		["/li-r-s", "/?utm_campaign=seankhliao&utm_medium=readme&utm_source=linkedin"],
		["/li-p-s", "/?utm_campaign=seankhliao&utm_medium=profile&utm_source=linkedin"],
		["/mtd-p-s", "/?utm_campaign=seankhliao&utm_medium=profile&utm_source=mastodon"],
		["/sl-p-gophers", "/?utm_campaign=gophers&utm_medium=profile&utm_source=slack"],
		["/tw-p-s", "/?utm_campaign=seankhliao&utm_medium=profile&utm_source=twitter"],
		["/w-s-liadev", "/?utm_campaign=liadev&utm_medium=site&utm_source=web"],
		["/yt-p-s", "/?utm_campaign=seankhliao&utm_medium=profile&utm_source=youtube"],
	]
	redirects: [for _red in _redirects {
		code:     307
		glob:     _red[0]
		location: _red[1]
	}]
}
