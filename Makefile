#!/usr/bin/env bash

OS = $(strip $(shell uname -s))
ARCH = linux_amd64
ifeq ($(OS),Darwin)
	ARCH = darwin_amd64
endif

PLUGIN_DIR = ~/.terraform.d/plugins

PROVIDER_NAME = terraform-provider-ansible
PROVIDER_VERSION = v0.0.4
PROVIDER_ARCHIVE = $(PROVIDER_NAME)-$(ARCH).zip
PROVIDER_URL = https://github.com/nbering/terraform-provider-ansible/releases/download/$(PROVIDER_VERSION)/$(PROVIDER_ARCHIVE)

PROVISIONER_NAME = terraform-provisioner-ansible
PROVISIONER_VERSION = v0.0.1
PROVISIONER_TMP = /tmp/${PROVISIONER_NAME}
PROVISIONER_URL = https://github.com/radekg/${PROVISIONER_NAME}

PLATFORM = linux
ifeq ($(OS),Darwin)
	PLATFORM = darwin
endif

all: requirements install-provider install-provisioner secrets cleanup
	echo "Success!"

plugins: install-provider install-provisioner

requirements:
	ansible-galaxy install --ignore-errors --force -r ansible/requirements.yml

install-unzip:
	ifeq (, $(shell which unzip)) \
 		$(error "No unzip in PATH, consider doing apt install unzip") \
 	endif

install-provider:
	if [ ! -e $(PLUGIN_DIR)/$(ARCH)/$(PROVIDER_NAME)_$(PROVIDER_VERSION) ]; then \
		mkdir -p $(PLUGIN_DIR); \
		wget $(PROVIDER_URL) -P $(PLUGIN_DIR); \
		unzip -o $(PLUGIN_DIR)/$(PROVIDER_ARCHIVE) -d $(PLUGIN_DIR); \
	fi

install-provisioner:
	if [ ! -e $(PLUGIN_DIR)/$(ARCH)/$(PROVISIONER_NAME)_$(PROVISIONER_VERSION) ]; then \
		mkdir -p $(PROVISIONER_TMP); \
		git clone $(PROVISIONER_URL) $(PROVISIONER_TMP); \
		cd $(PROVISIONER_TMP); \
		go get github.com/hashicorp/terraform; \
        go get github.com/mitchellh/go-homedir; \
        go get github.com/mitchellh/go-linereader; \
        go get github.com/mitchellh/mapstructure; \
        go get golang.org/x/crypto/ssh; \
        go get github.com/satori/go.uuid; \
		make install; \
		make build-$(PLATFORM); \
	fi

secrets:
	pass services/consul/ca-crt > ansible/files/consul-ca.crt
	pass services/consul/ca-key > ansible/files/consul-ca.key
	pass services/consul/client-crt > ansible/files/consul-client.crt
	pass services/consul/client-key > ansible/files/consul-client.key
	pass cloud/GoogleCloud/json > google-cloud.json
	echo "\
# secrets extracted from password-store\n\
digitalocean_token  = \"$(shell pass cloud/DigitalOcean/token)\"\n\
cloudflare_token    = \"$(shell pass cloud/Cloudflare/token)\"\n\
cloudflare_email    = \"$(shell pass cloud/Cloudflare/email)\"\n\
cloudflare_org_id   = \"$(shell pass cloud/Cloudflare/org_id)\"\n\
alicloud_access_key = \"$(shell pass cloud/Alibaba/access-key)\"\n\
alicloud_secret_key = \"$(shell pass cloud/Alibaba/secret-key)\"\n\
" > terraform.tfvars

cleanup:
	rm -rf $(PLUGIN_DIR)/$(ARCHIVE)
