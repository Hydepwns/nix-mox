# Execution module for nix-mox
# This replaces the bash exec.sh with a more robust Nushell implementation

use logging.nu *

def get_script_handler [script_path: string] {
    let extension = $script_path | path parse | get extension
    match $extension {
        ".sh" | ".bash" => "bash"
        ".nu" => "nu"
        ".bat" => "cmd"
        ".ps1" => "powershell"
        ".py" => "python3"
        ".js" => "node"
        ".rb" => "ruby"
        ".pl" => "perl"
        ".lua" => "lua"
        ".php" => "php"
        ".ts" | ".tsx" => "ts-node"
        ".fish" => "fish"
        ".zsh" => "zsh"
        ".ksh" => "ksh"
        ".dash" => "dash"
        ".vbs" => "cscript"
        ".wsf" => "cscript"
        ".cmd" => "cmd"
        ".psm1" => "powershell"
        _ => {
            log "ERROR" $"Unsupported script type: ($extension)"
            exit 1
        }
    }
}

def run_script [script_path: string, ...args: string] {
    let handler = get_script_handler $script_path
    let mut cmd_args = []

    # Add handler-specific arguments
    match $handler {
        "powershell" => { $cmd_args = ["-ExecutionPolicy", "Bypass", "-File"] }
        "cscript" => { $cmd_args = ["//nologo"] }
        _ => {}
    }

    # Add script path and arguments
    $cmd_args = ($cmd_args | append $script_path)
    $cmd_args = ($cmd_args | append $args)

    # Run with timeout if specified
    if $env.TIMEOUT > 0 {
        try {
            do {
                ^$handler ...$cmd_args
            } | timeout $env.TIMEOUT
        } catch {
            log "ERROR" $"Script execution timed out after ($env.TIMEOUT)s"
            handle_error $env.ERROR_CODES.TIMEOUT "Script execution timed out" "Consider increasing the timeout or optimizing the script"
        }
    } else {
        # Run without timeout
        try {
            ^$handler ...$cmd_args
        } catch {
            log "ERROR" $"Script execution failed: ($env.LAST_ERROR)"
            handle_error $env.ERROR_CODES.EXECUTION_FAILED "Script execution failed" $env.LAST_ERROR
        }
    }
}

def run_with_retry [script_path: string, ...args: string] {
    let mut retry_count = 0
    let mut exit_code = 1

    while $retry_count <= $env.RETRY_COUNT {
        if $retry_count > 0 {
            log "WARN" $"Script failed, retrying ($retry_count)/($env.RETRY_COUNT) in ($env.RETRY_DELAY)s..."
            sleep $env.RETRY_DELAY
        }

        try {
            run_script $script_path ...$args
            $exit_code = 0
            break
        } catch {
            $retry_count = $retry_count + 1
            if $retry_count > $env.RETRY_COUNT {
                log "ERROR" "Maximum retry attempts reached"
                handle_error $env.ERROR_CODES.EXECUTION_FAILED "Script execution failed after retries" "Check the script for errors or increase retry count"
            }
        }
    }

    $exit_code
}

def run_parallel [platforms: list<string>] {
    let mut jobs = []
    for platform in $platforms {
        let script_file = get_platform_script $platform $env.SCRIPT
        if $script_file != null {
            $jobs = ($jobs | append (run_script $script_file &))
        }
    }

    # Wait for all jobs to complete
    for job in $jobs {
        $job | complete
    }
}

# Export the functions
export-env {
    $env.LAST_ERROR = ""
}

# Main function to handle execution operations
def main [] {
    let args = $in
    match $args.0 {
        "run" => { run_script $args.1 $args.2... }
        "retry" => { run_with_retry $args.1 $args.2... }
        "parallel" => { run_parallel $args.1... }
        _ => { print "Unknown execution operation" }
    }
} 