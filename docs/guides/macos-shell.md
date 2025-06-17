# macOS Development Shell

> **⚠️ Note:**
> As of Nixpkgs 25.11, the macOS SDK stubs (CoreServices, Foundation, MacOSX-SDK) used in this shell are deprecated and will be removed in a future release. The shell will continue to work for now, but you should monitor the [Nixpkgs Darwin documentation](https://nixos.org/manual/nixpkgs/stable/#sec-darwin) for migration instructions and update your configuration accordingly when new methods are available.

The macOS development shell provides a comprehensive development environment for macOS users, with tools and configurations optimized for macOS development.

## Features

### Core Development Tools

- Git for version control
- Nix and Nixpkgs-fmt for package management and formatting
- Shellcheck for shell script validation
- Coreutils for basic Unix commands
- fd and ripgrep for efficient file searching

### macOS Specific Tools

- CoreServices framework for macOS system integration
- Foundation framework for macOS development

### Development Tools

- Visual Studio Code for code editing
- nixpkgs-code-cursor for AI-powered code navigation and editing
- jq and yq for JSON and YAML processing
- curl and wget for network operations
- htop for system monitoring
- tmux for terminal multiplexing
- zsh with oh-my-zsh for enhanced shell experience

## Usage

### Entering the Shell

```bash
nix develop .#macos
```

### Available Commands

#### Git

```bash
git status                       # Check repository status
git log --oneline               # View commit history
```

#### Nix

```bash
nix develop                     # Enter development shell
nix build                       # Build packages
```

#### Using Development Tools

```bash
code .                          # Open current directory in VS Code
jq '.' file.json               # Pretty print JSON
yq eval '.' file.yaml          # Pretty print YAML
curl -O url                    # Download file
wget url                       # Download file
htop                           # System monitor
tmux new -s session           # New tmux session
tmux attach -t session        # Attach to tmux session
zsh                           # Start ZSH shell
```

#### Cursor (nixpkgs-code-cursor)

```bash
cursor .   # Launch Cursor editor in the current directory
```

### Help Menu

The shell provides a built-in help menu that can be accessed by typing:

```bash
help
```

This will show:

- Available tools and their versions
- Common commands for each tool
- Quick start guide
- Additional information

## Tips and Tricks

1. **Customizing the Shell**
   - The shell uses zsh with oh-my-zsh, which can be customized through your `.zshrc`
   - VS Code settings can be customized through the settings UI or `settings.json`

2. **Using tmux**
   - Create a new session: `tmux new -s mysession`
   - Attach to a session: `tmux attach -t mysession`
   - List sessions: `tmux ls`
   - Detach from session: `Ctrl+b d`

3. **System Monitoring**
   - Use `htop` for real-time system monitoring
   - Press `F1` in htop to see all available commands

## Troubleshooting

### Common Issues

1. **VS Code Not Found**
   - Ensure you're in the macOS shell: `which-shell`
   - Try reinstalling the shell: `nix develop .#macos`

2. **Framework Issues**
   - If you encounter framework-related errors, ensure you're on macOS
   - The shell is only available on macOS systems

3. **Shell Integration**
   - If oh-my-zsh isn't loading properly, check your `.zshrc`
   - You may need to source the Nix profile: `source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`

## Contributing

If you'd like to add more tools or features to the macOS shell:

1. Edit `devshells/macos/default.nix`
2. Add your tools to the `buildInputs` list
3. Update the help menu in the `shellHook`
4. Test your changes: `nix develop .#macos`
5. Submit a pull request

## Related Documentation

- [Main README](../README.md)
- [Development Guide](../CONTRIBUTING.md)
- [Usage Guide](../USAGE.md)
