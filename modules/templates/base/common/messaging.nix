{ config, pkgs, inputs, ... }:

{
  # Messaging and communication applications
  environment.systemPackages = with pkgs; [
    # Primary messaging apps (Signal and Telegram as requested)
    signal-desktop
    telegram-desktop

    # Additional popular messaging platforms
    discord
    slack
    element-desktop # Matrix client
    whatsapp-for-linux

    # Video calling and conferencing
    zoom-us
    teams
    skypeforlinux

    # Email clients
    thunderbird
    evolution

    # IRC and chat
    hexchat
    weechat

    # Voice and video
    mumble
    teamspeak_client
  ];

  # Enable necessary services for messaging apps
  services = {
    # Enable dbus for desktop notifications
    dbus.enable = true;

    # Enable gvfs for file access in messaging apps
    gvfs.enable = true;
  };

  # Configure desktop notifications for messaging apps
  services.dbus.packages = with pkgs; [
    signal-desktop
    telegram-desktop
    discord
    slack
  ];

  # Enable necessary hardware support for video calling
  hardware = {
    # Enable webcam support
    video4linux2.enable = true;

    # Enable audio support for voice calls
    pulseaudio.enable = false; # Disable if using PipeWire
  };

  # Configure PipeWire for audio/video calls (if not already configured)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true; # For professional audio applications
  };
}
