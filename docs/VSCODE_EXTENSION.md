# nix-mox VS Code Extension

> Enhanced Nushell development experience with intelligent features

## 🎯 Overview

The nix-mox VS Code extension provides comprehensive IDE support for Nushell script development with:

- **Advanced syntax highlighting** for Nu scripts
- **Intelligent code completion** with nix-mox function awareness
- **Integrated script execution** with one-click running and testing
- **Real-time security validation** with dangerous pattern detection
- **Performance metrics viewer** built into VS Code
- **Interactive setup wizard** integration

## 🚀 Installation

### Method 1: From Source (Recommended)

```bash
# Navigate to your nix-mox directory
cd nix-mox

# Install dependencies
cd extensions/vscode
npm install

# Compile TypeScript
npm run compile

# Install extension in VS Code
code --install-extension ./nix-mox-nushell-1.0.0.vsix
```

### Method 2: Development Installation

```bash
# Link for development
cd extensions/vscode
code .

# Press F5 to launch Extension Development Host
# Your nix-mox extension will be loaded automatically
```

### Method 3: Manual Installation

1. **Copy extension directory**:
   ```bash
   cp -r extensions/vscode ~/.vscode/extensions/nix-mox-nushell-1.0.0/
   ```

2. **Restart VS Code**

3. **Verify installation**:
   - Open a `.nu` file
   - Check that syntax highlighting is active
   - Press `Ctrl+Shift+P` and search "nix-mox"

## ⚡ Features

### 1. Enhanced Language Support

**Syntax Highlighting:**
- Complete Nushell grammar support
- nix-mox-specific function highlighting
- Error pattern recognition
- Comment and documentation styling

**Code Completion:**
- 25+ nix-mox function completions
- Context-aware suggestions
- Parameter hints and documentation
- Import statement assistance

### 2. Integrated Commands

**Script Execution (Ctrl+F5):**
```
⚡ Run current Nu script
📊 Automatic performance tracking
🔍 Real-time output in terminal
```

**Testing Integration (Ctrl+Shift+T):**
```
🧪 Run individual test files
📈 Execute full test suite
📋 Coverage reporting
```

**Security Validation:**
```
🛡️ Scan for dangerous patterns
⚠️ Real-time threat detection
💡 Security recommendations
```

### 3. Performance Monitoring

**Metrics Dashboard:**
- Real-time performance data
- Script execution statistics
- Error rate monitoring
- System resource usage

**Access via:** `Ctrl+Shift+P` → "nix-mox: Show Performance Metrics"

### 4. Interactive Features

**Setup Wizard Integration:**
```
🧙‍♂️ Launch interactive setup from VS Code
⚙️ Guided configuration process
📝 Automatic code generation
```

**Documentation Generation:**
```
📚 Auto-generate API docs
🔗 Link functions to source
📖 Export comprehensive guides
```

## 🎮 Usage Guide

### Getting Started

1. **Open nix-mox project** in VS Code
2. **Open any `.nu` file** - extension activates automatically
3. **Start developing** with enhanced features

### Script Development Workflow

1. **Create new script**:
   - Type `nixmox-header` for complete script template
   - Includes error handling, logging, platform detection

2. **Add functionality**:
   - Use `nixmox-test` for test functions
   - Use `nixmox-error` for error handling blocks
   - Use `nixmox-platform` for platform-specific code

3. **Run and test**:
   - Press `Ctrl+F5` to execute script
   - Press `Ctrl+Shift+T` to run tests
   - View results in integrated terminal

4. **Validate security**:
   - Right-click → "Validate Script Security"
   - Review automatic threat detection
   - Address security recommendations

### Code Snippets

The extension includes 10+ powerful snippets:

#### Script Structure
- `nixmox-header` - Complete script template with imports
- `nixmox-imports` - Common nix-mox module imports
- `nixmox-test` - Test function with error handling

#### Error Handling
- `nixmox-error` - Try-catch with structured error handling
- `nixmox-assert` - Common assertion patterns

#### Platform & Configuration
- `nixmox-platform` - Platform-specific code blocks
- `nixmox-config` - Configuration loading and access

#### Monitoring & Performance
- `nixmox-perf` - Performance monitoring wrapper
- `nixmox-metrics` - Custom metrics tracking
- `nixmox-security` - Security validation blocks

#### Logging
- `nixmox-log` - Logging function calls

### Command Palette Actions

Access via `Ctrl+Shift+P`:

```
nix-mox: Run Script              - Execute current script
nix-mox: Test Script             - Run tests for current file  
nix-mox: Validate Script Security - Security scan
nix-mox: Show Performance Metrics - Open metrics dashboard
nix-mox: Generate Documentation  - Create API docs
nix-mox: Run Setup Wizard        - Interactive configuration
```

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+F5` | Run current script |
| `Ctrl+Shift+T` | Run tests |
| `F12` | Go to definition |
| `Ctrl+Space` | Trigger completions |
| `Ctrl+Shift+P` | Command palette |

## ⚙️ Configuration

### Extension Settings

Access via `File` → `Preferences` → `Settings` → Search "nix-mox":

```json
{
  "nix-mox.nushellPath": "nu",
  "nix-mox.enableMetrics": true,
  "nix-mox.securityValidation": true,
  "nix-mox.autoFormat": true,
  "nix-mox.testTimeout": 30,
  "nix-mox.showWelcome": true
}
```

**Setting Descriptions:**

- **`nushellPath`**: Path to Nu executable (default: "nu")
- **`enableMetrics`**: Enable performance tracking (default: true)
- **`securityValidation`**: Auto-validate security on save (default: true)
- **`autoFormat`**: Format code automatically (default: true)
- **`testTimeout`**: Test execution timeout in seconds (default: 30)
- **`showWelcome`**: Show welcome message on activation (default: true)

### Workspace Configuration

Create `.vscode/settings.json` in your project:

```json
{
  "nix-mox.nushellPath": "/usr/local/bin/nu",
  "nix-mox.enableMetrics": true,
  "files.associations": {
    "*.nu": "nushell"
  },
  "editor.tabSize": 4,
  "editor.insertSpaces": true
}
```

### Custom Themes

The extension includes a custom dark theme optimized for nix-mox development:

**Activate via:** `Ctrl+Shift+P` → "Preferences: Color Theme" → "nix-mox Dark"

## 🔍 Advanced Features

### Intelligent Code Completion

The extension provides context-aware completions:

**Function Completions:**
```nu
detect_platform    # Platform detection
log_info          # Logging functions  
track_test        # Test utilities
create_error      # Error handling
validate_script_security  # Security validation
```

**Hover Information:**
- Function documentation
- Parameter descriptions  
- Usage examples
- Links to source code

**Go to Definition:**
- Jump to function definitions
- Navigate between modules
- Find implementation details

### Real-time Diagnostics

**Security Issues:**
- Dangerous command detection (`rm -rf /`)
- Unescaped user input warnings
- Privilege escalation alerts

**Code Quality:**
- Missing error handling warnings
- Unused variable detection
- Style consistency suggestions

### Performance Monitoring Integration

**Metrics Dashboard:**
- Script execution times
- Memory usage patterns
- Error rate tracking
- Platform-specific performance

**Performance Alerts:**
- Slow script warnings
- Memory usage spikes
- Error rate increases

### Debugging Support

**Integrated Terminal:**
- Automatic environment setup
- Real-time output streaming  
- Error highlighting
- Stack trace navigation

**Variable Inspection:**
- Hover to see variable values
- Structured data visualization
- Type information display

## 🚨 Troubleshooting

### Extension Not Loading

1. **Check VS Code version** (requires 1.74.0+):
   ```bash
   code --version
   ```

2. **Verify installation**:
   ```bash
   code --list-extensions | grep nix-mox
   ```

3. **Check extension logs**:
   - `Ctrl+Shift+P` → "Developer: Reload Window"
   - `Ctrl+Shift+P` → "Developer: Toggle Developer Tools"
   - Check Console for errors

### Syntax Highlighting Issues

1. **File association**:
   - Ensure `.nu` files are associated with "nushell"
   - `Ctrl+Shift+P` → "Change Language Mode" → "Nushell"

2. **Theme conflicts**:
   - Try "nix-mox Dark" theme
   - Check for conflicting extensions

### Command Execution Problems

1. **Nushell path**:
   ```bash
   which nu  # Verify Nu is in PATH
   ```

2. **Extension settings**:
   - Check `nix-mox.nushellPath` setting
   - Ensure path is correct

3. **Permissions**:
   ```bash
   ls -la /path/to/script.nu  # Check file permissions
   ```

### Performance Issues

1. **Disable unused features**:
   ```json
   {
     "nix-mox.enableMetrics": false,
     "nix-mox.securityValidation": false
   }
   ```

2. **Increase timeouts**:
   ```json
   {
     "nix-mox.testTimeout": 60
   }
   ```

## 🔧 Development

### Building from Source

```bash
# Clone repository
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox/extensions/vscode

# Install dependencies
npm install

# Compile TypeScript
npm run compile

# Watch for changes (development)
npm run watch

# Package extension
npm run package
```

### Contributing

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Make changes in** `extensions/vscode/src/`
4. **Test thoroughly** with Extension Development Host
5. **Submit pull request**

### Extension Structure

```
extensions/vscode/
├── package.json           # Extension manifest
├── src/
│   └── extension.ts      # Main extension code
├── snippets/
│   └── nix-mox.json     # Code snippets
├── syntaxes/
│   └── nushell.tmGrammar.json  # Syntax highlighting
├── themes/
│   └── nix-mox-dark.json     # Custom theme
└── language-configuration.json  # Language config
```

## 📚 Related Documentation

- **[Shell Completions](COMPLETIONS.md)** - Universal completion setup
- **[API Reference](API.md)** - Complete function documentation  
- **[Testing Guide](TESTING.md)** - Comprehensive test framework
- **[Monitoring Setup](MONITORING.md)** - Performance monitoring

## 🎯 Tips & Best Practices

1. **Use snippets extensively** - type `nixmox-` and tab through options
2. **Enable auto-save** - security validation runs on save
3. **Customize keyboard shortcuts** - adapt to your workflow  
4. **Monitor performance** - use integrated metrics dashboard
5. **Validate security regularly** - especially for production scripts
6. **Leverage hover documentation** - learn functions while coding
7. **Use Go to Definition** - explore nix-mox internals efficiently