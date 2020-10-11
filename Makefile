.PHONY: *
all:
	webrender -disableanalytics -embedstyle -src=newtab.md -dst=index.html
