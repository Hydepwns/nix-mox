# Safe Configuration Template Changelog

## [2024-12-19] - Added Messaging and Communication Support

### Added

- **Messaging Applications**: Comprehensive messaging and communication support
  - **Signal Desktop**: Secure messaging with end-to-end encryption
  - **Telegram Desktop**: Feature-rich messaging platform
  - **Discord**: Gaming and community chat platform
  - **Slack**: Team collaboration and communication
  - **WhatsApp for Linux**: WhatsApp desktop client
  - **Element Desktop**: Matrix protocol client
  - **Thunderbird**: Email client
  - **Evolution**: GNOME email and calendar client

- **Video Calling & Conferencing**:
  - **Zoom**: Video conferencing platform
  - **Microsoft Teams**: Team collaboration platform
  - **Skype**: Voice and video calling

- **Voice & Chat Applications**:
  - **Mumble**: Low-latency voice chat
  - **TeamSpeak**: Voice communication
  - **HexChat**: IRC client
  - **WeeChat**: Modular chat client

- **Messaging Infrastructure**:
  - **New Fragment**: `messaging.nix` - Base messaging configuration fragment
  - **Communication Packages**: `modules/packages/productivity/communication.nix` - Centralized messaging packages
  - **Firewall Configuration**: WebRTC and STUN/TURN ports for voice/video calls
  - **D-Bus Integration**: Desktop notifications for messaging apps
  - **File Associations**: Deep linking support for messaging protocols
  - **Audio/Video Support**: Enhanced PipeWire configuration for calls

- **Setup Script Enhancements**:
  - Interactive prompts for messaging applications
  - Conditional configuration generation
  - Video calling application options
  - Email client configuration

### Updated

- **Base Common Template**: Added messaging fragment import
- **Safe Configuration**: Integrated messaging packages and services
- **Home Configuration**: Added desktop notifications and file associations
- **README.md**: Comprehensive documentation of messaging features
- **Test Suite**: Added 12 new tests for messaging functionality

### Technical Changes

- **Fragment System**: New `messaging.nix` fragment for reusable messaging configuration
- **Package Organization**: Centralized communication packages in productivity module
- **Service Integration**: D-Bus and GVFS services for messaging app support
- **Firewall Rules**: Added ports 3478-3479, 5349-5350, 16384-16387 for WebRTC
- **Audio Configuration**: Enhanced PipeWire setup with JACK support

### Compatibility

- **Backward Compatible**: All existing configurations continue to work
- **Optional Features**: Messaging applications are enabled by default but can be disabled
- **Display Safety**: No changes to display configuration that could cause CLI lock

### Usage

After deployment, messaging applications provide:

```bash
# Desktop applications available in application menu
signal-desktop
telegram-desktop
discord
slack

# Deep linking support
signal://your-phone-number
telegram://your-username

# Desktop notifications for new messages
# Audio/video calling capabilities
# File sharing and media support
```

## [2024-06-20] - Updated for nix-mox latest changes

### Added

- **New Package**: `nixos-flake-update` - Added to system packages for automated NixOS flake updates
- **New Dev Shell Aliases**: Added all available nix-mox development shells:
  - `dev-default` - Default development shell with base tools
  - `dev-development` - Development tools shell
  - `dev-testing` - Testing tools shell
  - `dev-services` - Service management tools shell
  - `dev-monitoring` - Monitoring tools shell
  - `dev-gaming` - Gaming development shell (Linux x86_64 only)
  - `dev-zfs` - ZFS tools shell (Linux only)
- **New Command Alias**: `nixos-update` - Quick access to nixos-flake-update command

### Updated

- **README.md**: Updated documentation to include all new packages and dev shells
- **setup.sh**: Updated setup script to include new package and dev shell aliases
- **configuration.nix**: Added nixos-flake-update to system packages
- **home.nix**: Added all new dev shell aliases and nixos-update command

### Technical Changes

- Test framework moved from `tests/` to `scripts/testing/` (internal change, doesn't affect safe config)
- All tests continue to pass ✅
- Display safety features remain intact
- nix-mox integration working correctly

### Compatibility

- **Backward Compatible**: All existing configurations will continue to work
- **New Features**: New packages and dev shells are available but optional
- **Display Safety**: No changes to display configuration that could cause CLI lock

### Usage

After updating, users can access:

```bash
# New system package
nixos-flake-update

# New dev shells
dev-default
dev-development
dev-testing
dev-services
dev-monitoring
dev-gaming
dev-zfs

# Quick command alias
nixos-update
```
