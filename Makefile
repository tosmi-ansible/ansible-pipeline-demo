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
	ansible-galaxy install -r collections/requirements.yaml

verify:
	@oc whoami

setup: verify collections ## Run setup playbook
	ansible-playbook playbooks/setup.yml

###################
# Content targets #
###################
.PHONY: controller-content

controller-content: ## Prepare Ansible Controller content
	ansible-playbook playbooks/setup.yml -e controller_subscription_installed=yes

##################
# Helper targets #
##################
.PHONY: toc

toc: ## Generate a simple markdown toc, does not support levels!
	@awk -F'^#+'  '/^#.*/ && !/^## Table/ && NR!=1  {gsub("^ ","",$$2); link=tolower($$2); gsub(" ","-",link); printf "* [%s](#%s)\n",$$2,link }' README.md
