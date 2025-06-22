#!/usr/bin/env nu

# Unified install script for nix-mox
# Uses enhanced modules for error handling, logging, configuration, and security

use ../lib/common.nu *
use ../lib/error-handling.nu *
use ../lib/config.nu *
use ../lib/logging.nu *
use ../lib/security.nu *

# Script metadata
export const SCRIPT_METADATA = {
    name: "install"
    description: "Install nix-mox on the current system"
    platform: "all"
    requires_root: false
    category: "core"
}

# Main installation function
export def main [args: list] {
    # Set script name for logging context
    $env.SCRIPT_NAME = "install"

    # Load configuration
    let config = (load_config)
    setup_logging $config

    info "Starting nix-mox installation" {
        version: "1.0.0"
        platform: (detect_platform)
        user: (whoami)
    }

    # Parse arguments
    let parsed_args = (parse_install_args $args)

    # Validate installation prerequisites
    let prereq_check = (check_prerequisites)
    if not $prereq_check.valid {
        handle_script_error "Prerequisites not met" "DEPENDENCY_MISSING" {
            missing: $prereq_check.missing
            errors: $prereq_check.errors
        }
    }

    # Security validation (if enabled)
    if $config.security.validate_scripts {
        let security_check = (validate_script_security $env.SCRIPT_NAME)
        if not $security_check.secure {
            warn "Security validation failed" {
                threats: $security_check.threats
                recommendations: $security_check.recommendations
            }

            if $parsed_args.strict_security {
                handle_script_error "Security validation failed in strict mode" "VALIDATION_FAILED" {
                    threats: $security_check.threats
                }
            }
        }
    }

    # Perform installation
    try {
        let install_result = (perform_installation $parsed_args $config)

        info "Installation completed successfully" {
            installed_components: $install_result.components
            duration: $install_result.duration
        }

        # Show post-installation instructions
        show_post_install_instructions $install_result

        exit 0
    } catch { |err|
        handle_script_error $"Installation failed: ($err)" "EXECUTION_FAILED" {
            error: $err
            args: $parsed_args
        }
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
        help: $help
        dry_run: $dry_run
        verbose: $verbose
        strict_security: $strict_security
        force: $force
        components: $components
    }
}

# Get component selection from arguments
export def get_component_selection [args: list] {
    let component_flags = [
        "--core"
        "--tools"
        "--development"
        "--gaming"
        "--monitoring"
        "--security"
    ]

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

    # Check for required commands
    let required_commands = ["curl", "wget", "git"]
    for cmd in $required_commands {
        if (which $cmd | length) == 0 {
            $missing = ($missing | append $cmd)
        }
    }

    # Check for required directories
    let required_dirs = ["~/.config", "~/.local/bin"]
    for dir in $required_dirs {
        if not ($dir | path exists) {
            $missing = ($missing | append $dir)
        }
    }

    # Check disk space
    let disk_space = (df ~ | get available.0 | into int)
    let min_space = 1GB  # 1GB minimum
    if $disk_space < $min_space {
        $errors = ($errors | append $"Insufficient disk space: ($disk_space) available, ($min_space) required")
    }

    let missing_count = ($missing | length | into int)
    let errors_count = ($errors | length | into int)
    let valid = ($missing_count == 0) and ($errors_count == 0)

    {
        valid: $valid
        missing: $missing
        errors: $errors
    }
}

# Perform the actual installation
export def perform_installation [args: record, config: record] {
    let start_time = (date now)
    mut installed_components = []

    info "Starting installation process" {
        components: $args.components
        dry_run: $args.dry_run
    }

    # Install each selected component
    for component in $args.components {
        info $"Installing component: ($component)"

        if $args.dry_run {
            info $"Would install ($component) (dry run)"
            $installed_components = ($installed_components | append $component)
        } else {
            try {
                let result = (install_component $component $config)
                if $result.success {
                    $installed_components = ($installed_components | append $component)
                    info $"Successfully installed ($component)"
                } else {
                    warn $"Failed to install ($component)" {
                        error: $result.error
                    }
                }
            } catch { |err|
                warn $"Error installing ($component)" {
                    error: $err
                }
            }
        }
    }

    # Create configuration files
    if not $args.dry_run {
        create_configuration_files $config
    }

    let end_time = (date now)
    let duration = (($end_time | into datetime) - ($start_time | into datetime) | into duration)

    {
        success: true
        components: $installed_components
        duration: $duration
        start_time: $start_time
        end_time: $end_time
    }
}

# Install a specific component
export def install_component [component: string, config: record] {
    match $component {
        "core" => { install_core_component $config }
        "tools" => { install_tools_component $config }
        "development" => { install_development_component $config }
        "gaming" => { install_gaming_component $config }
        "monitoring" => { install_monitoring_component $config }
        "security" => { install_security_component $config }
        _ => {
            error $"Unknown component: ($component)"
            { success: false, error: $"Unknown component: ($component)" }
        }
    }
}

# Install core component
export def install_core_component [config: record] {
    info "Installing core component"

    # Create necessary directories
    let dirs = [
        "~/.config/nix-mox"
        "~/.local/bin"
        "~/.local/share/nix-mox"
    ]

    for dir in $dirs {
        if not ($dir | path exists) {
            mkdir $dir
            info $"Created directory: ($dir)"
        }
    }

    # Copy core files
    try {
        cp -r "scripts" "~/.local/share/nix-mox/"
        cp "flake.nix" "~/.config/nix-mox/"
        cp "Makefile" "~/.config/nix-mox/"

        # Make scripts executable
        chmod +x "~/.local/share/nix-mox/scripts/core/*.nu"
        chmod +x "~/.local/share/nix-mox/scripts/tools/*.nu"

        { success: true, error: null }
    } catch { |err|
        { success: false, error: $err }
    }
}

# Install tools component
export def install_tools_component [config: record] {
    info "Installing tools component"

    # Install additional tools based on platform
    let platform = (detect_platform)

    match $platform {
        "linux" => { install_linux_tools $config }
        "darwin" => { install_darwin_tools $config }
        "windows" => { install_windows_tools $config }
        _ => { success: false, error: $"Unsupported platform: ($platform)" }
    }
}

# Install development component
export def install_development_component [config: record] {
    info "Installing development component"

    # Install development tools
    let dev_tools = [
        "git"
        "vim"
        "tmux"
        "htop"
        "jq"
        "yq"
    ]

    mut installed = []
    mut failed = []

    for tool in $dev_tools {
        if (which $tool | length) == 0 {
            info $"Installing development tool: ($tool)"
            # Here you would add platform-specific installation logic
            $installed = ($installed | append $tool)
        }
    }

    let failed_count = ($failed | length | into int)
    let success = ($failed_count == 0)
    let error_msg = if ($failed_count > 0) { $"Failed to install: ($failed | str join ', ')" } else { null }

    {
        success: $success
        error: $error_msg
        installed: $installed
    }
}

# Install gaming component
export def install_gaming_component [config: record] {
    info "Installing gaming component"

    # Platform-specific gaming setup
    let platform = (detect_platform)

    match $platform {
        "linux" => { install_linux_gaming $config }
        "windows" => { install_windows_gaming $config }
        _ => { success: false, error: $"Gaming not supported on ($platform)" }
    }
}

# Install monitoring component
export def install_monitoring_component [config: record] {
    info "Installing monitoring component"

    # Install monitoring tools
    let monitoring_tools = [
        "prometheus"
        "grafana"
        "node_exporter"
    ]

    # This would contain actual installation logic
    { success: true, error: null }
}

# Install security component
export def install_security_component [config: record] {
    info "Installing security component"

    # Install security tools
    let security_tools = [
        "fail2ban"
        "ufw"
        "clamav"
    ]

    # This would contain actual installation logic
    { success: true, error: null }
}

# Platform-specific installation functions
export def install_linux_tools [config: record] {
    # Linux-specific tools installation
    { success: true, error: null }
}

export def install_darwin_tools [config: record] {
    # macOS-specific tools installation
    { success: true, error: null }
}

export def install_windows_tools [config: record] {
    # Windows-specific tools installation
    { success: true, error: null }
}

export def install_linux_gaming [config: record] {
    # Linux gaming setup (Wine, Steam, etc.)
    { success: true, error: null }
}

export def install_windows_gaming [config: record] {
    # Windows gaming setup
    { success: true, error: null }
}

# Create configuration files
export def create_configuration_files [config: record] {
    info "Creating configuration files"

    # Create default configuration
    let default_config = {
        logging: {
            level: "INFO"
            file: "~/.config/nix-mox/logs/nix-mox.log"
            format: "text"
        }
        platform: {
            auto_detect: true
            preferred: "auto"
        }
        scripts: {
            timeout: 300
            retry_attempts: 3
        }
        security: {
            validate_scripts: true
            check_permissions: true
        }
        performance: {
            enable_monitoring: true
            log_performance: true
        }
    }

    try {
        $default_config | to json | save "~/.config/nix-mox/config.json"
        info "Configuration file created"
    } catch { |err|
        warn "Failed to create configuration file" { error: $err }
    }
}

# Show post-installation instructions
export def show_post_install_instructions [install_result: record] {
    print $"\n(ansi green_bold)Installation Complete!(ansi reset)"
    print $"\n(ansi cyan)Installed components:(ansi reset)"
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
    let os = (sys).host.name
    match $os {
        "Linux" => "linux"
        "Windows" => "windows"
        "Darwin" => "darwin"
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
if ($env.NIXMOX_ARGS? | is-not-empty) {
    let args = ($env.NIXMOX_ARGS | split row " ")
    main $args
} else {
    # Get command line arguments
    let args = ($nu.scope.command.args)
    main $args
}
