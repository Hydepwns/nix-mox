#!/usr/bin/env nu

# nix-mox Unified Setup Script
# Replaces: setup-wizard.nu, setup-personal.nu, setup-gaming-wizard.nu, setup-gaming-workstation.nu

def main [] {
    print "🚀 nix-mox Setup"
    print "================"
    print "\nChoose setup type:"
    print "1. Personal configuration (recommended)"
    print "2. Gaming workstation"
    print "3. Development environment"
    print "4. Server setup"
    print "5. Minimal system"

    let choice = (input "Enter choice (1-5): " | str trim)

    match $choice {
        "1" => { setup-personal }
        "2" => { setup-gaming }
        "3" => { setup-development }
        "4" => { setup-server }
        "5" => { setup-minimal }
        _ => {
            print "Invalid choice. Exiting."
            exit 1
        }
    }
}

def setup-personal [] {
    print "\n🎯 Personal Configuration Setup"
    print "=============================="

    # Check if personal config already exists
    if (ls config/personal/user.nix | length) > 0 {
        print "⚠️  Personal configuration already exists!"
        let response = (input "Do you want to overwrite it? (y/N): " | str trim)
        if $response != "y" and $response != "Y" {
            print "Setup cancelled."
            exit 0
        }
    }

    # Get user input
    print "\n📝 Please provide your personal information:"
    let username = (input "Username: " | str trim)
    let email = (input "Email: " | str trim)
    let timezone = (input "Timezone (e.g., America/New_York): " | str trim)
    let hostname = (input "Hostname: " | str trim)
    let git_username = (input "Git username: " | str trim)
    let git_email = (input "Git email: " | str trim)
    let initial_password = (input "Initial password: " | str trim)

    # Create personal configuration
    print "\n🔧 Creating personal configuration..."

    # Update user.nix with personal settings
    let user_config = $"# User-specific Configuration
# Customize this file with your personal settings
{{ config, pkgs, ... }}:
let
  # Get personal settings from environment or use defaults
  personal = config.personal or {{
    username = \"$username\";
    email = \"$email\";
    timezone = \"$timezone\";
    hostname = \"$hostname\";
    gitUsername = \"$git_username\";
    gitEmail = \"$git_email\";
  }};
in
{{
  # System user configuration
  users.users.${{personal.username}} = {{
    isNormalUser = true;
    description = personal.username;
    extraGroups = [ \"wheel\" \"networkmanager\" \"video\" \"audio\" ];
    shell = pkgs.zsh;
    initialPassword = builtins.getEnv \"INITIAL_PASSWORD\" or \"$initial_password\";
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

    $user_config | save config/personal/user.nix

    # Create .env file
    let env_config = $"# nix-mox Environment Configuration
# Generated by setup.nu

# Environment type (personal, development, production)
NIXMOX_ENV=personal

# User configuration
NIXMOX_USERNAME=$username
NIXMOX_EMAIL=$email
NIXMOX_TIMEZONE=$timezone
NIXMOX_HOSTNAME=$hostname

# Git configuration
NIXMOX_GIT_USERNAME=$git_username
NIXMOX_GIT_EMAIL=$git_email

# Security
INITIAL_PASSWORD=$initial_password
GIT_EMAIL=$git_email"

    $env_config | save .env

    print "\n✅ Personal configuration created successfully!"
    print "\n📋 Next steps:"
    print "1. Choose a template: cp config/templates/development.nix config/nixos/configuration.nix"
    print "2. Build and switch: sudo nixos-rebuild switch --flake .#nixos"
}

def setup-gaming [] {
    print "\n🎮 Gaming Workstation Setup"
    print "==========================="

    # First setup personal config
    setup-personal

    # Choose gaming template
    cp config/templates/gaming.nix config/nixos/configuration.nix

    print "\n✅ Gaming workstation configured!"
    print "\n📋 Next steps:"
    print "1. Build and switch: sudo nixos-rebuild switch --flake .#nixos"
    print "2. Enter gaming shell: nix develop .#gaming"
    print "3. Launch gaming platforms: steam, lutris, heroic"
}

def setup-development [] {
    print "\n💻 Development Environment Setup"
    print "================================"

    # First setup personal config
    setup-personal

    # Choose development template
    cp config/templates/development.nix config/nixos/configuration.nix

    print "\n✅ Development environment configured!"
    print "\n📋 Next steps:"
    print "1. Build and switch: sudo nixos-rebuild switch --flake .#nixos"
    print "2. Enter development shell: nix develop .#development"
    print "3. Open IDE: vscode or cursor"
}

def setup-server [] {
    print "\n🖥️  Server Setup"
    print "==============="

    # First setup personal config
    setup-personal

    # Choose server template
    cp config/templates/server.nix config/nixos/configuration.nix

    print "\n✅ Server configured!"
    print "\n📋 Next steps:"
    print "1. Build and switch: sudo nixos-rebuild switch --flake .#nixos"
    print "2. Configure SSH keys in config/personal/secrets.nix"
    print "3. Set up monitoring: prometheus, grafana"
}

def setup-minimal [] {
    print "\n⚡ Minimal System Setup"
    print "======================="

    # First setup personal config
    setup-personal

    # Choose minimal template
    cp config/templates/minimal.nix config/nixos/configuration.nix

    print "\n✅ Minimal system configured!"
    print "\n📋 Next steps:"
    print "1. Build and switch: sudo nixos-rebuild switch --flake .#nixos"
    print "2. Add packages as needed: edit config/personal/user.nix"
}

# Show help
export def show_help [] {
    print "nix-mox Setup Script"
    print ""
    print "Usage:"
    print "  setup.nu                    # Interactive setup"
    print "  setup.nu --help             # Show this help"
    print ""
    print "Setup Types:"
    print "  1. Personal configuration (recommended)"
    print "  2. Gaming workstation"
    print "  3. Development environment"
    print "  4. Server setup"
    print "  5. Minimal system"
    print ""
    print "Examples:"
    print "  nu scripts/core/setup.nu    # Run interactive setup"
    print "  nu scripts/core/setup.nu --help  # Show help"
}

# Check for help flag
if ($env | get --ignore-errors ARGS | default [] | any { |arg| $arg == "--help" or $arg == "-h" }) {
    show_help
    exit 0
}

# Run the main function
main
