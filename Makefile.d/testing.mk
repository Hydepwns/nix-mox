# Testing-related Makefile targets
# Include this file in the main Makefile

# Testing targets
test: check-nushell
	@echo "🧪 Running all tests..."
	$(NUSHELL) -c "source scripts/testing/run-tests.nu; run ['--verbose']"

test-unit: check-nushell
	@echo "🧪 Running unit tests..."
	$(NUSHELL) -c "source scripts/testing/run-tests.nu; run ['--unit', '--verbose']"

test-integration: check-nushell
	@echo "🧪 Running integration tests..."
	$(NUSHELL) -c "source scripts/testing/run-tests.nu; run ['--integration', '--verbose']"

test-flake: check-nushell
	@echo "🧪 Running flake tests..."
	$(NUSHELL) -c "source scripts/testing/run-tests.nu; run ['--flake', '--verbose']"

test-gaming: check-nushell
	@echo "🧪 Running gaming tests..."
	$(NUSHELL) -c "source scripts/testing/run-tests.nu; run ['--gaming', '--verbose']"

# Display testing targets
display-test: check-nushell
	@echo "🧪 Testing display configuration..."
	$(NUSHELL) -c "source scripts/validation/validate-display-config.nu; run ['--test', '--verbose']"

display-test-interactive: check-nushell
	@echo "🧪 Interactive display testing..."
	$(NUSHELL) -c "source scripts/validation/validate-display-config.nu; run ['--test', '--interactive', '--verbose']"

display-test-backup: check-nushell
	@echo "🧪 Display testing with backup..."
	$(NUSHELL) -c "source scripts/validation/validate-display-config.nu; run ['--test', '--backup', '--verbose']"

display-test-verbose: check-nushell
	@echo "🧪 Verbose display testing..."
	$(NUSHELL) -c "source scripts/validation/validate-display-config.nu; run ['--test', '--verbose', '--full']"

display-test-all: check-nushell
	@echo "🧪 Comprehensive display testing..."
	$(NUSHELL) -c "source scripts/validation/validate-display-config.nu; run ['--test', '--all', '--verbose']"

# Coverage targets
coverage: check-nushell
	@echo "📊 Setting up coverage..."
	$(NUSHELL) -c "source scripts/testing/generate-coverage.nu; run ['--approach', 'lcov', '--verbose']"

coverage-grcov: check-nushell
	@echo "📊 Setting up grcov coverage..."
	$(NUSHELL) -c "source scripts/testing/generate-coverage.nu; run ['--approach', 'grcov', '--verbose']"

coverage-tarpaulin: check-nushell
	@echo "📊 Setting up tarpaulin coverage..."
	$(NUSHELL) -c "source scripts/testing/generate-coverage.nu; run ['--approach', 'tarpaulin', '--verbose']"

coverage-custom: check-nushell
	@echo "📊 Setting up custom coverage..."
	$(NUSHELL) -c "source scripts/testing/generate-coverage.nu; run ['--approach', 'custom', '--verbose']"

coverage-ci: check-nushell
	@echo "📊 Setting up coverage for CI..."
	$(NUSHELL) -c "source scripts/testing/generate-coverage.nu; run ['ci_setup_coverage']"

coverage-local: check-nushell
	@echo "📊 Setting up coverage for local development..."
	$(NUSHELL) -c "source scripts/testing/generate-coverage.nu; run ['local_setup_coverage']" 