#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu *
use ../../lib/logging.nu *

# setup-interactive.nu - Interactive nix-mox Setup Script
# Usage: nu setup-interactive.nu [--dry-run] [--help]
#
# - Interactive setup wizard for nix-mox configuration
# - Guides users through personal, system, and environment configuration
# - Creates configuration files and sets up the development environment
# - Is idempotent and safe to re-run

# --- Global Variables ---
const CONFIG_DIR = "config"
const TEMPLATES_DIR = $CONFIG_DIR + "/templates"
const PERSONAL_DIR = $CONFIG_DIR + "/personal"
const NIXOS_DIR = $CONFIG_DIR + "/nixos"

def update_state [field: string, value: any] {
    $env.STATE = ($env.STATE | upsert $field $value)
}

def main [] {
    $env.STATE = {
        dry_run: false
        setup_type: ""
        username: ""
        email: ""
        timezone: ""
        hostname: ""
        git_username: ""
        git_email: ""
        initial_password: ""
        created_files: []
    }

    # --- Argument Parsing ---
    let args = $env._args
    for arg in $args {
        match $arg {
            "--dry-run" => {
                $env.STATE = ($env.STATE | upsert dry_run true)
            }
            "--help" | "-h" => {
                usage
            }
            _ => {
                error $"Unknown option: ($arg)"
                usage
            }
        }
    }

    if $env.STATE.dry_run {
        log_dryrun "Dry-run mode enabled. No files will be changed."
    }

    # --- Welcome and Setup Type Selection ---
    print_welcome
    let setup_type = select_setup_type
    $env.STATE = ($env.STATE | upsert setup_type $setup_type)

    # --- Personal Configuration ---
    let personal_config = collect_personal_info
    $env.STATE = ($env.STATE | merge $personal_config)

    # --- System Configuration ---
    let system_config = collect_system_info
    $env.STATE = ($env.STATE | merge $system_config)

    # --- Environment Setup ---
    setup_environment

    # --- Template Selection ---
    let template = select_template $setup_type
    $env.STATE = ($env.STATE | upsert template $template)

    # --- File Creation ---
    create_configuration_files

    # --- Final Steps ---
    print_final_steps

    return $env.STATE
}

def print_welcome [] {
    print $"\n(ansi green)🚀 nix-mox Interactive Setup(ansi reset)"
    print "================================"
    print ""
    print "Welcome to the nix-mox interactive setup wizard!"
    print "This script will guide you through configuring your nix-mox environment."
    print ""
    print "What this setup will do:"
    print "• Collect your personal information"
    print "• Configure system settings"
    print "• Set up development environment"
    print "• Create configuration files"
    print "• Choose appropriate templates"
    print ""
}

def select_setup_type [] {
    print $"\n(ansi blue)📋 Choose Setup Type(ansi reset)"
    print "=================="
    print "1. Personal configuration (recommended for new users)"
    print "2. Gaming workstation (includes gaming tools and optimizations)"
    print "3. Development environment (includes development tools and IDEs)"
    print "4. Server setup (minimal configuration for servers)"
    print "5. Minimal system (bare minimum configuration)"
    print ""

    print "Enter choice (1-5):"
    let choice = (input "" | str trim)

    match $choice {
        "1" => { "personal" }
        "2" => { "gaming" }
        "3" => { "development" }
        "4" => { "server" }
        "5" => { "minimal" }
        _ => {
            error "Invalid choice. Please enter a number between 1 and 5."
            select_setup_type
        }
    }
}

def collect_personal_info [] {
    print $"\n(ansi blue)👤 Personal Information(ansi reset)"
    print "======================="
    print "Please provide your personal information:"
    print ""

    print "Username (for system account):"
    let username = (input "" | str trim)
    print "Email address:"
    let email = (input "" | str trim)
    print "Git username:"
    let git_username = (input "" | str trim)
    print "Git email:"
    let git_email = (input "" | str trim)
    print "Initial password (for system account):"
    let initial_password = (input "" | str trim)

    {
        username: $username
        email: $email
        git_username: $git_username
        git_email: $git_email
        initial_password: $initial_password
    }
}

def collect_system_info [] {
    print $"\n(ansi blue)🖥️  System Information(ansi reset)"
    print "====================="
    print "Please provide system configuration:"
    print ""

    print "Hostname:"
    let hostname = (input "" | str trim)
    print "Timezone (e.g., America/New_York):"
    let timezone = (input "" | str trim)

    {
        hostname: $hostname
        timezone: $timezone
    }
}

def setup_environment [] {
    print $"\n(ansi blue)🔧 Environment Setup(ansi reset)"
    print "==================="

    # Check if .envrc exists and setup direnv
    if not (file_exists ".envrc") {
        info "Setting up direnv configuration..."
        if not $env.STATE.dry_run {
            "use flake" | save .envrc
            $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append ".envrc"))
        } else {
            log_dryrun "Would create .envrc file"
        }
    }

    # Check if devenv is available
    if not (file_exists "devenv.nix") {
        warn "devenv.nix not found. This may affect development environment setup."
    }

    # Setup Hydepwns dotfiles if available
    let dotfiles_script = "scripts/setup/setup-hydepwns-dotfiles.sh"
    if (file_exists $dotfiles_script) {
        print "Setup Hydepwns dotfiles integration? (y/N):"
        let response = (input "" | str trim)
        if $response == "y" or $response == "Y" {
            info "Setting up Hydepwns dotfiles..."
            if not $env.STATE.dry_run {
                try {
                    bash $dotfiles_script
                    success "Hydepwns dotfiles setup complete"
                } catch {
                    warn "Failed to setup Hydepwns dotfiles: ($env.LAST_ERROR)"
                }
            } else {
                log_dryrun "Would run Hydepwns dotfiles setup script"
            }
        }
    }
}

def select_template [setup_type: string] {
    print $"\n(ansi blue)📄 Template Selection(ansi reset)"
    print "====================="

    let template_map = {
        personal: "development.nix"
        gaming: "gaming.nix"
        development: "development.nix"
        server: "server.nix"
        minimal: "minimal.nix"
    }

    let default_template = ($template_map | get $setup_type)

    if (file_exists ($TEMPLATES_DIR + "/" + $default_template)) {
        print $"Recommended template for ($setup_type) setup: ($default_template)"
        print "Use recommended template? (Y/n):"
        let response = (input "" | str trim)

        if $response == "" or $response == "y" or $response == "Y" {
            $default_template
        } else {
            # Show available templates
            print "\nAvailable templates:"
            for template in (ls ($TEMPLATES_DIR + "/*.nix") | get name | path basename) {
                print $"  • ($template)"
            }
            print "Enter template name:"
            let custom_template = (input "" | str trim)
            if (file_exists ($TEMPLATES_DIR + "/" + $custom_template)) {
                $custom_template
            } else {
                error $"Template ($custom_template) not found. Using default."
                $default_template
            }
        }
    } else {
        warn $"Recommended template ($default_template) not found. Using development.nix"
        "development.nix"
    }
}

def create_configuration_files [] {
    print $"\n(ansi blue)📝 Creating Configuration Files(ansi reset)"
    print "================================"

    # Create directories if they don't exist
    for dir in [$PERSONAL_DIR, $NIXOS_DIR] {
        if not (dir_exists $dir) {
            if not $env.STATE.dry_run {
                mkdir $dir
                $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $dir))
            } else {
                log_dryrun $"Would create directory: ($dir)"
            }
        }
    }

    # Create personal configuration
    create_personal_config

    # Create environment configuration
    create_env_config

    # Copy template to configuration
    copy_template

    success "Configuration files created successfully!"
}

def create_personal_config [] {
    let user_config = $"# User-specific Configuration
# Generated by setup-interactive.nu
# Customize this file with your personal settings

{{ config, pkgs, ... }}:
let
  # Personal settings
  personal = {{
    username = \"$env.STATE.username\";
    email = \"$env.STATE.email\";
    timezone = \"$env.STATE.timezone\";
    hostname = \"$env.STATE.hostname\";
    gitUsername = \"$env.STATE.git_username\";
    gitEmail = \"$env.STATE.git_email\";
  }};
in
{{
  # System user configuration
  users.users.${{personal.username}} = {{
    isNormalUser = true;
    description = personal.username;
    extraGroups = [ \"wheel\" \"networkmanager\" \"video\" \"audio\" ];
    shell = pkgs.zsh;
    initialPassword = \"$env.STATE.initial_password\";
  }};

  # System configuration
  networking.hostName = personal.hostname;
  time.timeZone = personal.timezone;

  # User configuration managed by chezmoi
  # See ~/.local/share/chezmoi for user-specific configurations
}}"

    let config_path = $PERSONAL_DIR + "/user.nix"
    if not $env.STATE.dry_run {
        $user_config | save $config_path
        $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $config_path))
        info $"Created personal configuration: ($config_path)"
    } else {
        log_dryrun $"Would create personal configuration: ($config_path)"
    }
}

def create_env_config [] {
    let env_config = $"# nix-mox Environment Configuration
# Generated by setup-interactive.nu

# Environment type
NIXMOX_ENV=$env.STATE.setup_type

# User configuration
NIXMOX_USERNAME=$env.STATE.username
NIXMOX_EMAIL=$env.STATE.email
NIXMOX_TIMEZONE=$env.STATE.timezone
NIXMOX_HOSTNAME=$env.STATE.hostname

# Git configuration
NIXMOX_GIT_USERNAME=$env.STATE.git_username
NIXMOX_GIT_EMAIL=$env.STATE.git_email

# Security
INITIAL_PASSWORD=$env.STATE.initial_password
GIT_EMAIL=$env.STATE.git_email"

    if not $env.STATE.dry_run {
        $env_config | save .env
        $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append ".env"))
        info "Created environment configuration: .env"
    } else {
        log_dryrun "Would create environment configuration: .env"
    }
}

def copy_template [] {
    let template_path = $TEMPLATES_DIR + "/" + $env.STATE.template
    let config_path = $NIXOS_DIR + "/configuration.nix"

    if (file_exists $template_path) {
        if not $env.STATE.dry_run {
            cp $template_path $config_path
            $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $config_path))
            info $"Copied template ($env.STATE.template) to ($config_path)"
        } else {
            log_dryrun $"Would copy template ($env.STATE.template) to ($config_path)"
        }
    } else {
        error $"Template file ($template_path) not found!"
    }
}

def print_final_steps [] {
    print $"\n(ansi green)✅ Setup Complete!(ansi reset)"
    print "=================="
    print ""
    print "Your nix-mox environment has been configured successfully!"
    print ""
    print $"\n(ansi yellow)📋 Next Steps:(ansi reset)"
    print "1. Review your configuration files:"
    print $"   • Personal config: ($PERSONAL_DIR)/user.nix"
    print $"   • System config: ($NIXOS_DIR)/configuration.nix"
    print "   • Environment: .env"
    print ""
    print "2. Build and switch to your configuration:"
    print "   sudo nixos-rebuild switch --flake .#nixos"
    print ""
    print "3. Enter development environment:"
    print "   nix develop"
    print ""
    print "4. Test your setup:"
    print "   nix flake check"
    print ""

    if $env.STATE.setup_type == "gaming" {
        print $"\n(ansi blue)🎮 Gaming Setup Notes:(ansi reset)"
        print "• Enter gaming shell: nix develop .#gaming"
        print "• Launch gaming platforms: steam, lutris, heroic"
    }

    if $env.STATE.setup_type == "development" {
        print $"\n(ansi blue)💻 Development Setup Notes:(ansi reset)"
        print "• Enter development shell: nix develop .#development"
        print "• Open IDE: vscode or cursor"
    }

    print $"\n(ansi green)🎉 Enjoy your new nix-mox environment!(ansi reset)"
}

def usage [] {
    print "Usage: nu setup-interactive.nu [OPTIONS]"
    print ""
    print "Interactive setup wizard for nix-mox configuration."
    print ""
    print "Options:"
    print "  --dry-run    Show what would be done, but make no changes"
    print "  --help, -h   Show this help message"
    print ""
    print "This script guides you through:"
    print "• Personal information collection"
    print "• System configuration"
    print "• Environment setup"
    print "• Template selection"
    print "• Configuration file creation"
    exit 0
}

# --- Execution ---
try {
    main
} catch { | err|
    error $"Setup failed: ($err.msg)"
    exit 1
}
