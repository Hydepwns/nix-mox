.PHONY: test unit integration clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  test        - Run all tests"
	@echo "  unit        - Run unit tests only"
	@echo "  integration - Run integration tests only"
	@echo "  clean       - Clean up test artifacts"
	@echo "  format      - Format Nix files"
	@echo "  check       - Run nix flake check"
	@echo "  dev         - Enter development shell"
	@echo "  test-shell  - Enter testing shell"
	@echo "  gaming-shell - Enter gaming shell"
	@echo "  macos-shell - Enter macos shell"
	@echo "  services-shell - Enter services shell"
	@echo "  monitoring-shell - Enter monitoring shell"
	@echo "  storage-shell - Enter storage shell"

# Run all tests
test:
	TEST_TEMP_DIR=coverage-tmp nu -c "source tests/run-tests.nu; run []"

# Run unit tests only
unit:
	TEST_TEMP_DIR=coverage-tmp nu tests/unit/unit-tests.nu

# Run integration tests only
integration:
	TEST_TEMP_DIR=coverage-tmp nu tests/integration/integration-tests.nu

# Clean up test artifacts
clean:
	rm -rf coverage-tmp
	rm -f coverage.json coverage.yaml coverage.toml

# Format Nix files
format:
	nix fmt

# Run nix flake check
check:
	nix flake check

# Development shell
dev:
	nix develop

# Testing shell
test-shell:
	nix develop .#testing

# Gaming shell
gaming-shell:
	nix develop .#gaming

# Macos shell
macos-shell:
	nix develop .#macos

# Services shell
services-shell:
	nix develop .#services

# Monitoring shell
monitoring-shell:
	nix develop .#monitoring

# Storage shell
storage-shell:
	nix develop .#storage