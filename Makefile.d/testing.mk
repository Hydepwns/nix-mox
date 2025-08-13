# Testing-related Makefile targets
# Include this file in the main Makefile

# Testing targets
test: check-nushell
	@echo "🧪 Running all tests..."
	$(NUSHELL) scripts/testing/run-tests.nu --all --verbose

test-unit: check-nushell
	@echo "🧪 Running unit tests..."
	$(NUSHELL) scripts/testing/run-tests.nu --unit --verbose

test-integration: check-nushell
	@echo "🧪 Running integration tests..."
	$(NUSHELL) scripts/testing/run-tests.nu --integration --verbose

test-flake: check-nushell
	@echo "🧪 Running flake tests..."
	$(NUSHELL) scripts/testing/run-tests.nu --flake --verbose

test-gaming: check-nushell
	@echo "🧪 Running gaming tests..."
	$(NUSHELL) scripts/testing/run-tests.nu --gaming --verbose

# Display testing targets
display-test: check-nushell
	@echo "🧪 Testing display configuration..."
	$(NUSHELL) scripts/validation/validate-display-config.nu --test --verbose

display-test-interactive: check-nushell
	@echo "🧪 Interactive display testing..."
	$(NUSHELL) scripts/validation/validate-display-config.nu --test --interactive --verbose

display-test-backup: check-nushell
	@echo "🧪 Display testing with backup..."
	$(NUSHELL) scripts/validation/validate-display-config.nu --test --backup --verbose

display-test-verbose: check-nushell
	@echo "🧪 Verbose display testing..."
	$(NUSHELL) scripts/validation/validate-display-config.nu --test --verbose --full

display-test-all: check-nushell
	@echo "🧪 Comprehensive display testing..."
	$(NUSHELL) scripts/validation/validate-display-config.nu --test --all --verbose

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