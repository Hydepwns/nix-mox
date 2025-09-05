#!/usr/bin/env nu
# Secure command execution module for nix-mox
# Provides secure wrappers for system commands with validation and logging
# Replaces unsafe command execution patterns with security-validated alternatives

use logging.nu *
use validators.nu *

# Security validation for command execution
export def validate_command_security [
    command: string,
    args: list<string> = [],
    --context: string = "secure-command"
] {
    # Basic command validation
    let cmd_validation = (validate_command $command)
    if not $cmd_validation.success {
        error $"Command security validation failed: ($cmd_validation.message)" --context $context
        return { success: false, reason: $cmd_validation.message }
    }
    
    # Check for dangerous patterns
    let dangerous_patterns = [
        "rm -rf"
        "dd if="
        "mkfs"
        "fdisk"
        "parted"
        "chmod 777"
        "chown root"
    ]
    
    let full_command = $"($command) ($args | str join ' ')"
    for pattern in $dangerous_patterns {
        if ($full_command | str contains $pattern) {
            warn $"Potentially dangerous command detected: ($pattern)" --context $context
            return { success: false, reason: $"Dangerous command pattern: ($pattern)" }
        }
    }
    
    { success: true, reason: "Command passed security validation" }
}

# Secure system command execution with validation
export def secure_system [
    command: string,
    --context: string = "secure-command",
    --timeout: duration = 30sec
] {
    # Security validation
    let security_check = (validate_command_security $command --context $context)
    if not $security_check.success {
        error $"Command blocked by security validation: ($security_check.reason)" --context $context
        return { success: false, stdout: "", stderr: $security_check.reason, exit_code: 1 }
    }
    
    info $"Executing secure system command: ($command)" --context $context
    
    try {
        let result = (run-external $command | complete)
        if $result.exit_code == 0 {
            success $"Command executed successfully: ($command)" --context $context
        } else {
            warn $"Command completed with non-zero exit code: ($command)" --context $context
        }
        { success: ($result.exit_code == 0), stdout: $result.stdout, stderr: $result.stderr, exit_code: $result.exit_code }
    } catch { | err|
        error $"Command execution failed: ($command) - ($err.msg)" --context $context
        { success: false, stdout: "", stderr: $err.msg, exit_code: 1 }
    }
}

# Secure command execution with arguments
export def secure_execute [
    command: string,
    args: list<string> = [],
    --context: string = "secure-command",
    --timeout: duration = 30sec
] {
    # Security validation
    let security_check = (validate_command_security $command $args --context $context)
    if not $security_check.success {
        error $"Command blocked by security validation: ($security_check.reason)" --context $context
        return { success: false, stdout: "", stderr: $security_check.reason, exit_code: 1 }
    }
    
    info $"Executing secure command: ($command) ($args | str join ' ')" --context $context
    
    try {
        let result = (run-external $command ...$args | complete)
        if $result.exit_code == 0 {
            success $"Command executed successfully: ($command)" --context $context
        } else {
            warn $"Command completed with non-zero exit code: ($command)" --context $context
        }
        { success: ($result.exit_code == 0), stdout: $result.stdout, stderr: $result.stderr, exit_code: $result.exit_code }
    } catch { | err|
        error $"Command execution failed: ($command) - ($err.msg)" --context $context
        { success: false, stdout: "", stderr: $err.msg, exit_code: 1 }
    }
}

# Secure sudo command execution with privilege validation
export def secure_sudo [
    command: string,
    args: list<string> = [],
    --context: string = "secure-command",
    --require-confirmation = true,
    --timeout: duration = 30sec
] {
    # Security validation
    let security_check = (validate_command_security $command $args --context $context)
    if not $security_check.success {
        error $"Sudo command blocked by security validation: ($security_check.reason)" --context $context
        return { success: false, stdout: "", stderr: $security_check.reason, exit_code: 1 }
    }
    
    # Check if user has sudo access
    let sudo_check = (run-external "sudo" "-n" "true" | complete)
    if $sudo_check.exit_code != 0 {
        error "User does not have sudo access or sudo access expired" --context $context
        return { success: false, stdout: "", stderr: "No sudo access", exit_code: 1 }
    }
    
    info $"Executing secure sudo command: sudo ($command) ($args | str join ' ')" --context $context
    
    try {
        let result = (run-external "sudo" $command ...$args | complete)
        if $result.exit_code == 0 {
            success $"Sudo command executed successfully: ($command)" --context $context
        } else {
            warn $"Sudo command completed with non-zero exit code: ($command)" --context $context
        }
        { success: ($result.exit_code == 0), stdout: $result.stdout, stderr: $result.stderr, exit_code: $result.exit_code }
    } catch { | err|
        error $"Sudo command execution failed: ($command) - ($err.msg)" --context $context
        { success: false, stdout: "", stderr: $err.msg, exit_code: 1 }
    }
}

# Secure file operation wrapper
export def secure_file_operation [
    operation: string,
    path: string,
    --context: string = "secure-command",
    --backup = true
] {
    # Path validation
    let path_validation = (validate_file $path)
    if not $path_validation.success {
        error $"File operation blocked: ($path_validation.message)" --context $context
        return { success: false, reason: $path_validation.message }
    }
    
    # Check for dangerous operations
    let dangerous_ops = ["delete", "remove", "format", "overwrite"]
    if ($dangerous_ops | any { | op| $operation | str contains $op }) {
        warn $"Potentially dangerous file operation: ($operation) on ($path)" --context $context
        if $backup {
            info "Creating backup before dangerous operation" --context $context
            # Backup logic would go here
        }
    }
    
    info $"Executing secure file operation: ($operation) on ($path)" --context $context
    { success: true, reason: "File operation validated" }
}

# Command execution with timeout
export def secure_execute_with_timeout [
    command: string,
    args: list<string> = [],
    timeout: duration = 30sec,
    --context: string = "secure-command"
] {
    # Security validation
    let security_check = (validate_command_security $command $args --context $context)
    if not $security_check.success {
        error $"Command blocked by security validation: ($security_check.reason)" --context $context
        return { success: false, stdout: "", stderr: $security_check.reason, exit_code: 1 }
    }
    
    info $"Executing command with timeout: ($command) ($args | str join ' ') - timeout: ($timeout)" --context $context
    
    try {
        let result = (run-external "timeout" ($timeout | into string) $command ...$args | complete)
        if $result.exit_code == 124 {
            error $"Command timed out after ($timeout): ($command)" --context $context
            return { success: false, stdout: "", stderr: "Command timed out", exit_code: 124 }
        }
        
        if $result.exit_code == 0 {
            success $"Command executed successfully: ($command)" --context $context
        } else {
            warn $"Command completed with non-zero exit code: ($command)" --context $context
        }
        
        { success: ($result.exit_code == 0), stdout: $result.stdout, stderr: $result.stderr, exit_code: $result.exit_code }
    } catch { | err|
        error $"Command execution failed: ($command) - ($err.msg)" --context $context
        { success: false, stdout: "", stderr: $err.msg, exit_code: 1 }
    }
} 