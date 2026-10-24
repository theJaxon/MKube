# Local release flow for the MKube box. The Packer build needs VirtualBox on Apple silicon,
# so it runs on this Mac; everything else goes through Dagger.
#
#   make release
#
# `publish` needs GITHUB_TOKEN exported (contents: write on theJaxon/MKube),
# e.g. export GITHUB_TOKEN=$(gh auth token)

PACKER_TEMPLATE_LOCATION := $(HOME)/Documents/GitHub/Packer/Fedora/44
# Build VM disk, ISO cache, temp files and fedora.box all go to the external drive
BUILD_DIR                := /Volumes/Jaxon-Gaming/packer
# Box version = Kubernetes minor from the kickstart (e.g. 1.37), looked up only when a target needs it
VERSION                  = $(shell dagger call kubernetes-version --template $(PACKER_TEMPLATE_LOCATION))

.PHONY: release lint build publish bump smoke-test

release: lint build publish bump smoke-test

lint:
	dagger call lint --template $(PACKER_TEMPLATE_LOCATION)

build:
	mkdir -p $(BUILD_DIR)/cache $(BUILD_DIR)/tmp
	cd $(PACKER_TEMPLATE_LOCATION) && packer init . && \
	  PACKER_CACHE_DIR=$(BUILD_DIR)/cache TMPDIR=$(BUILD_DIR)/tmp \
	  packer build -force -var build_dir=$(BUILD_DIR) .

# Uploads to GitHub Releases; rebuilds of the same Kubernetes minor replace that version
publish:
	dagger call publish --box-file $(BUILD_DIR)/fedora.box --version $(VERSION) \
	  --github-token env://GITHUB_TOKEN

bump:
	dagger call bump --version $(VERSION) export --path .

# Drops the cached box first, since a rebuilt version keeps its number
smoke-test:
	vagrant box remove the-jaxon/mkube --box-version $(VERSION) --provider virtualbox --force || true
	vagrant up
	vagrant ssh controlplane -c 'KUBECONFIG=~/.kube/conf kubectl wait --for=condition=Ready node --all --timeout=10m && KUBECONFIG=~/.kube/conf kubectl get nodes -o wide'
	vagrant destroy -f
