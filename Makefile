# Get the directory of the Make file
MAKE_FILE := $(realpath $(firstword $(MAKEFILE_LIST)))

# Get the directory of the Make file
MAKE_DIR := $(realpath $(dir $(MAKE_FILE)))

# Static site sources
STATIC_DIR := $(MAKE_DIR)/Static

# All static sources
STATIC_SOURCES := $(shell find $(STATIC_DIR) -type f)

# Build directory
BUILD_DIR ?= $(MAKE_DIR)/.build

# JS Package Outputs
JS_PACKAGE_DIR := $(BUILD_DIR)/plugins/PackageToJS/outputs

# JS Packages
JS_PACKAGES := Scala

# JS Package sources
JS_PACKAGE_SOURCES := $(foreach package,$(JS_PACKAGES),$(shell find "$(JS_PACKAGE_DIR)/$(package)/" -type f))

# Site worktree
SITE_DIR ?= $(MAKE_DIR)/site

# Package output directory
SITE_PACKAGE_DIR := $(SITE_DIR)/Package

# Static outputs
STATIC_OUTPUTS := $(patsubst $(STATIC_DIR)/%,$(SITE_DIR)/%,$(STATIC_SOURCES))

# JS Package outputs
JS_PACKAGE_OUTPUTS := $(patsubst $(JS_PACKAGE_DIR)/%,$(SITE_PACKAGE_DIR)/%,$(JS_PACKAGE_SOURCES))

# Swift
# =====

# SDK
SWIFT_SDK_ID := swift-6.4.1-RELEASE_wasm

# Configuration
SWIFT_CONFIGURATION ?= release

# Swiftly
ifdef SWIFTLY_HOME_DIR
	SWIFTLY_PATH=$(SWIFTLY_HOME_DIR)/bin
	SWIFT_PATH=$(SWIFTLY_PATH):$(subst $(SWIFTLY_PATH):,,$(PATH))
else
	SWIFT_PATH=$(PATH)
endif

# swift
SWIFT_TOOL := env PATH="$(SWIFT_PATH)" swift

# swift package
SWIFT_PACKAGE_TOOL := \
	$(SWIFT_TOOL) package \
		--swift-sdk "$(SWIFT_SDK_ID)" \
		--scratch-path "$(BUILD_DIR)"

# Scala WASM package
SCALA_PACKAGE := $(JS_PACKAGE_DIR)/Scala
SCALA_SOURCES := \
	$(MAKE_DIR)/Package.swift \
	$(wildcard $(MAKE_DIR)/Sources/**/*)

# Generic rules

.PHONY: serve
serve:
	npx serve "$(SITE_DIR)"

.PHONY: site
site: package-build
	@$(MAKE) -f $(MAKE_FILE) site-clean
	@$(MAKE) -f $(MAKE_FILE) site-install

.PHONY: site-clean
site-clean:
	@printf -- "Clean site: %s\n" $(SITE_DIR)
	@rm -rvf $(wildcard $(SITE_DIR)/*)

.PHONY: site-install
site-install: static package-install

.PHONY: static
static: $(STATIC_OUTPUTS)

.PHONY: package-build
package-build: $(SCALA_PACKAGE)

.PHONY: package-install
package-install: $(JS_PACKAGE_OUTPUTS)

# Specific targets

# Static Files
$(STATIC_OUTPUTS): $(SITE_DIR)/%: $(STATIC_DIR)/%
	@printf -- "Copy: %s\n" "$*"
	@mkdir -p "$(dir $@)"
	@cp "$<" "$@"

# Scala WASM package
.PHONY: $(SCALA_PACKAGE)
$(SCALA_PACKAGE): $(SCALA_SOURCES)
	@printf -- "Build WASM package: %s\n" "$@"
	@mkdir -p "$(SCALA_PACKAGE)"
	$(SWIFT_PACKAGE_TOOL) js \
		--use-cdn \
		--product Scala \
		--configuration $(SWIFT_CONFIGURATION) \
		--output "$(SCALA_PACKAGE)"

# Installed WASM packages
$(JS_PACKAGE_OUTPUTS): $(SITE_PACKAGE_DIR)/%: $(JS_PACKAGE_DIR)/%
	@printf -- "Copy: %s\n" "$*"
	@mkdir -p "$(dir $@)"
	@cp "$<" "$@"
