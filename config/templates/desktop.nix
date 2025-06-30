# Desktop Template Configuration
# Full desktop environment with GUI applications
{ config, pkgs, ... }:
{
  imports = [
    ../profiles/base.nix
    ../profiles/security.nix
    ../profiles/desktop.nix
  ];

  # Desktop-specific configuration
  environment.systemPackages = with pkgs; [
    # Desktop environment
    gnome.gnome-tweaks
    gnome.gnome-software

    # File management
    nautilus
    thunar
    dolphin

    # Web browsers
    firefox
    chromium
    brave

    # Office applications
    libreoffice
    gimp
    inkscape

    # Media applications
    vlc
    mpv
    spotify

    # Communication
    discord
    telegram-desktop
    signal-desktop

    # Terminal emulators
    kitty
    alacritty
    gnome.gnome-terminal

    # System tools
    gnome.gnome-system-monitor
    gnome.gnome-disk-utility
    gnome.gnome-settings-daemon
  ];

  # Desktop programs
  programs = {
    zsh.enable = true;
    git.enable = true;
    firefox.enable = true;
    vscode.enable = true;
  };

  # Desktop services
  services = {
    # Display manager
    xserver = {
      enable = true;
      displayManager = {
        lightdm.enable = true;
        # sddm.enable = true;  # Alternative: KDE's display manager
        # gdm.enable = true;   # Alternative: GNOME's display manager
      };
      desktopManager = {
        gnome.enable = true;
        # plasma5.enable = true;  # Alternative: KDE Plasma
        # xfce.enable = true;     # Alternative: XFCE
      };
    };

    # Audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # Bluetooth
    blueman.enable = true;

    # Printing
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
    };
  };

  # Desktop environment variables
  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
    PAGER = "less";
    BROWSER = "firefox";
  };

  # Desktop-specific security
  security = {
    # Polkit for desktop applications
    polkit.enable = true;

    # PAM for desktop login
    pam.services = {
      lightdm.enableGnomeKeyring = true;
    };
  };
}
