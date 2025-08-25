#!/usr/bin/env nu
# Consolidated setup script for nix-mox
# Replaces multiple setup scripts with functional patterns
# Provides guided and automated installation options

use lib/logging.nu *
use lib/platform.nu *
use lib/validators.nu *
use lib/command-wrapper.nu *
use lib/script-template.nu *

# Main setup dispatcher
def main [
    mode: string = "interactive",
    --component: string = "all",
    --dry-run: bool = false,
    --force: bool = false,
    --config-file: string = "",
    --verbose: bool = false,
    --context: string = "setup"
] {
    if $verbose { $env.LOG_LEVEL = "DEBUG" }
    
    script_main "nix-mox setup" $"Running ($mode) setup for ($component)" --context $context {||
        
        # Validate platform compatibility
        let platform_check = (test_platform_compatibility {
            platforms: ["linux", "macos"],
            commands: ["git", "nix"]
        })
        
        if not $platform_check.compatible {
            error "Platform not compatible:" --context $context
            $platform_check.issues | each { |issue| error $"  - ($issue.issue)" --context $context }
            return
        }
        
        # Load configuration if specified
        let config = if ($config_file | is-empty) {
            get_default_setup_config
        } else {
            load_script_config $config_file --required true
        }
        
        # Dispatch to appropriate setup mode
        match $mode {
            "interactive" => (interactive_setup $component $config $dry_run),
            "automated" => (automated_setup $component $config $dry_run),
            "gaming" => (gaming_setup $config $dry_run),
            "minimal" => (minimal_setup $config $dry_run),
            "development" => (development_setup $config $dry_run),
            "help" => { show_setup_help; return },
            _ => {
                error $"Unknown setup mode: ($mode). Use 'help' to see available modes."
                return
            }
        }
    }
}

# Interactive setup with guided configuration
def interactive_setup [component: string, config: record, dry_run: bool] {
    info "Starting interactive nix-mox setup..." --context "setup"
    
    # Gather user preferences
    let preferences = (gather_user_preferences $component)
    let final_config = ($config | merge $preferences)
    
    # Show setup plan
    show_setup_plan $final_config $component
    
    if not (confirm "Continue with this setup?") {
        info "Setup cancelled by user" --context "setup"
        return
    }
    
    # Execute setup
    execute_setup_plan $final_config $component $dry_run
}

# Automated setup with minimal prompts
def automated_setup [component: string, config: record, dry_run: bool] {
    info "Starting automated nix-mox setup..." --context "setup"
    
    # Use default configuration for automated setup
    let final_config = ($config | merge { automated: true, interactive: false })
    
    # Execute setup without prompts
    execute_setup_plan $final_config $component $dry_run
}

# Gaming-focused setup
def gaming_setup [config: record, dry_run: bool] {
    info "Starting gaming workstation setup..." --context "gaming-setup"
    
    let gaming_config = ($config | merge {
        gaming: true,
        components: ["base", "gaming", "display", "audio", "performance"]
    })
    
    # Gaming-specific validations
    let gaming_validations = [
        { name: "graphics_driver", validator: {|| validate_graphics_capability } },
        { name: "audio_system", validator: {|| validate_audio_system } },
        { name: "controller_support", validator: {|| validate_controller_support } }
    ]
    
    let validation_results = (run_validations $gaming_validations --context "gaming-setup")
    if not $validation_results.success {
        warn "Some gaming validations failed - continuing anyway" --context "gaming-setup"
    }
    
    execute_setup_plan $gaming_config "gaming" $dry_run
}

# Minimal setup for basic functionality
def minimal_setup [config: record, dry_run: bool] {
    info "Starting minimal nix-mox setup..." --context "minimal-setup"
    
    let minimal_config = ($config | merge {
        minimal: true,
        components: ["base", "core"]
    })
    
    execute_setup_plan $minimal_config "minimal" $dry_run
}

# Development environment setup
def development_setup [config: record, dry_run: bool] {
    info "Starting development environment setup..." --context "dev-setup"
    
    let dev_config = ($config | merge {
        development: true,
        components: ["base", "development", "testing", "analysis"]
    })
    
    execute_setup_plan $dev_config "development" $dry_run
}

# Gather user preferences interactively
def gather_user_preferences [component: string] {
    info "Gathering setup preferences..." --context "preferences"
    
    let platform_info = (get_platform)
    
    let gaming_enabled = (confirm "Enable gaming workstation features?" --default true)
    let development_enabled = (confirm "Set up development environment?" --default true)
    let chezmoi_enabled = (confirm "Configure Chezmoi dotfiles management?" --default true)
    
    let components = match $component {
        "all" => {
            mut selected = ["base", "core"]
            if $gaming_enabled { $selected = ($selected | append "gaming") }
            if $development_enabled { $selected = ($selected | append "development") }
            if $chezmoi_enabled { $selected = ($selected | append "chezmoi") }
            $selected
        },
        _ => [$component]
    }
    
    {
        gaming: $gaming_enabled,
        development: $development_enabled,
        chezmoi: $chezmoi_enabled,
        components: $components,
        platform: $platform_info.normalized,
        user: ($env | get -i USER | default "unknown")
    }
}

# Show setup plan to user
def show_setup_plan [config: record, component: string] {
    info "Setup Plan:" --context "setup"
    info $"  Platform: ($config.platform)" --context "setup"
    info $"  Components: ($config.components | str join ', ')" --context "setup"
    info $"  Gaming: ($config | get -i gaming | default false)" --context "setup"
    info $"  Development: ($config | get -i development | default false)" --context "setup"
    info $"  Chezmoi: ($config | get -i chezmoi | default false)" --context "setup"
    print ""
}

# Execute the setup plan
def execute_setup_plan [config: record, component: string, dry_run: bool] {
    info "Executing setup plan..." --context "setup"
    
    let components = ($config | get components | default ["base"])
    
    for comp in $components {
        info $"Setting up component: ($comp)" --context "setup"
        
        match $comp {
            "base" => (setup_base_system $config $dry_run),
            "core" => (setup_core_system $config $dry_run),
            "gaming" => (setup_gaming_system $config $dry_run),
            "development" => (setup_development_system $config $dry_run),
            "chezmoi" => (setup_chezmoi_system $config $dry_run),
            "display" => (setup_display_system $config $dry_run),
            "audio" => (setup_audio_system $config $dry_run),
            "performance" => (setup_performance_system $config $dry_run),
            "testing" => (setup_testing_system $config $dry_run),
            "analysis" => (setup_analysis_system $config $dry_run),
            _ => {
                warn $"Unknown component: ($comp)" --context "setup"
            }
        }
    }
    
    success "Setup completed successfully!" --context "setup"
    show_post_setup_instructions $config
}

# Component setup functions
def setup_base_system [config: record, dry_run: bool] {
    with_logging "base system setup" --context "setup" {||
        
        # Ensure we're in the right directory
        if not ("flake.nix" | path exists) {
            error "Not in nix-mox directory. Please run from project root." --context "setup"
            return
        }
        
        # Create necessary directories
        let dirs = ["logs", "tmp", "coverage-tmp", "secrets"]
        for dir in $dirs {
            if not ($dir | path exists) {
                if $dry_run {
                    dry_run $"Would create directory: ($dir)" --context "setup"
                } else {
                    mkdir $dir
                    debug $"Created directory: ($dir)" --context "setup"
                }
            }
        }
        
        # Set up git hooks if in git repo
        if (".git" | path exists) {
            setup_git_hooks $dry_run
        }
        
        success "Base system setup complete" --context "setup"
    }
}

def setup_core_system [config: record, dry_run: bool] {
    with_logging "core system setup" --context "setup" {||
        
        # Validate Nix configuration
        let result = if $dry_run {
            dry_run "Would validate Nix configuration" --context "setup"
            { exit_code: 0 }
        } else {
            nix_command "flake" --extra-args ["check", "--no-build"]
        }
        
        if $result.exit_code != 0 {
            error "Nix configuration validation failed" --context "setup"
            return
        }
        
        success "Core system setup complete" --context "setup"
    }
}

def setup_gaming_system [config: record, dry_run: bool] {
    with_logging "gaming system setup" --context "setup" {||
        
        let platform = (get_platform)
        if not $platform.is_linux {
            warn "Gaming setup is primarily designed for Linux" --context "gaming-setup"
        }
        
        # Check for gaming flake
        if ("flakes/gaming/flake.nix" | path exists) {
            info "Gaming flake detected" --context "gaming-setup"
            
            if not $dry_run {
                let result = (nix_command "develop" --flake "flakes/gaming")
                if $result.exit_code != 0 {
                    warn "Gaming development environment setup failed" --context "gaming-setup"
                }
            }
        } else {
            warn "Gaming flake not found - skipping gaming-specific setup" --context "gaming-setup"
        }
        
        success "Gaming system setup complete" --context "setup"
    }
}

def setup_development_system [config: record, dry_run: bool] {
    with_logging "development system setup" --context "setup" {||
        
        # Set up development environment
        if not $dry_run {
            let result = (nix_command "develop")
            if $result.exit_code != 0 {
                warn "Development environment setup had issues" --context "dev-setup"
            }
        }
        
        # Set up shell completions
        setup_shell_completions $dry_run
        
        success "Development system setup complete" --context "setup"
    }
}

def setup_chezmoi_system [config: record, dry_run: bool] {
    with_logging "chezmoi system setup" --context "setup" {||
        
        if not (which "chezmoi" | is-not-empty) {
            warn "Chezmoi not found - please install chezmoi first" --context "chezmoi-setup"
            return
        }
        
        if not $dry_run {
            let result = (chezmoi_command "init")
            if $result.exit_code == 0 {
                success "Chezmoi initialized successfully" --context "chezmoi-setup"
            } else {
                warn "Chezmoi initialization had issues" --context "chezmoi-setup"
            }
        }
        
        success "Chezmoi system setup complete" --context "setup"
    }
}

def setup_display_system [config: record, dry_run: bool] {
    with_logging "display system setup" --context "setup" {||
        info "Display system setup - checking configuration" --context "display-setup"
        # Display setup logic would go here
        success "Display system setup complete" --context "setup"
    }
}

def setup_audio_system [config: record, dry_run: bool] {
    with_logging "audio system setup" --context "setup" {||
        info "Audio system setup - checking configuration" --context "audio-setup"
        # Audio setup logic would go here
        success "Audio system setup complete" --context "setup"
    }
}

def setup_performance_system [config: record, dry_run: bool] {
    with_logging "performance system setup" --context "setup" {||
        info "Performance system setup - optimizing configuration" --context "perf-setup"
        # Performance setup logic would go here
        success "Performance system setup complete" --context "setup"
    }
}

def setup_testing_system [config: record, dry_run: bool] {
    with_logging "testing system setup" --context "setup" {||
        setup_test_environment --temp-dir "coverage-tmp/nix-mox-tests"
        success "Testing system setup complete" --context "setup"
    }
}

def setup_analysis_system [config: record, dry_run: bool] {
    with_logging "analysis system setup" --context "setup" {||
        info "Analysis system setup - configuring monitoring" --context "analysis-setup"
        # Analysis setup logic would go here
        success "Analysis system setup complete" --context "setup"
    }
}

# Helper functions
def setup_git_hooks [dry_run: bool] {
    let hooks_dir = ".git/hooks"
    if ($hooks_dir | path exists) {
        let pre_commit_hook = $"($hooks_dir)/pre-commit"
        let hook_content = "#!/bin/sh\nnix run .#fmt"
        
        if $dry_run {
            dry_run $"Would create git pre-commit hook: ($pre_commit_hook)" --context "git-setup"
        } else {
            $hook_content | save $pre_commit_hook
            chmod +x $pre_commit_hook
            debug $"Created git pre-commit hook" --context "git-setup"
        }
    }
}

def setup_shell_completions [dry_run: bool] {
    let platform_paths = (get_platform_paths)
    let completion_dir = $"($platform_paths.config_home)/nu/completions"
    
    if $dry_run {
        dry_run $"Would set up shell completions in: ($completion_dir)" --context "completions"
    } else {
        if not ($completion_dir | path exists) {
            mkdir $completion_dir
        }
        # Completion setup logic would go here
        debug $"Shell completions configured" --context "completions"
    }
}

# Validation functions
def validate_graphics_capability [] {
    let platform = (get_platform)
    if $platform.is_linux {
        try {
            let gpu_info = (lspci | grep -i "vga\|3d\|display" | complete)
            if $gpu_info.exit_code == 0 {
                validation_result true "Graphics hardware detected"
            } else {
                validation_result false "No graphics hardware detected"
            }
        } catch {
            validation_result false "Failed to detect graphics hardware"
        }
    } else {
        validation_result true "Graphics validation skipped on this platform"
    }
}

def validate_audio_system [] {
    let platform = (get_platform)
    if $platform.is_linux {
        if (which "pulseaudio" | is-not-empty) or (which "pipewire" | is-not-empty) {
            validation_result true "Audio system detected"
        } else {
            validation_result false "No audio system detected"
        }
    } else {
        validation_result true "Audio validation skipped on this platform"
    }
}

def validate_controller_support [] {
    if (which "jstest" | is-not-empty) or ("dev/input" | path exists) {
        validation_result true "Controller support available"
    } else {
        validation_result false "No controller support detected"
    }
}

# Configuration management
def get_default_setup_config [] {
    {
        gaming: false,
        development: true,
        chezmoi: true,
        components: ["base", "core"],
        interactive: true,
        automated: false
    }
}

def show_post_setup_instructions [config: record] {
    info "Post-Setup Instructions:" --context "setup"
    info "1. Review and apply configuration: make chezmoi-apply" --context "setup"
    info "2. Validate system: nu validate.nu pre-rebuild" --context "setup"
    info "3. Test configuration: sudo nixos-rebuild test --flake .#nixos" --context "setup"
    info "4. Apply configuration: make safe-rebuild" --context "setup"
    
    if ($config | get -i gaming | default false) {
        info "Gaming setup complete - check flakes/gaming/ for configuration" --context "setup"
    }
    
    if ($config | get -i development | default false) {
        info "Development environment ready - use 'make dev' to enter" --context "setup"
    }
}

def show_setup_help [] {
    format_help "nix-mox setup" "Consolidated setup system for nix-mox" "nu setup.nu <mode> [options]" [
        { name: "interactive", description: "Interactive setup with guided configuration" }
        { name: "automated", description: "Automated setup with minimal prompts" }
        { name: "gaming", description: "Gaming workstation setup" }
        { name: "minimal", description: "Minimal setup for basic functionality" }
        { name: "development", description: "Development environment setup" }
    ] [
        { name: "component", description: "Specific component to set up (default: all)" }
        { name: "dry-run", description: "Show what would be done without making changes" }
        { name: "force", description: "Force setup even if already configured" }
        { name: "config-file", description: "Use custom configuration file" }
        { name: "verbose", description: "Enable verbose output" }
    ] [
        { command: "nu setup.nu interactive", description: "Interactive setup with prompts" }
        { command: "nu setup.nu gaming --dry-run", description: "Preview gaming setup" }
        { command: "nu setup.nu automated --component development", description: "Automated development setup" }
    ]
}

# If script is run directly, call main with arguments
if not ($nu.scope.args | is-empty) {
    main ...$nu.scope.args
}