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

# Display testing targets - DRY pattern
display-test: check-nushell
	@echo "🧪 Testing display configuration..."
	$(NUSHELL) scripts/testing/display/display-tests.nu --verbose

# Parameterized display test runner
display-test-%: check-nushell
	@echo "🧪 Display testing ($*)..."
	$(NUSHELL) scripts/testing/display/display-tests.nu --mode $* --verbose

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

# Hardware EMI Detection targets
emi-check: check-nushell
	@echo "🔍 Running EMI detection check..."
	$(NUSHELL) scripts/testing/hardware/emi-detection.nu

emi-report: check-nushell
	@echo "📊 Generating comprehensive EMI detection report..."
	$(NUSHELL) scripts/testing/hardware/emi-detection.nu --report

emi-monitor: check-nushell
	@echo "👁️ Monitoring for EMI patterns (5 min)..."
	$(NUSHELL) scripts/testing/hardware/emi-detection.nu --monitor 5min

emi-stress: check-nushell
	@echo "⚡ Running EMI stress test..."
	$(NUSHELL) scripts/testing/hardware/emi-detection.nu --stress-test

emi-watch: check-nushell
	@echo "📺 Starting EMI watch mode (Ctrl+C to stop)..."
	$(NUSHELL) scripts/testing/hardware/emi-detection.nu --watch 10 