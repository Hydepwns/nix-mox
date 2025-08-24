#!/usr/bin/env nu

# Import unified libraries
use ../lib/unified-checks.nu
use ../lib/unified-error-handling.nu


# Documentation generation tool for nix-mox scripts
# Automatically generates comprehensive documentation using enhanced modules
use ../lib/unified-logging.nu *
use ../lib/unified-error-handling.nu *
use ../lib/unified-logging.nu *
use ../lib/discovery.nu *

# Script metadata
export const SCRIPT_METADATA = {
    name: "generate-docs"
    description: "Generate comprehensive documentation for nix-mox scripts"
    platform: "all"
    requires_root: false
    category: "tools"
}

# Main documentation generation function
export def main [args: list] {
    # Set script name for logging context
    $env.SCRIPT_NAME = "generate-docs"

    # Parse arguments
    let parsed_args = (parse_doc_args $args)

    if $parsed_args.help {
        show_help
        exit 0
    }

    info $"Starting documentation generation" "generate-docs"
    info $"Configuration" "generate-docs"

    # Discover all scripts
    let all_scripts = (discover_scripts)
    info $"Discovered ($all_scripts | length) scripts"

    # Generate documentation
    try {
        let result = (generate_documentation $all_scripts $parsed_args)
        info $"Documentation generation completed" "generate-docs"
        info $"Results" "generate-docs"

        # Show summary
        show_generation_summary $result
        exit 0
    } catch { |err|
        error $"Documentation generation failed: ($err)" "generate-docs"
        exit 1
    }
}

# Parse documentation generation arguments
export def parse_doc_args [args: list] {
    let help = ($args | any { |it| $it == "--help" or $it == "-h" })
    let verbose = ($args | any { |it| $it == "--verbose" or $it == "-v" })
    let include_examples = ($args | any { |it| $it == "--examples" })
    let format = (get_flag_value $args "--format" "markdown")
    let output_dir = (get_flag_value $args "--output" "docs/generated")

    {
        help: $help
        verbose: $verbose
        include_examples: $include_examples
        format: $format
        output_dir: $output_dir
    }
}

# Get flag value from arguments
export def get_flag_value [args: list, flag: string, default: any] {
    let idx = ($args | enumerate | where item == $flag | get index.0?)
    if ($idx | is-not-empty) and ($args | length) > ($idx + 1) {
        $args | get ($idx + 1)
    } else {
        $default
    }
}

# Generate comprehensive documentation
export def generate_documentation [scripts: list, args: record] {
    # Ensure output directory exists
    if not ($args.output_dir | path exists) {
        mkdir $args.output_dir
    }

    mut files_generated = []

    # Generate main documentation
    let main_doc = (generate_main_documentation $scripts $args)
    $main_doc | save $"($args.output_dir)/scripts-reference.md"
    $files_generated = ($files_generated | append "scripts-reference.md")

    # Generate category-specific documentation
    let categories = ($scripts | get category | uniq)
    for category in $categories {
        let category_scripts = ($scripts | where category == $category)
        let category_doc = (generate_category_documentation $category $category_scripts $args)
        $category_doc | save $"($args.output_dir)/($category)-scripts.md"
        $files_generated = ($files_generated | append $"($category)-scripts.md")
    }

    # Generate JSON index
    let json_index = ($scripts | to json)
    $json_index | save $"($args.output_dir)/scripts-index.json"
    $files_generated = ($files_generated | append "scripts-index.json")

    # Generate README
    let readme = (generate_readme $scripts $args)
    $readme | save $"($args.output_dir)/README.md"
    $files_generated = ($files_generated | append "README.md")

    # Generate examples if requested
    if $args.include_examples {
        let examples = (generate_examples $scripts)
        $examples | save $"($args.output_dir)/examples.md"
        $files_generated = ($files_generated | append "examples.md")
    }

    {
        success: true
        output_dir: $args.output_dir
        files_generated: $files_generated
        total_scripts: ($scripts | length)
        categories: $categories
    }
}

# Generate main documentation
export def generate_main_documentation [scripts: list, args: record] {
    mut markdown = []

    # Header
    $markdown = ($markdown | append "# nix-mox Scripts Reference")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "This document provides a comprehensive reference for all available scripts in the nix-mox toolkit.")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append $"Generated on: (date now | format date '%Y-%m-%d %H:%M:%S')")
    $markdown = ($markdown | append $"Total scripts: ($scripts | length)")
    $markdown = ($markdown | append "")

    # Table of contents
    $markdown = ($markdown | append "## Table of Contents")
    $markdown = ($markdown | append "")
    let categories = ($scripts | get category | uniq)
    for category in $categories {
        let category_scripts = ($scripts | where category == $category)
        $markdown = ($markdown | append $"- [$category Scripts (($category_scripts | length))](#$category-scripts)")
    }
    $markdown = ($markdown | append "")

    # Quick start
    $markdown = ($markdown | append "## Quick Start")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "```bash")
    $markdown = ($markdown | append "# Install nix-mox")
    $markdown = ($markdown | append "./scripts/setup/install.nu")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "# Run health check")
    $markdown = ($markdown | append "./scripts/maintenance/health-check.nu")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "# Generate documentation")
    $markdown = ($markdown | append "./scripts/analysis/generate-docs.nu")
    $markdown = ($markdown | append "```")
    $markdown = ($markdown | append "")

    # Script categories
    for category in $categories {
        let category_scripts = ($scripts | where category == $category)
        $markdown = ($markdown | append $"## $category Scripts")
        $markdown = ($markdown | append "")

        for script in $category_scripts {
            $markdown = ($markdown | append $"### $script.name")
            $markdown = ($markdown | append "")
            $markdown = ($markdown | append $script.description)
            $markdown = ($markdown | append "")
            $markdown = ($markdown | append $"**Path:** `$script.path`")
            $markdown = ($markdown | append $"**Platform:** $script.platform")
            $markdown = ($markdown | append $"**Requires Root:** $script.requires_root")
            $markdown = ($markdown | append $"**Category:** $script.category")
            $markdown = ($markdown | append "")

            if ($script.dependencies | length) > 0 {
                $markdown = ($markdown | append $"**Dependencies:** ($script.dependencies | str join ', ')")
                $markdown = ($markdown | append "")
            }

            if $args.include_examples {
                let example = (generate_script_example $script)
                if ($example | str length) > 0 {
                    $markdown = ($markdown | append "**Example:**")
                    $markdown = ($markdown | append "```bash")
                    $markdown = ($markdown | append $example)
                    $markdown = ($markdown | append "```")
                    $markdown = ($markdown | append "")
                }
            }
        }
    }

    # Footer
    $markdown = ($markdown | append "---")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "For more information, see the [nix-mox documentation](../../docs/).")

    $markdown | str join "\n"
}

# Generate category-specific documentation
export def generate_category_documentation [category: string, scripts: list, args: record] {
    mut markdown = []

    $markdown = ($markdown | append $"# $category Scripts")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append $"This document lists all scripts in the $category category.")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append $"Total scripts: ($scripts | length)")
    $markdown = ($markdown | append "")

    for script in $scripts {
        $markdown = ($markdown | append $"## $script.name")
        $markdown = ($markdown | append "")
        $markdown = ($markdown | append $script.description)
        $markdown = ($markdown | append "")
        $markdown = ($markdown | append $"**Usage:** `$script.path`")
        $markdown = ($markdown | append "")

        if ($script.dependencies | length) > 0 {
            $markdown = ($markdown | append $"**Dependencies:** ($script.dependencies | str join ', ')")
            $markdown = ($markdown | append "")
        }

        if $args.include_examples {
            let example = (generate_script_example $script)
            if ($example | str length) > 0 {
                $markdown = ($markdown | append "**Example:**")
                $markdown = ($markdown | append "```bash")
                $markdown = ($markdown | append $example)
                $markdown = ($markdown | append "```")
                $markdown = ($markdown | append "")
            }
        }
    }

    $markdown | str join "\n"
}

# Generate README for documentation
export def generate_readme [scripts: list, args: record] {
    mut markdown = []

    $markdown = ($markdown | append "# nix-mox Scripts Documentation")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "This directory contains automatically generated documentation for all nix-mox scripts.")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "## Files")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "- `README.md` - This file")
    $markdown = ($markdown | append "- `scripts-reference.md` - Complete script reference")
    $markdown = ($markdown | append "- `scripts-index.json` - JSON index of all scripts")
    $markdown = ($markdown | append "")

    let categories = ($scripts | get category | uniq)
    for category in $categories {
        let category_scripts = ($scripts | where category == $category)
        $markdown = ($markdown | append $"- `($category)-scripts.md` - $category scripts (($category_scripts | length))")
    }
    $markdown = ($markdown | append "")

    if $args.include_examples {
        $markdown = ($markdown | append "- `examples.md` - Usage examples")
        $markdown = ($markdown | append "")
    }

    $markdown = ($markdown | append "## Statistics")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "- Total scripts: ($scripts | length)")
    $markdown = ($markdown | append "- Categories: ($categories | length)")
    $markdown = ($markdown | append "- Platforms supported: ($scripts | get platform | uniq | length)")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "## Regeneration")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "To regenerate this documentation:")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "```bash")
    $markdown = ($markdown | append "./scripts/analysis/generate-docs.nu")
$markdown = ($markdown | append "```")
$markdown = ($markdown | append "")
$markdown = ($markdown | append "For more options:")
$markdown = ($markdown | append "")
$markdown = ($markdown | append "```bash")
$markdown = ($markdown | append "./scripts/analysis/generate-docs.nu --help")
    $markdown = ($markdown | append "```")

    $markdown | str join "\n"
}

# Generate examples
export def generate_examples [scripts: list] {
    mut markdown = []

    $markdown = ($markdown | append "# nix-mox Script Examples")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "This document provides usage examples for nix-mox scripts.")
    $markdown = ($markdown | append "")

    let categories = ($scripts | get category | uniq)
    for category in $categories {
        let category_scripts = ($scripts | where category == $category)
        $markdown = ($markdown | append $"## $category Scripts")
        $markdown = ($markdown | append "")

        for script in $category_scripts {
            let example = (generate_script_example $script)
            if ($example | str length) > 0 {
                $markdown = ($markdown | append $"### $script.name")
                $markdown = ($markdown | append "")
                $markdown = ($markdown | append "```bash")
                $markdown = ($markdown | append $example)
                $markdown = ($markdown | append "```")
                $markdown = ($markdown | append "")
            }
        }
    }

    $markdown | str join "\n"
}

# Generate example for a specific script
export def generate_script_example [script: record] {
    match $script.name {
        "install" => "nu scripts/setup/install.nu --core --tools"
"health-check" => "nu scripts/maintenance/health-check.nu --check all"
"generate-docs" => "nu scripts/analysis/generate-docs.nu --examples"
"setup" => "nu scripts/setup/unified-setup.nu"
        "security-scan" => "nu scripts/analysis/quality/security-scan.nu --strict"
"performance-report" => "nu scripts/analysis/quality/performance-report.nu"
        _ => ""
    }
}

# Show generation summary
export def show_generation_summary [result: record] {
    print $"\n(ansi green_bold)Documentation Generation Complete!(ansi reset)"
    print $"\n(ansi cyan)Summary:(ansi reset)"
    print $"  Output directory:  ($result.output_dir)"
    print $"  Files generated:  ($result.files_generated | length)"
    print $"  Total scripts:  ($result.total_scripts)"
    print $"  Categories:  ($result.categories | length)"
    print $"\n(ansi cyan)Generated files:(ansi reset)"
    for file in $result.files_generated {
        print $"  ✓ ($file)"
    }
    print $"\n(ansi yellow)Next steps:(ansi reset)"
    print "  1. Review the generated documentation"
    print "  2. Update any script metadata as needed"
    print "  3. Commit the documentation to version control"
    print "  4. Update the main README to reference the new docs"
}

# Show help
export def show_help [] {
    print "nix-mox Documentation Generator"
    print ""
    print "Usage:"
    print "  generate-docs [options]"
    print ""
    print "Options:"
    print "  -h, --help              Show this help message"
    print "  -v, --verbose          Enable verbose output"
    print "  --examples             Include usage examples"
    print "  --format <format>      Output format (markdown, html, json) [default: markdown]"
    print "  --output <dir>         Output directory [default: docs/generated]"
    print ""
    print "Examples:"
    print "  generate-docs                    # Generate basic documentation"
    print "  generate-docs --examples         # Include usage examples"
    print "  generate-docs --output docs/api  # Output to custom directory"
    print "  generate-docs --verbose          # Verbose output"
}

# Main execution
if ($env | get -i NIXMOX_ARGS | is-not-empty) {
    let args = ($env.NIXMOX_ARGS | split row " ")
    main $args
} else {
    main ($in | default [])
}
