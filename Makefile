# nix-mox Development Makefile
# ============================
# This Makefile provides convenient commands for development, testing, and maintenance

# Variables
TEST_DIR = coverage-tmp/nix-mox-tests
TEST_TEMP_DIR = coverage-tmp
NUSHELL = nu
NIX = nix

# Available packages (from flake.nix)
PACKAGES = proxmox-update vzdump-backup zfs-snapshot nixos-flake-update install uninstall

# Phony targets
.PHONY: help test unit integration clean format check build build-all \
        dev test-shell gaming-shell macos-shell services-shell monitoring-shell zfs-shell \
        ci-test ci-local update lock clean-all packages shells analyze-sizes

# Default target - show help
help:
	@echo "nix-mox Development Commands"
	@echo "============================"
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  dev         - Enter development shell"
	@echo "  build       - Build default package"
	@echo "  test        - Run all tests"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  test        - Run all tests (unit + integration)"
	@echo "  unit        - Run unit tests only"
	@echo "  integration - Run integration tests only"
	@echo "  clean       - Clean up test artifacts"
	@echo ""
	@echo "🔧 Development:"
	@echo "  format      - Format Nix files with nixpkgs-fmt"
	@echo "  check       - Run nix flake check"
	@echo "  build       - Build default package"
	@echo "  build-all   - Build all packages"
	@echo "  update      - Update flake inputs"
	@echo "  lock        - Update flake.lock"
	@echo ""
	@echo "💻 Development Shells:"
	@echo "  dev         - Enter default development shell"
	@echo "  test-shell  - Enter testing shell"
	@echo "  gaming-shell - Enter gaming shell (Linux x86_64 only)"
	@echo "  macos-shell - Enter macOS shell (macOS only)"
	@echo "  services-shell - Enter services shell"
	@echo "  monitoring-shell - Enter monitoring shell"
	@echo "  zfs-shell   - Enter ZFS/storage shell (Linux only)"
	@echo ""
	@echo "📊 Analysis:"
	@echo "  analyze-sizes - Analyze size of packages, devshells, and templates"
	@echo ""
	@echo "🔄 CI/CD:"
	@echo "  ci-test     - Run quick CI test locally"
	@echo "  ci-local    - Run comprehensive CI test locally"
	@echo ""
	@echo "🧹 Maintenance:"
	@echo "  clean       - Clean test artifacts"
	@echo "  clean-all   - Clean all artifacts and temporary files"
	@echo ""
	@echo "📦 Information:"
	@echo "  packages    - Show available packages"
	@echo "  shells      - Show available development shells"
	@echo ""
	@echo "💡 Tips:"
	@echo "  - Use 'make dev' to start development"
	@echo "  - Use 'make test' before committing changes"
	@echo "  - Use 'make format' to ensure consistent code style"
	@echo "  - Use 'make analyze-sizes' to see performance tradeoffs"
	@echo "  - Use 'make clean-all' if you encounter build issues"

# Testing targets
test: $(TEST_DIR)
	@echo "🧪 Running all tests..."
	$(NUSHELL) -c "source scripts/tests/run-tests.nu; run []"

unit: $(TEST_DIR)
	@echo "🧪 Running unit tests..."
	$(NUSHELL) scripts/tests/unit/unit-tests.nu

integration: $(TEST_DIR)
	@echo "🧪 Running integration tests..."
	$(NUSHELL) scripts/tests/integration/integration-tests.nu

# Create test directory
$(TEST_DIR):
	@echo "📁 Creating test directory..."
	mkdir -p $(TEST_DIR)

# Clean up test artifacts
clean:
	@echo "🧹 Cleaning test artifacts..."
	rm -rf coverage-tmp
	rm -f coverage.json coverage.yaml coverage.toml

# Development targets
format:
	@echo "🎨 Formatting Nix files..."
	$(NIX) fmt

check:
	@echo "✅ Running flake check..."
	$(NIX) flake check

# Build targets
build:
	@echo "🔨 Building default package..."
	$(NIX) build .#default

build-all:
	@echo "🔨 Building all packages..."
	@for package in $(PACKAGES); do \
		echo "Building $$package..."; \
		$(NIX) build .#$$package || exit 1; \
	done
	@echo "✅ All packages built successfully!"

# Flake management
update:
	@echo "🔄 Updating flake inputs..."
	$(NIX) flake update

lock:
	@echo "🔒 Updating flake.lock..."
	$(NIX) flake lock

# Development shells
dev:
	@echo "💻 Entering development shell..."
	$(NIX) develop

test-shell:
	@echo "🧪 Entering testing shell..."
	$(NIX) develop .#testing

gaming-shell:
	@echo "🎮 Entering gaming shell..."
	$(NIX) develop .#gaming

macos-shell:
	@echo "🍎 Entering macOS shell..."
	$(NIX) develop .#macos

services-shell:
	@echo "🔧 Entering services shell..."
	$(NIX) develop .#services

monitoring-shell:
	@echo "📊 Entering monitoring shell..."
	$(NIX) develop .#monitoring

zfs-shell:
	@echo "💾 Entering ZFS shell..."
	$(NIX) develop .#zfs

# Analysis targets
analyze-sizes:
	@echo "📊 Analyzing repository sizes..."
	./scripts/analyze-sizes.sh

# CI/CD targets
ci-test:
	@echo "🔄 Running quick CI test..."
	./scripts/ci-test.sh

ci-local:
	@echo "🔄 Running comprehensive CI test..."
	./scripts/test-ci-local.sh

# Maintenance targets
clean-all: clean
	@echo "🧹 Cleaning all artifacts..."
	rm -rf tmp/
	rm -rf result/
	$(NIX) store gc
	@echo "✅ All artifacts cleaned!"

# Information targets
packages:
	@echo "📦 Available packages:"
	@for package in $(PACKAGES); do \
		echo "  - $$package"; \
	done

shells:
	@echo "💻 Available development shells:"
	@echo "  - default (general development)"
	@echo "  - development (full dev tools)"
	@echo "  - testing (test tools)"
	@echo "  - services (service deployment)"
	@echo "  - monitoring (monitoring tools)"
	@echo "  - gaming (Linux x86_64 only)"
	@echo "  - macos (macOS only)"
	@echo "  - zfs (Linux only)"
