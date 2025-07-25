# nix-mox Zed Extension

> Enhanced Nushell development experience with intelligent features for Zed editor

## 🎯 Overview

The nix-mox Zed extension provides comprehensive IDE support for Nushell script development with:

- **Advanced syntax highlighting** for Nu scripts
- **Intelligent code completion** with nix-mox function awareness
- **Integrated script execution** with one-click running and testing
- **Real-time security validation** with dangerous pattern detection
- **Performance metrics viewer** built into Zed
- **Interactive setup wizard** integration

## 🚀 Installation

### Method 1: From Source (Recommended)

```bash
# Navigate to your nix-mox directory
cd nix-mox

# Build and install the extension
cd extensions/zed
./build.sh --install
```

### Method 2: Development Installation

```bash
# Build for development
cd extensions/zed
cargo build

# Install manually
cp -r target/release/nix-mox-zed-1.0.0 ~/.config/zed/extensions/
```

### Method 3: Manual Installation

1. **Build extension**:

   ```bash
   cd extensions/zed
   cargo build --release
   ```

2. **Copy to Zed extensions**:

   ```bash
   cp -r target/release/nix-mox-zed-1.0.0 ~/.config/zed/extensions/
   ```

3. **Restart Zed**

4. **Verify installation**:
   - Open a `.nu` file
   - Check that syntax highlighting is active
   - Use `Cmd/Ctrl+Shift+P` and search "nix-mox"

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

**Script Execution (Cmd/Ctrl+Shift+P → "nix-mox:run-script"):**

```
⚡ Run current Nu script
📊 Automatic performance tracking
🔍 Real-time output in terminal
```

**Testing Integration (Cmd/Ctrl+Shift+P → "nix-mox:test-script"):**

```
🧪 Run individual test files
📈 Execute full test suite
📋 Coverage reporting
```

**Security Validation (Cmd/Ctrl+Shift+P → "nix-mox:validate-security"):**

```
🛡️ Scan for dangerous patterns
⚠️ Real-time threat detection
💡 Security recommendations
```

### 3. Performance Monitoring

**Metrics Dashboard (Cmd/Ctrl+Shift+P → "nix-mox:show-metrics"):**

- Real-time performance data
- Script execution statistics
- Error rate monitoring
- System resource usage

### 4. Interactive Features

**Setup Wizard Integration (Cmd/Ctrl+Shift+P → "nix-mox:setup-wizard"):**

```
🧙‍♂️ Launch interactive setup from Zed
⚙️ Guided configuration process
📝 Automatic code generation
```

**Documentation Generation (Cmd/Ctrl+Shift+P → "nix-mox:generate-docs"):**

```
📚 Auto-generate API docs
🔗 Link functions to source
📖 Export comprehensive guides
```

## 🎮 Usage Guide

### Getting Started

1. **Open nix-mox project** in Zed
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
   - Use `Cmd/Ctrl+Shift+P` → "nix-mox:run-script" to execute script
   - Use `Cmd/Ctrl+Shift+P` → "nix-mox:test-script" to run tests
   - View results in integrated terminal

4. **Validate security**:
   - Use `Cmd/Ctrl+Shift+P` → "nix-mox:validate-security"
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

Access via `Cmd/Ctrl+Shift+P`:

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
| `Cmd/Ctrl+Shift+P` | Command palette |
| `Cmd/Ctrl+Space` | Trigger completions |
| `F12` | Go to definition |

## ⚙️ Configuration

### Extension Settings

The extension automatically configures itself based on your nix-mox installation. No manual configuration required.

### Workspace Configuration

The extension integrates seamlessly with your existing nix-mox project structure.

## 🔧 Development

### Building from Source

```bash
# Clone repository
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox/extensions/zed

# Install dependencies
cargo build

# Build for release
cargo build --release

# Install extension
./build.sh --install
```

### Contributing

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Make changes in** `extensions/zed/src/`
4. **Test thoroughly** with Zed
5. **Submit pull request**

### Extension Structure

```
extensions/zed/
├── extension.json        # Extension manifest
├── Cargo.toml           # Rust dependencies
├── src/
│   ├── main.rs         # Main extension code
│   ├── commands.rs     # Command implementations
│   ├── snippets.rs     # Code snippets
│   ├── themes.rs       # Custom themes
│   └── language_server.rs # Language server integration
├── build.sh            # Build script
└── README.md           # Extension documentation
```

## 🐛 Troubleshooting

### Common Issues

### Extension Not Loading

1. **Check installation**:

   ```bash
   ls ~/.config/zed/extensions/
   ```

2. **Verify build**:

   ```bash
   cd extensions/zed
   cargo build --release
   ```

3. **Check Zed logs**:
   - Restart Zed
   - Check for error messages

### Syntax Highlighting Issues

1. **File association**:
   - Ensure `.nu` files are associated with "nushell"
   - Check file extension recognition

2. **Theme conflicts**:
   - Try "nix-mox Dark" theme
   - Check for conflicting extensions

### Command Execution Problems

1. **Nushell path**:

   ```bash
   which nu  # Verify Nu is in PATH
   ```

2. **Permissions**:

   ```bash
   ls -la /path/to/script.nu  # Check file permissions
   ```

### Performance Issues

1. **Disable unused features**:
   - The extension is lightweight by default
   - No performance impact on normal usage

## 📚 Additional Resources

- **[nix-mox Documentation](docs/)** - Complete project documentation
- **[Zed Editor](https://zed.dev/)** - Official Zed documentation
- **[Nushell](https://www.nushell.sh/)** - Nushell documentation
- **[Rust](https://www.rust-lang.org/)** - Rust programming language

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This extension is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Zed Team** for the excellent editor
- **Nushell Team** for the amazing shell
- **Rust Community** for the powerful language
- **nix-mox Contributors** for the comprehensive toolkit
