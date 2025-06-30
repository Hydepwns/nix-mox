# Desktop Profile
# Desktop environment and GUI applications shared across desktop templates
{ config, pkgs, ... }:
{
  # Desktop packages
  environment.systemPackages = with pkgs; [
    # Desktop environment
    gnome.gnome-tweaks
    gnome.gnome-software
    gnome.gnome-system-monitor
    gnome.gnome-disk-utility
    gnome.gnome-settings-daemon

    # File management
    nautilus
    thunar
    dolphin
    pcmanfm

    # Web browsers
    firefox
    chromium
    brave
    vivaldi

    # Office applications
    libreoffice
    gimp
    inkscape
    krita
    blender

    # Media applications
    vlc
    mpv
    spotify
    rhythmbox
    audacity

    # Communication
    discord
    telegram-desktop
    signal-desktop
    element-desktop
    slack

    # Terminal emulators
    kitty
    alacritty
    gnome.gnome-terminal
    konsole
    xfce4-terminal

    # System tools
    gnome.gnome-control-center
    gnome.gnome-calculator
    gnome.gnome-calendar
    gnome.gnome-maps
    gnome.gnome-weather

    # Utilities
    gnome.gnome-screenshot
    gnome.gnome-font-viewer
    gnome.gnome-color-manager
    gnome.gnome-documents
    gnome.gnome-music
  ];

  # Desktop programs
  programs = {
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

    # GNOME services
    gnome = {
      core-utilities.enable = true;
      core-developer-tools.enable = true;
      evolution-data-server.enable = true;
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = true;
      gnome-online-miners.enable = true;
      gnome-user-share.enable = true;
      gnome-remote-desktop.enable = true;
      gnome-initial-setup.enable = true;
    };
  };

  # Desktop environment variables
  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
    PAGER = "less";
    BROWSER = "firefox";

    # GNOME specific
    GNOME_DISABLE_CRASH_DIALOG = "1";
    GNOME_DISABLE_SAVE_WORKSPACE = "1";

    # XDG
    XDG_CURRENT_DESKTOP = "GNOME";
    XDG_SESSION_TYPE = "x11";
  };

  # Desktop-specific security
  security = {
    # Polkit for desktop applications
    polkit.enable = true;

    # PAM for desktop login
    pam.services = {
      lightdm.enableGnomeKeyring = true;
      gdm.enableGnomeKeyring = true;
    };
  };

  # Desktop shell configuration
  programs.zsh.interactiveShellInit = ''
    # Desktop aliases
    alias files="nautilus"
    alias settings="gnome-control-center"
    alias screenshot="gnome-screenshot"
    alias calc="gnome-calculator"
    alias calendar="gnome-calendar"
    
    # Quick access
    alias home="cd ~"
    alias desktop="cd ~/Desktop"
    alias downloads="cd ~/Downloads"
    alias documents="cd ~/Documents"
  '';

  # Desktop file associations
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "text/xml" = "firefox.desktop";
    "application/pdf" = "firefox.desktop";
    "image/jpeg" = "org.gnome.eog.desktop";
    "image/png" = "org.gnome.eog.desktop";
    "image/gif" = "org.gnome.eog.desktop";
    "video/mp4" = "vlc.desktop";
    "video/avi" = "vlc.desktop";
    "audio/mpeg" = "vlc.desktop";
    "audio/wav" = "vlc.desktop";
  };
}
