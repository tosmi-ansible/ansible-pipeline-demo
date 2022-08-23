.DEFAULT_GOAL := verify

.PHONY: collections
collections:
	ansible-galaxy install -r collections/requirements.yaml

.PHONY: verify
verify:
	@echo "bla"
