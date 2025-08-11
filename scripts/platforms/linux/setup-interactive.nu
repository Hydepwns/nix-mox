#!/usr/bin/env nu
# setup-interactive.nu - Interactive nix-mox Setup Script
# Usage: nu setup-interactive.nu [--dry-run] [--help]
#
# - Interactive setup wizard for nix-mox configuration
# - Guides users through personal, system, and environment configuration
# - Creates configuration files and sets up the development environment
# - Is idempotent and safe to re-run
use ../lib/common.nu

# --- Global Variables ---
const CONFIG_DIR = "config"
const TEMPLATES_DIR = $CONFIG_DIR + "/templates"
const PERSONAL_DIR = $CONFIG_DIR + "/personal"
const NIXOS_DIR = $CONFIG_DIR + "/nixos"

def update-state [field: string, value: any] {
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
                log_error $"Unknown option: ($arg)"
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
    print $"\n($GREEN)🚀 nix-mox Interactive Setup($NC)"
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
    print $"\n($BLUE)📋 Choose Setup Type($NC)"
    print "=================="
    print "1. Personal configuration (recommended for new users)"
    print "2. Gaming workstation (includes gaming tools and optimizations)"
    print "3. Development environment (includes development tools and IDEs)"
    print "4. Server setup (minimal configuration for servers)"
    print "5. Minimal system (bare minimum configuration)"
    print ""

    let choice = (input "Enter choice (1-5): " | str trim)

    match $choice {
        "1" => { "personal" }
        "2" => { "gaming" }
        "3" => { "development" }
        "4" => { "server" }
        "5" => { "minimal" }
        _ => {
            log_error "Invalid choice. Please enter a number between 1 and 5."
            select_setup_type
        }
    }
}

def collect_personal_info [] {
    print $"\n($BLUE)👤 Personal Information($NC)"
    print "======================="
    print "Please provide your personal information:"
    print ""

    let username = (input "Username (for system account): " | str trim)
    let email = (input "Email address: " | str trim)
    let git_username = (input "Git username: " | str trim)
    let git_email = (input "Git email: " | str trim)
    let initial_password = (input "Initial password (for system account): " | str trim)

    {
        username: $username
        email: $email
        git_username: $git_username
        git_email: $git_email
        initial_password: $initial_password
    }
}

def collect_system_info [] {
    print $"\n($BLUE)🖥️  System Information($NC)"
    print "====================="
    print "Please provide system configuration:"
    print ""

    let hostname = (input "Hostname: " | str trim)
    let timezone = (input "Timezone (e.g., America/New_York): " | str trim)

    {
        hostname: $hostname
        timezone: $timezone
    }
}

def setup_environment [] {
    print $"\n($BLUE)🔧 Environment Setup($NC)"
    print "==================="

    # Check if .envrc exists and setup direnv
    if not (file_exists ".envrc") {
        log_info "Setting up direnv configuration..."
        if not $env.STATE.dry_run {
            "use flake" | save .envrc
            $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append ".envrc"))
        } else {
            log_dryrun "Would create .envrc file"
        }
    }

    # Check if devenv is available
    if not (file_exists "devenv.nix") {
        log_warn "devenv.nix not found. This may affect development environment setup."
    }

    # Setup Hydepwns dotfiles if available
    let dotfiles_script = "scripts/setup/setup-hydepwns-dotfiles.sh"
    if (file_exists $dotfiles_script) {
        let response = (input "Setup Hydepwns dotfiles integration? (y/N): " | str trim)
        if $response == "y" or $response == "Y" {
            log_info "Setting up Hydepwns dotfiles..."
            if not $env.STATE.dry_run {
                try {
                    bash $dotfiles_script
                    log_success "Hydepwns dotfiles setup complete"
                } catch {
                    log_warn "Failed to setup Hydepwns dotfiles: ($env.LAST_ERROR)"
                }
            } else {
                log_dryrun "Would run Hydepwns dotfiles setup script"
            }
        }
    }
}

def select_template [setup_type: string] {
    print $"\n($BLUE)📄 Template Selection($NC)"
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
        let response = (input $"Use recommended template? (Y/n): " | str trim)

        if $response == "" or $response == "y" or $response == "Y" {
            $default_template
        } else {
            # Show available templates
            print "\nAvailable templates:"
            for template in (ls ($TEMPLATES_DIR + "/*.nix") | get name | path basename) {
                print $"  • ($template)"
            }
            let custom_template = (input "Enter template name: " | str trim)
            if (file_exists ($TEMPLATES_DIR + "/" + $custom_template)) {
                $custom_template
            } else {
                log_error $"Template ($custom_template) not found. Using default."
                $default_template
            }
        }
    } else {
        log_warn $"Recommended template ($default_template) not found. Using development.nix"
        "development.nix"
    }
}

def create_configuration_files [] {
    print $"\n($BLUE)📝 Creating Configuration Files($NC)"
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

    log_success "Configuration files created successfully!"
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

  # Home Manager configuration
  home-manager.users.${{personal.username}} = {{
    home.stateVersion = \"23.11\";
    home.username = personal.username;
    home.homeDirectory = \"/home/${{personal.username}}\";

    # Shell configuration
    programs.zsh = {{
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {{
        ll = \"ls -l\";
        la = \"ls -la\";
        nrs = \"sudo nixos-rebuild switch --flake .#nixos\";
        nfu = \"nix flake update\";
        ngc = \"nix-collect-garbage -d\";
      }};

      initContent = \'\'
        export EDITOR=vim
      \'\';
    }};

    # Git configuration
    programs.git = {{
      enable = true;
      userName = personal.gitUsername;
      userEmail = personal.gitEmail;
      extraConfig = {{
        init.defaultBranch = \"main\";
        push.autoSetupRemote = true;
      }};
    }};

    # Common programs
    programs.firefox.enable = true;
    programs.vscode.enable = true;
  }};
}}"

    let config_path = $PERSONAL_DIR + "/user.nix"
    if not $env.STATE.dry_run {
        $user_config | save $config_path
        $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $config_path))
        log_info $"Created personal configuration: ($config_path)"
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
        log_info "Created environment configuration: .env"
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
            log_info $"Copied template ($env.STATE.template) to ($config_path)"
        } else {
            log_dryrun $"Would copy template ($env.STATE.template) to ($config_path)"
        }
    } else {
        log_error $"Template file ($template_path) not found!"
    }
}

def print_final_steps [] {
    print $"\n($GREEN)✅ Setup Complete!($NC)"
    print "=================="
    print ""
    print "Your nix-mox environment has been configured successfully!"
    print ""
    print $"\n($YELLOW)📋 Next Steps:($NC)"
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
        print $"\n($BLUE)🎮 Gaming Setup Notes:($NC)"
        print "• Enter gaming shell: nix develop .#gaming"
        print "• Launch gaming platforms: steam, lutris, heroic"
    }

    if $env.STATE.setup_type == "development" {
        print $"\n($BLUE)💻 Development Setup Notes:($NC)"
        print "• Enter development shell: nix develop .#development"
        print "• Open IDE: vscode or cursor"
    }

    print $"\n($GREEN)🎉 Enjoy your new nix-mox environment!($NC)"
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
} catch {
    log_error $"Setup failed: ($env.LAST_ERROR)"
    exit 1
}
