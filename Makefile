.DEFAULT_GOAL := help

###############
# Help Target #
###############
.PHONY: help
help: ## Show this help screen
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@echo 'Available targets are:'
	@echo ''
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

#################
# Setup targets #
#################
.PHONY: collections setup pythonlibs verify

pythonlibs: ## Install required python libraries
	python -m pip install -q -r collections/requirements.txt

collections: pythonlibs  ## Install required collections
	@echo "Trying to install required collections..."
	ansible-galaxy install -r collections/requirements.yaml

verify:
	@oc whoami

setup: verify collections ## Run setup playbook
	ansible-playbook $(VERBOSITY) playbooks/setup.yml

##################
# Helper targets #
##################
.PHONY: toc pipeline-test utils-image

toc: ## Generate a simple markdown toc, does not support levels!
	@awk -F'^#+'  '/^#.*/ && !/^## Table/ && NR!=1  {gsub("^ ","",$$2); link=tolower($$2); gsub(" ","-",link); printf "* [%s](#%s)\n",$$2,link }' README.md

pipeline-test: ## Trigger a pipeline run with a locally stored gitea event (just for testing)
	@bash -x tests/pipeline/trigger-pipeline.sh

utils-image: ## Generate a UBI 9 based image that contains the `jq` binary
	@buildah build -t quay.io/tosmi/ubi9-utils:latest pipeline/scripts/
	@podman push quay.io/tosmi/ubi9-utils:latest
