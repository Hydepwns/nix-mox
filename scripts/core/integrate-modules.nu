#!/usr/bin/env nu

# nix-mox Module Integration Script
# This script helps integrate existing modules with the new template system

def main [] {
    print "🔧 nix-mox Module Integration"
    print "============================="

    print "\n📋 Available Modules:"
    print "====================="

    # List available modules
    let modules = [
        { name: "services/infisical", description: "Infisical secrets management" }
        { name: "services/tailscale", description: "Tailscale VPN" }
        { name: "gaming", description: "Gaming support and tools" }
        { name: "monitoring", description: "System monitoring" }
        { name: "storage", description: "Storage management" }
        { name: "packages/development", description: "Development packages" }
        { name: "packages/gaming", description: "Gaming packages" }
        { name: "security", description: "Security features" }
    ]

    for item in ($modules | enumerate) {
        print $"  {$item.index + 1}. {$item.item.name} - {$item.item.description}"
    }

    print "\n❓ What would you like to do?"
    print "1. Add modules to existing templates"
    print "2. Create new template with modules"
    print "3. List module details"
    print "4. Exit"

    let choice = (input "Enter your choice (1-4): ")

    match $choice {
        "1" => { add-modules-to-templates }
        "2" => { create-template-with-modules }
        "3" => { list-module-details }
        "4" => { print "Goodbye!"; exit 0 }
        _ => { print "Invalid choice. Exiting."; exit 1 }
    }
}

def add-modules-to-templates [] {
    print "\n🎯 Add Modules to Templates"
    print "==========================="

    # List available templates
    let templates = (ls config/templates/*.nix | get name | path basename | str replace ".nix" "")

    print "\nAvailable templates:"
    for item in ($templates | enumerate) {
        print $"  {$item.index + 1}. {$item.item}"
    }

    let template_choice = (input "Select template (number): ")
    let template_name = ($templates | get ($template_choice | into int) - 1)

    print $"\nSelected template: {$template_name}"

    # List available modules
    let modules = [
        "services/infisical"
        "services/tailscale"
        "gaming"
        "monitoring"
        "storage"
        "packages/development"
        "packages/gaming"
        "security"
    ]

    print "\nAvailable modules:"
    for item in ($modules | enumerate) {
        print $"  {$item.index + 1}. {$item.item}"
    }

    let module_choice = (input "Select module to add (number): ")
    let module_name = ($modules | get ($module_choice | into int) - 1)

    print $"\nAdding module {$module_name} to template {$template_name}..."

    # Read current template
    let template_path = $"config/templates/{$template_name}.nix"
    let current_content = (open $template_path)

    # Add module import
    let module_import = $"  # Import {$module_name} module
  ../../modules/{$module_name}/index.nix"

    # Find the imports section and add the module
    let updated_content = ($current_content | str replace "imports = [" $"imports = [\n{$module_import}")

    # Save updated template
    $updated_content | save $template_path

    print $"✅ Added module {$module_name} to template {$template_name}"
}

def create-template-with-modules [] {
    print "\n🆕 Create Template with Modules"
    print "==============================="

    let template_name = (input "Enter template name: ")
    let template_description = (input "Enter template description: ")

    # List available modules
    let modules = [
        "services/infisical"
        "services/tailscale"
        "gaming"
        "monitoring"
        "storage"
        "packages/development"
        "packages/gaming"
        "security"
    ]

    print "\nSelect modules to include (comma-separated numbers):"
    for item in ($modules | enumerate) {
        print $"  {$item.index + 1}. {$item.item}"
    }

    let module_choices = (input "Enter module numbers: ")
    let selected_modules = ($module_choices | split row "," | each { |i| $modules | get ($i | into int) - 1 })

    # Create template content
    let imports = ($selected_modules | each { |m| $"  ../../modules/{$m}/index.nix" } | str join "\n")

    let header = $"# {$template_description}"
    let modules_line = $"# Template with modules: ($selected_modules | str join ', ')"
    let nix_header = "{ config, pkgs, ... }:"
    let nix_start = "{{"
    let imports_start = "  imports = ["
    let base_imports = "    ../profiles/base.nix\n    ../profiles/security.nix"
    let imports_end = "  ];"
    let packages_section = "  # Template-specific configuration\n  environment.systemPackages = with pkgs; [\n    # Add your packages here\n  ];"
    let services_section = "  # Template-specific services\n  services = {{\n    # Add your services here\n  }};"
    let nix_end = "}}"

    let template_content = $"($header)\n($modules_line)\n($nix_header)\n($nix_start)\n($imports_start)\n($base_imports)\n($imports)\n($imports_end)\n\n($packages_section)\n\n($services_section)\n($nix_end)"

    # Save template
    $template_content | save $"config/templates/{$template_name}.nix"

    print $"✅ Created template {$template_name} with modules: {$selected_modules | str join ", "}"
}

def list-module-details [] {
    print "\n📖 Module Details"
    print "================="

    let modules = [
        { name: "services/infisical", file: "modules/services/infisical.nix" }
        { name: "services/tailscale", file: "modules/services/tailscale.nix" }
        { name: "gaming", file: "modules/gaming/index.nix" }
        { name: "monitoring", file: "modules/monitoring/index.nix" }
        { name: "storage", file: "modules/storage/index.nix" }
        { name: "packages/development", file: "modules/packages/development/index.nix" }
        { name: "packages/gaming", file: "modules/packages/gaming/index.nix" }
        { name: "security", file: "modules/security/index.nix" }
    ]

    for module in $modules {
        print $"\n🔹 {$module.name}:"
        if (ls $module.file | length) > 0 {
            let content = (open $module.file | lines | take 10 | str join "\n")
            print $"   File: {$module.file}"
            print $"   Preview:"
            print ($content | str replace "^" "   ")
        } else {
            print $"   File not found: {$module.file}"
        }
    }
}

# Run the main function
main