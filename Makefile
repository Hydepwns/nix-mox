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
.PHONY: help test test-unit test-integration test-flake test-gaming clean format fmt check check-flake build build-all build-packages \
        dev test-shell gaming-shell macos-shell services-shell monitoring-shell zfs-shell \
        ci-test ci-local update update-flake lock clean-all packages shells analyze-sizes \
        setup setup-gaming gaming-setup gaming-workstation gaming-workstation-dev gaming-workstation-interactive gaming-benchmark validate-gaming \
        health-check security-check sbom sbom-spdx sbom-cyclonedx sbom-csv cache-optimize cache-warm cache-maintain \
        size-dashboard size-dashboard-html size-dashboard-api remote-builder-setup test-remote-builder \
        performance-analyze performance-optimize performance-report perf \
        code-quality code-syntax code-security quality \
        validate-display validate-display-interactive validate-display-backup validate-display-verbose validate-display-full \
        coverage coverage-grcov coverage-tarpaulin coverage-custom coverage-ci coverage-local \
        safe-rebuild safety-check safe-test bootstrap-check

# Default target - show help
help:
	@echo "nix-mox Development Commands"
	@echo "============================"
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  dev         - Enter development shell"
	@echo "  build       - Build default package"
	@echo "  test        - Run all tests"
	@echo "  setup       - Interactive configuration setup"
	@echo "  health-check - System health validation"
	@echo "  gaming-setup - Setup gaming workstation"
	@echo "  storage-guard - Validate storage before reboot"
	@echo "  fix-storage - Auto-fix storage configuration"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  test        - Run all tests (unit + integration)"
	@echo "  test-flake  - Run tests with flake"
	@echo "  unit        - Run unit tests only"
	@echo "  integration - Run integration tests only"
	@echo "  gaming-test - Test gaming setup"
	@echo "  display-test - Test display configuration"
	@echo "  display-test-interactive - Interactive display testing"
	@echo "  display-test-backup - Display testing with backup"
	@echo "  display-test-verbose - Verbose display testing"
	@echo "  display-test-all - Comprehensive display testing"
	@echo "  clean       - Clean up test artifacts"
	@echo ""
	@echo "🔧 Development:"
	@echo "  format      - Format Nix files with nixpkgs-fmt"
	@echo "  fmt         - Format all code with treefmt"
	@echo "  check       - Run nix flake check"
	@echo "  build       - Build default package"
	@echo "  build-all   - Build all packages"
	@echo "  update      - Update flake inputs"
	@echo "  update-flake - Update flake inputs with flake"
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
	@echo "📊 Analysis & Optimization:"
	@echo "  analyze-sizes - Analyze size of packages, devshells, and templates"
	@echo "  size-dashboard - Generate and serve web-based size analysis dashboard"
	@echo "  cache-optimize - Run advanced caching strategy with optimization"
	@echo "  performance-analyze - Comprehensive performance analysis"
	@echo "  performance-optimize - Apply performance optimizations"
	@echo "  performance-report - Generate performance report"
	@echo "  perf - Quick performance check"
	@echo "  code-quality - Comprehensive code quality analysis"
	@echo "  code-syntax - Check syntax of all files"
	@echo "  code-security - Check for security issues"
	@echo "  quality - Quick code quality check"
	@echo ""
	@echo "📊 Coverage & Testing:"
	@echo "  coverage - Set up LCOV coverage (recommended for Codecov)"
	@echo "  coverage-grcov - Set up grcov coverage (Rust-based)"
	@echo "  coverage-tarpaulin - Set up tarpaulin coverage (Rust-based)"
	@echo "  coverage-custom - Set up custom test-based coverage"
	@echo "  coverage-ci - Set up coverage for CI environments"
	@echo "  coverage-local - Set up coverage for local development"
	@echo ""
	@echo "🔒 Compliance & Security:"
	@echo "  security-check - Validate security module configuration"
	@echo "  sbom         - Generate Software Bill of Materials (SPDX, CycloneDX, CSV)"
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
	@echo "🛡️  Safety & Bootstrap:"
	@echo "  bootstrap-check - REQUIRED: Check bootstrap requirements"
	@echo "  safety-check - REQUIRED: Validate system safety before rebuild"
	@echo "  safe-test    - Comprehensive flake testing strategy"  
	@echo "  safe-rebuild - Safe nixos-rebuild with mandatory validation"
	@echo ""
	@echo "💡 Tips:"
	@echo "  - ALWAYS run 'make bootstrap-check' on fresh systems"
	@echo "  - ALWAYS run 'make safety-check' before any nixos-rebuild"
	@echo "  - Use 'make safe-rebuild' instead of direct nixos-rebuild"
	@echo "  - Use 'make dev' to start development"
	@echo "  - Use 'make test' before committing changes"
	@echo "  - Use 'make format' to ensure consistent code style"
	@echo "  - Use 'make fmt' to format all code with treefmt"
	@echo "  - Use 'make code-quality' to check code quality"
	@echo "  - Use 'make analyze-sizes' to see performance tradeoffs"
	@echo "  - Use 'make size-dashboard' for interactive size analysis"
	@echo "  - Use 'make cache-optimize' for faster builds"
	@echo "  - Use 'make sbom' for compliance documentation"
	@echo "  - Use 'make clean-all' if you encounter build issues"
	@echo "  - Use 'make setup' for interactive configuration"
	@echo "  - Use 'make health-check' to validate system health"
	@echo "  - Use 'make gaming-setup' to configure gaming workstation"
	@echo "  - Use 'make gaming-test' to test gaming configuration"
	@echo "  - Use 'make security-check' to validate security configuration"
	@echo "  - Use 'make remote-builder-setup' to set up remote builder"
	@echo "  - Use 'make test-remote-builder' to test remote builder"

# Setup and health check targets
setup:
	@echo "🔧 Starting nix-mox Configuration Setup..."
	$(NUSHELL) scripts/setup/unified-setup.nu

health-check:
	@echo "🏥 Running nix-mox Health Check..."
	$(NUSHELL) scripts/maintenance/health-check.nu

setup-gaming:
	$(NUSHELL) scripts/setup/unified-setup.nu

gaming-workstation:
gaming-setup:
	@echo "🎮 Setting up Gaming Workstation..."
	$(NUSHELL) scripts/setup/unified-setup.nu

gaming-workstation-dev:
	@echo "🎮 Setting up Development + Gaming Workstation..."
	$(NUSHELL) scripts/setup/unified-setup.nu

gaming-workstation-interactive:
	@echo "🎮 Interactive Gaming Workstation Setup..."
	$(NUSHELL) scripts/setup/unified-setup.nu

gaming-benchmark: check-nushell
	@echo "🎮 Running Gaming Performance Benchmark..."
	$(NUSHELL) scripts/benchmarks/gaming-benchmark.nu

validate-gaming: check-nushell
	@echo "🎮 Validating Gaming Configuration..."
	$(NUSHELL) scripts/validation/validate-gaming-config.nu

test-gaming: validate-gaming

validate-display: check-nushell
	@echo "🖥️  Testing Display Configuration..."
	$(NUSHELL) scripts/validation/validate-display-config.nu

validate-display-interactive: check-nushell
	@echo "🖥️  Interactive Display Configuration Testing..."
	$(NUSHELL) scripts/validation/validate-display-config.nu --interactive

validate-display-backup: check-nushell
	@echo "🖥️  Testing Display Configuration with Backup..."
	$(NUSHELL) scripts/validation/validate-display-config.nu --backup

validate-display-verbose: check-nushell
	@echo "🖥️  Verbose Display Configuration Testing..."
	$(NUSHELL) scripts/validation/validate-display-config.nu --verbose

validate-display-full: check-nushell
	@echo "🖥️  Comprehensive Display Configuration Testing..."
	$(NUSHELL) scripts/validation/validate-display-config.nu --full

# Code quality targets
code-quality: check-nushell
	@echo "🔍 Running comprehensive code quality analysis..."
	$(NUSHELL) scripts/quality/code-quality.nu

code-syntax: check-nushell
	@echo "🔍 Checking code syntax..."
	$(NUSHELL) scripts/quality/code-quality.nu --syntax-only

code-security: check-nushell
	@echo "🔍 Checking for security issues..."
	$(NUSHELL) scripts/quality/code-quality.nu --security-only

quality: code-quality

performance-optimize: check-nushell
	@echo "⚡ Running performance optimization analysis..."
	$(NUSHELL) scripts/quality/performance-optimize.nu

pre-commit: check-nushell
	@echo "🔍 Running pre-commit checks..."
	$(NUSHELL) scripts/ci/pre-commit.nu

# New flake-based targets
fmt:
	@echo "🎨 Formatting code with treefmt..."
	$(NIX) run .#fmt

test-flake:
	@echo "🧪 Running tests with flake..."
	$(NIX) run .#test

update-flake:
	@echo "🔄 Updating flake inputs..."
	$(NIX) run .#update

check-flake:
	@echo "✅ Running flake check..."
	$(NIX) flake check

build-packages:
	@echo "📦 Building all packages..."
	$(NIX) build .#proxmox-update .#vzdump-backup .#zfs-snapshot .#nixos-flake-update

security-check:
	@echo "🔒 Validating security module configuration..."
	@echo "✅ Checking security module syntax..."
	$(NIX) eval --impure --expr 'with import <nixpkgs> {}; callPackage ./modules/security/index.nix {}' > /dev/null
	@echo "✅ Security module validation passed!"
	@echo "💡 Security features available:"
	@echo "  - fail2ban: Intrusion prevention"
	@echo "  - ufw: Firewall management"
	@echo "  - ssl: SSL/TLS security"
	@echo "  - apparmor: Application security"
	@echo "  - audit: System auditing"
	@echo "  - selinux: Advanced access control"
	@echo "  - kernel: Kernel security features"
	@echo "  - network: Network hardening"
	@echo "  - filesystem: File system security"
	@echo "  - users: User security policies"

# Add this at the top, after variable definitions
check-nushell:
	@command -v $(NUSHELL) >/dev/null 2>&1 || { \
		echo >&2 "❌ Nushell (nu) is not installed or not in your PATH."; \
		echo >&2 "💡 Run 'nix develop' to enter the dev shell, or install Nushell globally."; \
		exit 127; \
	}

# Testing targets
test: check-nushell $(TEST_DIR)
	@echo "🧪 Running all tests..."
	$(NUSHELL) -c "source scripts/testing/run-tests.nu; run []"

test-unit: check-nushell $(TEST_DIR)
	@echo "🧪 Running unit tests..."
	$(NUSHELL) scripts/testing/unit/unit-tests.nu

test-integration: check-nushell $(TEST_DIR)
	@echo "🧪 Running integration tests..."
	$(NUSHELL) scripts/testing/integration/integration-tests.nu

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
	./scripts/analysis/analyze-sizes.sh

# Size analysis dashboard
size-dashboard: check-nushell
	@echo "📊 Generating size analysis dashboard..."
	$(NUSHELL) -c "source scripts/analysis/size-dashboard.nu; run"

size-dashboard-html: check-nushell
	@echo "📊 Generating HTML dashboard..."
	$(NUSHELL) -c "source scripts/analysis/size-dashboard.nu; generate-html"

size-dashboard-api: check-nushell
	@echo "📊 Generating JSON API..."
	$(NUSHELL) -c "source scripts/analysis/size-dashboard.nu; generate-api"

# Advanced caching
cache-optimize: check-nushell
	@echo "🔄 Running advanced caching optimization..."
	$(NUSHELL) -c "source scripts/analysis/advanced-cache.nu; run"

cache-warm: check-nushell
	@echo "🔥 Warming cache..."
	$(NUSHELL) -c "source scripts/analysis/advanced-cache.nu; warm"

cache-maintain: check-nushell
	@echo "🔧 Maintaining cache..."
	$(NUSHELL) -c "source scripts/analysis/advanced-cache.nu; maintain"

# SBOM generation
sbom: check-nushell
	@echo "📋 Generating Software Bill of Materials..."
	$(NUSHELL) -c "source scripts/analysis/generate-sbom.nu; run"

sbom-spdx: check-nushell
	@echo "📋 Generating SPDX format SBOM..."
	$(NUSHELL) -c "source scripts/analysis/generate-sbom.nu; generate_spdx_sbom"

sbom-cyclonedx: check-nushell
	@echo "📋 Generating CycloneDX format SBOM..."
	$(NUSHELL) -c "source scripts/analysis/generate-sbom.nu; generate_cyclonedx_sbom"

sbom-csv: check-nushell
	@echo "📋 Generating CSV format SBOM..."
	$(NUSHELL) -c "source scripts/analysis/generate-sbom.nu; generate_csv_report"

# CI/CD targets
ci-test:
	@echo "🔄 Running quick CI test..."
	./scripts/maintenance/ci/ci-test.sh

ci-local:
	@echo "🔄 Running comprehensive CI test..."
	./scripts/maintenance/ci/test-ci-local.sh

# Remote builder targets
remote-builder-setup:
	@echo "🔧 Setting up remote builder..."
	./scripts/setup/setup-remote-builder.sh

test-remote-builder:
	@echo "🔧 Testing remote builder..."
	./scripts/setup/test-remote-builder.sh

# Maintenance targets
clean-all: clean
	@echo "🧹 Cleaning all artifacts..."
	rm -rf tmp/
	rm -rf result/
	rm -rf sbom/
	rm -f size-dashboard.html
	rm -f size-api.json
	rm -f cache-report.json
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
	@echo "  - development (full development tools)"
	@echo "  - testing (testing and CI tools)"
	@echo "  - services (service deployment tools)"
	@echo "  - monitoring (monitoring and observability)"
	@echo "  - gaming (gaming tools - Linux x86_64 only)"
	@echo "  - zfs (ZFS management tools - Linux only)"
	@echo "  - macos (macOS development - macOS only)"

# Performance optimization targets
performance-analyze: check-nushell
	@echo "📊 Analyzing performance..."
	$(NUSHELL) -c "source scripts/validation/performance-optimize.nu; analyze"

performance-optimize: check-nushell
	@echo "⚡ Optimizing performance..."
	$(NUSHELL) -c "source scripts/validation/performance-optimize.nu; optimize"

performance-report: check-nushell
	@echo "📋 Generating performance report..."
	$(NUSHELL) -c "source scripts/validation/performance-optimize.nu; report"

# Quick performance check
perf: performance-report

# Coverage targets
coverage: check-nushell
	@echo "📊 Setting up coverage..."
	$(NUSHELL) scripts/testing/generate-coverage.nu --approach lcov --verbose

coverage-grcov: check-nushell
	@echo "📊 Setting up grcov coverage..."
	$(NUSHELL) scripts/testing/generate-coverage.nu --approach grcov --verbose

coverage-tarpaulin: check-nushell
	@echo "📊 Setting up tarpaulin coverage..."
	$(NUSHELL) scripts/testing/generate-coverage.nu --approach tarpaulin --verbose

coverage-custom: check-nushell
	@echo "📊 Setting up custom coverage..."
	$(NUSHELL) scripts/testing/generate-coverage.nu --approach custom --verbose

coverage-ci: check-nushell
	@echo "📊 Setting up coverage for CI..."
	$(NUSHELL) -c "source scripts/testing/generate-coverage.nu; ci_setup_coverage"

coverage-local: check-nushell
	@echo "📊 Setting up coverage for local development..."
	$(NUSHELL) -c "source scripts/testing/generate-coverage.nu; local_setup_coverage"

# Bootstrap and safety targets
bootstrap-check:
	@echo "🔍 Checking bootstrap requirements..."
	@echo "✓ Git: $$(command -v git >/dev/null 2>&1 && echo "installed" || echo "❌ MISSING - install with: nix-shell -p git")"
	@echo "✓ Nushell: $$(command -v nu >/dev/null 2>&1 && echo "installed" || echo "❌ MISSING - install with: nix-shell -p nushell")"
	@echo "✓ NixOS: $$(test -d /etc/nixos -o -f /etc/NIXOS && echo "detected" || echo "❌ NOT DETECTED - this script requires NixOS")"
	@echo "✓ User in wheel group: $$(groups | grep -q wheel && echo "yes" || echo "❌ NO - add user to wheel group for sudo access")"
	@echo ""
	@echo "💡 If any checks failed, install missing components before proceeding"

safety-check: check-nushell
	@echo "🛡️  Running mandatory safety validation..."
	$(NUSHELL) scripts/validation/pre-rebuild-safety-check.nu --verbose

safe-test: check-nushell
	@echo "🧪 Running comprehensive flake testing..."
	$(NUSHELL) scripts/validation/safe-flake-test.nu --test-minimal --backup-current --verbose

safe-rebuild: check-nushell
	@echo "🚀 Running safe nixos-rebuild with validation..."
	$(NUSHELL) scripts/maintenance/safe-rebuild.nu --backup --test-first --verbose

# Storage safety targets
storage-guard: check-nushell
	@echo "🔍 Validating storage configuration..."
	nix run .#storage-guard

fix-storage: check-nushell
	@echo "🔧 Auto-fixing storage configuration issues..."
	nix run .#fix-storage
