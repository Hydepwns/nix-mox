#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to prompt for input with default value
prompt_with_default() {
  local prompt="$1"
  local default="$2"
  local var_name="$3"

  echo -n "$prompt [$default]: "
  read -r input
  if [ -z "$input" ]; then
    eval "$var_name='$default'"
  else
    eval "$var_name='$input'"
  fi
}

# Function to validate input
validate_input() {
  local value="$1"
  local pattern="$2"
  local error_msg="$3"

  if [[ ! $value =~ $pattern ]]; then
    print_error "$error_msg"
    return 1
  fi
  return 0
}

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check if running as root
check_root() {
  if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    exit 1
  fi
}

# Function to check system requirements
check_requirements() {
  print_status "Checking system requirements..."
  
  local missing_deps=()
  
  if ! command_exists nix; then
    missing_deps+=("nix")
  fi
  
  if ! command_exists git; then
    missing_deps+=("git")
  fi
  
  if [ ${#missing_deps[@]} -ne 0 ]; then
    print_error "Missing required dependencies: ${missing_deps[*]}"
    print_status "Please install the missing dependencies and try again"
    exit 1
  fi
  
  print_success "All system requirements met"
}

# Function to create directory structure
create_directory_structure() {
  local config_dir="$1"
  
  print_status "Creating configuration directory structure..."
  mkdir -p "$config_dir"/{nixos,home,hardware}
  cd "$config_dir"
  
  print_success "Directory structure created in $config_dir"
}

# Function to backup existing configuration
backup_existing_config() {
  local config_dir="$1"
  
  if [ -d "$config_dir" ]; then
    print_warning "Directory $config_dir already exists"
    read -p "Do you want to backup existing configuration? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      local backup_dir="${config_dir}_backup_$(date +%Y%m%d_%H%M%S)"
      cp -r "$config_dir" "$backup_dir"
      print_success "Existing configuration backed up to $backup_dir"
    fi
  fi
} 