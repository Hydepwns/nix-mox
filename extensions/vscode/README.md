# nix-mox Nushell Support for VS Code

Enhanced Nushell scripting tools for nix-mox: run, test, validate, and document .nu scripts with integrated metrics and security checks.

## Features

### 🚀 Core Functionality

- **Script Execution**: Run Nushell scripts directly from VS Code (Ctrl+F5)
- **Testing**: Execute and manage test suites (Ctrl+Shift+T)
- **Security Validation**: Automatic security scanning for dangerous patterns
- **Performance Metrics**: Real-time monitoring and analytics
- **Documentation Generation**: Auto-generate documentation for your scripts

### 🎨 Language Support

- **Syntax Highlighting**: Full Nushell syntax support with Synthwave '84 theme
- **IntelliSense**: Smart completions for nix-mox functions and Nushell commands
- **Hover Information**: Inline documentation and help
- **Go to Definition**: Navigate to function definitions

### 🔧 Code Quality Tools

- **Linting & Diagnostics**: Real-time error detection and warnings
- **Auto-formatting**: Clean up code formatting (Ctrl+Shift+F)
- **Code Actions**: Quick fixes for common issues
- **Snippets**: Pre-built templates for common nix-mox patterns

### 📝 Snippets Included

- `nixmox-header`: Standard script template with error handling
- `nixmox-test`: Test function template
- `nixmox-error`: Error handling block
- `nixmox-platform`: Platform-specific logic
- `nixmox-config`: Configuration loader

## Installation

1. Install the extension from the VS Code marketplace
2. Open a `.nu` file to activate the extension
3. Use the command palette (Ctrl+Shift+P) to access nix-mox commands

## Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| Run Script | Ctrl+F5 | Execute the current Nushell script |
| Test Script | Ctrl+Shift+T | Run tests for the current script |
| Validate Script | - | Security validation |
| Format Document | Ctrl+Shift+F | Format the current document |
| Show Metrics | - | Display performance metrics |
| Generate Docs | - | Create documentation |
| Setup Wizard | - | Initial setup and configuration |

## Configuration

### Extension Settings

```json
{
  "nix-mox.nushellPath": "nu",
  "nix-mox.enableMetrics": true,
  "nix-mox.securityValidation": true,
  "nix-mox.autoFormat": true,
  "nix-mox.testTimeout": 30,
  "nix-mox.enableLinting": true,
  "nix-mox.enableFormatting": true,
  "nix-mox.formatOnSave": false,
  "nix-mox.lintSeverity": "warning"
}
```

## Linting Features

The extension provides real-time diagnostics for:

- **Trailing whitespace** (Info)
- **Dangerous commands** (Error)
- **Missing error handling** (Warning)
- **Hardcoded paths** (Warning)
- **TODO comments** (Info)
- **FIXME comments** (Warning)

## Code Actions

Quick fixes available for:

- Remove trailing whitespace
- Add error handling to try blocks
- Convert tabs to spaces
- Fix common syntax issues

## Theme

The extension includes the iconic **Synthwave '84** theme for a retro aesthetic that matches the nix-mox vibe.

## Development

### Building the Extension

```bash
npm install
npm run compile
```

### Testing

1. Open the test file `test.nu` in VS Code
2. Observe the linting diagnostics in the Problems panel
3. Try the formatting command (Ctrl+Shift+F)
4. Test code actions by right-clicking on diagnostics

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

- **Issues**: Report bugs and feature requests on GitHub
- **Documentation**: Check the nix-mox documentation
- **Community**: Join the nix-mox community discussions
