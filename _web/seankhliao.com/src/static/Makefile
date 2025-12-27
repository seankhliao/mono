.PHONY: map
map: map.png map.avif
map.png: map.svg
	magick -background none -density 150 $? -resize 2256x1390 $@
map.avif: map.svg
	magick -background none -density 150 $? -resize 2256x1390 $@

.PHONY: icon
icon: icon-192.png icon-512.png
icon-192.png: icon.svg
	magick -background none -density 150 $? -resize 192x192 $@
icon-512.png: icon.svg
	magick -background none -density 150 $? -resize 512x512 $@

.PHONY: go-list
go-list: go-list-all.avif go-list-all115.avif go-list-base.avif go-list-dotdotdot.avif go-list-dotdotdotdeps.avif go-list-dotdotdotdepstest.avif go-list-m.avif go-list-mall.avif
go-list-all.png go-list-all.avif: go-list-all.svg
	magick -background none -density 150 $? -resize 1920x1080 -write $@
go-list-all115.png go-list-all115.avif: go-list-all115.svg
	magick -background none -density 150 $? -resize 1920x1080 -write $@
go-list-base.png go-list-base.avif: go-list-base.svg
	magick -background none -density 150 $? -resize 1920x1080 -write $@
go-list-dotdotdot.png go-list-dotdotdot.avif: go-list-dotdotdot.svg
	magick -background none -density 150 $? -resize 1920x1080 -write $@
go-list-dotdotdotdeps.png go-list-dotdotdotdeps.avif: go-list-dotdotdotdeps.svg
	magick -background none -density 150 $? -resize 1920x1080 -write $@
go-list-dotdotdotdepstest.png go-list-dotdotdotdepstest.avif: go-list-dotdotdotdepstest.svg
	magick -background none -density 150 $? -resize 1920x1080 -write $@
go-list-m.png go-list-m.avif: go-list-m.svg
	magick -background none -density 150 $? -resize 1920x1080 -write $@
go-list-mall.png go-list-mall.avif: go-list-mall.svg
	magick -background none -density 150 $? -resize 1920x1080 -write $@

.PHONY: http-timeouts
http-timeouts: http-timeouts.avif
http-timeouts.png http-timeouts.avif: http-timeouts.svg
	magick $? -background none -density 150 -resize 1920x1080 $@

.PHONY: cf-rule-order-1
cf-rule-order-1: cf-rule-order-1.avif
cf-rule-order-1.avif: cf-rule-order-1.png
	magick $? $@

.PHONY: merged-analytics
merged-analytics: merged-analytics.avif
merged-analytics.avif: merged-analytics.png
	magick $? $@

.PHONY: spotify-code
spotify-code: spotify-code.avif
spotify-code.avif: spotify-code.png
	magick $? $@

.PHONY: earbug-2022
earbug-2022: earbug-2022-artist.avif earbug-2022-consistency.avif earbug-2022-time.avif earbug-2022-track.avif
earbug-2022-artist.avif: earbug-2022-artist.png
	magick $? $@
earbug-2022-consistency.avif: earbug-2022-consistency.png
	magick $? $@
earbug-2022-time.avif: earbug-2022-time.png
	magick $? $@
earbug-2022-track.avif: earbug-2022-track.png
	magick $? $@

.PHONY: github-merge-queue
github-merge-queue: github-merge-queue.avif
github-merge-queue.avif: github-merge-queue.png
	magick $? $@

.PHONY: pruned-module-graph
pruned-module-graph: pruned-module-graph.avif
pruned-module-graph.avif: pruned-module-graph.png
	magick $? $@
