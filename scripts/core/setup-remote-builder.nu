#!/usr/bin/env nu

# Remote Nix Builder Setup Script
# This script automates setting up a remote Linux builder for Nix on macOS

# Colors for output
let RED = (char -u "001b[0;31m")
let GREEN = (char -u "001b[0;32m")
let YELLOW = (char -u "001b[1;33m")
let BLUE = (char -u "001b[0;34m")
let NC = (char -u "001b[0m")  # No Color

# Function to print colored output
def print_status [message: string] {
    print $"[$BLUE][INFO]$NC $message"
}

def print_success [message: string] {
    print $"[$GREEN][SUCCESS]$NC $message"
}

def print_warning [message: string] {
    print $"[$YELLOW][WARNING]$NC $message"
}

def print_error [message: string] {
    print $"[$RED][ERROR]$NC $message"
}

# Function to check if command exists
def command_exists [cmd: string] {
    (which $cmd | length) > 0
}

# Function to check if we're on macOS
def check_macos [] {
    let os = (sys | get host.name)
    if $os != "Darwin" {
        print_error "This script is designed to run on macOS"
        exit 1
    }
}

# Function to check if SSH key exists
def check_ssh_key [] {
    let ssh_key_path = $env.HOME + "/.ssh/id_rsa.pub"
    if not ($ssh_key_path | path exists) {
        print_warning "SSH public key not found at $ssh_key_path"
        print_status "Generating SSH key pair..."
        do { ssh-keygen -t rsa -b 4096 -f ($env.HOME + "/.ssh/id_rsa") -N "" } | complete | ignore
        print_success "SSH key pair generated"
    }
}

# Function to display usage
def show_usage [] {
    print "Usage: setup-remote-builder.nu [OPTIONS] REMOTE_HOST"
    print ""
    print "Setup a remote Linux builder for Nix on macOS."
    print ""
    print "OPTIONS:"
    print "    -u, --user USERNAME     Remote username (default: nixremote)"
    print "    -p, --port PORT         SSH port (default: 22)"
    print "    -k, --key PATH          Path to SSH public key (default: ~/.ssh/id_rsa.pub)"
    print "    -s, --systems SYSTEMS   Comma-separated list of systems to build for (default: x86_64-linux,aarch64-linux)"
    print "    -h, --help              Show this help message"
    print ""
    print "EXAMPLES:"
    print "    setup-remote-builder.nu 192.168.1.100"
    print "    setup-remote-builder.nu -u myuser -p 2222 my-linux-server.com"
    print "    setup-remote-builder.nu --systems x86_64-linux 192.168.1.100"
}

# Simple argument parsing - just get the first non-flag argument as host
def get_remote_host [args: list] {
    $args | where not ($it | str starts-with "-") | get 0
}

# Function to setup remote machine
def setup_remote_machine [remote_host: string, remote_user: string, ssh_port: string, ssh_key_path: string] {
    print_status "Setting up remote machine..."

    # Create remote setup script content
    let remote_script_content = "#!/bin/bash
set -euo pipefail

REMOTE_USER=\"$1\"
SSH_KEY_CONTENT=\"$2\"

echo \"Setting up Nix on remote machine...\"

# Install Nix if not already installed
if ! command -v nix >/dev/null 2>&1; then
    echo \"Installing Nix...\"
    sh <(curl -L https://nixos.org/nix/install) --daemon
    source /etc/profile.d/nix-daemon.sh
fi

# Create build user if it doesn't exist
if ! id \"$REMOTE_USER\" &>/dev/null; then
    echo \"Creating build user: $REMOTE_USER\"
    sudo useradd -m -s /bin/bash \"$REMOTE_USER\"
    sudo passwd -d \"$REMOTE_USER\"  # Remove password
fi

# Setup SSH for the build user
sudo mkdir -p \"/home/$REMOTE_USER/.ssh\"
sudo chown \"$REMOTE_USER:$REMOTE_USER\" \"/home/$REMOTE_USER/.ssh\"
sudo chmod 700 \"/home/$REMOTE_USER/.ssh\"

# Add SSH key
echo \"$SSH_KEY_CONTENT\" | sudo tee \"/home/$REMOTE_USER/.ssh/authorized_keys\" > /dev/null
sudo chown \"$REMOTE_USER:$REMOTE_USER\" \"/home/$REMOTE_USER/.ssh/authorized_keys\"
sudo chmod 600 \"/home/$REMOTE_USER/.ssh/authorized_keys\"

# Add user to nixbld group
sudo usermod -aG nixbld \"$REMOTE_USER\"

# Ensure Nix daemon is running
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable nix-daemon
    sudo systemctl start nix-daemon
fi

# Test Nix access for the build user
sudo -u \"$REMOTE_USER\" nix --version > /dev/null

echo \"Remote setup complete!\""

    # Write remote script to temp file
    $remote_script_content | save /tmp/remote_nix_setup.sh

    # Copy and execute remote setup script
    print_status "Copying setup script to remote machine..."
    let scp_result = (do { scp -P $ssh_port /tmp/remote_nix_setup.sh $"($remote_user)@($remote_host):/tmp/" } | complete)
    if $scp_result.exit_code != 0 {
        print_error "Failed to copy setup script to remote machine"
        exit 1
    }

    print_status "Executing setup script on remote machine..."
    let ssh_key_content = (open $ssh_key_path)
    let ssh_result = (do { ssh -p $ssh_port $"($remote_user)@($remote_host)" $"chmod +x /tmp/remote_nix_setup.sh && /tmp/remote_nix_setup.sh '($remote_user)' '($ssh_key_content)'" } | complete)
    if $ssh_result.exit_code != 0 {
        print_error "Failed to execute setup script on remote machine"
        exit 1
    }

    # Cleanup
    rm /tmp/remote_nix_setup.sh
    do { ssh -p $ssh_port $"($remote_user)@($remote_host)" "rm /tmp/remote_nix_setup.sh" } | complete | ignore
    print_success "Remote machine setup complete"
}

# Function to setup local machine
def setup_local_machine [remote_host: string, remote_user: string, ssh_port: string, systems: string] {
    print_status "Setting up local machine..."

    # Create Nix config directory
    mkdir ($env.HOME + "/.config/nix")

    # Create or update nix.conf
    let nix_conf = $env.HOME + "/.config/nix/nix.conf"
    let builder_config = $"builders = ssh-ng://($remote_user)@($remote_host):($ssh_port) ($systems) / 4 1 kvm"

    if ($nix_conf | path exists) {
        # Remove existing builder configuration
        let config_content = (open $nix_conf)
        let filtered_content = ($config_content | lines | where not ($it | str contains "builders = ssh-ng://"))
        $filtered_content | save $nix_conf
        print_status "Updated existing nix.conf"
    } else {
        print_status "Creating new nix.conf"
    }

    # Add builder configuration
    $builder_config | save --append $nix_conf
    print_success "Local machine setup complete"
}

# Function to test remote builder
def test_remote_builder [] {
    print_status "Testing remote builder..."

    # Test with a simple derivation
    let test_expr = 'derivation { name = "test"; system = "x86_64-linux"; builder = "/bin/sh"; args = ["-c" "echo hello > $out"]; }'
    let test_drv = (do { nix-instantiate --expr $test_expr } | complete)

    if $test_drv.exit_code == 0 {
        let drv_path = ($test_drv.stdout | str trim)
        print_status "Testing build on remote machine..."
        let dry_run = (do { nix-store --realise $drv_path --dry-run } | complete)

        if ($dry_run.stderr | str contains "will be built") {
            print_success "Remote builder is working correctly"
        } else {
            print_warning "Remote builder may not be working as expected"
        }
    } else {
        print_error "Could not create test derivation"
    }
}

# Main setup function
def main [args: list] {
    # Simple argument handling for now
    let remote_host = (get_remote_host $args)
    let remote_user = "nixremote"
    let ssh_port = "22"
    let ssh_key_path = $env.HOME + "/.ssh/id_rsa.pub"
    let systems = "x86_64-linux,aarch64-linux"

    if ($remote_host | is-empty) {
        print_error "Remote host is required"
        show_usage
        exit 1
    }

    print_status "Starting remote Nix builder setup..."
    print $"Remote host: $remote_host"
    print $"Remote user: $remote_user"
    print $"SSH port: $ssh_port"
    print $"Systems: $systems"

    # Check prerequisites
    check_macos
    check_ssh_key

    # Test SSH connection
    print_status $"Testing SSH connection to $remote_host..."
    let ssh_test = (do { ssh -p $ssh_port -o ConnectTimeout=10 -o BatchMode=yes $"($remote_user)@($remote_host)" exit } | complete)
    if $ssh_test.exit_code != 0 {
        print_error $"Cannot connect to $remote_host as $remote_user"
        print_error "Please ensure:"
        print_error "1. The remote host is accessible"
        print_error "2. SSH key authentication is set up"
        print_error "3. The remote user exists and has SSH access"
        exit 1
    }
    print_success "SSH connection successful"

    # Setup remote machine
    setup_remote_machine $remote_host $remote_user $ssh_port $ssh_key_path

    # Setup local machine
    setup_local_machine $remote_host $remote_user $ssh_port $systems

    # Test the setup
    test_remote_builder

    print_success "Remote Nix builder setup complete!"
    print_status "You can now build Linux packages from macOS using:"
    print "  nix build .#packages.x86_64-linux.default"
    print "  nix build .#packages.aarch64-linux.default"
}

# Run the setup with command line arguments
if ($env | get --ignore-errors ARGS | default [] | length) > 0 {
    let args = ($env.ARGS | split row " ")
    main $args
} else {
    show_usage
    exit 1
}
