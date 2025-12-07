SHELL := /bin/bash

# Default target: show help
.DEFAULT_GOAL := help

# Install paths (can be overridden: make PREFIX=/usr)
PREFIX      ?= /usr/local
BINDIR      ?= $(PREFIX)/bin
SYSCONFDIR  ?= /etc
MANDIR      ?= $(PREFIX)/share/man
DOCDIR      ?= $(PREFIX)/share/doc/tgpipe

# Tools (can be overridden: make SHFMT=/path/to/shfmt)
SHELLCHECK  ?= shellcheck
SHFMT       ?= shfmt
GIT         ?= git
RSYNC       ?= rsync

# Sources
SOURCES     := bin/tgpipe

# Version from debian/changelog (upstream part, without -1)
UPSTREAM_VERSION ?= $(shell dpkg-parsechangelog -S Version 2>/dev/null | sed 's/-[^-]*$$//' || echo "0.0.0")

# Debian build staging directory (keeps artifacts inside repo/sandbox)
DEB_BUILD_DIR ?= dist/debbuild
DEB_BUILD_OPTIONS ?= nocheck

# Phony targets
PHONY_TARGETS := \
	help \
	all \
	fmt \
	lint \
	test \
	install \
	uninstall \
	man \
	deb \
	deb-clean \
	dist \
	release \
	clean

.PHONY: $(PHONY_TARGETS)

## Help #######################################################################

# Self-documenting help: any target with "##" comment will appear here
help: ## Show this help
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_.-]+:.*##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

## Default / meta targets ######################################################

all: lint ## Run linters (shellcheck + shfmt -d)

## Formatting / linting #######################################################

fmt: ## Format shell sources with shfmt
	$(SHFMT) -w $(SOURCES)

lint: ## Run shellcheck and shfmt -d
	$(SHELLCHECK) $(SOURCES)
	$(SHFMT) -d $(SOURCES)

## Tests ######################################################################

test: ## Run smoke test (requires TGPIPE_* env vars)
	./tests/smoke-test.sh

## Local install / uninstall ##################################################

install: ## Install tgpipe, config example, man page and docs
	install -Dm0755 bin/tgpipe                "$(DESTDIR)$(BINDIR)/tgpipe"
	install -Dm0644 etc/tgpipe.conf.example  "$(DESTDIR)$(SYSCONFDIR)/tgpipe.conf.example"
	install -Dm0644 man/tgpipe.1             "$(DESTDIR)$(MANDIR)/man1/tgpipe.1"
	install -Dm0644 README.md                "$(DESTDIR)$(DOCDIR)/README.md"
	install -Dm0644 CHANGELOG.md             "$(DESTDIR)$(DOCDIR)/CHANGELOG.md"
	install -Dm0644 LICENSE                  "$(DESTDIR)$(DOCDIR)/LICENSE"
	install -Dm0644 assets/tgpipe-logo.svg   "$(DESTDIR)$(DOCDIR)/tgpipe-logo.svg"

uninstall: ## Uninstall tgpipe and related files (except real /etc/tgpipe.conf)
	rm -f  "$(DESTDIR)$(BINDIR)/tgpipe"
	rm -f  "$(DESTDIR)$(SYSCONFDIR)/tgpipe.conf.example"
	rm -f  "$(DESTDIR)$(MANDIR)/man1/tgpipe.1"
	rm -rf "$(DESTDIR)$(DOCDIR)"

## Man page ###################################################################

man: ## Build compressed man page man/tgpipe.1.gz
	gzip -c man/tgpipe.1 > man/tgpipe.1.gz

## Debian package #############################################################

deb: lint ## Build Debian package via dpkg-buildpackage
	@mkdir -p $(DEB_BUILD_DIR)
	$(RSYNC) -a --delete --exclude 'dist' --exclude '.git' ./ $(DEB_BUILD_DIR)/
	cd $(DEB_BUILD_DIR) && \
		PREFIX=/usr BINDIR=/usr/bin MANDIR=/usr/share/man DOCDIR=/usr/share/doc/tgpipe \
		DEB_BUILD_OPTIONS="$(DEB_BUILD_OPTIONS)" \
		dpkg-buildpackage -us -uc
	@echo "Debian artifacts are in dist/:"
	@ls -1 dist/tgpipe_* 2>/dev/null || true

deb-clean: ## Remove Debian build artifacts
	@echo "Cleaning Debian build artifacts..."
	rm -f dist/tgpipe_*_all.deb dist/tgpipe_*.buildinfo dist/tgpipe_*.changes dist/tgpipe_*.dsc dist/tgpipe_*.tar.* || true
	rm -rf $(DEB_BUILD_DIR) || true

## Distribution tarball / release #############################################

dist: ## Create source tarball tgpipe-<version>.tar.gz in dist/
	@mkdir -p dist
	@if command -v $(GIT) >/dev/null 2>&1; then \
	  echo "Creating git archive for version $(UPSTREAM_VERSION)..."; \
	  $(GIT) archive --format=tar --prefix=tgpipe-$(UPSTREAM_VERSION)/ HEAD | gzip -9 > dist/tgpipe-$(UPSTREAM_VERSION).tar.gz; \
	  echo "Created dist/tgpipe-$(UPSTREAM_VERSION).tar.gz"; \
	else \
	  echo "git not found; cannot create dist tarball" >&2; \
	  exit 1; \
	fi

release: lint test deb dist ## Run lint/test, build .deb and tarball (for GitHub release)
	@echo
	@echo "Release artifacts are ready:"
	@ls -1 ../tgpipe_*_all.deb dist/tgpipe-$(UPSTREAM_VERSION).tar.gz 2>/dev/null || true
	@echo
	@echo "Next steps (example):"
	@echo "  1) Tag the release:"
	@echo "       git tag v$(UPSTREAM_VERSION)"
	@echo "       git push --tags"
	@echo "  2) Create a GitHub Release and upload the .deb and tarball."

## Cleanup ####################################################################

clean: deb-clean ## Clean build artifacts (Debian + dist/)
	@echo "Cleaning dist/..."
	rm -rf dist
