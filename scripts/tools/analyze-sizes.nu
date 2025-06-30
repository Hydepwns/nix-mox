#!/usr/bin/env nu

# nix-mox Size Analysis Script
# ============================
# Analyzes the size of all packages, devshells, and templates
# Provides detailed reporting and performance tradeoffs

def main [] {
    print "🔍 nix-mox Size Analysis"
    print "========================"
    print ""

    # Check if we're in the right directory
    if (ls | where name == "flake.nix" | is-empty) {
        error make {msg: "Must be run from nix-mox root directory"}
    }

    # Get system architecture
    let system = (^uname -m | str trim)
    print $"📊 Analyzing for system: ($system)"
    print ""

    # Analyze packages
    let packages = analyze_packages $system
    print "📦 Package Analysis"
    print "------------------"
    display_package_analysis $packages
    print ""

    # Analyze devshells
    let devshells = analyze_devshells $system
    print "💻 Development Shell Analysis"
    print "----------------------------"
    display_devshell_analysis $devshells
    print ""

    # Analyze templates
    let templates = analyze_templates $system
    print "🏗️ Template Analysis"
    print "-------------------"
    display_template_analysis $templates
    print ""

    # Generate summary report
    let summary = generate_summary $packages $devshells $templates
    print "📈 Summary Report"
    print "----------------"
    display_summary $summary
    print ""

    # Save detailed report
    let report_file = $"nix-mox-size-analysis-{$system}-{(date now | format date '%Y%m%d-%H%M%S')}.json"
    $summary | to json | save $report_file
    print $"💾 Detailed report saved to: ($report_file)"
    print ""

    # Performance recommendations
    print "💡 Performance Recommendations"
    print "----------------------------"
    display_recommendations $summary
}

def analyze_packages [system: string] {
    let package_names = [
        "proxmox-update"
        "vzdump-backup"
        "zfs-snapshot"
        "nixos-flake-update"
        "install"
        "uninstall"
    ]

    mut results = []

    for package in $package_names {
        print $"  Analyzing package: ($package)..."

        # Build package and get size
        let start_time = (date now)
        let build_result = (do --ignore-errors { nix build .#($package) --json --no-link } | from json)
        let end_time = (date now)
        let build_duration = (($end_time - $start_time) | into duration)

        # Get closure size
        let closure_size_raw = (do --ignore-errors { nix path-info --closure-size .#($package) })
        let closure_size = if ($closure_size_raw | is-empty) { 0 } else {
            let parsed = ($closure_size_raw | lines | parse "{size} {path}")
            if ($parsed | is-empty) { 0 } else {
                let size_str = $parsed.size.0
                let size_int = (do --ignore-errors { $size_str | into int })
                if ($size_int | is-empty) { 0 } else { $size_int }
            }
        }

        # Get individual package size
        let package_size_raw = (do --ignore-errors { nix path-info --size .#($package) })
        let package_size = if ($package_size_raw | is-empty) { 0 } else {
            let parsed = ($package_size_raw | lines | parse "{size} {path}")
            if ($parsed | is-empty) { 0 } else {
                let size_str = $parsed.size.0
                let size_int = (do --ignore-errors { $size_str | into int })
                if ($size_int | is-empty) { 0 } else { $size_int }
            }
        }

        $results = ($results | append {
            type: "package"
            name: $package
            system: $system
            closure_size: $closure_size
            package_size: $package_size
            build_duration: $build_duration
            dependencies: ($closure_size - $package_size)
        })
    }

    $results
}

def analyze_devshells [system: string] {
    let shell_names = [
        "default"
        "development"
        "testing"
        "services"
        "monitoring"
        "gaming"
        "zfs"
        "macos"
    ]

    mut results = []

    for shell in $shell_names {
        print $"  Analyzing devshell: ($shell)..."

        # Check if shell exists for this system
        let shell_exists = not (do --ignore-errors { nix flake show .#($shell) } | is-empty)

        if $shell_exists {
            # Get shell size by building it
            let start_time = (date now)
            let build_result = (do --ignore-errors { nix build .#($shell) --json --no-link } | from json)
            let end_time = (date now)
            let build_duration = (($end_time - $start_time) | into duration)

            # Get closure size
            let closure_size_raw = (do --ignore-errors { nix path-info --closure-size .#($shell) })
            let closure_size = if ($closure_size_raw | is-empty) { 0 } else {
                let parsed = ($closure_size_raw | lines | parse "{size} {path}")
                if ($parsed | is-empty) { 0 } else {
                    let size_str = $parsed.size.0
                    let size_int = (do --ignore-errors { $size_str | into int })
                    if ($size_int | is-empty) { 0 } else { $size_int }
                }
            }

            $results = ($results | append {
                type: "devshell"
                name: $shell
                system: $system
                closure_size: $closure_size
                build_duration: $build_duration
                available: true
            })
        } else {
            $results = ($results | append {
                type: "devshell"
                name: $shell
                system: $system
                closure_size: 0
                build_duration: "0ms"
                available: false
            })
        }
    }

    $results
}

def analyze_templates [system: string] {
    # Analyze NixOS configurations - check for common template names
    let template_names = ["nixos"]

    mut results = []

    for template in $template_names {
        print $"  Analyzing template: ($template)..."

        # Check if template exists
        let template_exists = not (do --ignore-errors { nix flake show .#($template) } | is-empty)

        if $template_exists {
            # Get configuration size
            let start_time = (date now)
            let build_result = (do --ignore-errors { nix build .#($template).config.system.build.toplevel --json --no-link } | from json)
            let end_time = (date now)
            let build_duration = (($end_time - $start_time) | into duration)

            # Get closure size
            let closure_size_raw = (do --ignore-errors { nix path-info --closure-size .#($template).config.system.build.toplevel })
            let closure_size = if ($closure_size_raw | is-empty) { 0 } else {
                let parsed = ($closure_size_raw | lines | parse "{size} {path}")
                if ($parsed | is-empty) { 0 } else {
                    let size_str = $parsed.size.0
                    let size_int = (do --ignore-errors { $size_str | into int })
                    if ($size_int | is-empty) { 0 } else { $size_int }
                }
            }

            $results = ($results | append {
                type: "template"
                name: $template
                system: $system
                closure_size: $closure_size
                build_duration: $build_duration
            })
        }
    }

    $results
}

def display_package_analysis [packages: list] {
    let sorted_packages = ($packages | sort-by closure_size -r)

    print "Package Sizes (closure size):"
    print ""

    for package in $sorted_packages {
        let size_mb = (($package.closure_size | into float) / 1024 / 1024 | into string | str substring 0..6)
        let deps_mb = (($package.dependencies | into float) / 1024 / 1024 | into string | str substring 0..6)
        let pkg_mb = (($package.package_size | into float) / 1024 / 1024 | into string | str substring 0..6)
        let name_padded = ($package.name + "                    " | str substring 0..20)
        print $"  ($name_padded) | ($size_mb) MB total | ($pkg_mb) MB package | ($deps_mb) MB deps | ($package.build_duration)"
    }

    print ""
    let total_size = ($packages | get closure_size | math sum)
    let total_mb = (($total_size | into float) / 1024 / 1024 | into string | str substring 0..6)
    print $"Total package size: ($total_mb) MB"
}

def display_devshell_analysis [devshells: list] {
    let available_shells = ($devshells | where available == true | sort-by closure_size -r)

    print "Development Shell Sizes (closure size):"
    print ""

    for shell in $available_shells {
        let size_mb = (($shell.closure_size | into float) / 1024 / 1024 | into string | str substring 0..6)
        let name_padded = ($shell.name + "               " | str substring 0..15)
        print $"  ($name_padded) | ($size_mb) MB | ($shell.build_duration)"
    }

    print ""
    let unavailable_shells = ($devshells | where available == false | get name)
    if ($unavailable_shells | length) > 0 {
        print "Unavailable shells for this system:"
        for shell in $unavailable_shells {
            print $"  - ($shell)"
        }
        print ""
    }

    let total_size = if ($available_shells | length) > 0 { ($available_shells | get closure_size | math sum) } else { 0 }
    let total_mb = (($total_size | into float) / 1024 / 1024 | into string | str substring 0..6)
    print $"Total devshell size: ($total_mb) MB"
}

def display_template_analysis [templates: list] {
    if ($templates | length) == 0 {
        print "No NixOS configurations found for this system."
        return
    }

    let sorted_templates = ($templates | sort-by closure_size -r)

    print "Template Sizes (closure size):"
    print ""

    for template in $sorted_templates {
        let size_mb = (($template.closure_size | into float) / 1024 / 1024 | into string | str substring 0..6)
        let name_padded = ($template.name + "                    " | str substring 0..20)
        print $"  ($name_padded) | ($size_mb) MB | ($template.build_duration)"
    }

    print ""
    let total_size = ($templates | get closure_size | math sum)
    let total_mb = (($total_size | into float) / 1024 / 1024 | into string | str substring 0..6)
    print $"Total template size: ($total_mb) MB"
}

def generate_summary [packages: list, devshells: list, templates: list] {
    let total_package_size = if ($packages | length) > 0 { ($packages | get closure_size | math sum) } else { 0 }
    let total_devshell_size = if ($devshells | where available == true | length) > 0 { ($devshells | where available == true | get closure_size | math sum) } else { 0 }
    let total_template_size = if ($templates | length) > 0 { ($templates | get closure_size | math sum) } else { 0 }
    let grand_total = ($total_package_size + $total_devshell_size + $total_template_size)

    let largest_package = if ($packages | length) > 0 { ($packages | sort-by closure_size -r | get 0) } else { null }
    let largest_devshell = if ($devshells | where available == true | length) > 0 { ($devshells | where available == true | sort-by closure_size -r | get 0) } else { null }
    let largest_template = if ($templates | length) > 0 { ($templates | sort-by closure_size -r | get 0) } else { null }

    {
        timestamp: (date now | into string)
        system: (^uname -m | str trim)
        totals: {
            packages: $total_package_size
            devshells: $total_devshell_size
            templates: $total_template_size
            grand_total: $grand_total
        }
        largest: {
            package: $largest_package
            devshell: $largest_devshell
            template: $largest_template
        }
        details: {
            packages: $packages
            devshells: $devshells
            templates: $templates
        }
    }
}

def display_summary [summary: record] {
    let total_mb = (($summary.totals.grand_total | into float) / 1024 / 1024 | into string | str substring 0..6)
    let packages_mb = (($summary.totals.packages | into float) / 1024 / 1024 | into string | str substring 0..6)
    let devshells_mb = (($summary.totals.devshells | into float) / 1024 / 1024 | into string | str substring 0..6)
    let templates_mb = (($summary.totals.templates | into float) / 1024 / 1024 | into string | str substring 0..6)

    print $"📊 Total Repository Size: ($total_mb) MB"
    print $"   📦 Packages: ($packages_mb) MB"
    print $"   💻 DevShells: ($devshells_mb) MB"
    print $"   🏗️ Templates: ($templates_mb) MB"
    print ""

    let largest_pkg_mb = if $summary.largest.package != null { (($summary.largest.package.closure_size | into float) / 1024 / 1024 | into string | str substring 0..6) } else { "0" }
    let largest_shell_mb = if $summary.largest.devshell != null { (($summary.largest.devshell.closure_size | into float) / 1024 / 1024 | into string | str substring 0..6) } else { "0" }
    let largest_template_mb = if $summary.largest.template != null { (($summary.largest.template.closure_size | into float) / 1024 / 1024 | into string | str substring 0..6) } else { "0" }

    print "🏆 Largest Components:"
    if $summary.largest.package != null {
        let pkg_name = $summary.largest.package.name
        let pkg_size_str = $"($largest_pkg_mb) MB"
        print $"   📦 Package: ($pkg_name) ($pkg_size_str)"
    }
    if $summary.largest.devshell != null {
        let shell_name = $summary.largest.devshell.name
        let shell_size_str = $"($largest_shell_mb) MB"
        print $"   💻 DevShell: ($shell_name) ($shell_size_str)"
    }
    if $summary.largest.template != null {
        let template_name = $summary.largest.template.name
        let template_size_str = $"($largest_template_mb) MB"
        print $"   🏗️ Template: ($template_name) ($template_size_str)"
    }
}

def display_recommendations [summary: record] {
    let total_mb = (($summary.totals.grand_total | into float) / 1024 / 1024)

    print "Based on the size analysis:"
    print ""

    if $total_mb > 5000 {
        print "⚠️  Large repository size detected (>5GB)"
        print "   - Consider using smaller templates for development"
        print "   - Use specific devshells instead of the full development shell"
        print "   - Clean up unused packages with 'nix store gc'"
    } else if $total_mb > 2000 {
        print "📈 Moderate repository size (2-5GB)"
        print "   - Good balance between features and size"
        print "   - Consider the gaming shell only if needed (largest devshell)"
    } else {
        print "✅ Compact repository size (<2GB)"
        print "   - Excellent for quick development and CI/CD"
        print "   - Good choice for resource-constrained environments"
    }

    print ""
    print "💡 Optimization Tips:"
    print "   - Use 'nix develop .#specific-shell' instead of the default shell"
    print "   - Build only needed packages: 'nix build .#package-name'"
    print "   - Use 'nix store gc' regularly to clean up unused derivations"
    print "   - Consider using smaller templates for testing and development"
}

# Run the main function
main
