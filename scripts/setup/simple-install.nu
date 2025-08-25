#!/usr/bin/env nu

# Import unified libraries
use ../lib/validators.nu *
use ../lib/logging.nu


# Simple working install script for nix-mox
# Fixed version that actually works

def main [
    --create-dirs  # Create missing directories
    --help (-h)    # Show help
] {
    if $help {
        show_help
        return
    }

    print "🚀 nix-mox Simple Install"
    print "========================="
    print ""

    # Check basic prerequisites
    let prereq_check = validate_prerequisites $create_dirs
    
    if not $prereq_check.success {
        print "❌ Prerequisites check failed:"
        for issue in $prereq_check.issues {
            print $"   - ($issue)"
        }
        if not $create_dirs {
            print ""
            print "💡 Try running with --create-dirs to fix directory issues"
        }
        exit 1
    }

    print "✅ Prerequisites check passed"
    print ""

    # Perform basic installation
    let install_result = perform_basic_install

    if $install_result.success {
        print "✅ Basic installation completed!"
        print ""
        print "📋 Next Steps:"
        print "1. Run unified setup (RECOMMENDED):"
        print "   nix-shell -p nushell --run 'nu scripts/setup/unified-setup.nu'"
        print ""
        print "2. Or run configuration setup separately:"
        print "   nix-shell -p nushell --run 'nu scripts/setup/simple-setup.nu'"
        print ""
        print "3. Always validate before rebuilding:"
        print "   nix-shell -p nushell --run 'nu scripts/validation/pre-rebuild-safety-check.nu'"
    } else {
        print "❌ Installation failed:"
        for error in $install_result.errors {
            print $"   - ($error)"
        }
        exit 1
    }
}

def validate_prerequisites [create_dirs: bool] {
    mut issues = []
    mut success = true

    # Check for config directory
    if not ("config" | path exists) {
        $issues = ($issues | append "config/ directory not found")  
        $success = false
    }

    # Check for basic commands
    let required_commands = ["git", "nix"]
    for cmd in $required_commands {
        let cmd_check = (which $cmd | length)
        if $cmd_check == 0 {
            $issues = ($issues | append $"Command not found: ($cmd)")
            $success = false
        }
    }

    # Check/create directories
    let user_home = ($env.HOME | default "/tmp")
    let required_dirs = [
        $"($user_home)/.config",
        $"($user_home)/.local", 
        $"($user_home)/.local/bin"
    ]

    for dir in $required_dirs {
        if not ($dir | path exists) {
            if $create_dirs {
                let mkdir_result = (^mkdir -p $dir | complete)
                if $mkdir_result.exit_code == 0 {
                    print $"📁 Created directory: ($dir)"
                } else {
                    $issues = ($issues | append $"Cannot create directory: ($dir)")
                    $success = false
                }
            } else {
                $issues = ($issues | append $"Directory missing: ($dir)")
            }
        }
    }

    # Check NixOS
    if not (("/etc/nixos" | path exists) or ("/etc/NIXOS" | path exists)) {
        $issues = ($issues | append "This doesn't appear to be a NixOS system")
        $success = false
    }

    # Check user permissions - simplified
    let groups_output = (groups | complete)
    if $groups_output.exit_code == 0 {
        let groups_text = $groups_output.stdout
        if not ($groups_text | str contains "wheel") {
            $issues = ($issues | append "User not in wheel group (no sudo access)")
            $success = false
        }
    } else {
        print "⚠️  Could not check user groups"
    }

    {success: $success, issues: $issues}
}

def perform_basic_install [] {
    mut errors = []
    mut success = true

    print "📦 Performing basic nix-mox installation..."

    # Create config directories if they don't exist
    let config_dirs = ["config/personal", "config/build"]
    for dir in $config_dirs {
        if not ($dir | path exists) {
            let mkdir_result = (^mkdir -p $dir | complete)
            if $mkdir_result.exit_code == 0 {
                print $"📁 Created: ($dir)"
            } else {
                $errors = ($errors | append $"Failed to create directory: ($dir)")
                $success = false
            }
        }
    }

    # Create basic .gitignore if it doesn't exist
    if not (".gitignore" | path exists) {
        let gitignore_content = "# nix-mox gitignore
config/personal/
.env
result/
result-*
.direnv/
"
        $gitignore_content | save .gitignore
        print "📄 Created .gitignore"
    }

    # Create example env file if it doesn't exist  
    if not ("env.example" | path exists) and not (".env" | path exists) {
        let env_example = "# nix-mox Environment Configuration Example
# Copy this to .env and customize

NIXMOX_USERNAME=nixos
NIXMOX_HOSTNAME=nixos
NIXMOX_TIMEZONE=UTC
NIXMOX_EMAIL=user@example.com
"
        $env_example | save env.example
        print "📄 Created env.example"
    }

    # Verify flake syntax
    let flake_check = (nix flake check --no-build | complete)
    if $flake_check.exit_code == 0 {
        print "✅ Flake syntax check passed"
    } else {
        $errors = ($errors | append "Flake syntax check failed - run 'nix flake check' for details")
        $success = false
    }

    {success: $success, errors: $errors}
}

def show_help [] {
    print "nix-mox Simple Install Script"
    print ""
    print "Usage:"
    print "  simple-install.nu                    # Basic install check"
    print "  simple-install.nu --create-dirs      # Create missing directories"
    print "  simple-install.nu --help             # Show this help"
    print ""
    print "This script performs basic validation and setup for nix-mox."
    print "It checks prerequisites and creates necessary directories."
    print ""
    print "After running this script, use:"
    print "  nu scripts/setup/unified-setup.nu     # Unified setup (RECOMMENDED)"
print "  nu scripts/setup/simple-setup.nu      # Simple setup (alternative)"
}