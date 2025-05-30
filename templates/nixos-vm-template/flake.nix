{
  description = "Example NixOS VM Template Flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        nixosConfigurations.example-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ config, pkgs, ... }: {
              networking.hostName = "example-vm";
              time.timeZone = "UTC";
              users.users.example = {
                isNormalUser = true;
                extraGroups = [ "wheel" ];
                password = "example";
              };
              services.openssh.enable = true;

              # --- SSH Hardening ---
              services.openssh.settings.PasswordAuthentication = false;
              services.openssh.settings.PermitRootLogin = "no";
              # Only allow login with SSH keys (add your public key below)
              users.users.example.openssh.authorizedKeys.keys = [
                # "ssh-ed25519 AAAA... user@host"
              ];
              # ---------------------------------------

              # --- Firewall ---
              networking.firewall.enable = true;
              networking.firewall.allowedTCPPorts = [ 22 ]; # Allow SSH only by default
              # networking.firewall.allowedTCPPorts = [ 22 80 443 ]; # Example: allow web ports
              # ---------------------------------------

              # --- Automatic Updates ---
              system.autoUpgrade.enable = true;
              system.autoUpgrade.allowReboot = false; # Set to true if you want automatic reboots
              # ---------------------------------------

              # --- Example Hardware Configuration ---
              # Disk and filesystem setup
              fileSystems."/" = {
                device = "/dev/vda1";
                fsType = "ext4";
              };
              # Uncomment and adjust for additional disks or mount points
              # fileSystems."/data" = {
              #   device = "/dev/vdb1";
              #   fsType = "ext4";
              # };

              # Example swap device
              swapDevices = [
                { device = "/dev/vda2"; }
              ];

              # Network interface configuration
              networking.interfaces.eth0.useDHCP = true;
              # For a static IP example, comment out the above and use:
              # networking.interfaces.eth0.ipv4.addresses = [{
              #   address = "192.168.100.10";
              #   prefixLength = 24;
              # }];
              # networking.defaultGateway = "192.168.100.1";
              # networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
              # ---------------------------------------

              system.stateVersion = "24.05";
            })
          ];
        };
      });
} 