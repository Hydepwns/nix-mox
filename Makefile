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
        ci-test ci-local update lock clean-all packages shells analyze-sizes \
        setup-wizard health-check security-check sbom cache-optimize size-dashboard \
        remote-builder-setup test-remote-builder performance-analyze performance-optimize performance-report perf \
        code-quality code-syntax code-security quality

# Default target - show help
help:
	@echo "nix-mox Development Commands"
	@echo "============================"
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  dev         - Enter development shell"
	@echo "  build       - Build default package"
	@echo "  test        - Run all tests"
	@echo "  setup-wizard - Interactive configuration setup"
	@echo "  health-check - System health validation"
	@echo "  gaming-setup - Setup gaming workstation"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  test        - Run all tests (unit + integration)"
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
	@echo "💡 Tips:"
	@echo "  - Use 'make dev' to start development"
	@echo "  - Use 'make test' before committing changes"
	@echo "  - Use 'make format' to ensure consistent code style"
	@echo "  - Use 'make analyze-sizes' to see performance tradeoffs"
	@echo "  - Use 'make size-dashboard' for interactive size analysis"
	@echo "  - Use 'make cache-optimize' for faster builds"
	@echo "  - Use 'make sbom' for compliance documentation"
	@echo "  - Use 'make clean-all' if you encounter build issues"
	@echo "  - Use 'make setup-wizard' for interactive configuration"
	@echo "  - Use 'make health-check' to validate system health"
	@echo "  - Use 'make gaming-setup' to configure gaming workstation"
	@echo "  - Use 'make gaming-test' to test gaming configuration"
	@echo "  - Use 'make security-check' to validate security configuration"
	@echo "  - Use 'make remote-builder-setup' to set up remote builder"
	@echo "  - Use 'make test-remote-builder' to test remote builder"

# Setup and health check targets
setup-wizard:
	@echo "🔧 Starting nix-mox Configuration Wizard..."
	$(NUSHELL) scripts/setup-wizard.nu

health-check:
	@echo "🏥 Running nix-mox Health Check..."
	$(NUSHELL) scripts/health-check.nu

gaming-setup:
	@echo "🎮 Setting up Gaming Workstation..."
	$(NUSHELL) scripts/setup-gaming-workstation.nu

gaming-wizard:
	@echo "🎮 Interactive Gaming Setup Wizard..."
	$(NUSHELL) scripts/setup-gaming-wizard.nu

gaming-benchmark:
	@echo "🎮 Running Gaming Performance Benchmark..."
	$(NUSHELL) scripts/gaming-benchmark.nu

gaming-validate:
	@echo "🎮 Validating Gaming Configuration..."
	$(NUSHELL) scripts/validate-gaming-config.nu

gaming-test:
	@echo "🎮 Testing Gaming Setup..."
	./devshells/gaming/scripts/test-gaming.sh

display-test:
	@echo "🖥️  Testing Display Configuration..."
	$(NUSHELL) scripts/validate-display-config.nu

display-test-interactive:
	@echo "🖥️  Interactive Display Configuration Testing..."
	$(NUSHELL) scripts/validate-display-config.nu --interactive

display-test-backup:
	@echo "🖥️  Testing Display Configuration with Backup..."
	$(NUSHELL) scripts/validate-display-config.nu --backup

display-test-verbose:
	@echo "🖥️  Verbose Display Configuration Testing..."
	$(NUSHELL) scripts/validate-display-config.nu --verbose

display-test-all:
	@echo "🖥️  Comprehensive Display Configuration Testing..."
	$(NUSHELL) scripts/validate-display-config.nu --backup --verbose --interactive

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
	$(NUSHELL) -c "source scripts/tests/run-tests.nu; run []"

unit: check-nushell $(TEST_DIR)
	@echo "🧪 Running unit tests..."
	$(NUSHELL) scripts/tests/unit/unit-tests.nu

integration: check-nushell $(TEST_DIR)
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

# Size analysis dashboard
size-dashboard: check-nushell
	@echo "📊 Generating size analysis dashboard..."
	$(NUSHELL) -c "source scripts/size-dashboard.nu; run"

size-dashboard-html: check-nushell
	@echo "📊 Generating HTML dashboard..."
	$(NUSHELL) -c "source scripts/size-dashboard.nu; generate-html"

size-dashboard-api: check-nushell
	@echo "📊 Generating JSON API..."
	$(NUSHELL) -c "source scripts/size-dashboard.nu; generate-api"

# Advanced caching
cache-optimize: check-nushell
	@echo "🔄 Running advanced caching optimization..."
	$(NUSHELL) -c "source scripts/advanced-cache.nu; run"

cache-warm: check-nushell
	@echo "🔥 Warming cache..."
	$(NUSHELL) -c "source scripts/advanced-cache.nu; warm"

cache-maintain: check-nushell
	@echo "🔧 Maintaining cache..."
	$(NUSHELL) -c "source scripts/advanced-cache.nu; maintain"

# SBOM generation
sbom: check-nushell
	@echo "📋 Generating Software Bill of Materials..."
	$(NUSHELL) -c "source scripts/generate-sbom.nu; run"

sbom-spdx: check-nushell
	@echo "📋 Generating SPDX format SBOM..."
	$(NUSHELL) -c "source scripts/generate-sbom.nu; generate_spdx_sbom"

sbom-cyclonedx: check-nushell
	@echo "📋 Generating CycloneDX format SBOM..."
	$(NUSHELL) -c "source scripts/generate-sbom.nu; generate_cyclonedx_sbom"

sbom-csv: check-nushell
	@echo "📋 Generating CSV format SBOM..."
	$(NUSHELL) -c "source scripts/generate-sbom.nu; generate_csv_report"

# CI/CD targets
ci-test:
	@echo "🔄 Running quick CI test..."
	./scripts/ci-test.sh

ci-local:
	@echo "🔄 Running comprehensive CI test..."
	./scripts/test-ci-local.sh

# Remote builder targets
remote-builder-setup:
	@echo "🔧 Setting up remote builder..."
	./scripts/setup-remote-builder.sh

test-remote-builder:
	@echo "🔧 Testing remote builder..."
	./scripts/test-remote-builder.sh

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
	$(NUSHELL) -c "source scripts/performance-optimize.nu; analyze"

performance-optimize: check-nushell
	@echo "⚡ Optimizing performance..."
	$(NUSHELL) -c "source scripts/performance-optimize.nu; optimize"

performance-report: check-nushell
	@echo "📋 Generating performance report..."
	$(NUSHELL) -c "source scripts/performance-optimize.nu; report"

# Quick performance check
perf: performance-report

# Code quality targets
code-quality: check-nushell
	@echo "🔍 Analyzing code quality..."
	$(NUSHELL) -c "source scripts/code-quality.nu; analyze"

code-syntax: check-nushell
	@echo "✅ Checking syntax..."
	$(NUSHELL) -c "source scripts/code-quality.nu; check-syntax"

code-security: check-nushell
	@echo "🔒 Checking security..."
	$(NUSHELL) -c "source scripts/code-quality.nu; check-security"

# Quick code quality check
quality: code-quality

# Coverage targets
coverage: check-nushell
	@echo "📊 Setting up coverage..."
	$(NUSHELL) scripts/tests/setup-coverage.nu --approach lcov --verbose

coverage-grcov: check-nushell
	@echo "📊 Setting up grcov coverage..."
	$(NUSHELL) scripts/tests/setup-coverage.nu --approach grcov --verbose

coverage-tarpaulin: check-nushell
	@echo "📊 Setting up tarpaulin coverage..."
	$(NUSHELL) scripts/tests/setup-coverage.nu --approach tarpaulin --verbose

coverage-custom: check-nushell
	@echo "📊 Setting up custom coverage..."
	$(NUSHELL) scripts/tests/setup-coverage.nu --approach custom --verbose

coverage-ci: check-nushell
	@echo "📊 Setting up coverage for CI..."
	$(NUSHELL) -c "source scripts/tests/setup-coverage.nu; ci_setup_coverage"

coverage-local: check-nushell
	@echo "📊 Setting up coverage for local development..."
	$(NUSHELL) -c "source scripts/tests/setup-coverage.nu; local_setup_coverage"
