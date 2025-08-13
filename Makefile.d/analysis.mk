# Analysis and reporting Makefile targets
# Include this file in the main Makefile

# Analysis targets
analyze-sizes: check-nushell
	@echo "📊 Analyzing package sizes..."
	$(NUSHELL) scripts/analysis/analyze-sizes.nu --verbose

size-dashboard: check-nushell
	@echo "📊 Generating size dashboard..."
	$(NUSHELL) scripts/analysis/size-dashboard.nu --serve

size-dashboard-html: check-nushell
	@echo "📊 Generating HTML size dashboard..."
	$(NUSHELL) scripts/analysis/size-dashboard.nu --html

size-dashboard-api: check-nushell
	@echo "📊 Generating API size dashboard..."
	$(NUSHELL) scripts/analysis/size-dashboard.nu --api

# Performance analysis targets
performance-analyze: check-nushell
	@echo "📊 Analyzing performance..."
	$(NUSHELL) -c "source scripts/validation/performance-optimize.nu; analyze"

performance-optimize: check-nushell
	@echo "⚡ Optimizing performance..."
	$(NUSHELL) -c "source scripts/validation/performance-optimize.nu; optimize"

performance-report: check-nushell
	@echo "📋 Generating performance report..."
	$(NUSHELL) -c "source scripts/validation/performance-optimize.nu; report"

perf: performance-report

# Code quality targets
code-quality: check-nushell
	@echo "🔍 Running comprehensive code quality analysis..."
	$(NUSHELL) scripts/analysis/quality/code-quality.nu --full

code-syntax: check-nushell
	@echo "🔍 Checking syntax of all files..."
	$(NUSHELL) scripts/analysis/quality/code-quality.nu --syntax

code-security: check-nushell
	@echo "🔍 Checking for security issues..."
	$(NUSHELL) scripts/analysis/quality/code-quality.nu --security

quality: check-nushell
	@echo "🔍 Quick code quality check..."
	$(NUSHELL) scripts/analysis/quality/code-quality.nu --quick

# Cache optimization targets
cache-optimize: check-nushell
	@echo "⚡ Running advanced caching strategy..."
	$(NUSHELL) scripts/analysis/advanced-cache.nu --optimize

cache-warm: check-nushell
	@echo "🔥 Warming cache..."
	$(NUSHELL) scripts/analysis/advanced-cache.nu --warm

cache-maintain: check-nushell
	@echo "🔧 Maintaining cache..."
	$(NUSHELL) scripts/analysis/advanced-cache.nu --maintain

# Remote builder targets
remote-builder-setup: check-nushell
	@echo "🔧 Setting up remote builder..."
	$(NUSHELL) scripts/setup/setup-remote-builder.nu --verbose

test-remote-builder: check-nushell
	@echo "🧪 Testing remote builder..."
	$(NUSHELL) scripts/setup/test-remote-builder.nu --verbose 