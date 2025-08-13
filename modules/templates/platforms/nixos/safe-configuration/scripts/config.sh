#!/usr/bin/env bash

# Source utilities
source "$(dirname "$0")/utils.sh"

# Function to get system configuration
get_system_config() {
  print_status "Getting system configuration..."
  
  # Get hostname
  prompt_with_default "Enter your desired hostname" "hydebox" hostname
  validate_input "$hostname" "^[a-zA-Z0-9-]+$" "Hostname must contain only letters, numbers, and hyphens"
  
  # Get username
  prompt_with_default "Enter your username" "hyde" username
  validate_input "$username" "^[a-z_][a-z0-9_-]*$" "Username must start with a letter or underscore and contain only lowercase letters, numbers, underscores, and hyphens"
  
  # Get timezone
  prompt_with_default "Enter your timezone" "America/New_York" timezone
  
  # Get SSH key
  prompt_with_default "Enter your SSH public key (or leave empty to skip)" "" ssh_key
  
  print_success "System configuration collected"
}

# Function to select display manager
select_display_manager() {
  echo
  print_status "Choose your display manager:"
  echo "1) LightDM (lightweight, recommended)"
  echo "2) SDDM (KDE's display manager)"
  echo "3) GDM (GNOME's display manager)"
  
  local display_manager_choice
  prompt_with_default "Enter your choice (1-3)" "1" display_manager_choice
  
  case $display_manager_choice in
    1)
      display_manager="lightdm"
      ;;
    2)
      display_manager="sddm"
      ;;
    3)
      display_manager="gdm"
      ;;
    *)
      print_error "Invalid choice. Using LightDM as default."
      display_manager="lightdm"
      ;;
  esac
  
  print_success "Selected display manager: $display_manager"
}

# Function to select desktop environment
select_desktop_environment() {
  echo
  print_status "Choose your desktop environment:"
  echo "1) GNOME (modern, feature-rich)"
  echo "2) Plasma 6 (KDE's desktop environment)"
  echo "3) XFCE (lightweight, traditional)"
  echo "4) i3 (tiling window manager)"
  echo "5) Awesome (tiling window manager)"
  
  local desktop_choice
  prompt_with_default "Enter your choice (1-5)" "1" desktop_choice
  
  case $desktop_choice in
    1)
      desktop_environment="gnome"
      ;;
    2)
      desktop_environment="plasma6"
      ;;
    3)
      desktop_environment="xfce"
      ;;
    4)
      desktop_environment="i3"
      ;;
    5)
      desktop_environment="awesome"
      ;;
    *)
      print_error "Invalid choice. Using GNOME as default."
      desktop_environment="gnome"
      ;;
  esac
  
  print_success "Selected desktop environment: $desktop_environment"
}

# Function to select graphics driver
select_graphics_driver() {
  echo
  print_status "Choose your graphics driver:"
  echo "1) Auto-detect (recommended)"
  echo "2) NVIDIA proprietary"
  echo "3) AMD (amdgpu)"
  echo "4) Intel (i915)"
  
  local graphics_choice
  prompt_with_default "Enter your choice (1-4)" "1" graphics_choice
  
  case $graphics_choice in
    1)
      graphics_driver="auto"
      ;;
    2)
      graphics_driver="nvidia"
      ;;
    3)
      graphics_driver="amdgpu"
      ;;
    4)
      graphics_driver="intel"
      ;;
    *)
      print_error "Invalid choice. Using auto-detect as default."
      graphics_driver="auto"
      ;;
  esac
  
  print_success "Selected graphics driver: $graphics_driver"
}

# Function to configure additional features
configure_additional_features() {
  echo
  print_status "Configure additional features:"
  
  # Steam for gaming
  read -p "Enable Steam for gaming? (y/N): " -n 1 -r
  echo
  enable_steam=$([[ $REPLY =~ ^[Yy]$ ]] && echo "true" || echo "false")
  
  # Docker
  read -p "Enable Docker containerization? (y/N): " -n 1 -r
  echo
  enable_docker=$([[ $REPLY =~ ^[Yy]$ ]] && echo "true" || echo "false")
  
  # SSH server
  read -p "Enable SSH server? (y/N): " -n 1 -r
  echo
  enable_ssh=$([[ $REPLY =~ ^[Yy]$ ]] && echo "true" || echo "false")
  
  # Firewall
  read -p "Enable firewall? (y/N): " -n 1 -r
  echo
  enable_firewall=$([[ $REPLY =~ ^[Yy]$ ]] && echo "true" || echo "false")
  
  # Messaging applications
  read -p "Enable messaging applications (Signal, Telegram, Discord)? (y/N): " -n 1 -r
  echo
  enable_messaging=$([[ $REPLY =~ ^[Yy]$ ]] && echo "true" || echo "false")
  
  # Video calling applications
  read -p "Enable video calling applications (Zoom, Teams, Skype)? (y/N): " -n 1 -r
  echo
  enable_video_calling=$([[ $REPLY =~ ^[Yy]$ ]] && echo "true" || echo "false")
  
  # Email clients
  read -p "Enable email clients (Thunderbird, Evolution)? (y/N): " -n 1 -r
  echo
  enable_email_clients=$([[ $REPLY =~ ^[Yy]$ ]] && echo "true" || echo "false")
  
  print_success "Additional features configured"
}

# Function to get Git configuration
get_git_config() {
  echo
  print_status "Git configuration:"
  
  prompt_with_default "Enter your Git user name" "Your Name" git_user_name
  prompt_with_default "Enter your Git user email" "your.email@example.com" git_user_email
  
  print_success "Git configuration collected"
} 