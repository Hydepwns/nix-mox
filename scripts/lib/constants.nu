#!/usr/bin/env nu
# Constants module for nix-mox
# Provides centralized constants used across the system

# Context constants for logging and operations
export const CONTEXTS = {
    # Test contexts
    test: "test-runner"
    unit_test: "unit-test"
    integration_test: "integration-test"
    validation_test: "validation-test"
    maintenance_test: "maintenance-test"
    setup_test: "setup-test"
    platform_test: "platform-test"
    analysis_test: "analysis-test"
    gaming_test: "gaming-test"
    gaming_scripts_test: "gaming-scripts-test"
    handlers_test: "handlers-test"
    macos_platform_test: "macos-platform-test"
    windows_platform_test: "windows-platform-test"
    infrastructure_test: "infrastructure-test"
    security_test: "security-test"
    performance_test: "performance-test"
    
    # System contexts
    system: "system"
    validation: "validation"
    storage: "storage"
    security: "security"
    maintenance: "maintenance"
    setup: "setup"
    gaming: "gaming"
    analysis: "analysis"
    platform: "platform"
    
    # Component contexts
    command: "command"
    validator: "validator"
    secure_command: "secure-command"
    test_env: "test-env"
    test_report: "test-report"
    emi_health_check: "emi-health-check"
    gaming_validation: "gaming-validation"
    rebuild_dry_run: "rebuild-dry-run"
    system_rebuild: "system-rebuild"
    usb_validation: "usb-validation"
    i2c_validation: "i2c-validation"
    hardware_validation: "hardware-validation"
    graphics_validation: "graphics-validation"
    boot_validation: "boot-validation"
    root_validation: "root-validation"
    filesystem_validation: "filesystem-validation"
    nix_validation: "nix-validation"
    nixos_validation: "nixos-validation"
    rollback_validation: "rollback-validation"
    backup_validation: "backup-validation"
    emi_validation: "emi-validation"
}

# Test result constants
export const TEST_RESULTS = {
    PASSED: "passed"
    FAILED: "failed"
    SKIPPED: "skipped"
    ERROR: "error"
    TIMEOUT: "timeout"
}

# Log level constants
export const LOG_LEVELS = {
    TRACE: "TRACE"
    DEBUG: "DEBUG"
    INFO: "INFO"
    SUCCESS: "SUCCESS"
    WARN: "WARN"
    ERROR: "ERROR"
    CRITICAL: "CRITICAL"
}

# Platform constants
export const PLATFORMS = {
    LINUX: "linux"
    MACOS: "macos"
    WINDOWS: "windows"
    UNKNOWN: "unknown"
}

# File system constants
export const FILESYSTEM = {
    MAX_PATH_LENGTH: 4096
    MAX_COMMAND_LENGTH: 255
    BOOT_PARTITION: "/boot"
    ROOT_PARTITION: "/"
}

# Time constants
export const TIMEOUTS = {
    DEFAULT_COMMAND: 30sec
    DEFAULT_NETWORK: 3sec
    DEFAULT_VALIDATION: 60sec
    DEFAULT_REBUILD: 300sec
}

# Security constants
export const SECURITY = {
    DANGEROUS_PATTERNS: [
        "rm -rf"
        "dd if="
        "mkfs"
        "fdisk"
        "parted"
        "chmod 777"
        "chown root"
    ]
    DANGEROUS_OPERATIONS: [
        "delete"
        "remove"
        "format"
        "overwrite"
    ]
}

# Validation constants
export const VALIDATION = {
    DISK_USAGE_THRESHOLD: 80
    MEMORY_USAGE_THRESHOLD: 80
    NETWORK_TIMEOUT: 3
    MAX_RETRY_ATTEMPTS: 3
    RETRY_DELAY: 1sec
}

# Test environment constants
export const TEST_ENV = {
    OUTPUT_DIR: "coverage-tmp/test-results"
    COVERAGE_DIR: "coverage-tmp"
    LOG_LEVEL: "INFO"
    PARALLEL_DEFAULT: true
    FAIL_FAST_DEFAULT: false
} 