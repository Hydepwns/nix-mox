#!/usr/bin/env nu

# Import unified libraries
use ../lib/unified-checks.nu
use ../lib/unified-logging.nu *
use ../lib/unified-error-handling.nu *


# Simplified install script for nix-mox
# This is a test version without complex dependencies

# Script metadata
export const SCRIPT_METADATA = {
    name: "install",
    description: "Install nix-mox on the current system",
    platform: "all",
    requires_root: false,
    category: "core"
}

# Use unified logging functions instead of custom ones

# Main installation function
export def main [args: list] {
    info $"Starting nix-mox installation" "install"

    # Parse arguments
    let parsed_args = (parse_install_args $args)

    # Show help if requested
    if $parsed_args.help {
        show_help
        exit 0
    }

    # Validate installation prerequisites
    let prereq_check = (check_prerequisites)
    if not $prereq_check.valid {
        error "Prerequisites not met" "install"
        exit 1
    }

    # Perform installation
    try {
        let install_result = (perform_installation $parsed_args)
        info $"Installation completed successfully" "install"

        # Show post-installation instructions
        show_post_install_instructions $install_result
        exit 0
    } catch { |err|
        error $"Installation failed: ($err)" "install"
        exit 1
    }
}

# Parse installation arguments
export def parse_install_args [args: list] {
    let help = ($args | any { |it| $it == "--help" or $it == "-h" })
    let dry_run = ($args | any { |it| $it == "--dry-run" })
    let verbose = ($args | any { |it| $it == "--verbose" or $it == "-v" })
    let strict_security = ($args | any { |it| $it == "--strict-security" })
    let force = ($args | any { |it| $it == "--force" or $it == "-f" })

    # Get component selection
    let components = (get_component_selection $args)

    {
        help: $help,
        dry_run: $dry_run,
        verbose: $verbose,
        strict_security: $strict_security,
        force: $force,
        components: $components
    }
}

# Get component selection from arguments
export def get_component_selection [args: list] {
    let component_flags = ["--core", "--tools", "--development", "--gaming", "--monitoring", "--security"]
    mut selected_components = []

    for flag in $component_flags {
        if ($args | any { |it| $it == $flag }) {
            let component = ($flag | str replace "--" "")
            $selected_components = ($selected_components | append $component)
        }
    }

    # If no components specified, install core by default
    if ($selected_components | length) == 0 {
        $selected_components = ["core"]
    }

    $selected_components
}

# Check installation prerequisites
export def check_prerequisites [] {
    mut missing = []
    mut errors = []

    # Check for Nix installation
    if (which nix | is-empty) {
        $errors = ($errors | append "Nix is not installed")
    }

    # Check for required directories
    let required_dirs = ["~/.config", "~/.local/bin"]
    for dir in $required_dirs {
        if not ($dir | path exists) {
            $missing = ($missing | append $dir)
        }
    }

    let missing_count = ($missing | length | into int)
    let errors_count = ($errors | length | into int)
    let valid = ($missing_count == 0) and ($errors_count == 0)

    {valid: $valid, missing: $missing, errors: $errors}
}

# Perform the actual installation
export def perform_installation [args: record] {
    let start_time = (date now)
    mut installed_components = []

    info $"Starting installation process" "install"

    # Install each selected component
    for component in $args.components {
        info $"Installing component: ($component)"
        if $args.dry_run {
            info $"Would install ($component) (dry run)"
            $installed_components = ($installed_components | append $component)
        } else {
            try {
                let result = (install_component $component)
                if $result.success {
                    $installed_components = ($installed_components | append $component)
                    info $"Successfully installed ($component)"
                } else {
                    error $"Failed to install ($component)" "install"
                }
            } catch { |err|
                error $"Error installing ($component)" "install"
            }
        }
    }

    # Create configuration files
    if not $args.dry_run {
        create_configuration_files
    }

    let end_time = (date now)
    let duration = (($end_time | into datetime) - ($start_time | into datetime) | into duration)

    {success: true, components: $installed_components, duration: $duration, start_time: $start_time, end_time: $end_time}
}

# Install a specific component
export def install_component [component: string] {
    match $component {
        "core" => { install_core_component }
        "tools" => { install_tools_component }
        "development" => { install_development_component }
        "gaming" => { install_gaming_component }
        "monitoring" => { install_monitoring_component }
        "security" => { install_security_component }
        _ => { error $"Unknown component: ($component)" "install" }
    }
}

# Install core component
export def install_core_component [] {
    info "Installing core component"

    # Create necessary directories
    let dirs = ["~/.config/nix-mox", "~/.local/bin", "~/.local/share/nix-mox"]
    for dir in $dirs {
        if not ($dir | path exists) {
            mkdir $dir
            info $"Created directory: ($dir)"
        }
    }

    # Copy core files (simulated)
    try {
        info "Copying core files..."
        # In a real implementation, this would copy actual files
        {success: true, error: null}
    } catch { |err|
        {success: false, error: $err}
    }
}

# Install tools component
export def install_tools_component [] {
    info "Installing tools component"
    {success: true, error: null}
}

# Install development component
export def install_development_component [] {
    info "Installing development component"
    {success: true, error: null}
}

# Install gaming component
export def install_gaming_component [] {
    info "Installing gaming component"
    {success: true, error: null}
}

# Install monitoring component
export def install_monitoring_component [] {
    info "Installing monitoring component"
    {success: true, error: null}
}

# Install security component
export def install_security_component [] {
    info "Installing security component"
    {success: true, error: null}
}

# Create configuration files
export def create_configuration_files [] {
    info "Creating configuration files"

    # Create default configuration
    let default_config = {
        logging: {
            level: "INFO",
            file: "~/.config/nix-mox/logs/nix-mox.log",
            format: "text"
        },
        platform: {
            auto_detect: true,
            preferred: "auto"
        },
        scripts: {
            timeout: 300,
            retry_attempts: 3
        },
        security: {
            validate_scripts: true,
            check_permissions: true
        },
        performance: {
            enable_monitoring: true,
            log_performance: true
        }
    }

    try {
        $default_config | to json | save "~/.config/nix-mox/config.json"
        info "Configuration file created"
    } catch { |err|
        error "Failed to create configuration file" "install"
    }
}

# Show post-installation instructions
export def show_post_install_instructions [install_result: record] {
    print $"\n(ansi green_bold)Installation Complete!(ansi reset)"
    print $"\n(ansi cyan)Installed components: (ansi reset)"
    for component in $install_result.components {
        print $"  ✓ ($component)"
    }

    print $"\n(ansi cyan)Next steps:(ansi reset)"
    print "  1. Add ~/.local/bin to your PATH"
    print "  2. Run 'nix-mox --help' to see available commands"
    print "  3. Check ~/.config/nix-mox/config.json for configuration options"
    print "  4. Run 'nix-mox health-check' to verify installation"

    print $"\n(ansi yellow)Documentation:(ansi reset)"
    print "  - User guide: docs/USAGE.md"
    print "  - Configuration: docs/guides/advanced-configuration.md"
    print "  - Troubleshooting: docs/guides/TROUBLESHOOTING.md"
}

# Simple platform detection
export def detect_platform [] {
    let os = (sys host | get name)
    match $os {
        "Linux" => "linux",
        "Windows" => "windows",
        "Darwin" => "darwin",
        _ => "unknown"
    }
}

# Show help
export def show_help [] {
    print "nix-mox Install Script"
    print ""
    print "Usage:"
    print "  install [options] [components]"
    print ""
    print "Options:"
    print "  -h, --help              Show this help message"
    print "  --dry-run              Show what would be installed without making changes"
    print "  -v, --verbose          Enable verbose output"
    print "  --strict-security      Fail installation if security validation fails"
    print "  -f, --force            Force installation even if components exist"
    print ""
    print "Components:"
    print "  --core                 Install core nix-mox functionality (default)"
    print "  --tools                Install additional tools"
    print "  --development          Install development tools"
    print "  --gaming               Install gaming support"
    print "  --monitoring           Install monitoring tools"
    print "  --security             Install security tools"
    print ""
    print "Examples:"
    print "  install                    # Install core component"
    print "  install --core --tools     # Install core and tools"
    print "  install --dry-run          # Show what would be installed"
    print "  install --verbose --force  # Verbose installation with force"
}

# Main execution
if ($env | get --ignore-errors NIXMOX_ARGS | default "" | str length) > 0 {
    let args = ($env.NIXMOX_ARGS | split row " ")
    main $args
} else {
    # For now, just run with empty args - this can be improved later
    main []
}
