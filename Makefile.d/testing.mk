# Testing-related Makefile targets
# Include this file in the main Makefile

# Testing targets
test: check-nushell
	@echo "🧪 Running all tests..."
	$(NUSHELL) scripts/test.nu all --verbose

test-unit: check-nushell
	@echo "🧪 Running unit tests..."
	$(NUSHELL) scripts/test.nu unit --verbose

test-integration: check-nushell
	@echo "🧪 Running integration tests..."
	$(NUSHELL) scripts/test.nu integration --verbose

test-flake: check-nushell
	@echo "🧪 Running flake tests..."
	$(NUSHELL) scripts/test.nu flake --verbose

test-gaming: check-nushell
	@echo "🧪 Running gaming tests..."
	$(NUSHELL) scripts/test.nu gaming --verbose

# Display testing targets
display-test: check-nushell
	@echo "🧪 Testing display configuration..."
	$(NUSHELL) -c "source scripts/validation/validate-display-config.nu; main"

display-test-interactive: check-nushell
	@echo "🧪 Interactive display testing..."
	$(NUSHELL) -c "source scripts/validation/validate-display-config.nu; main"

display-test-backup: check-nushell
	@echo "🧪 Display testing with backup..."
	$(NUSHELL) -c "source scripts/validation/validate-display-config.nu; main"

display-test-verbose: check-nushell
	@echo "🧪 Verbose display testing..."
	$(NUSHELL) -c "source scripts/validation/validate-display-config.nu; main"

display-test-all: check-nushell
	@echo "🧪 Comprehensive display testing..."
	$(NUSHELL) -c "source scripts/validation/validate-display-config.nu; main"

# Coverage targets (main coverage target is in development.mk)

coverage-grcov: check-nushell
	@echo "📊 Setting up grcov coverage..."
	$(NUSHELL) scripts/coverage.nu generate --approach grcov --verbose

coverage-tarpaulin: check-nushell
	@echo "📊 Setting up tarpaulin coverage..."
	$(NUSHELL) scripts/coverage.nu generate --approach tarpaulin --verbose

coverage-custom: check-nushell
	@echo "📊 Setting up custom coverage..."
	$(NUSHELL) scripts/coverage.nu generate --approach custom --verbose

coverage-ci: check-nushell
	@echo "📊 Setting up coverage for CI..."
	$(NUSHELL) scripts/coverage.nu generate --output-dir ./coverage-report --ci

coverage-local: check-nushell
	@echo "📊 Setting up coverage for local development..."
	$(NUSHELL) scripts/coverage.nu generate --output-dir ./coverage-report 