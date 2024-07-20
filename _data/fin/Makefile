.PHONY: push
push:
	gcloud storage rsync --exclude "^(Makefile|.gitignore|README.md)$$" . gs://fin-liao-dev

.PHONY: pull
pull:
	gcloud storage rsync gs://fin-liao-dev .
