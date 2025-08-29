#!/usr/bin/env nu
# Modular display safety validation for nix-mox
# Refactored from monolithic 730-line file into focused modules
# Comprehensive tests to ensure rebuild won't break display/greeter

use ../lib/validators.nu *
use ../lib/logging.nu *
use ../lib/platform.nu *
use ../lib/constants.nu *

# Import display safety modules
use display-safety/validators.nu *
use display-safety/advanced-checks.nu *
use display-safety/reporting.nu *

# ──────────────────────────────────────────────────────────
# MAIN VALIDATION ORCHESTRATOR
# ──────────────────────────────────────────────────────────

def main [] {
    let context = "display-safety"
    banner "Display Manager Safety Validation" $CONTEXTS.validation
    warn "Running comprehensive display safety checks before rebuild..." --context $context
    
    let results = {
        stage1: (validate_stage1_boot),
        display_manager: (validate_display_manager),
        greeter: (validate_greeter_config),
        xserver: (validate_xserver_config),
        wayland: (validate_wayland_config),
        gpu_driver: (validate_gpu_drivers),
        dependencies: (validate_display_dependencies),
        config_syntax: (validate_config_syntax)
    }
    
    print_validation_report $results
    
    # Check for critical failures
    let critical_failures = check_critical_failures $results
    
    if $critical_failures {
        error "❌ CRITICAL: Display configuration has issues that WILL break your system!" --context $context
        error "DO NOT proceed with nixos-rebuild switch!" --context $context
        warn "Fix the issues above before rebuilding." --context $context
        exit 1
    }
    
    let all_passed = ($results | values | all {|r| $r.success})
    if $all_passed {
        success "✅ Display configuration validated - safe to rebuild" --context $context
        exit 0
    } else {
        warn "⚠️  Some display checks failed - review carefully before rebuilding" --context $context
        exit 1
    }
}


# ──────────────────────────────────────────────────────────
# EXECUTION
# ──────────────────────────────────────────────────────────

# Run main if called directly
main