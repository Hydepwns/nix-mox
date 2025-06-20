# Variables
TEST_DIR = coverage-tmp/nix-mox-tests
TEST_TEMP_DIR = coverage-tmp
NUSHELL = nu
NIX = nix

# Available packages (from flake.nix)
PACKAGES = proxmox-update vzdump-backup zfs-snapshot nixos-flake-update

# Phony targets
.PHONY: help test unit integration clean format check build build-all \
        dev test-shell gaming-shell macos-shell services-shell monitoring-shell storage-shell \
        ci-test ci-local update lock clean-all

# Default target
help:
	@echo "nix-mox Development Commands"
	@echo "============================"
	@echo ""
	@echo "Testing:"
	@echo "  test        - Run all tests"
	@echo "  unit        - Run unit tests only"
	@echo "  integration - Run integration tests only"
	@echo "  clean       - Clean up test artifacts"
	@echo ""
	@echo "Development:"
	@echo "  format      - Format Nix files"
	@echo "  check       - Run nix flake check"
	@echo "  build       - Build default package"
	@echo "  build-all   - Build all packages"
	@echo "  update      - Update flake inputs"
	@echo "  lock        - Update flake.lock"
	@echo ""
	@echo "Shells:"
	@echo "  dev         - Enter development shell"
	@echo "  test-shell  - Enter testing shell"
	@echo "  gaming-shell - Enter gaming shell (Linux x86_64 only)"
	@echo "  macos-shell - Enter macOS shell (macOS only)"
	@echo "  services-shell - Enter services shell"
	@echo "  monitoring-shell - Enter monitoring shell"
	@echo "  storage-shell - Enter storage shell"
	@echo ""
	@echo "CI/CD:"
	@echo "  ci-test     - Run quick CI test locally"
	@echo "  ci-local    - Run comprehensive CI test locally"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean-all   - Clean all artifacts and temporary files"

# Testing targets
test: $(TEST_DIR)
	$(NUSHELL) -c "source scripts/tests/run-tests.nu; run []"

unit: $(TEST_DIR)
	$(NUSHELL) scripts/tests/unit/unit-tests.nu

integration: $(TEST_DIR)
	$(NUSHELL) scripts/tests/integration/integration-tests.nu

# Create test directory
$(TEST_DIR):
	mkdir -p $(TEST_DIR)

# Clean up test artifacts
clean:
	rm -rf coverage-tmp
	rm -f coverage.json coverage.yaml coverage.toml

# Development targets
format:
	$(NIX) fmt

check:
	$(NIX) flake check

# Build targets
build:
	$(NIX) build .#default

build-all:
	@echo "Building all packages..."
	@for package in $(PACKAGES); do \
		echo "Building $$package..."; \
		$(NIX) build .#$$package || exit 1; \
	done
	@echo "All packages built successfully!"

# Flake management
update:
	$(NIX) flake update

lock:
	$(NIX) flake lock

# Development shells
dev:
	$(NIX) develop

test-shell:
	$(NIX) develop .#testing

gaming-shell:
	$(NIX) develop .#gaming

macos-shell:
	$(NIX) develop .#macos

services-shell:
	$(NIX) develop .#services

monitoring-shell:
	$(NIX) develop .#monitoring

storage-shell:
	$(NIX) develop .#storage

# CI/CD targets
ci-test:
	./scripts/ci-test.sh

ci-local:
	./scripts/test-ci-local.sh

# Maintenance targets
clean-all: clean
	rm -rf tmp/
	rm -rf result/
	$(NIX) store gc
	@echo "All artifacts cleaned!"

# Show available packages
packages:
	@echo "Available packages:"
	@for package in $(PACKAGES); do \
		echo "  - $$package"; \
	done

# Show available shells
shells:
	@echo "Available development shells:"
	@echo "  - default"
	@echo "  - development"
	@echo "  - testing"
	@echo "  - services"
	@echo "  - monitoring"
	@echo "  - gaming (Linux x86_64 only)"
	@echo "  - macos (macOS only)"
	@echo "  - storage"
