#!/usr/bin/env nu
# Functional command wrapper library for nix-mox
# Eliminates duplication in command execution patterns
# Uses functional composition and error handling

use logging.nu *

# Core command execution with functional error handling
export def execute_command [
    command: list<string>,
    --operation: string = "",
    --context: string = "command",
    --timeout: duration = 30sec,
    --success-message: string = "",
    --error-message: string = "",
    --dry-run = false
] {
    let op_name = if ($operation | is-empty) { 
        $command | str join " " 
    } else { 
        $operation 
    }
    
    if $dry_run {
        dry_run $"Would execute: ($command | str join ' ')" --context $context
        return { success: true, stdout: "", stderr: "", exit_code: 0 }
    }
    
    debug $"Executing: ($command | str join ' ')" --context $context
    
    try {
        let result = (run-external ...$command | complete)
        
        if $result.exit_code == 0 {
            if not ($success_message | is-empty) {
                success $success_message --context $context
            }
            $result
        } else {
            if not ($error_message | is-empty) {
                error $error_message --context $context
            } else {
                error $"Command failed: ($result.stderr)" --context $context
            }
            $result
        }
    } catch { |err|
        error $"Execution failed: ($err.msg)" --context $context
        { success: false, stdout: "", stderr: $err.msg, exit_code: 1 }
    }
}

# Higher-order retry wrapper
export def with_retry [
    max_attempts: int = 3,
    delay: duration = 1sec,
    --backoff = false
] {
    |operation: closure|
    
    # Simplified retry - just try the operation once for now
    # TODO: Implement proper retry logic without mutable variables  
    try {
        do $operation
    } catch { |err|
        warn $"Operation failed: ($err.msg)" --context "retry"
        error make { msg: $"Operation failed: ($err)" }
    }
}

# Functional command builder
export def build_command [base_command: string] {
    |...args: string|
    [$base_command] | append $args
}

# Safe command execution with validation
export def safe_execute [
    command: list<string>,
    --prereqs: list<string> = [],
    --context: string = "safe-execute",
    --timeout: duration = 30sec
] {
    # Validate prerequisites
    for $prereq in $prereqs {
        if not (which $prereq | is-not-empty) {
            error make { msg: $"Required command not found: ($prereq)" }
        }
    }
    
    execute_command $command --context $context --timeout $timeout
}

# Chezmoi command wrapper (replaces multiple scripts)
export def chezmoi_command [
    subcommand: string,
    --context: string = "chezmoi",
    --dry-run = false
] {
    let command = ["chezmoi" $subcommand]
    let operation = $"chezmoi ($subcommand)"
    
    execute_command $command --operation $operation --context $context --dry-run $dry_run --success-message $"Chezmoi ($subcommand) completed successfully" --error-message $"Chezmoi ($subcommand) failed"
}

# Nix command wrapper with common patterns
export def nix_command [
    subcommand: string,
    --flake: string = ".",
    --extra-args: list<string> = [],
    --context: string = "nix"
] {
    let base_command = ["nix" $subcommand]
    let command = if ($flake | is-not-empty) and ($subcommand in ["build", "develop", "run"]) {
        $base_command | append "--flake" | append $flake | append $extra_args
    } else {
        $base_command | append $extra_args
    }
    
    execute_command $command --context $context --operation $"nix ($subcommand)"
}

# Git command wrapper
export def git_command [
    subcommand: string,
    --args: list<string> = [],
    --context: string = "git"
] {
    let command = ["git" $subcommand] | append $args
    execute_command $command --context $context --operation $"git ($subcommand)"
}

# Make command wrapper
export def make_command [
    target: string,
    --args: list<string> = [],
    --context: string = "make"
] {
    let command = ["make" $target] | append $args
    execute_command $command --context $context --operation $"make ($target)"
}

# System service command wrapper
export def service_command [
    action: string,
    service: string,
    --context: string = "service"
] {
    let command = ["systemctl" $action $service]
    execute_command $command --context $context --operation $"systemctl ($action) ($service)"
}

# Pipeline command composition
export def pipe_commands [commands: list<list<string>>, --context: string = "pipeline"] {
    debug "Starting command pipeline" --context $context
    $commands | reduce { |cmd, acc|
        let result = (execute_command $cmd --context $context)
        if $result.exit_code != 0 {
            error $"Pipeline failed at: ($cmd | str join ' ')" --context $context
            return $result
        }
        $result.stdout
    }
}

# Conditional command execution
export def execute_if [condition] {
    |command: list<string>, context: string = "conditional"|
    if $condition {
        execute_command $command --context $context
    } else {
        debug "Condition not met, skipping command" --context $context
        { success: true, stdout: "", stderr: "", exit_code: 0 }
    }
}

# Specialized command wrappers for common patterns

# Nix evaluation command wrapper
export def nix_eval [
    expression: string,
    --impure = false,
    --context: string = "nix-eval"
] {
    let nix_args = if $impure {
        ["nix" "eval" "--extra-experimental-features" "nix-command" "--impure" $expression]
    } else {
        ["nix" "eval" "--extra-experimental-features" "nix-command" $expression]
    }
    
    execute_command $nix_args --context $context --operation $"nix eval ($expression)"
}

# APT package management wrapper
export def apt_command [
    action: string,
    packages: list<string> = [],
    --context: string = "apt"
] {
    let apt_args = (["apt" $action] | append $packages)
    execute_command $apt_args --context $context --operation $"apt ($action)"
}

# Homebrew package management wrapper  
export def brew_command [
    action: string,
    packages: list<string> = [],
    --context: string = "brew"
] {
    let brew_args = (["brew" $action] | append $packages)
    execute_command $brew_args --context $context --operation $"brew ($action)"
}

# Git command wrapper already exists above

# Systemd service management (enhanced version)
export def systemd_command [
    action: string,
    service: string,
    --user = false,
    --context: string = "systemd"
] {
    let systemctl_args = if $user {
        ["systemctl" "--user" $action $service]
    } else {
        ["systemctl" $action $service]
    }
    
    execute_command $systemctl_args --context $context --operation $"systemctl ($action) ($service)"
}

# Docker command wrapper
export def docker_command [
    subcommand: string,
    args: list<string> = [],
    --context: string = "docker"
] {
    let docker_args = (["docker" $subcommand] | append $args)
    execute_command $docker_args --context $context --operation $"docker ($subcommand)"
}

# Curl wrapper with common options
export def curl_get [
    url: string,
    --output: string = "",
    --timeout: int = 30,
    --context: string = "curl"
] {
    let curl_args = if not ($output | is-empty) {
        ["curl" "-fsSL" "--connect-timeout" ($timeout | into string) $url "-o" $output]
    } else {
        ["curl" "-fsSL" "--connect-timeout" ($timeout | into string) $url]
    }
    
    execute_command $curl_args --context $context --operation $"curl GET ($url)"
}

# Package manager detection and wrapper
export def package_install [
    packages: list<string>,
    --context: string = "package-install"
] {
    let platform_info = (sys host)
    let platform_name = ($platform_info.name | str downcase)
    
    match $platform_name {
        "linux" | "nixos" => {
            # Try nix-env first, then apt if available
            if (which nix-env | is-not-empty) {
                let nix_args = (["nix-env" "-iA"] | append $packages)
                execute_command $nix_args --context $context --operation "nix install packages"
            } else if (which apt | is-not-empty) {
                apt_command "install" $packages --context $context
            } else {
                error "No supported package manager found" --context $context
                { success: false, stdout: "", stderr: "No package manager", exit_code: 1 }
            }
        },
        "darwin" => {
            if (which brew | is-not-empty) {
                brew_command "install" $packages --context $context
            } else {
                error "Homebrew not found on macOS" --context $context
                { success: false, stdout: "", stderr: "No Homebrew", exit_code: 1 }
            }
        },
        _ => {
            error $"Unsupported platform: ($platform_name)" --context $context
            { success: false, stdout: "", stderr: "Unsupported platform", exit_code: 1 }
        }
    }
}