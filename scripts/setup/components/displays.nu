#!/usr/bin/env nu
# Component display functions
# Extracted from scripts/setup/component-browser.nu for better organization

use database.nu [COMPONENT_DB, get_all_categories, get_category, get_component]

# Color definitions - using simple strings for cross-platform compatibility
const GREEN = ""
const YELLOW = ""
const CYAN = ""
const RED = ""
const NC = ""

# =============================================================================
# MAIN DISPLAY FUNCTIONS
# =============================================================================

export def show_main_menu [] {
    print $"\n($GREEN)🔍 nix-mox Component Browser($NC)"
    print "================================"
    print ""
    print "Browse available configuration components:"
    print ""
    
    for category in (get_all_categories) {
        let config = (get_category $category)
        print $"($config.icon) ($YELLOW)($config.name)($NC)"
        print $"   ($config.description)"
        print ""
    }
    
    print "Usage:"
    print "  nu component-browser.nu --category CATEGORY"
    print "  nu component-browser.nu --category CATEGORY --component COMPONENT"
    print ""
    print "Examples:"
    print "  nu component-browser.nu --category development"
    print "  nu component-browser.nu --category gaming --component platforms"
    print ""
}

export def show_category_details [category: string] {
    try {
        let config = (get_category $category)
        
        print $"\n($config.icon) ($YELLOW)($config.name)($NC)"
        print $"($config.description)"
        print "=" * ($config.name | str length + 10)
        print ""
        
        for component in ($config.components | transpose name details | get name) {
            let details = ($config.components | get $component)
            
            print $"($details.icon) ($CYAN)($details.name)($NC)"
            print $"   ($details.description)"
            print ""
            
            # Show packages
            if not ($details.packages | is-empty) {
                print "   📦 Packages:"
                for package in ($details.packages | transpose name pkg | get name) {
                    let pkg = ($details.packages | get $package)
                    print $"     • ($pkg.name) - ($pkg.description) [($pkg.size)]"
                }
                print ""
            }
            
            # Show services
            if not ($details.services | is-empty) {
                print "   ⚙️  Services:"
                for service in ($details.services | transpose name svc | get name) {
                    let svc = ($details.services | get $service)
                    print $"     • ($svc.name) - ($svc.description)"
                }
                print ""
            }
        }
        
        print "To see detailed information about a specific component:"
        print $"  nu component-browser.nu --category ($category) --component COMPONENT_NAME"
        print ""
    } catch {
        print $"\n($RED)❌ Category '($category)' not found.($NC)"
        print ""
        print "Available categories:"
        for cat in (get_all_categories) {
            print $"  • ($cat)"
        }
        print ""
    }
}

export def show_component_details [category: string, component: string] {
    try {
        let category_config = (get_category $category)
        let comp_config = (get_component $category $component)
        
        print $"\n($comp_config.icon) ($YELLOW)($comp_config.name)($NC)"
        print $"($comp_config.description)"
        print "=" * ($comp_config.name | str length + 10)
        print ""
        
        # Show packages in detail
        if not ($comp_config.packages | is-empty) {
            print "📦 Packages:"
            print "-----------"
            for package in ($comp_config.packages | transpose name pkg | get name) {
                let pkg = ($comp_config.packages | get $package)
                
                print $"\n($CYAN)($pkg.name)($NC) [($pkg.category)]"
                print $"   Description: ($pkg.description)"
                print $"   Size: ($pkg.size)"
                if ($pkg.dependencies | length) > 0 {
                    print $"   Dependencies: ($pkg.dependencies | str join ', ')"
                } else {
                    print "   Dependencies: None"
                }
            }
            print ""
        }
        
        # Show services in detail
        if not ($comp_config.services | is-empty) {
            print "⚙️  Services:"
            print "------------"
            for service in ($comp_config.services | transpose name svc | get name) {
                let svc = ($comp_config.services | get $service)
                
                print $"\n($CYAN)($svc.name)($NC)"
                print $"   Description: ($svc.description)"
                print $"   Configuration:"
                print $"     ($svc.config)"
            }
            print ""
        }
        
        # Show installation example
        show_installation_example $comp_config
        
    } catch {
        try {
            let category_config = (get_category $category)
            print $"\n($RED)❌ Component '($component)' not found in category '($category)'.($NC)"
            print ""
            print "Available components in ($category):"
            for comp in ($category_config.components | transpose name details | get name) {
                print $"  • ($comp)"
            }
            print ""
        } catch {
            print $"\n($RED)❌ Category '($category)' not found.($NC)"
            print ""
            print "Available categories:"
            for cat in (get_all_categories) {
                print $"  • ($cat)"
            }
            print ""
        }
    }
}

# =============================================================================
# HELPER DISPLAY FUNCTIONS
# =============================================================================

def show_installation_example [comp_config: record] {
    print "📋 Installation Example:"
    print "----------------------"
    print "To include this component in your configuration:"
    print ""
    print "1. Run the enhanced setup:"
    print "   nu scripts/setup/enhanced-setup.nu"
    print ""
    print "2. Select the appropriate category and component"
    print ""
    print "3. Or manually add to your configuration.nix:"
    if not ($comp_config.packages | is-empty) {
        print "   environment.systemPackages = with pkgs; ["
        for package in ($comp_config.packages | transpose name pkg | get name) {
            print $"     ($package)"
        }
        print "   ];"
    }
    if not ($comp_config.services | is-empty) {
        for service in ($comp_config.services | transpose name svc | get name) {
            let svc = ($comp_config.services | get $service)
            print $"   ($svc.config)"
        }
    }
    print ""
}

export def show_usage [] {
    print "Usage: nu component-browser.nu [OPTIONS]"
    print ""
    print "Browse and preview nix-mox configuration components."
    print ""
    print "Options:"
    print "  --category CATEGORY    Show details for a specific category"
    print "  --component COMPONENT  Show details for a specific component (requires --category)"
    print "  --help, -h            Show this help message"
    print ""
    print "Categories:"
    for category in (get_all_categories) {
        let config = (get_category $category)
        print $"  ($category) - ($config.name)"
    }
    print ""
    print "Examples:"
    print "  nu component-browser.nu"
    print "  nu component-browser.nu --category development"
    print "  nu component-browser.nu --category gaming --component platforms"
}