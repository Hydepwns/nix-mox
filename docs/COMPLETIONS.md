# nix-mox Shell Completions Guide

> Universal intelligent completions for all supported shells

## 🎯 Overview

nix-mox provides comprehensive shell completions for:
- **Bash** - Traditional Linux shell completion
- **Zsh** - Advanced completion with descriptions
- **Fish** - Modern shell with rich completions
- **Nushell** - Native Nu completion integration

## 🚀 Quick Setup

### Auto-Detection & Installation
```bash
# Auto-detect shell and install completions
nu scripts/lib/completions.nu install_completions

# Or specify shell explicitly
nu scripts/lib/completions.nu install_completions bash
nu scripts/lib/completions.nu install_completions zsh
nu scripts/lib/completions.nu install_completions fish
nu scripts/lib/completions.nu install_completions nu
```

### Generate All Completions
```bash
# Generate completions for all shells
nu scripts/lib/completions.nu generate_all_completions

# Files created in ./completions/
ls completions/
# nix-mox-completion.bash
# _nix-mox
# nix-mox.fish  
# nix-mox-completion.nu
```

## 📚 Shell-Specific Setup

### Bash Completions

**Installation:**
```bash
# Generate bash completions
nu scripts/lib/completions.nu generate_bash_completions

# Add to ~/.bashrc
echo "source $(pwd)/completions/nix-mox-completion.bash" >> ~/.bashrc

# Reload shell
source ~/.bashrc
```

**Usage:**
```bash
nix-mox <TAB>              # Show all commands
nix-mox --platform <TAB>   # Show platform options
nix-mox --script <TAB>     # Show available scripts
```

### Zsh Completions

**Installation:**
```bash
# Generate zsh completions
nu scripts/lib/completions.nu generate_zsh_completions

# Add to ~/.zshrc
echo "fpath=($(pwd)/completions \$fpath)" >> ~/.zshrc
echo "autoload -U compinit && compinit" >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

**Features:**
- Rich descriptions for all options
- Context-aware completions
- Script name completion with descriptions
- File path completion for configs

### Fish Completions

**Installation:**
```bash
# Generate fish completions
nu scripts/lib/completions.nu generate_fish_completions

# Copy to fish config directory
cp completions/nix-mox.fish ~/.config/fish/completions/

# Completions activate automatically
```

**Features:**
- Modern completion interface
- Intelligent context awareness
- Real-time script discovery
- Visual completion descriptions

### Nushell Completions

**Installation:**
```bash
# Generate Nu completions
nu scripts/lib/completions.nu generate_nu_completions

# Add to config.nu
echo "source $(pwd)/completions/nix-mox-completion.nu" >> ~/.config/nushell/config.nu

# Restart Nu shell
```

**Native Integration:**
```nu
# Use completions directly in Nu
nix-mox setup        # Completion works automatically
nix-mox --platform   # Shows: linux, darwin, windows, auto
```

## 🎛️ Available Completions

### Main Commands
```bash
nix-mox <TAB>
setup        # Run interactive setup wizard
install      # Install nix-mox configuration  
update       # Update system configuration
test         # Run test suite
validate     # Validate configuration
monitor      # Show monitoring dashboard
cleanup      # Clean up temporary files
docs         # Generate documentation
security     # Run security scan
performance  # Show performance metrics
```

### Command Options
```bash
nix-mox --<TAB>
--platform   # Specify target platform
--config     # Use custom config file
--script     # Run specific script
--log-level  # Set logging level
--verbose    # Enable verbose output
--dry-run    # Show what would be done
--help       # Show help information
```

### Platform Completions
```bash
nix-mox --platform <TAB>
linux    # Linux/NixOS systems
darwin   # macOS systems  
windows  # Windows systems
auto     # Auto-detect platform
```

### Script Completions
```bash
nix-mox --script <TAB>
setup.nu              # Main setup script
health-check.nu        # System health validation
interactive-setup.nu   # Interactive configuration wizard
install.nu            # Installation script
cleanup.nu            # Project cleanup
# ... all discovered scripts with descriptions
```

### Log Level Completions
```bash
nix-mox --log-level <TAB>
DEBUG    # Detailed debugging information
INFO     # General information messages
WARN     # Warning messages
ERROR    # Error messages only
```

## 🔧 Advanced Configuration

### Custom Completion Functions

**Extend script completions:**
```nu
# Add to completions.nu
def complete_custom_scripts [] {
    [
        {value: "my-script", description: "Custom script for X"},
        {value: "deploy", description: "Deployment automation"}
    ]
}
```

**Add context-aware completions:**
```nu
def complete_with_context [context: string] {
    let words = ($context | split row " ")
    let current = ($words | last)
    
    # Custom logic based on context
    if ($context | str contains "--config") {
        glob "config/*.nix" | each {|f| {value: $f, description: "Config file"}}
    } else {
        complete_main_commands
    }
}
```

### Performance Optimization

**Cache completion data:**
```nu
# Enable completion caching
$env.NIX_MOX_COMPLETION_CACHE = "true"

# Cache expiry (seconds)
$env.NIX_MOX_COMPLETION_CACHE_TTL = "300"
```

**Lazy loading:**
```nu
# Only initialize when needed
def lazy_init_completions [] {
    if not $COMPLETION_STATE.initialized {
        init_completions
    }
}
```

## 🔍 Troubleshooting

### Completions Not Working

**1. Check shell detection:**
```bash
# Verify shell is detected correctly
nu -c 'use scripts/lib/completions.nu; detect_current_shell'
```

**2. Verify file permissions:**
```bash
# Ensure completion files are readable
ls -la completions/
chmod +r completions/*
```

**3. Check shell configuration:**
```bash
# Bash
grep -n "nix-mox-completion" ~/.bashrc

# Zsh  
grep -n "nix-mox" ~/.zshrc

# Fish
ls ~/.config/fish/completions/nix-mox.fish
```

### Slow Completions

**1. Enable caching:**
```bash
export NIX_MOX_COMPLETION_CACHE=true
export NIX_MOX_COMPLETION_CACHE_TTL=600
```

**2. Reduce script discovery scope:**
```nu
# Limit to specific directories
def discover_scripts_fast [dir: string] {
    glob $"($dir)/*.nu" | take 20  # Limit results
}
```

**3. Use completion profiling:**
```bash
# Bash - enable completion debugging
set -x  
nix-mox <TAB>
set +x

# Check timing
time nix-mox <TAB>
```

### Missing Completions

**1. Regenerate completion files:**
```bash
rm -rf completions/
nu scripts/lib/completions.nu generate_all_completions
```

**2. Check Nu availability:**
```bash
which nu
nu --version
```

**3. Verify script discovery:**
```bash
nu -c 'use scripts/lib/completions.nu; discover_scripts "scripts" | length'
```

## 🎨 Customization Examples

### Add Custom Commands
```nu
# Extend main command completions
def complete_main_commands [] {
    let default_commands = [
        {value: "setup", description: "Run interactive setup wizard"},
        # ... existing commands
    ]
    
    let custom_commands = [
        {value: "deploy", description: "Deploy to production"},
        {value: "rollback", description: "Rollback deployment"}
    ]
    
    $default_commands | append $custom_commands
}
```

### Environment-Specific Completions
```nu
# Different completions per environment
def complete_environments [] {
    match $env.NIX_MOX_ENV? {
        "production" => ["prod-deploy", "prod-status", "prod-logs"]
        "staging" => ["stage-deploy", "stage-test", "stage-reset"]
        _ => ["dev-build", "dev-test", "dev-watch"]
    }
}
```

### Dynamic Script Discovery
```nu
# Discover scripts based on current directory
def complete_context_scripts [] {
    let current_dir = (pwd | path basename)
    
    match $current_dir {
        "linux" => (glob "scripts/linux/*.nu")
        "macos" => (glob "scripts/macos/*.nu") 
        "windows" => (glob "scripts/windows/*.nu")
        _ => (glob "scripts/core/*.nu")
    } | each {|f| 
        {
            value: ($f | path basename),
            description: $"Script for ($current_dir)"
        }
    }
}
```

## 🚀 Integration Examples

### VS Code Integration
```json
// settings.json
{
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "bash",
      "args": ["--rcfile", "~/.bashrc"]
    }
  }
}
```

### CI/CD Integration
```yaml
# .github/workflows/completions.yml
- name: Test Completions
  run: |
    nu scripts/lib/completions.nu generate_all_completions
    bash -c 'source completions/nix-mox-completion.bash && complete -p nix-mox'
```

### Docker Integration
```dockerfile
# Add completions to container
COPY completions/ /etc/bash_completion.d/
RUN echo "source /etc/bash_completion.d/nix-mox-completion.bash" >> ~/.bashrc
```

## 📋 Best Practices

1. **Cache completion data** for better performance
2. **Test completions** in all supported shells
3. **Keep descriptions concise** but informative
4. **Update completions** when adding new scripts
5. **Profile completion performance** in large projects
6. **Use lazy loading** for expensive operations
7. **Provide fallbacks** when Nu is unavailable

## 📚 Further Reading

- [Bash Completion Guide](https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion.html)
- [Zsh Completion System](http://zsh.sourceforge.net/Doc/Release/Completion-System.html)
- [Fish Completion Tutorial](https://fishshell.com/docs/current/completions.html)
- [Nushell External Completions](https://www.nushell.sh/book/custom_completions.html#external-completer)

## 🎯 Tips & Tricks

1. **Test in clean shell** - `exec bash -l` to test without history
2. **Use completion debugging** - most shells have debug flags
3. **Profile slow completions** - identify bottlenecks early
4. **Cache expensive operations** - script discovery, function parsing
5. **Provide meaningful descriptions** - users rely on them for complex commands
6. **Handle errors gracefully** - completions should never break the shell
7. **Keep completions fast** - aim for <100ms response time