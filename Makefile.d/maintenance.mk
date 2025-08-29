# Maintenance and safety Makefile targets
# Include this file in the main Makefile

# Maintenance targets
health-check: check-nushell
	@echo "🏥 Running system health check..."
	$(NUSHELL) scripts/maintenance/health-check.nu

cleanup: check-nushell
	@echo "🧹 Running cleanup..."
	$(NUSHELL) scripts/maintenance/cleanup.nu --verbose

safe-rebuild: check-nushell
	@echo "🚀 Running safe nixos-rebuild with validation..."
	$(NUSHELL) scripts/maintenance/safe-rebuild.nu --backup --test-first --verbose

# Safety targets
safety-check: check-nushell
	@echo "🛡️  Running mandatory safety validation..."
	$(NUSHELL) scripts/validation/pre-rebuild-safety-check.nu --verbose

display-check: check-nushell
	@echo "🖥️  Validating display manager configuration..."
	$(NUSHELL) scripts/validation/validate-display-safety.nu

pre-rebuild: check-nushell
	@echo "🔍 Running comprehensive pre-rebuild checks..."
	$(NUSHELL) scripts/validation/pre-rebuild-comprehensive-check.nu --verbose

safe-test: check-nushell
	@echo "🧪 Running comprehensive flake testing..."
	$(NUSHELL) scripts/validation/safe-flake-test.nu --test-minimal --backup-current --verbose

# Storage safety targets (main storage-guard target is in development.mk)

fix-storage: check-nushell
	@echo "🔧 Auto-fixing storage configuration issues..."
	nix run .#fix-storage

# Bootstrap and validation targets
bootstrap-check:
	@echo "🔍 Checking bootstrap requirements..."
	@echo "✓ Git: $$(command -v git >/dev/null 2>&1 && echo "installed" || echo "❌ MISSING - install with: nix-shell -p git")"
	@echo "✓ Nushell: $$(command -v nu >/dev/null 2>&1 && echo "installed" || echo "❌ MISSING - install with: nix-shell -p nushell")"
	@echo "✓ NixOS: $$(test -d /etc/nixos -o -f /etc/NIXOS && echo "detected" || echo "❌ NOT DETECTED - this script requires NixOS")"
	@echo "✓ User in wheel group: $$(groups | grep -q wheel && echo "yes" || echo "❌ NO - add user to wheel group for sudo access")"
	@echo ""
	@echo "💡 If any checks failed, install missing components before proceeding"

# Clean targets
clean: check-nushell
	@echo "🧹 Cleaning test artifacts..."
	rm -rf $(TEST_DIR)
	rm -rf $(TEST_TEMP_DIR)
	@echo "✅ Test artifacts cleaned!"

clean-all: check-nushell
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