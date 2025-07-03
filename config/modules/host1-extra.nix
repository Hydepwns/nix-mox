# ============================================================================
# HOST1 EXTRA MODULE
# ============================================================================
# Desktop-specific configurations for host1
# ============================================================================

{ config, lib, pkgs, inputs, mySecret, hostType, ... }:

{
  # Desktop-specific settings
  services = {
    xserver = {
      enable = true;
      displayManager = {
        lightdm.enable = true;
        # gdm.enable = true;  # Commented out to match current system
      };
      desktopManager = {
        gnome.enable = true;
      };
    };
    pulseaudio.enable = false;
  };

  # Hardware-specific settings
  hardware = {
    graphics.enable = true;
  };

  # Desktop applications
  environment.systemPackages = with pkgs; [
    # Development tools
    vscode
    firefox
    chromium

    # Media tools
    vlc
    gimp

    # System tools
    gnome-tweaks
    gnome-software
  ];

  # User-specific settings
  users.users.droo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = lib.mkForce pkgs.zsh;
  };

  # Security settings for desktop
  security = {
    sudo.wheelNeedsPassword = lib.mkForce false;
    rtkit.enable = true;
  };

  # Networking for desktop
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
    };
  };

  # System settings
  system = {
    autoUpgrade = {
      enable = lib.mkForce true;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };

  # Debug: Print host-specific arguments
  system.activationScripts.debug = ''
    echo "Host1 configuration loaded"
    echo "Host type: ${hostType}"
    echo "Secret: ${mySecret}"
  '';

  services.pipewire = {
    enable = true;
    audio.enable = true;
  };
}
