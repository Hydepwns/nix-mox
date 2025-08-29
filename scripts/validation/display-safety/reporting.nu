#!/usr/bin/env nu
# Display safety validation reporting functions
# Extracted from scripts/validation/validate-display-safety.nu for better organization

use ../../lib/logging.nu *

# ──────────────────────────────────────────────────────────
# VALIDATION ANALYSIS AND REPORTING
# ──────────────────────────────────────────────────────────

# Check for critical failures
export def check_critical_failures [results: record] {
    let critical_components = ["stage1" "display_manager" "gpu_driver" "config_syntax"]
    
    let has_critical_failure = ($critical_components | any {|component|
        if ($results | get $component | is-not-empty) {
            let result = ($results | get $component)
            if ($result | get critical? | default false) {
                not $result.success
            } else {
                false
            }
        } else {
            false
        }
    })
    
    $has_critical_failure
}

# Print validation report
export def print_validation_report [results: record] {
    let context = "display-safety"
    banner "Display Safety Validation Report" --context $context
    
    $results | transpose key value | each {|row|
        let component = $row.key
        let result = $row.value
        let is_critical = ($result | get critical? | default false)
        let component_name = ($component | str replace '_' ' ' | str capitalize)
        
        if $result.success { 
            success $"($component_name) validation passed" --context $context
        } else if $is_critical { 
            error $"($component_name) validation failed (CRITICAL)" --context $context
        } else { 
            warn $"($component_name) validation had issues" --context $context
        }
        
        if ($result | get checks? | is-not-empty) {
            $result.checks | each {|check|
                let check_message = $"($check.name): ($check.message)"
                if $check.success {
                    info $"  ✓ ($check_message)" --context $context
                } else {
                    warn $"  ✗ ($check_message)" --context $context
                }
                
                if ($check | get error? | is-not-empty) and ($check.error | is-not-empty) {
                    warn $"    Error details: ($check.error | lines | first | default '')" --context $context
                }
            }
        }
    }
}