#!/usr/bin/env nu
# Modular component browser for nix-mox
# Refactored from monolithic 784-line file into focused modules
# Browse and preview available configuration components

use ../lib/validators.nu *
use ../lib/logging.nu *

# Import component modules
use components/database.nu *
use components/displays.nu *

# =============================================================================
# MAIN DISPATCHER
# =============================================================================

def main [
    --category: string = "",
    --component: string = "",
    --help (-h)
] {
    if $help {
        show_usage
        return
    }
    
    # Validate arguments
    if $component != "" and $category == "" {
        print "Error: --component requires --category to be specified"
        exit 1
    }
    
    if $category != "" and $component != "" {
        show_component_details $category $component
    } else if $category != "" {
        show_category_details $category
    } else {
        show_main_menu
    }
}


# =============================================================================
# EXECUTION
# =============================================================================

try {
    main
} catch { |err|
    print $"❌ Component browser failed: ($err)"
    exit 1
}
