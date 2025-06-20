# NixOS VM Template - Fragment System

This template has been updated to use a **fragment system** that allows you to compose VM configurations from reusable, focused modules.

## 🧩 Fragment System Overview

The fragment system breaks down the monolithic `base.nix` into focused, reusable components:

```bash
fragments/
├── base.nix          # Main entry point that imports all base fragments
├── networking.nix    # Network interface configuration
├── users.nix         # User accounts and security
├── ssh.nix          # SSH service and hardening
├── firewall.nix     # Firewall rules
├── updates.nix      # Automatic updates and flake updates
├── hardware.nix     # Filesystem and swap configuration
├── graphics.nix     # Graphics and OpenGL support
├── web-server.nix   # Web server configuration
├── database.nix     # Database server configuration
└── ci-runner.nix    # CI/CD runner configuration
```

## 🚀 Quick Start with Fragments

### Use Pre-built Examples

```bash
# Basic VM with minimal configuration
nixos-rebuild switch --flake .#basic-vm

# Web server VM
nixos-rebuild switch --flake .#web-server-vm

# Database VM
nixos-rebuild switch --flake .#database-vm

# CI Runner VM
nixos-rebuild switch --flake .#ci-runner-vm
```

### Create Custom VM Configuration

1. **Create a new configuration file:**

```nix
# examples/my-custom-vm.nix
{ config, pkgs, inputs, ... }:
{
  imports = [
    ../fragments/base.nix
    ../fragments/web-server.nix
    ../fragments/database.nix
  ];

  networking.hostName = "my-custom-vm";
  
  # Add custom configuration
  services.nginx.virtualHosts."myapp.local" = {
    root = "/var/www/myapp";
  };
}
```

2. **Add to flake.nix:**

```nix
nixosConfigurations.my-custom-vm = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./examples/my-custom-vm.nix
  ];
  specialArgs = { inherit nix-mox inputs; };
};
```

3. **Deploy:**

```bash
nixos-rebuild switch --flake .#my-custom-vm
```

## 📋 Available Fragments

### Base Fragments (Always Included)

- **`base.nix`**: Main entry point that imports all essential fragments
- **`networking.nix`**: Network interface configuration (DHCP/static IP)
- **`users.nix`**: User accounts and security settings
- **`ssh.nix`**: SSH service with security hardening
- **`firewall.nix`**: Basic firewall configuration
- **`updates.nix`**: Automatic system and flake updates
- **`hardware.nix`**: Filesystem and swap configuration
- **`graphics.nix`**: Graphics support (commented out by default)

### Role-Specific Fragments

- **`web-server.nix`**: Nginx web server with SSL support
- **`database.nix`**: Database servers (PostgreSQL, MySQL, Redis, MongoDB)
- **`ci-runner.nix`**: CI/CD tools (Docker, build tools, languages)

## 🎯 Fragment Composition Examples

### Minimal VM (SSH only)

```nix
imports = [ ../fragments/base.nix ];
```

### Web Server VM

```nix
imports = [
  ../fragments/base.nix
  ../fragments/web-server.nix
];
```

### Full-Stack Application VM

```nix
imports = [
  ../fragments/base.nix
  ../fragments/web-server.nix
  ../fragments/database.nix
];
```

### Development VM

```nix
imports = [
  ../fragments/base.nix
  ../fragments/ci-runner.nix
];
```

## 🔧 Customizing Fragments

### Override Fragment Settings

```nix
{ config, pkgs, inputs, ... }:
{
  imports = [ ../fragments/base.nix ];
  
  # Override networking settings
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.100";
    prefixLength = 24;
  }];
  
  # Override firewall settings
  networking.firewall.allowedTCPPorts = [ 22 80 443 8080 ];
}
```

### Create Custom Fragments

```nix
# fragments/monitoring.nix
{ config, pkgs, inputs, ... }:
{
  services.prometheus.enable = true;
  services.grafana.enable = true;
  
  networking.firewall.allowedTCPPorts = 
    config.networking.firewall.allowedTCPPorts ++ [ 9090 3000 ];
}
```

### Conditional Fragment Loading

```nix
{ config, pkgs, inputs, ... }:
let
  isProduction = config.networking.hostName == "prod-server";
in
{
  imports = [
    ../fragments/base.nix
  ] ++ (if isProduction then [
    ../fragments/monitoring.nix
  ] else []);
}
```

## 🔒 Security Best Practices

### SSH Key Authentication

```nix
# In your configuration
users.users.example.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... your-public-key"
];
users.users.example.password = null; # Disable password auth
```

### Firewall Configuration

```nix
# Only open necessary ports
networking.firewall.allowedTCPPorts = [ 22 ]; # SSH only
# Add more ports as needed: [ 22 80 443 5432 ]
```

### User Security

```nix
# Lock user if no SSH key is set
users.users.example.isLocked = true;
```

## 🏗️ Hardware Configuration

### Different VM Environments

**KVM/QEMU:**

```nix
fileSystems."/" = {
  device = "/dev/vda1";
  fsType = "ext4";
};
```

**VMware:**

```nix
fileSystems."/" = {
  device = "/dev/sda1";
  fsType = "ext4";
};
```

**VirtualBox:**

```nix
fileSystems."/" = {
  device = "/dev/sda1";
  fsType = "ext4";
};
```

## 🔄 Migration from Old System

### Legacy Configurations Still Work

The old monolithic approach is still supported for backward compatibility:

```nix
# Old way (still works)
nixosConfigurations.legacy-vm = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [ ./base.nix ];
  specialArgs = { inherit nix-mox inputs; };
};
```

### Migration Path

1. **Start with fragments**: Use the new fragment system for new VMs
2. **Gradually migrate**: Convert existing VMs one by one
3. **Test thoroughly**: Ensure all functionality works after migration

## 📚 Advanced Usage

### Environment-Specific Configurations

```nix
# examples/production-vm.nix
{ config, pkgs, inputs, ... }:
let
  environment = "production";
in
{
  imports = [
    ../fragments/base.nix
    ../fragments/web-server.nix
    ../fragments/database.nix
  ];

  networking.hostName = "prod-${environment}-vm";
  
  # Production-specific settings
  system.autoUpgrade.allowReboot = false;
  services.nginx.enableReload = false;
}
```

### Multi-Environment Deployment

```nix
# flake.nix
let
  environments = [ "dev" "staging" "prod" ];
  mkVM = env: nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./examples/${env}-vm.nix
    ];
    specialArgs = { inherit nix-mox inputs; };
  };
in
{
  nixosConfigurations = builtins.listToAttrs
    (map (env: { name = "${env}-vm"; value = mkVM env; }) environments);
}
```

## 🧪 Testing

### Test Configuration Syntax

```bash
nix flake check .#checks.x86_64-linux.unit
```

### Test VM Build

```bash
nix build .#nixosConfigurations.web-server-vm.config.system.build.vm
```

### Test in QEMU

```bash
./result/bin/run-*-vm
```

## 📖 Fragment Reference

See individual fragment files for detailed configuration options and examples.

## 🤝 Contributing

When adding new fragments:

1. **Keep fragments focused**: Each fragment should handle one concern
2. **Document options**: Include comments explaining configuration choices
3. **Provide examples**: Show common usage patterns
4. **Maintain compatibility**: Don't break existing configurations
5. **Test thoroughly**: Ensure fragments work together correctly
