#!/usr/bin/env nu
# Auto-update storage configuration script
# This script serves as a wrapper for the storage update functions

use ../lib/logging.nu *
use ../lib/platform.nu *
use ./updaters.nu [auto_update_storage]

def main [
    --backup             # Create backup before updating
    --dry-run            # Show what would be done without making changes
    --verbose            # Show detailed output
] {
    if $verbose {
        info "Auto-update storage configuration" --context "auto-update-storage"
    }
    
    let platform = (get_platform)
    if not $platform.is_linux {
        if $verbose {
            warn "Auto-update storage is primarily designed for Linux systems" --context "auto-update-storage"
        }
    }
    
    try {
        let result = (auto_update_storage ($backup | default false) ($dry_run | default false))
        
        if $verbose {
            if $result.success {
                success "Storage configuration update completed successfully" --context "auto-update-storage"
            } else {
                error "Storage configuration update failed" --context "auto-update-storage"
            }
        }
        
        if $result.success {
            exit 0
        } else {
            exit 1
        }
    } catch { |err|
        if $verbose {
            error $"Storage update failed: ($err.msg)" --context "auto-update-storage"
        }
        exit 1
    }
}