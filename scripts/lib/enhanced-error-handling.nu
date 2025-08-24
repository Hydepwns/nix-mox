# Enhanced error handling for nix-mox scripts
# This library provides standardized error handling and logging

export def handle_error [error: record, context: string] {
    """Standardized error handling with context"""
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let error_msg = $error.msg? | default "Unknown error"
    let error_code = $error.code? | default "unknown"
    
    print $"(ansi red)❌ Error in ($context):(ansi reset)"
    print $"  Time: ($timestamp)"
    print $"  Code: ($error_code)"
    print $"  Message: ($error_msg)"
    
    if ($error | get -i debug) != null {
        print $"  Debug: ($error.debug)"
    }
    
    if ($error | get -i help) != null {
        print $"  Help: ($error.help)"
    }
}

export def log_with_level [level: string, message: string, context: string = ""] {
    """Unified logging with levels"""
    let timestamp = (date now | format date '%H:%M:%S')
    let level_icon = match $level {
        "info" => "ℹ️",
        "success" => "✅",
        "warning" => "⚠️",
        "error" => "❌",
        "debug" => "🐛",
        _ => "📝"
    }
    
    let level_color = match $level {
        "info" => "blue",
        "success" => "green",
        "warning" => "yellow",
        "error" => "red",
        "debug" => "dark_gray",
        _ => "white"
    }
    
    let context_prefix = if ($context | str length) > 0 {
        "[$context] "
    } else {
        ""
    }
    
    print $"(ansi $level_color)($level_icon) ($timestamp) ($context_prefix)($message)(ansi reset)"
}

export def log_info [message: string, context: string = ""] {
    """Log info message"""
    log_with_level "info" $message $context
}

export def log_success [message: string, context: string = ""] {
    """Log success message"""
    log_with_level "success" $message $context
}

export def log_warning [message: string, context: string = ""] {
    """Log warning message"""
    log_with_level "warning" $message $context
}

export def log_error [message: string, context: string = ""] {
    """Log error message"""
    log_with_level "error" $message $context
}

export def log_debug [message: string, context: string = ""] {
    """Log debug message"""
    log_with_level "debug" $message $context
}

export def safe_exec [command: string, context: string = "command"] {
    """Safely execute a command with error handling"""
    try {
        let result = (nu -c $command | complete)
        if $result.exit_code == 0 {
            {
                success: true,
                output: $result.stdout,
                error: $result.stderr,
                exit_code: $result.exit_code
            }
        } else {
            log_error $"Command failed with exit code ($result.exit_code)" $context
            {
                success: false,
                output: $result.stdout,
                error: $result.stderr,
                exit_code: $result.exit_code
            }
        }
    } catch { |err|
        log_error $"Command execution failed: ($err.msg)" $context
        {
            success: false,
            output: "",
            error: $err.msg,
            exit_code: -1
        }
    }
}

export def require_command [cmd: string, context: string = ""] {
    """Require a command to be available, exit if not"""
    let cmd_exists = (which $cmd | length)
    if $cmd_exists == 0 {
        log_error $"Required command '$cmd' not found" $context
        exit 1
    }
    log_success $"Command '$cmd' available" $context
}

export def require_file [path: string, context: string = ""] {
    """Require a file to exist, exit if not"""
    if not ($path | path exists) {
        log_error $"Required file '$path' not found" $context
        exit 1
    }
    log_success $"File '$path' exists" $context
}

export def require_directory [path: string, context: string = ""] {
    """Require a directory to exist, exit if not"""
    if not (($path | path exists) and (($path | path type) == "dir")) {
        log_error $"Required directory '$path' not found" $context
        exit 1
    }
    log_success $"Directory '$path' exists" $context
}

export def exit_with_error [message: string, exit_code: int = 1, context: string = ""] {
    """Exit with error message and code"""
    log_error $message $context
    exit $exit_code
}

export def exit_with_success [message: string, context: string = ""] {
    """Exit with success message"""
    log_success $message $context
    exit 0
}

export def validate_environment [requirements: list] {
    """Validate environment requirements"""
    mut all_valid = true
    mut results = {}
    
    for req in $requirements {
        let valid = match $req.type {
            "command" => {
                let cmd_exists = (which $req.value | length)
                $cmd_exists > 0
            },
            "file" => ($req.value | path exists),
            "directory" => (($req.value | path exists) and (($req.value | path type) == "dir")),
            "permission" => {
                let perms = (ls -la $req.path | get mode | get 0)
                $perms | str contains $req.value
            },
            _ => false
        }
        
        $results = ($results | upsert $req.name $valid)
        if not $valid {
            $all_valid = false
            log_warning $"Requirement '$($req.name)' not met" "environment"
        } else {
            log_success $"Requirement '$($req.name)' met" "environment"
        }
    }
    
    {
        all_valid: $all_valid,
        results: $results
    }
}

export def retry_command [command: string, max_attempts: int = 3, delay: int = 1, context: string = ""] {
    """Retry a command with exponential backoff"""
    mut attempt = 1
    
    while $attempt <= $max_attempts {
        log_info $"Attempt ($attempt)/($max_attempts): ($command)" $context
        
        let result = (safe_exec $command $context)
        if $result.success {
            log_success $"Command succeeded on attempt ($attempt)" $context
            return $result
        }
        
        if $attempt < $max_attempts {
            let wait_time = ($delay * $attempt)
            log_warning $"Command failed, retrying in ($wait_time) seconds..." $context
            sleep ($wait_time | into duration)
        }
        
        $attempt = $attempt + 1
    }
    
    log_error $"Command failed after ($max_attempts) attempts" $context
    return {
        success: false,
        output: "",
        error: "Max retry attempts exceeded",
        exit_code: -1
    }
} 