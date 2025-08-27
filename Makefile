# nix-mox Development Makefile
# ============================
# This Makefile provides convenient commands for development, testing, and maintenance

# Variables
TEST_DIR = coverage-tmp/nix-mox-tests
TEST_TEMP_DIR = coverage-tmp
NUSHELL = nu
NIX = nix

# Available packages (from flake.nix)
PACKAGES = backup-system

# Include modular Makefile components
include Makefile.d/testing.mk
include Makefile.d/development.mk
include Makefile.d/analysis.mk
include Makefile.d/maintenance.mk

# Phony targets
.PHONY: help check-nushell ci-test ci-local

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
	@echo "  display-troubleshoot - Diagnose KDE/NVIDIA display issues"
	@echo "  display-fix - Apply automatic display fixes"
	@echo "  emergency-display-recovery - Emergency display recovery"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  test        - Run all tests (unit + integration)"
	@echo "  test-flake  - Run tests with flake"
	@echo "  unit        - Run unit tests only"
	@echo "  integration - Run integration tests only"
	@echo "  gaming-test - Test gaming setup"
	@echo "  display-test - Test display configuration"
	@echo "  clean       - Clean up test artifacts"
	@echo ""
	@echo "🔧 Development:"
	@echo "  format      - Format Nix files with nixpkgs-fmt"
	@echo "  fmt         - Format all code with treefmt"
	@echo "  check       - Run nix flake check"
	@echo "  build       - Build default package"
	@echo "  build-all   - Build all packages"
	@echo "  update      - Update flake inputs"
	@echo "  lock        - Update flake.lock"
	@echo "  build-zed-extension - Build Zed extension for nix-mox"
	@echo "  install-synthwave84-zed - Install/update Synthwave84 theme for Zed"
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
	@echo "📊 Analysis & Dashboards:"
	@echo "  dashboard       - Interactive system dashboard (default: overview)"
	@echo "  dashboard-system - Detailed system information dashboard"
	@echo "  dashboard-performance - Performance metrics dashboard"
	@echo "  dashboard-gaming - Gaming system dashboard"
	@echo "  analyze-sizes - Analyze size of packages, devshells, and templates"
	@echo "  cache-optimize - Run advanced caching strategy with optimization"
	@echo "  performance-analyze - Comprehensive performance analysis"
	@echo "  code-quality - Comprehensive code quality analysis"
	@echo "  quality - Quick code quality check"
	@echo ""
	@echo "📊 Coverage & Testing:"
	@echo "  coverage - Generate LCOV coverage report"
	@echo "  coverage-all - Generate all coverage formats (LCOV, HTML, JSON, XML)"
	@echo "  coverage-html - Generate HTML coverage report"
	@echo "  coverage-watch - Real-time coverage monitoring"
	@echo ""
	@echo "🔒 Compliance & Security:"
	@echo "  security-check - Validate security module configuration"
	@echo "  sbom         - Generate Software Bill of Materials (SPDX, CycloneDX, CSV)"
	@echo ""
	@echo "🔄 CI/CD:"
	@echo "  ci-test     - Run quick CI test locally"
	@echo "  ci-local    - Run local CI pipeline"
	@echo ""
	@echo "🛡️  Safety & Validation:"
	@echo "  validate        - Run validation suite (default: basic)"
	@echo "  validate-config - Validate NixOS configuration"
	@echo "  validate-gaming - Validate gaming setup"
	@echo "  validate-storage - Validate storage safety"
	@echo "  validate-pre-rebuild - Comprehensive pre-rebuild validation"
	@echo "  safety-check - Run mandatory safety validation"
	@echo "  safe-rebuild - Run safe nixos-rebuild with validation"
	@echo "  storage-guard - Validate storage configuration"
	@echo "  storage-fix - Fix storage configuration issues"
	@echo "  storage-health - Comprehensive storage health check"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  clean       - Clean test artifacts"
	@echo "  clean-all   - Clean all artifacts and garbage collect"
	@echo ""
	@echo "📋 Information:"
	@echo "  packages    - Show available packages"
	@echo "  shells      - Show available development shells"
	@echo ""
	@echo "For full details, run: nix flake show"

# Check if nushell is available
check-nushell:
	@if ! command -v $(NUSHELL) >/dev/null 2>&1; then \
		echo "❌ Nushell is not installed. Please install it first:"; \
		echo "   nix-shell -p nushell"; \
		exit 1; \
	fi

# CI targets
ci-test: check-nushell
	@echo "🚀 Running quick CI test..."
	$(NUSHELL) scripts/maintenance/ci/ci-test.nu

ci-local: check-nushell
	@echo "🚀 Running local CI pipeline..."
	$(NUSHELL) scripts/maintenance/ci/ci-local.sh

# Setup targets
setup: check-nushell
	@echo "🔧 Running interactive setup..."
	$(NUSHELL) scripts/setup.nu interactive

gaming-setup: check-nushell
	@echo "🎮 Setting up gaming workstation..."
	$(NUSHELL) scripts/setup.nu gaming

automated-setup: check-nushell
	@echo "⚡ Running automated setup..."
	$(NUSHELL) scripts/setup.nu automated

minimal-setup: check-nushell
	@echo "📦 Running minimal setup..."
	$(NUSHELL) scripts/setup.nu minimal

# SBOM targets
sbom: check-nushell
	@echo "📋 Generating Software Bill of Materials..."
	$(NUSHELL) scripts/analysis/generate-sbom.nu --all

sbom-spdx: check-nushell
	@echo "📋 Generating SPDX SBOM..."
	$(NUSHELL) scripts/analysis/generate-sbom.nu --spdx

sbom-cyclonedx: check-nushell
	@echo "📋 Generating CycloneDX SBOM..."
	$(NUSHELL) scripts/analysis/generate-sbom.nu --cyclonedx

sbom-csv: check-nushell
	@echo "📋 Generating CSV SBOM..."
	$(NUSHELL) scripts/analysis/generate-sbom.nu --csv

# Chezmoi integration targets
chezmoi-apply: ## Apply chezmoi configuration
	@echo "🔄 Applying chezmoi configuration..."
	@nu scripts/chezmoi.nu apply

chezmoi-diff: ## Show chezmoi differences
	@echo "🔍 Checking chezmoi differences..."
	@nu scripts/chezmoi.nu diff

chezmoi-sync: ## Sync chezmoi with remote repository
	@echo "📡 Syncing chezmoi with remote repository..."
	@nu scripts/chezmoi.nu sync

chezmoi-edit: ## Edit chezmoi configuration
	@echo "✏️  Opening chezmoi configuration for editing..."
	@nu scripts/chezmoi.nu edit

chezmoi-status: ## Show chezmoi status
	@echo "📊 Showing chezmoi status..."
	@nu scripts/chezmoi.nu status

chezmoi-verify: ## Verify chezmoi configuration
	@echo "✅ Verifying chezmoi configuration..."
	@nu scripts/chezmoi.nu verify

chezmoi-setup: ## Complete chezmoi setup and integration
	@echo "🔗 Setting up chezmoi integration..."
	@nu scripts/setup/chezmoi-integration.nu
