#!/usr/bin/env nu

# Test Remote Nix Builder Script
# This script tests if the remote Linux builder is working correctly

# Colors for output
let RED = (char -u "001b[0;31m")
let GREEN = (char -u "001b[0;32m")
let YELLOW = (char -u "001b[1;33m")
let BLUE = (char -u "001b[0;34m")
let NC = (char -u "001b[0m") # No Color

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

# Function to check if we're on macOS
def check_macos [] {
    let os = (sys | get host.name)
    if $os != "Darwin" {
        print_error "This script is designed to run on macOS"
        exit 1
    }
}

# Function to check Nix configuration
def check_nix_config [] {
    let nix_conf = ($env.HOME + "/.config/nix/nix.conf")
    if not ($nix_conf | path exists) {
        print_error $"Nix configuration file not found at $nix_conf"
        print_error "Run the setup script first: ./scripts/setup/setup-remote-builder.sh REMOTE_HOST"
        exit 1
    }

    let config_content = (open $nix_conf)
    if not ($config_content | str contains "builders = ssh-ng://") {
        print_error $"No remote builder configuration found in $nix_conf"
        print_error "Run the setup script first: ./scripts/setup/setup-remote-builder.sh REMOTE_HOST"
        exit 1
    }

    print_success "Remote builder configuration found"
}

# Function to test SSH connection
def test_ssh_connection [] {
    print_status "Testing SSH connection to remote builder..."

    # Extract remote host from nix.conf
    let nix_conf = ($env.HOME + "/.config/nix/nix.conf")
    let config_content = (open $nix_conf)
    let builder_line = ($config_content | lines | where ($it | str contains "builders = ssh-ng://") | first)

    if ($builder_line | is-empty) {
        print_error "Could not find builder configuration line"
        exit 1
    }

    # Extract components using regex
    let remote_user = ($builder_line | parse -r 'ssh-ng://(?P<user>[^@]+)@' | first.user)
    let remote_host = ($builder_line | parse -r '@(?P<host>[^:]+)' | first.host)
    let ssh_port = ($builder_line | parse -r ':(?P<port>[0-9]+)' | first.port | default "22")

    if ($remote_host | is-empty) {
        print_error "Could not extract remote host from nix.conf"
        exit 1
    }

    print_status $"Remote host: $remote_host"
    print_status $"Remote user: $remote_user"
    print_status $"SSH port: $ssh_port"

    # Test SSH connection
    let ssh_result = (do {
        ssh -p $ssh_port -o ConnectTimeout=10 -o BatchMode=yes $"($remote_user)@($remote_host)" exit
    } | complete)

    if $ssh_result.exit_code == 0 {
        print_success "SSH connection successful"
    } else {
        print_error "SSH connection failed"
        print_error "Please check:"
        print_error "1. Remote host is accessible"
        print_error "2. SSH key authentication is working"
        print_error "3. Remote user has proper permissions"
        exit 1
    }
}

# Function to test simple derivation
def test_simple_derivation [] {
    print_status "Testing simple derivation build..."

    let test_expr = 'derivation {
        name = "remote-test";
        system = "x86_64-linux";
        builder = "/bin/sh";
        args = ["-c" "echo \"Remote builder test successful\" > $out"];
    }'

    let test_drv = (do { nix-instantiate --expr $test_expr } | complete)

    if $test_drv.exit_code == 0 {
        let drv_path = ($test_drv.stdout | str trim)
        print_status "Testing build on remote machine..."

        let dry_run = (do { nix-store --realise $drv_path --dry-run } | complete)

        if ($dry_run.stderr | str contains "will be built") {
            print_success "Remote builder is working correctly"
            print_success "Build will be performed on remote machine"
        } else {
            print_warning "Remote builder may not be working as expected"
            print_warning "Build might be performed locally"
        }
    } else {
        print_error "Could not create test derivation"
        exit 1
    }
}

# Function to test actual build
def test_actual_build [] {
    print_status "Testing actual build on remote machine..."

    let test_expr = $"derivation {{
        name = \"remote-build-test\";
        system = \"x86_64-linux\";
        builder = \"/bin/sh\";
        args = [\"-c\" \"echo \\\"Build completed at $(date)\\\" > \$out\"];
    }}"

    let test_drv = (do { nix-instantiate --expr $test_expr } | complete)

    if $test_drv.exit_code != 0 {
        print_error "Could not create test derivation"
        exit 1
    }

    let drv_path = ($test_drv.stdout | str trim)
    print_status "Building test derivation..."

    let build_result = (do { nix-store --realise $drv_path } | complete)

    if $build_result.exit_code == 0 {
        let result_path = ($build_result.stdout | str trim)
        print_success "Build completed successfully!"
        print_status $"Result: $result_path"

        let content = (open $result_path)
        print_status $"Content: $content"

        # Cleanup
        do { nix-store --delete $result_path } | complete | ignore
        print_status "Cleaned up test build"
    } else {
        print_error "Build failed"
        exit 1
    }
}

# Function to show builder status
def show_builder_status [] {
    print_status "Current builder configuration:"
    print ""

    let nix_conf = ($env.HOME + "/.config/nix/nix.conf")
    let config_content = (open $nix_conf)
    let builder_lines = ($config_content | lines | where ($it | str contains "builders"))

    if ($builder_lines | length) > 0 {
        print ($builder_lines | str join "\n")
    }

    print ""
    print_status "Available builders:"

    let nix_config = (do { nix show-config } | complete)

    if $nix_config.exit_code == 0 {
        let builder_config = ($nix_config.stdout | lines | where ($it | str contains "builders"))

        if ($builder_config | length) > 0 {
            print ($builder_config | str join "\n")
        } else {
            print_warning "No builder configuration found"
        }
    } else {
        print_error "Could not retrieve Nix configuration"
    }
}

# Function to test your project builds
def test_project_builds [] {
    print_status "Testing your project builds..."

    # Check if we're in a nix-mox project
    if ("flake.nix" | path exists) {
        print_status "Found flake.nix, testing project builds..."

        # Test x86_64-linux build
        let x86_64_test = (do { nix eval .#packages.x86_64-linux.default } | complete)

        if $x86_64_test.exit_code == 0 {
            print_status "Testing x86_64-linux build..."

            let x86_64_dry_run = (do { nix build .#packages.x86_64-linux.default --dry-run } | complete)

            if ($x86_64_dry_run.stderr | str contains "will be built") {
                print_success "x86_64-linux build will use remote builder"
            } else {
                print_warning "x86_64-linux build may not use remote builder"
            }
        } else {
            print_warning "No x86_64-linux packages found"
        }

        # Test aarch64-linux build
        let aarch64_test = (do { nix eval .#packages.aarch64-linux.default } | complete)

        if $aarch64_test.exit_code == 0 {
            print_status "Testing aarch64-linux build..."

            let aarch64_dry_run = (do { nix build .#packages.aarch64-linux.default --dry-run } | complete)

            if ($aarch64_dry_run.stderr | str contains "will be built") {
                print_success "aarch64-linux build will use remote builder"
            } else {
                print_warning "aarch64-linux build may not use remote builder"
            }
        } else {
            print_warning "No aarch64-linux packages found"
        }
    } else {
        print_warning "No flake.nix found in current directory"
    }
}

# Main function
def main [] {
    print_status "Testing remote Nix builder setup..."
    print ""

    # Check if we're on macOS
    check_macos

    # Check Nix configuration
    check_nix_config

    # Test SSH connection
    test_ssh_connection

    # Show builder status
    show_builder_status

    # Test simple derivation
    test_simple_derivation

    # Test project builds
    test_project_builds

    print ""
    print_status "Do you want to run an actual build test? (y/N)"
    let response = (input | str trim)

    if ($response | str downcase | str contains "y") {
        test_actual_build
    }

    print ""
    print_success "Remote builder test complete!"
    print_success "If all tests passed, you can now build Linux packages from macOS"
}

# Run main function
main
