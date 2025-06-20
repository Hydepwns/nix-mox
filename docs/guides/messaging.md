# Messaging & Communication Guide

nix-mox provides comprehensive messaging and communication support with Signal Desktop, Telegram Desktop, Discord, Slack, and many other popular messaging applications.

## 🚀 Quick Start

### Enable Messaging Support

Add messaging to your NixOS configuration:

```nix
# config/nixos/configuration.nix
{ config, pkgs, inputs, ... }:
{
  imports = [
    ../../modules/templates/base/common/messaging.nix
  ];
  
  # Or use the complete base configuration
  imports = [
    ../../modules/templates/base/common.nix  # Includes messaging.nix
  ];
}
```

### Using Safe Configuration Template

The safe configuration template includes messaging support by default:

```bash
# Use the safe configuration template
cp -r modules/templates/nixos/safe-configuration/* config/

# Run interactive setup
./modules/templates/nixos/safe-configuration/setup.sh
```

## 📱 Primary Messaging Applications

### Signal Desktop

Secure messaging with end-to-end encryption.

```nix
# Signal Desktop is included by default
environment.systemPackages = with pkgs; [
  signal-desktop
];
```

**Features:**

- End-to-end encryption
- Desktop notifications
- File sharing
- Voice and video calls
- Deep linking support (`signal://`)

**Configuration:**

```nix
# Enable desktop notifications
services.dbus.packages = with pkgs; [ signal-desktop ];

# Configure file associations
programs.xdg.mimeApps.defaultApplications = {
  "x-scheme-handler/signal" = "signal-desktop.desktop";
};
```

### Telegram Desktop

Feature-rich messaging platform with bots and channels.

```nix
environment.systemPackages = with pkgs; [
  telegram-desktop
];
```

**Features:**

- Cloud-based messaging
- Bot support
- Channel subscriptions
- File sharing up to 2GB
- Voice and video calls
- Deep linking support (`telegram://`)

**Configuration:**

```nix
# Enable desktop notifications
services.dbus.packages = with pkgs; [ telegram-desktop ];

# Configure file associations
programs.xdg.mimeApps.defaultApplications = {
  "x-scheme-handler/telegram" = "telegram-desktop.desktop";
};
```

## 🎮 Gaming & Community Messaging

### Discord

Gaming and community chat platform.

```nix
environment.systemPackages = with pkgs; [
  discord
];
```

**Features:**

- Voice channels
- Text channels
- Server management
- Bot integration
- Screen sharing
- Game integration

### Slack

Team collaboration and communication.

```nix
environment.systemPackages = with pkgs; [
  slack
];
```

**Features:**

- Team workspaces
- Channel organization
- File sharing
- App integrations
- Video calls
- Thread conversations

## 📞 Video Calling & Conferencing

### Zoom

Video conferencing platform.

```nix
environment.systemPackages = with pkgs; [
  zoom-us
];
```

**Features:**

- HD video calls
- Screen sharing
- Meeting recording
- Virtual backgrounds
- Breakout rooms

### Microsoft Teams

Team collaboration platform.

```nix
environment.systemPackages = with pkgs; [
  teams
];
```

**Features:**

- Team chat
- Video meetings
- File collaboration
- Calendar integration
- App integrations

### Skype

Voice and video calling.

```nix
environment.systemPackages = with pkgs; [
  skypeforlinux
];
```

## 📧 Email Clients

### Thunderbird

Feature-rich email client.

```nix
environment.systemPackages = with pkgs; [
  thunderbird
];
```

**Features:**

- Multiple account support
- Calendar integration
- Add-on ecosystem
- Advanced filtering
- Encryption support

### Evolution

GNOME email and calendar client.

```nix
environment.systemPackages = with pkgs; [
  evolution
];
```

**Features:**

- GNOME integration
- Calendar and contacts
- Task management
- Exchange support
- Offline access

## 🎤 Voice & Chat Applications

### Mumble

Low-latency voice chat.

```nix
environment.systemPackages = with pkgs; [
  mumble
];
```

**Features:**

- Ultra-low latency
- Positional audio
- Server hosting
- Channel management
- Overlay support

### TeamSpeak

Voice communication platform.

```nix
environment.systemPackages = with pkgs; [
  teamspeak_client
];
```

**Features:**

- High-quality voice
- Server administration
- File sharing
- Permission system
- Mobile apps

### IRC Clients

#### HexChat

Modern IRC client.

```nix
environment.systemPackages = with pkgs; [
  hexchat
];
```

#### WeeChat

Modular chat client.

```nix
environment.systemPackages = with pkgs; [
  weechat
];
```

## 🔧 Advanced Configuration

### Desktop Notifications

Enable desktop notifications for all messaging apps:

```nix
# Enable D-Bus for notifications
services.dbus.enable = true;

# Configure notification packages
services.dbus.packages = with pkgs; [
  signal-desktop
  telegram-desktop
  discord
  slack
  thunderbird
  evolution
];
```

### File Associations

Configure deep linking and file associations:

```nix
programs.xdg = {
  enable = true;
  mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/signal" = "signal-desktop.desktop";
      "x-scheme-handler/telegram" = "telegram-desktop.desktop";
      "x-scheme-handler/discord" = "discord.desktop";
      "x-scheme-handler/slack" = "slack.desktop";
    };
  };
};
```

### Audio/Video Support

Configure PipeWire for voice and video calls:

```nix
# Enable real-time scheduling
security.rtkit.enable = true;

# Configure PipeWire
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  jack.enable = true;
};

# Enable webcam support
hardware.video4linux2.enable = true;
```

### Firewall Configuration

Configure firewall for messaging applications:

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [
    80 443    # HTTP/HTTPS for web-based messaging
    3478 3479 # STUN/TURN for WebRTC
    5349 5350 # STUN/TURN over TLS
    8080 8081 # Alternative ports
  ];
  allowedUDPPorts = [
    3478 3479 # STUN/TURN for WebRTC
    5349 5350 # STUN/TURN over TLS
    16384 16387 # WebRTC media ports
  ];
};
```

## 🧩 Fragment System Integration

### Using Messaging Fragment

Import only the messaging functionality:

```nix
# config/nixos/configuration.nix
{ config, pkgs, inputs, ... }:
{
  imports = [
    ../../modules/templates/base/common/messaging.nix
  ];
  
  # Your custom configuration
  networking.hostName = "my-desktop";
  time.timeZone = "America/New_York";
}
```

### Custom Messaging Configuration

Create custom messaging configurations:

```nix
# modules/templates/base/common/custom-messaging.nix
{ config, pkgs, inputs, ... }:
{
  imports = [
    ./messaging.nix
  ];
  
  # Add custom messaging packages
  environment.systemPackages = with pkgs; [
    # Additional messaging apps
    element-desktop  # Matrix client
    whatsapp-for-linux
    hexchat
    weechat
  ];
  
  # Custom notification settings
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 0;
        follow = "mouse";
        geometry = "300x5-30+20";
        indicate_hidden = "yes";
        shrink = "no";
        transparency = 0;
        notification_height = 0;
        separator_height = 2;
        padding = 8;
        horizontal_padding = 8;
        font = "Monospace 8";
        line_height = 0;
        idle_threshold = 120;
        markup = "full";
        format = "%s\n%b";
        alignment = "left";
        show_age_threshold = 60;
        word_wrap = "yes";
        ignore_newline = "no";
        stack_duplicates = "true";
        hide_duplicate_count = "false";
        show_indicators = "yes";
        icon_position = "left";
        max_icon_size = 32;
        icon_path = "/usr/share/pixmaps/:/usr/share/icons/hicolor/32x32/apps/";
        sticky_history = "yes";
        history_length = 20;
        dmenu = "/usr/bin/dmenu -p dunst:";
        browser = "/usr/bin/firefox -new-tab";
        always_run_script = "true";
        title = "Dunst";
        class = "Dunst";
        startup_notification = "false";
        verbosity = "mesg";
        corner_radius = 0;
        ignore_dbusclose = "false";
        force_xinerama = "false";
        mouse_left_click = "close_current";
        mouse_middle_click = "do_action";
        mouse_right_click = "close_all";
      };
    };
  };
}
```

## 🎯 Use Cases

### Personal Desktop Setup

```nix
# Personal desktop with messaging
{ config, pkgs, inputs, ... }:
{
  imports = [
    ../../modules/templates/base/common/display.nix
    ../../modules/templates/base/common/messaging.nix
    ../../modules/templates/base/common/packages.nix
  ];
  
  # Personal configuration
  networking.hostName = "personal-desktop";
  time.timeZone = "America/New_York";
}
```

### Gaming Setup with Communication

```nix
# Gaming setup with messaging
{ config, pkgs, inputs, ... }:
{
  imports = [
    ../../modules/templates/base/common/display.nix
    ../../modules/templates/base/common/messaging.nix
    ../../modules/templates/base/common/graphics.nix
  ];
  
  # Gaming-specific configuration
  programs.steam.enable = true;
  hardware.opengl.enable = true;
}
```

### Work Setup

```nix
# Work setup with professional messaging
{ config, pkgs, inputs, ... }:
{
  imports = [
    ../../modules/templates/base/common/networking.nix
    ../../modules/templates/base/common/messaging.nix
    ../../modules/templates/base/common/packages.nix
  ];
  
  # Work-specific packages
  environment.systemPackages = with pkgs; [
    slack
    teams
    thunderbird
    evolution
  ];
}
```

## 🔍 Troubleshooting

### Common Issues

#### Desktop Notifications Not Working

```bash
# Check D-Bus status
systemctl status dbus

# Check notification daemon
systemctl status dunst

# Test notifications
notify-send "Test" "This is a test notification"
```

#### Audio/Video Issues

```bash
# Check PipeWire status
systemctl status pipewire

# Check audio devices
pactl list short sources
pactl list short sinks

# Check video devices
v4l2-ctl --list-devices
```

#### Firewall Issues

```bash
# Check firewall status
systemctl status firewall

# Check open ports
netstat -tuln | grep -E "(80|443|3478|5349)"
```

### Debug Commands

```bash
# Check messaging app status
which signal-desktop
which telegram-desktop
which discord

# Check file associations
xdg-mime query default x-scheme-handler/signal
xdg-mime query default x-scheme-handler/telegram

# Check D-Bus packages
systemctl status dbus
```

### Audio/Video Troubleshooting

#### Microphone Not Working

```bash
# Check microphone status
pactl list sources short

# Set default microphone
pactl set-default-source <source_name>

# Test microphone
parecord --record-time=5 test.wav
paplay test.wav
```

#### Voice Chat Issues

```bash
# Check audio routing
pavucontrol

# Configure audio for messaging
# - Set messaging audio to headset
# - Set voice chat to separate device
# - Configure push-to-talk
```

#### Communication App Issues

```bash
# Check if apps are running
ps aux | grep signal
ps aux | grep telegram
ps aux | grep discord

# Restart apps
pkill signal-desktop
signal-desktop

# Check notification settings
dconf-editor
# Navigate to: /org/gnome/desktop/notifications/
```

## 📚 Related Documentation

- [Safe Configuration Guide](./safe-configuration.md) - Complete desktop setup
- [Gaming Guide](./gaming.md) - Gaming with communication
- [Development Workflow](./development-workflow.md) - Development practices
- [Troubleshooting Guide](./troubleshooting.md) - Common issues and solutions

## 🤝 Contributing

To add new messaging applications or improve existing ones:

1. Add packages to `modules/packages/productivity/communication.nix`
2. Update `modules/templates/base/common/messaging.nix`
3. Add tests to the test suite
4. Update this documentation

## Quick Reference

### Essential Commands

```bash
# Primary Messaging
signal-desktop         # Launch Signal
telegram-desktop       # Launch Telegram
discord                # Launch Discord
slack                  # Launch Slack

# Video Calling
zoom-us                # Launch Zoom
teams                  # Launch Microsoft Teams
skypeforlinux          # Launch Skype

# Email
thunderbird            # Launch Thunderbird
evolution              # Launch Evolution

# Voice & Chat
mumble                 # Launch Mumble
teamspeak_client       # Launch TeamSpeak
hexchat                # Launch HexChat
weechat                # Launch WeeChat
```

### Configuration Files

```bash
# Messaging fragment
modules/templates/base/common/messaging.nix

# Communication packages
modules/packages/productivity/communication.nix

# Safe configuration
modules/templates/platforms/nixos/safe-configuration/configuration.nix
```

### Environment Variables

```bash
# Audio settings
PULSE_LATENCY_MSEC=60

# WebRTC settings
WEBRTC_USE_PIPEWIRE=1
```

---

**Need help?** Check the [Troubleshooting Guide](./troubleshooting.md) or open an issue on GitHub.
