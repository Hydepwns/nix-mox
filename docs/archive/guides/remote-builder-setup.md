# Remote Linux Builder Setup Guide

This guide explains how to set up a remote Linux builder for Nix on macOS, allowing you to build Linux packages from your macOS machine.

## Overview

When developing on macOS but targeting Linux systems, you need a way to build Linux packages. Nix's remote builder feature allows you to use a Linux machine to build packages while developing on macOS.

## Prerequisites

- A Linux machine (VM, cloud instance, or physical machine) accessible via SSH
- SSH key authentication set up between your macOS machine and the Linux machine
- Nix installed on both machines

## Quick Start

### 1. Setup Remote Builder

```bash
# Basic setup with default options
./scripts/setup-remote-builder.sh YOUR_LINUX_HOST

# Custom username and port
./scripts/setup-remote-builder.sh -u myuser -p 2222 YOUR_LINUX_HOST

# Only build for specific systems
./scripts/setup-remote-builder.sh -s x86_64-linux YOUR_LINUX_HOST
```

### 2. Test the Setup

```bash
# Test if the remote builder is working
./scripts/test-remote-builder.sh
```

### 3. Build Linux Packages

```bash
# Build for x86_64-linux
nix build .#packages.x86_64-linux.default

# Build for aarch64-linux
nix build .#packages.aarch64-linux.default

# Build both
nix build .#packages.x86_64-linux.default .#packages.aarch64-linux.default
```

## Script Options

| Option | Description | Default |
|--------|-------------|---------|
| `-u, --user` | Remote username | `nixremote` |
| `-p, --port` | SSH port | `22` |
| `-k, --key` | Path to SSH public key | `~/.ssh/id_rsa.pub` |
| `-s, --systems` | Comma-separated list of systems | `x86_64-linux,aarch64-linux` |
| `-h, --help` | Show help message | - |

### Examples

```bash
# Setup with custom user and port
./scripts/setup-remote-builder.sh -u builder -p 2222 192.168.1.100

# Setup for specific systems only
./scripts/setup-remote-builder.sh -s x86_64-linux 192.168.1.100

# Setup with custom SSH key
./scripts/setup-remote-builder.sh -k ~/.ssh/id_ed25519.pub 192.168.1.100
```

## Script Functionality

1. **Checks prerequisites**: Verifies you're on macOS and have SSH keys
2. **Tests SSH connection**: Ensures the remote machine is accessible
3. **Sets up remote machine**:
   - Installs Nix if not present
   - Creates build user with proper permissions
   - Configures SSH access
   - Starts Nix daemon
4. **Configures local machine**:
   - Creates `~/.config/nix/nix.conf`
   - Adds remote builder configuration
5. **Tests the setup**: Verifies the remote builder is working

## Manual Setup (Alternative)

If you prefer to set up manually or the scripts don't work for your environment:

### Remote Machine Setup

```bash
# Install Nix (if not already installed)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Create build user
sudo useradd -m nixremote
sudo usermod -aG nixbld nixremote

# Setup SSH access
sudo mkdir -p /home/nixremote/.ssh
sudo chown nixremote:nixremote /home/nixremote/.ssh
sudo chmod 700 /home/nixremote/.ssh

# Add your SSH public key
echo "YOUR_SSH_PUBLIC_KEY" | sudo tee /home/nixremote/.ssh/authorized_keys
sudo chown nixremote:nixremote /home/nixremote/.ssh/authorized_keys
sudo chmod 600 /home/nixremote/.ssh/authorized_keys

# Start Nix daemon
sudo systemctl enable nix-daemon
sudo systemctl start nix-daemon
```

### Local Machine Setup

```bash
# Create Nix config directory
mkdir -p ~/.config/nix

# Add remote builder configuration
cat >> ~/.config/nix/nix.conf << EOF
builders = ssh-ng://nixremote@YOUR_LINUX_HOST x86_64-linux,aarch64-linux / 4 1 kvm
EOF
```

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connection manually
ssh nixremote@YOUR_LINUX_HOST

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Nix Daemon Issues

```bash
# On remote machine, check daemon status
sudo systemctl status nix-daemon

# Restart daemon if needed
sudo systemctl restart nix-daemon
```

### Permission Issues

```bash
# On remote machine, check user permissions
sudo -u nixremote nix --version

# Fix permissions if needed
sudo chown -R nixremote:nixbld /nix/store
```

### Build Failures

```bash
# Check if remote builder is being used
nix build .#packages.x86_64-linux.default --dry-run

# Check Nix configuration
nix show-config | grep builders
```

## Advanced Configuration

### Multiple Remote Builders

You can configure multiple remote builders for load balancing:

```bash
# In ~/.config/nix/nix.conf
builders = ssh-ng://nixremote@host1 x86_64-linux / 2 1 kvm
builders = ssh-ng://nixremote@host2 x86_64-linux / 2 1 kvm
builders = ssh-ng://nixremote@host3 aarch64-linux / 2 1 kvm
```

### Custom Build Options

```bash
# In ~/.config/nix/nix.conf
builders = ssh-ng://nixremote@host x86_64-linux / 4 1 kvm - - - 300
```

The format is: `builders = ssh-ng://user@host systems / max-jobs speed-factor supported-features mandatory-features ssh-options max-silent-time`

## Security Considerations

- Use SSH key authentication (not passwords)
- Restrict SSH access to the build user
- Consider using SSH config for easier management
- Regularly update both machines
- Monitor build logs for suspicious activity

## Performance Tips

- Use a machine with good CPU and RAM for faster builds
- Ensure good network connectivity between machines
- Consider using local caching (Cachix) to avoid rebuilding
- Monitor resource usage on the remote machine

## Integration with CI/CD

You can use these scripts in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Setup remote builder
  run: |
    ./scripts/setup-remote-builder.sh ${{ secrets.LINUX_HOST }}
  
- name: Build Linux packages
  run: |
    nix build .#packages.x86_64-linux.default
    nix build .#packages.aarch64-linux.default
```

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Run the test script: `./scripts/test-remote-builder.sh`
3. Check Nix and SSH logs
4. Verify network connectivity and permissions

For more help, see the main [Troubleshooting Guide](../TROUBLESHOOTING.md).
