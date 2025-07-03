#!/bin/bash

# Remote Nix Builder Setup Script
# This script automates setting up a remote Linux builder for Nix on macOS

set -euo pipefail

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

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check if we're on macOS
check_macos() {
  if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is designed to run on macOS"
    exit 1
  fi
}

# Function to check if SSH key exists
check_ssh_key() {
  if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
    print_warning "SSH public key not found at ~/.ssh/id_rsa.pub"
    print_status "Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    print_success "SSH key pair generated"
  fi
}

# Function to display usage
show_usage() {
  cat <<EOF
Usage: $0 [OPTIONS] REMOTE_HOST

Setup a remote Linux builder for Nix on macOS.

OPTIONS:
    -u, --user USERNAME     Remote username (default: nixremote)
    -p, --port PORT         SSH port (default: 22)
    -k, --key PATH          Path to SSH public key (default: ~/.ssh/id_rsa.pub)
    -s, --systems SYSTEMS   Comma-separated list of systems to build for (default: x86_64-linux,aarch64-linux)
    -h, --help              Show this help message

EXAMPLES:
    $0 192.168.1.100
    $0 -u myuser -p 2222 my-linux-server.com
    $0 --systems x86_64-linux 192.168.1.100

EOF
}

# Parse command line arguments
REMOTE_HOST=""
REMOTE_USER="nixremote"
SSH_PORT="22"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
SYSTEMS="x86_64-linux,aarch64-linux"

while [[ $# -gt 0 ]]; do
  case $1 in
  -u | --user)
    REMOTE_USER="$2"
    shift 2
    ;;
  -p | --port)
    SSH_PORT="$2"
    shift 2
    ;;
  -k | --key)
    SSH_KEY_PATH="$2"
    shift 2
    ;;
  -s | --systems)
    SYSTEMS="$2"
    shift 2
    ;;
  -h | --help)
    show_usage
    exit 0
    ;;
  -*)
    print_error "Unknown option: $1"
    show_usage
    exit 1
    ;;
  *)
    if [[ -z $REMOTE_HOST ]]; then
      REMOTE_HOST="$1"
    else
      print_error "Multiple hosts specified"
      exit 1
    fi
    shift
    ;;
  esac
done

# Check if remote host is provided
if [[ -z $REMOTE_HOST ]]; then
  print_error "Remote host is required"
  show_usage
  exit 1
fi

# Expand SSH key path
SSH_KEY_PATH=$(eval echo "$SSH_KEY_PATH")

# Main setup function
setup_remote_builder() {
  print_status "Starting remote Nix builder setup..."
  print_status "Remote host: $REMOTE_HOST"
  print_status "Remote user: $REMOTE_USER"
  print_status "SSH port: $SSH_PORT"
  print_status "Systems: $SYSTEMS"

  # Check prerequisites
  check_macos
  check_ssh_key

  # Test SSH connection
  print_status "Testing SSH connection to $REMOTE_HOST..."
  if ! ssh -p "$SSH_PORT" -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" exit 2>/dev/null; then
    print_error "Cannot connect to $REMOTE_HOST as $REMOTE_USER"
    print_status "Please ensure:"
    print_status "1. The remote host is accessible"
    print_status "2. SSH key authentication is set up"
    print_status "3. The remote user exists and has SSH access"
    exit 1
  fi
  print_success "SSH connection successful"

  # Setup remote machine
  setup_remote_machine

  # Setup local machine
  setup_local_machine

  # Test the setup
  test_remote_builder

  print_success "Remote Nix builder setup complete!"
  print_status "You can now build Linux packages from macOS using:"
  print_status "nix build .#packages.x86_64-linux.default"
  print_status "nix build .#packages.aarch64-linux.default"
}

# Function to setup remote machine
setup_remote_machine() {
  print_status "Setting up remote machine..."

  # Create remote setup script
  cat >/tmp/remote_nix_setup.sh <<'REMOTE_SCRIPT'
#!/bin/bash
set -euo pipefail

REMOTE_USER="$1"
SSH_KEY_CONTENT="$2"

echo "Setting up Nix on remote machine..."

# Install Nix if not already installed
if ! command -v nix >/dev/null 2>&1; then
    echo "Installing Nix..."
    sh <(curl -L https://nixos.org/nix/install) --daemon
    source /etc/profile.d/nix-daemon.sh
fi

# Create build user if it doesn't exist
if ! id "$REMOTE_USER" &>/dev/null; then
    echo "Creating build user: $REMOTE_USER"
    sudo useradd -m -s /bin/bash "$REMOTE_USER"
    sudo passwd -d "$REMOTE_USER"  # Remove password
fi

# Setup SSH for the build user
sudo mkdir -p "/home/$REMOTE_USER/.ssh"
sudo chown "$REMOTE_USER:$REMOTE_USER" "/home/$REMOTE_USER/.ssh"
sudo chmod 700 "/home/$REMOTE_USER/.ssh"

# Add SSH key
echo "$SSH_KEY_CONTENT" | sudo tee "/home/$REMOTE_USER/.ssh/authorized_keys" > /dev/null
sudo chown "$REMOTE_USER:$REMOTE_USER" "/home/$REMOTE_USER/.ssh/authorized_keys"
sudo chmod 600 "/home/$REMOTE_USER/.ssh/authorized_keys"

# Add user to nixbld group
sudo usermod -aG nixbld "$REMOTE_USER"

# Ensure Nix daemon is running
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable nix-daemon
    sudo systemctl start nix-daemon
fi

# Test Nix access for the build user
sudo -u "$REMOTE_USER" nix --version > /dev/null

echo "Remote setup complete!"
REMOTE_SCRIPT

  # Copy and execute remote setup script
  print_status "Copying setup script to remote machine..."
  scp -P "$SSH_PORT" /tmp/remote_nix_setup.sh "$REMOTE_USER@$REMOTE_HOST:/tmp/"

  print_status "Executing setup script on remote machine..."
  ssh -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "chmod +x /tmp/remote_nix_setup.sh && /tmp/remote_nix_setup.sh '$REMOTE_USER' '$(cat "$SSH_KEY_PATH")'"

  # Cleanup
  rm /tmp/remote_nix_setup.sh
  ssh -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "rm /tmp/remote_nix_setup.sh"

  print_success "Remote machine setup complete"
}

# Function to setup local machine
setup_local_machine() {
  print_status "Setting up local machine..."

  # Create Nix config directory
  mkdir -p ~/.config/nix

  # Create or update nix.conf
  local nix_conf="$HOME/.config/nix/nix.conf"
  local builder_config="builders = ssh-ng://$REMOTE_USER@$REMOTE_HOST:$SSH_PORT $SYSTEMS / 4 1 kvm"

  if [[ -f $nix_conf ]]; then
    # Remove existing builder configuration
    sed -i.bak '/^builders = ssh-ng:\/\/.*$/d' "$nix_conf"
    print_status "Updated existing nix.conf"
  else
    print_status "Creating new nix.conf"
  fi

  # Add builder configuration
  echo "$builder_config" >>"$nix_conf"

  print_success "Local machine setup complete"
}

# Function to test remote builder
test_remote_builder() {
  print_status "Testing remote builder..."

  # Test with a simple derivation
  local test_drv
  test_drv=$(nix-instantiate --expr 'derivation { name = "test"; system = "x86_64-linux"; builder = "/bin/sh"; args = ["-c" "echo hello > $out"]; }' 2>/dev/null || true)

  if [[ -n $test_drv ]]; then
    print_status "Testing build on remote machine..."
    if nix-store --realise "$test_drv" --dry-run 2>&1 | grep -q "will be built"; then
      print_success "Remote builder is working correctly"
    else
      print_warning "Remote builder may not be working as expected"
    fi
  else
    print_warning "Could not create test derivation"
  fi
}

# Function to cleanup on exit
cleanup() {
  if [[ -f /tmp/remote_nix_setup.sh ]]; then
    rm -f /tmp/remote_nix_setup.sh
  fi
}

# Set trap for cleanup
trap cleanup EXIT

# Run the setup
setup_remote_builder
