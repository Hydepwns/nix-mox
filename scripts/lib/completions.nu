#!/usr/bin/env nu

# Shell completion system for nix-mox
# Provides intelligent completions for all nix-mox commands and functions

use discovery.nu *
use platform.nu *

# Global completion state
mut $COMPLETION_STATE = {
    scripts: [],
    functions: [],
    configs: [],
    platforms: ["linux", "darwin", "windows", "auto"],
    initialized: false
}

# Initialize completion system
export def init_completions [] {
    if $COMPLETION_STATE.initialized {
        return
    }
    
    print "🔄 Initializing nix-mox completions..."
    
    # Discover all scripts
    $COMPLETION_STATE.scripts = discover_scripts "scripts"
    
    # Extract all exported functions
    $COMPLETION_STATE.functions = extract_all_functions
    
    # Load configuration keys
    $COMPLETION_STATE.configs = extract_config_keys
    
    $COMPLETION_STATE.initialized = true
    print "✅ Completions initialized"
}

# Extract all exported functions from library modules
def extract_all_functions [] {
    let lib_files = (glob "scripts/lib/*.nu")
    mut all_functions = []
    
    for file in $lib_files {
        let content = (open $file)
        let functions = ($content | lines | where { |line| $line | str starts-with "export def " } | each { |line|
            let parts = ($line | split row " ")
            if ($parts | length) >= 3 {
                let func_name = ($parts | get 2 | split row " " | get 0)
                {
                    name: $func_name,
                    module: ($file | path basename),
                    signature: $line
                }
            }
        })
        $all_functions = ($all_functions | append $functions)
    }
    
    $all_functions
}

# Extract configuration keys from default config
def extract_config_keys [] {
    let config_keys = [
        "logging.level", "logging.file", "logging.format",
        "storage.pool", "storage.devices", "storage.compression",
        "performance.enabled", "performance.monitoring_interval",
        "security.level", "security.fail2ban", "security.auto_updates",
        "network.manager", "network.firewall", "network.ssh",
        "platform", "hostname", "timezone", "locale"
    ]
    $config_keys
}

# Generate completions for nix-mox main command
export def complete_nix_mox [context: string] {
    let words = ($context | split row " ")
    let current_word = ($words | last)
    let previous_word = if ($words | length) > 1 { $words | get (($words | length) - 2) } else { "" }
    
    match $previous_word {
        "--platform" => $COMPLETION_STATE.platforms
        "--config" => complete_config_paths
        "--script" => complete_script_names
        "--log-level" => ["DEBUG", "INFO", "WARN", "ERROR"]
        _ => complete_main_commands
    }
}

# Complete main nix-mox commands
def complete_main_commands [] {
    [
        {value: "setup", description: "Run interactive setup wizard"},
        {value: "install", description: "Install nix-mox configuration"},
        {value: "update", description: "Update system configuration"},
        {value: "test", description: "Run test suite"},
        {value: "validate", description: "Validate configuration"},
        {value: "monitor", description: "Show monitoring dashboard"},
        {value: "cleanup", description: "Clean up temporary files"},
        {value: "docs", description: "Generate documentation"},
        {value: "security", description: "Run security scan"},
        {value: "performance", description: "Show performance metrics"},
        {value: "--platform", description: "Specify target platform"},
        {value: "--config", description: "Use custom config file"},
        {value: "--script", description: "Run specific script"},
        {value: "--verbose", description: "Enable verbose output"},
        {value: "--dry-run", description: "Show what would be done"},
        {value: "--help", description: "Show help information"}
    ]
}

# Complete script names
def complete_script_names [] {
    if not $COMPLETION_STATE.initialized {
        init_completions
    }
    
    $COMPLETION_STATE.scripts | each { |script|
        {
            value: $script.name,
            description: ($script.description | default "nix-mox script")
        }
    }
}

# Complete configuration paths
def complete_config_paths [] {
    if not $COMPLETION_STATE.initialized {
        init_completions
    }
    
    $COMPLETION_STATE.configs | each { |key|
        {value: $key, description: "Configuration key"}
    }
}

# Complete function names for debugging/development
export def complete_functions [context: string] {
    if not $COMPLETION_STATE.initialized {
        init_completions
    }
    
    $COMPLETION_STATE.functions | each { |func|
        {
            value: $func.name,
            description: $"Function from ($func.module)"
        }
    }
}

# Complete file paths with nix-mox context
export def complete_files [context: string, extension: string = ""] {
    let current_dir = (pwd)
    let pattern = if ($extension | is-empty) { "*" } else { $"*($extension)" }
    
    let files = (glob $pattern | each { |file|
        let relative_path = ($file | str replace $current_dir "." | str replace "//" "/")
        {
            value: $relative_path,
            description: if ($file | path type) == "dir" { "Directory" } else { "File" }
        }
    })
    
    $files
}

# Generate bash completion script
export def generate_bash_completions [] {
    let bash_script = $"#!/bin/bash

# nix-mox bash completion script
# Source this file or add to ~/.bashrc

_nix_mox_completions() {
    local cur prev opts
    COMPREPLY=()
    cur=\"\\$\\{COMP_WORDS[COMP_CWORD]\\}\"
    prev=\"\\$\\{COMP_WORDS[COMP_CWORD-1]\\}\"
    
    case \\$prev in
        --platform)
            COMPREPLY=(\\$(compgen -W \"linux darwin windows auto\" -- \\$cur))
            return 0
            ;;
        --config)
            COMPREPLY=(\\$(compgen -f -- \\$cur))
            return 0
            ;;
        --script)
            local scripts=(\\$(nu -c 'use scripts/lib/completions.nu; complete_script_names | get value | str join \" \"' 2>/dev/null))
            COMPREPLY=(\\$(compgen -W \"\\$scripts\" -- \\$cur))
            return 0
            ;;
        --log-level)
            COMPREPLY=(\\$(compgen -W \"DEBUG INFO WARN ERROR\" -- \\$cur))
            return 0
            ;;
    esac
    
    opts=\"setup install update test validate monitor cleanup docs security performance --platform --config --script --verbose --dry-run --help\"
    COMPREPLY=(\\$(compgen -W \"\\$opts\" -- \\$cur))
}

complete -F _nix_mox_completions nix-mox
complete -F _nix_mox_completions nu scripts/common/nix-mox.nu
"

    $bash_script | save "completions/nix-mox-completion.bash"
    print "✅ Bash completions generated: completions/nix-mox-completion.bash"
}

# Generate zsh completion script
export def generate_zsh_completions [] {
    let zsh_script = $"#compdef nix-mox

# nix-mox zsh completion script

_nix_mox() {
    local context state line
    typeset -A opt_args

    _arguments \\
        '--platform[Specify target platform]:platform:(linux darwin windows auto)' \\
        '--config[Use custom config file]:config file:_files' \\
        '--script[Run specific script]:script name:_nix_mox_scripts' \\
        '--log-level[Set log level]:level:(DEBUG INFO WARN ERROR)' \\
        '--verbose[Enable verbose output]' \\
        '--dry-run[Show what would be done]' \\
        '--help[Show help information]' \\
        '1:command:_nix_mox_commands'
}

_nix_mox_commands() {
    local commands
    commands=(
        'setup:Run interactive setup wizard'
        'install:Install nix-mox configuration' 
        'update:Update system configuration'
        'test:Run test suite'
        'validate:Validate configuration'
        'monitor:Show monitoring dashboard' 
        'cleanup:Clean up temporary files'
        'docs:Generate documentation'
        'security:Run security scan'
        'performance:Show performance metrics'
    )
    _describe 'nix-mox commands' commands
}

_nix_mox_scripts() {
    local scripts
    if command -v nu >/dev/null; then
        scripts=(\\$(nu -c 'use scripts/lib/completions.nu; complete_script_names | each {|s| \\$\"\\$s.value:\\$s.description\"} | str join \" \"' 2>/dev/null))
        _describe 'nix-mox scripts' scripts
    fi
}

_nix_mox
"

    $zsh_script | save "completions/_nix-mox"
    print "✅ Zsh completions generated: completions/_nix-mox"
}

# Generate fish completion script
export def generate_fish_completions [] {
    let fish_script = $"# nix-mox fish completion script

# Main commands
complete -c nix-mox -f
complete -c nix-mox -n '__fish_use_subcommand' -a 'setup' -d 'Run interactive setup wizard'
complete -c nix-mox -n '__fish_use_subcommand' -a 'install' -d 'Install nix-mox configuration'
complete -c nix-mox -n '__fish_use_subcommand' -a 'update' -d 'Update system configuration'
complete -c nix-mox -n '__fish_use_subcommand' -a 'test' -d 'Run test suite'
complete -c nix-mox -n '__fish_use_subcommand' -a 'validate' -d 'Validate configuration'
complete -c nix-mox -n '__fish_use_subcommand' -a 'monitor' -d 'Show monitoring dashboard'
complete -c nix-mox -n '__fish_use_subcommand' -a 'cleanup' -d 'Clean up temporary files'
complete -c nix-mox -n '__fish_use_subcommand' -a 'docs' -d 'Generate documentation'
complete -c nix-mox -n '__fish_use_subcommand' -a 'security' -d 'Run security scan'
complete -c nix-mox -n '__fish_use_subcommand' -a 'performance' -d 'Show performance metrics'

# Options
complete -c nix-mox -l platform -d 'Specify target platform' -xa 'linux darwin windows auto'
complete -c nix-mox -l config -d 'Use custom config file' -r
complete -c nix-mox -l script -d 'Run specific script' -xa '(nu -c \"use scripts/lib/completions.nu; complete_script_names | get value\" 2>/dev/null)'
complete -c nix-mox -l log-level -d 'Set log level' -xa 'DEBUG INFO WARN ERROR'
complete -c nix-mox -l verbose -d 'Enable verbose output'
complete -c nix-mox -l dry-run -d 'Show what would be done'
complete -c nix-mox -l help -d 'Show help information'
"

    $fish_script | save "completions/nix-mox.fish"
    print "✅ Fish completions generated: completions/nix-mox.fish"
}

# Generate Nushell completion script
export def generate_nu_completions [] {
    let nu_script = $"# nix-mox Nushell completion script

# Custom completions for nix-mox
export extern \"nix-mox\" [
    command?: string@complete_nix_mox_commands    # Main command
    --platform(-p): string@complete_platforms    # Target platform  
    --config(-c): path                           # Config file path
    --script(-s): string@complete_script_names   # Script name
    --log-level(-l): string@complete_log_levels  # Log level
    --verbose(-v)                                # Verbose output
    --dry-run(-n)                               # Dry run mode
    --help(-h)                                  # Show help
]

def complete_nix_mox_commands [] {
    [
        \"setup\", \"install\", \"update\", \"test\", \"validate\",
        \"monitor\", \"cleanup\", \"docs\", \"security\", \"performance\"
    ]
}

def complete_platforms [] {
    [\"linux\", \"darwin\", \"windows\", \"auto\"]
}

def complete_script_names [] {
    try {
        nu -c 'use scripts/lib/completions.nu; complete_script_names | get value'
    } catch {
        []
    }
}

def complete_log_levels [] {
    [\"DEBUG\", \"INFO\", \"WARN\", \"ERROR\"]
}
"

    $nu_script | save "completions/nix-mox-completion.nu"
    print "✅ Nushell completions generated: completions/nix-mox-completion.nu"
}

# Install completions for current shell
export def install_completions [shell: string = "auto"] {
    let detected_shell = if $shell == "auto" {
        detect_current_shell
    } else {
        $shell
    }
    
    print $"🔧 Installing completions for ($detected_shell)..."
    
    # Ensure completions directory exists
    mkdir completions
    
    match $detected_shell {
        "bash" => {
            generate_bash_completions
            print "To enable completions, add this to your ~/.bashrc:"
            print "source $(pwd)/completions/nix-mox-completion.bash"
        }
        "zsh" => {
            generate_zsh_completions
            print "To enable completions, add this to your ~/.zshrc:"
            print "fpath=($(pwd)/completions \\$fpath)"
            print "autoload -U compinit && compinit"
        }
        "fish" => {
            generate_fish_completions
            let fish_config_dir = ($env | get -i FISH_CONFIG_DIR | default "~/.config/fish")
            print $"Copy completions/nix-mox.fish to ($fish_config_dir)/completions/"
        }
        "nu" => {
            generate_nu_completions
            print "To enable completions, add this to your config.nu:"
            print "source $(pwd)/completions/nix-mox-completion.nu"
        }
        _ => {
            print $"❌ Unsupported shell: ($detected_shell)"
            print "Supported shells: bash, zsh, fish, nu"
        }
    }
}

# Detect current shell
def detect_current_shell [] {
    let shell_path = ($env.SHELL | default "")
    
    if ($shell_path | str contains "bash") {
        "bash"
    } else if ($shell_path | str contains "zsh") {
        "zsh"
    } else if ($shell_path | str contains "fish") {
        "fish"
    } else if ($shell_path | str contains "nu") {
        "nu"
    } else {
        "unknown"
    }
}

# Generate all completion files
export def generate_all_completions [] {
    print "🚀 Generating completions for all supported shells..."
    
    mkdir completions
    init_completions
    
    generate_bash_completions
    generate_zsh_completions
    generate_fish_completions
    generate_nu_completions
    
    print ""
    print "✅ All completions generated in ./completions/"
    print ""
    print "Installation instructions:"
    print "========================="
    print "Bash: source ./completions/nix-mox-completion.bash"
    print "Zsh:  fpath=($(pwd)/completions \\$fpath) && autoload -U compinit && compinit"  
    print "Fish: cp ./completions/nix-mox.fish ~/.config/fish/completions/"
    print "Nu:   source ./completions/nix-mox-completion.nu"
}

# Auto-initialize if run directly
if ($env.PWD? != null) and (not $COMPLETION_STATE.initialized) {
    init_completions
}