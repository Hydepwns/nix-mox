# Multi-Host NixOS Management

> Manage multiple NixOS hosts from a single flake with host-specific configurations.

## Overview

nix-mox supports managing multiple NixOS hosts from a single flake, allowing you to:

- Define host-specific hardware configurations
- Customize user environments per host
- Add host-specific services and modules
- Pass host-specific arguments and secrets
- Maintain consistent base configurations

## Quick Start

```bash
# Build specific host configurations
nix build .#nixosConfigurations.host1.config.system.build.toplevel
nix build .#nixosConfigurations.host2.config.system.build.toplevel

# Deploy to hosts
nixos-rebuild switch --flake .#host1
nixos-rebuild switch --flake .#host2

# See available hosts and outputs
nix run .#dev
```

## Configuration Structure

```
config/
├── hosts.nix                    # Host definitions
├── hardware/                    # Host-specific hardware configs
│   ├── host1-hardware-configuration.nix
│   └── host2-hardware-configuration.nix
├── home/                        # Host-specific home configs
│   ├── host1-home.nix
│   └── host2-home.nix
├── modules/                     # Host-specific modules
│   ├── host1-extra.nix
│   └── server-extra.nix
└── nixos/                       # Shared base configuration
    └── configuration.nix
```

## Host Configuration

### Basic Host Definition

```nix
# config/hosts.nix
{
  host1 = {
    system = "x86_64-linux";
    hardware = ./hardware/host1-hardware-configuration.nix;
    home = ./home/host1-home.nix;
    extraModules = [ ./modules/host1-extra.nix ];
    specialArgs = { 
      hostType = "desktop";
      mySecret = "host1-secret";
    };
  };
}
```

### Host-Specific Arguments

Each host can have its own special arguments:

```nix
specialArgs = { 
  hostType = "desktop";           # Host type for conditional logic
  mySecret = "host1-secret";      # Host-specific secrets
  environment = "production";     # Environment variables
  features = [ "gaming" "development" ]; # Feature flags
};
```

## Hardware Configurations

### Desktop Hardware (host1)

```nix
# config/hardware/host1-hardware-configuration.nix
{ config, lib, pkgs, ... }:

{
  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = [ "kvm-intel" ];
  };

  # Hardware-specific settings
  hardware = {
    cpu.intel.updateMicrocode = true;
    pulseaudio.enable = true;
    bluetooth.enable = true;
    firmware = with pkgs; [
      linux-firmware
      intel-media-driver
    ];
  };

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Network
  networking = {
    hostName = "host1";
    useDHCP = true;
  };
}
```

### Server Hardware (host2)

```nix
# config/hardware/host2-hardware-configuration.nix
{ config, lib, pkgs, ... }:

{
  # Server-specific optimizations
  boot = {
    kernel.sysctl = {
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
    };
  };

  # Data directory for server applications
  fileSystems."/var/lib" = {
    device = "/dev/disk/by-label/data";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # Network
  networking = {
    hostName = "host2";
    useDHCP = true;
  };
}
```

## Home Configurations

### Desktop User Environment (host1)

```nix
# config/home/host1-home.nix
{ config, lib, pkgs, ... }:

{
  home = {
    username = "droo";
    homeDirectory = "/home/droo";
    stateVersion = "23.11";
  };

  programs = {
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      syntaxHighlighting.enable = true;
    };
    
    neovim.enable = true;
    alacritty.enable = true;
    firefox.enable = true;
  };

  home.packages = with pkgs; [
    vscode
    firefox
    chromium
    vlc
    gimp
  ];
}
```

### Server User Environment (host2)

```nix
# config/home/host2-home.nix
{ config, lib, pkgs, ... }:

{
  programs = {
    bash = {
      enable = true;
      shellAliases = {
        logs = "journalctl -f";
        status = "systemctl status";
        restart = "sudo systemctl restart";
      };
    };
    
    tmux = {
      enable = true;
      shortcut = "Space";
    };
  };

  home.packages = with pkgs; [
    htop
    iotop
    tcpdump
    nmap
    git
    vim
    tmux
  ];
}
```

## Host-Specific Modules

### Desktop Module (host1-extra.nix)

```nix
# config/modules/host1-extra.nix
{ config, lib, pkgs, inputs, mySecret, hostType, ... }:

{
  # Desktop-specific settings
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Hardware-specific settings
  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    pulseaudio.enable = true;
  };

  # Desktop applications
  environment.systemPackages = with pkgs; [
    vscode
    firefox
    chromium
    vlc
    gimp
  ];

  # Debug: Print host-specific arguments
  system.activationScripts.debug = ''
    echo "Host1 configuration loaded"
    echo "Host type: ${hostType}"
    echo "Secret: ${mySecret}"
  '';
}
```

### Server Module (server-extra.nix)

```nix
# config/modules/server-extra.nix
{ config, lib, pkgs, inputs, mySecret, hostType, ... }:

{
  # Server-specific settings
  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        PubkeyAuthentication = true;
      };
    };

    nginx.enable = true;
    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
    };

    prometheus.enable = true;
    grafana.enable = true;
  };

  # Server applications
  environment.systemPackages = with pkgs; [
    htop
    iotop
    tcpdump
    nmap
    git
    vim
    tmux
  ];

  # Security settings for server
  security = {
    sudo.wheelNeedsPassword = true;
    auditd.enable = true;
  };
}
```

## Usage Examples

### Building Host Configurations

```bash
# Build all host configurations
nix build .#nixosConfigurations.host1.config.system.build.toplevel
nix build .#nixosConfigurations.host2.config.system.build.toplevel

# Build with specific system
nix build .#nixosConfigurations.host1.config.system.build.toplevel --system x86_64-linux
```

### Deploying to Hosts

```bash
# Deploy to specific host
nixos-rebuild switch --flake .#host1
nixos-rebuild switch --flake .#host2

# Dry-run deployment
nixos-rebuild dry-activate --flake .#host1

# Build and copy to remote host
nixos-rebuild switch --flake .#host1 --target-host user@host1.example.com
```

### Remote Deployment

```bash
# Deploy to remote host via SSH
nixos-rebuild switch --flake .#host1 --target-host admin@192.168.1.100

# Deploy with specific SSH key
nixos-rebuild switch --flake .#host1 --target-host admin@192.168.1.100 --build-host admin@192.168.1.100
```

## Advanced Features

### Conditional Configuration

Use host-specific arguments for conditional logic:

```nix
# In any module
{ config, lib, pkgs, hostType, ... }:

{
  # Enable different services based on host type
  services = lib.mkIf (hostType == "desktop") {
    xserver.enable = true;
    pipewire.enable = true;
  };

  # Different packages for different hosts
  environment.systemPackages = with pkgs; 
    if hostType == "desktop" then [
      firefox
      vscode
      gimp
    ] else if hostType == "server" then [
      htop
      tcpdump
      prometheus
    ] else [];
}
```

### Secrets Management

```nix
# Pass secrets to hosts
specialArgs = { 
  mySecret = "host1-secret";
  apiKey = "your-api-key";
  databasePassword = "db-password";
};

# Use in modules
{ config, lib, pkgs, mySecret, apiKey, ... }:

{
  # Use secrets in configuration
  services.myapp = {
    enable = true;
    apiKey = apiKey;
    secret = mySecret;
  };
}
```

### Adding New Hosts

1. **Create hardware configuration:**

   ```bash
   cp config/hardware/host1-hardware-configuration.nix config/hardware/host3-hardware-configuration.nix
   ```

2. **Create home configuration:**

   ```bash
   cp config/home/host1-home.nix config/home/host3-home.nix
   ```

3. **Create host-specific module:**

   ```bash
   cp config/modules/host1-extra.nix config/modules/host3-extra.nix
   ```

4. **Add to hosts.nix:**

   ```nix
   host3 = {
     system = "x86_64-linux";
     hardware = ./hardware/host3-hardware-configuration.nix;
     home = ./home/host3-home.nix;
     extraModules = [ ./modules/host3-extra.nix ];
     specialArgs = { 
       hostType = "laptop";
       mySecret = "host3-secret";
     };
   };
   ```

5. **Add to flake.nix:**

   ```nix
   nixosConfigurations = {
     host1 = inputs.nixpkgs.lib.nixosSystem { /* ... */ };
     host2 = inputs.nixpkgs.lib.nixosSystem { /* ... */ };
     host3 = inputs.nixpkgs.lib.nixosSystem { /* ... */ };
   };
   ```

## Best Practices

### 1. **Modular Design**

- Keep host-specific configurations in separate files
- Use shared base configuration for common settings
- Create reusable modules for common features

### 2. **Security**

- Use host-specific secrets and arguments
- Avoid hardcoding sensitive information
- Use SSH keys for remote deployment

### 3. **Maintenance**

- Use descriptive host names
- Document host-specific requirements
- Keep hardware configurations minimal and focused

### 4. **Testing**

- Test configurations before deployment
- Use dry-run mode for validation
- Maintain separate test environments

## Troubleshooting

### Common Issues

1. **Path resolution errors:**

   ```bash
   # Ensure all paths in hosts.nix are correct
   ls -la config/hardware/
   ls -la config/home/
   ls -la config/modules/
   ```

2. **Import errors:**

   ```bash
   # Check flake evaluation
   nix flake check
   nix flake show
   ```

3. **Deployment failures:**

   ```bash
   # Use dry-run mode
   nixos-rebuild dry-activate --flake .#host1
   
   # Check system logs
   journalctl -u nixos-rebuild
   ```

### Debugging

```bash
# Show host configuration
nix eval .#nixosConfigurations.host1.config.system.build.toplevel.drvPath

# Show available outputs
nix run .#dev

# Check flake structure
nix flake show
```

## Next Steps

1. **Customize host configurations** - Modify hardware, home, and module files
2. **Add more hosts** - Follow the pattern to add additional hosts
3. **Implement secrets management** - Use agenix or sops-nix for encrypted secrets
4. **Set up CI/CD** - Automate deployment with GitHub Actions
5. **Monitor deployments** - Use monitoring tools to track host status

For more information, see the [Usage Guide](USAGE.md) and [Development Guide](DEVELOPMENT.md).
