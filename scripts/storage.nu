#!/usr/bin/env nu
# Modular storage operations for nix-mox
# Refactored from monolithic 784-line file into focused modules
# Uses functional patterns for safe storage management

use lib/logging.nu *
use lib/platform.nu *
use lib/validators.nu *
use lib/script-template.nu *
use lib/constants.nu *

# Import storage modules
use storage/validators.nu *
use storage/fixers.nu *
use storage/updaters.nu *
use storage/backup.nu *
use storage/health-checks.nu *

# Main storage operations dispatcher
def main [
    operation: string = "guard",
    --fix,
    --auto-update,
    --backup,
    --dry-run,
    --verbose,
    --context: string = "storage"
] {
    if ($verbose | default false) { $env.LOG_LEVEL = "DEBUG" }
    
    banner $"nix-mox storage: ($operation)" $CONTEXTS.storage
    
    # Dispatch to appropriate storage operation
    match $operation {
        "guard" => (storage_guard $fix $backup $dry_run),
        "fix" => (fix_storage_config $backup $dry_run),
        "auto-update" => (auto_update_storage $backup $dry_run),
        "validate" => (validate_storage_config $dry_run),
        "backup" => (backup_storage_config),
        "restore" => (restore_storage_config),
        "health-check" => (storage_health_check),
        "help" => { show_storage_help; return },
        _ => {
            error $"Unknown storage operation: ($operation). Use 'help' to see available operations."
            return
        }
    }
}

# ──────────────────────────────────────────────────────────
# MAIN STORAGE OPERATIONS
# ──────────────────────────────────────────────────────────

# Storage guard - comprehensive safety validation before reboot
export def storage_guard [fix: bool, backup: bool, dry_run: bool] {
    info "Starting storage guard validation" --context "storage-guard"
    
    critical "🛡️  STORAGE GUARD: Critical boot safety validation" --context "storage-guard"
    
    # Run comprehensive storage validation
    let validation_results = (run_comprehensive_storage_validation)
    
    if not $validation_results.success {
        critical "❌ STORAGE VALIDATION FAILED - DO NOT REBOOT!" --context "storage-guard"
        error "Failed validations:" --context "storage-guard"
        
        for failure in ($validation_results.results | where success == false) {
            error $"  - ($failure.name): ($failure.message)" --context "storage-guard"
        }
        
        if $fix {
            warn "Attempting automatic fixes..." --context "storage-guard"
            let fix_result = (fix_storage_config $backup $dry_run)
            
            if $fix_result.success {
                info "Re-running validation after fixes..." --context "storage-guard"
                let revalidation = (run_comprehensive_storage_validation)
                
                if $revalidation.success {
                    success "✅ Storage validation PASSED after fixes - system is safe to reboot" --context "storage-guard"
                    return { success: true, fixed: true }
                } else {
                    critical "❌ Storage validation STILL FAILING after fixes - DO NOT REBOOT!" --context "storage-guard"
                    return { success: false, fixed: false }
                }
            } else {
                critical "❌ Automatic fixes FAILED - manual intervention required" --context "storage-guard"
                return { success: false, fixed: false }
            }
        } else {
            critical "Use --fix to attempt automatic repairs" --context "storage-guard"
            return { success: false, fixed: false }
        }
    } else {
        success "✅ Storage validation PASSED - system is safe to reboot" --context "storage-guard"
        return { success: true, fixed: false }
    }
}

# Validate storage configuration
export def validate_storage_config [dry_run: bool] {
    run_comprehensive_storage_validation
}

# Show storage help
def show_storage_help [] {
    format_help "nix-mox storage operations" "Consolidated storage safety and management system" "nu storage.nu <operation> [options]" [
        { name: "guard", description: "Comprehensive storage safety validation (default)" }
        { name: "fix", description: "Fix detected storage configuration issues" }
        { name: "auto-update", description: "Auto-update storage configuration" }
        { name: "validate", description: "Validate storage configuration only" }
        { name: "backup", description: "Backup storage configuration" }
        { name: "restore", description: "Restore storage configuration from backup" }
        { name: "health-check", description: "Comprehensive storage health check" }
    ] [
        { name: "fix", description: "Attempt automatic fixes for detected issues" }
        { name: "auto-update", description: "Enable automatic configuration updates" }
        { name: "backup", description: "Create backup before making changes (default: true)" }
        { name: "dry-run", description: "Show what would be done without making changes" }
        { name: "verbose", description: "Enable verbose output" }
    ] [
        { command: "nu storage.nu guard", description: "Basic storage safety check" }
        { command: "nu storage.nu guard --fix", description: "Check and fix storage issues" }
        { command: "nu storage.nu health-check", description: "Comprehensive health assessment" }
        { command: "nu storage.nu backup", description: "Create configuration backup" }
    ]
}

