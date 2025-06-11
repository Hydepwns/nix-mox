# Execution module for nix-mox
# This replaces the bash exec.sh with a more robust Nushell implementation

export module exec {
    use logging.nu

    # Export the environment variables
    export-env {
        $env.TIMEOUT = 0
        $env.RETRY_COUNT = 3
        $env.RETRY_DELAY = 5
        $env.LAST_ERROR = ""
        $env.SCRIPT = ""
        $env.ERROR_CODES = {
            TIMEOUT: 124
            EXECUTION_FAILED: 1
        }
        $env._args = []
    }

    export def get_script_handler [script_path: string] {
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

    export def run_script [script_path: string] {
        let handler = get_script_handler $script_path
        mut cmd_args = []

        # Add handler-specific arguments
        match $handler {
            "powershell" => { $cmd_args = ["-ExecutionPolicy", "Bypass", "-File"] }
            "cscript" => { $cmd_args = ["//nologo"] }
            _ => {}
        }

        # Add script path and arguments
        $cmd_args = ($cmd_args | append $script_path)

        # Run with timeout if specified
        if $env.TIMEOUT > 0 {
            try {
                let args = $cmd_args
                do { ^$handler $args } | timeout $env.TIMEOUT
            } catch {|e|
                $env.LAST_ERROR = $e
                log "ERROR" $"Script execution timed out after ($env.TIMEOUT)s"
                handle_error $env.ERROR_CODES.TIMEOUT "Script execution timed out" "Consider increasing the timeout or optimizing the script"
            }
        } else {
            # Run without timeout
            try {
                let args = $cmd_args
                ^$handler $args
            } catch {|e|
                $env.LAST_ERROR = $e
                log "ERROR" $"Script execution failed: ($env.LAST_ERROR)"
                handle_error $env.ERROR_CODES.EXECUTION_FAILED "Script execution failed" $env.LAST_ERROR
            }
        }
    }

    export def run_with_retry [script_path: string] {
        let max_retries = $env.RETRY_COUNT
        let retry_delay = $env.RETRY_DELAY
        mut exit_code = 1

        for i in 0..$max_retries {
            if $i > 0 {
                log "WARN" $"Script failed, retrying ($i)/($max_retries) in ($retry_delay)s..."
                sleep $retry_delay
            }

            try {
                run_script $script_path
                $exit_code = 0
                break
            } catch {
                if $i == $max_retries {
                    log "ERROR" "Maximum retry attempts reached"
                    handle_error $env.ERROR_CODES.EXECUTION_FAILED "Script execution failed after retries" "Check the script for errors or increase retry count"
                }
            }
        }

        $exit_code
    }

    export def run_parallel [platforms: list<string>] {
        mut jobs = []
        for platform in $platforms {
            let script_file = $"scripts/($platform)/($env.SCRIPT)"
            if ($script_file | path exists) {
                $jobs = ($jobs | append (do { run_script $script_file } &))
            } else {
                log "ERROR" $"Script not found: ($script_file)"
            }
        }

        # Wait for all jobs to complete
        for job in $jobs {
            $job | complete
        }
    }

    export def handle_error [code: int, message: string, details: string] {
        log "ERROR" $message
        log "DETAILS" $details
        exit $code
    }

    # Main function to handle execution operations
    export def main [args: list<string>] {
        $env._args = $args
        match $args.0 {
            "run" => { run_script $args.1 }
            "retry" => { run_with_retry $args.1 }
            "parallel" => { run_parallel ($args | skip 1) }
            _ => { print "Unknown execution operation" }
        }
    }
}
