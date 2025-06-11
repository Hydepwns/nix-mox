# Handlers module for nix-mox
# This replaces the bash handlers.sh with a more robust Nushell implementation

use logging.nu *
use exec.nu *

def validate_dependencies [dependencies: list<string>] {
    for dep in $dependencies {
        if not (which $dep | length > 0) {
            log "ERROR" $"Required dependency not found: ($dep)"
            handle_error $env.ERROR_CODES.DEPENDENCY_MISSING "Missing dependency" $"Please install ($dep) and try again"
        }
    }
}

def check_permissions [path: string] {
    if not ($path | path exists) {
        log "ERROR" $"Path does not exist: ($path)"
        handle_error $env.ERROR_CODES.FILE_NOT_FOUND "File not found" $"Path: ($path)"
    }

    if not ($path | path type) == "file" {
        log "ERROR" $"Not a file: ($path)"
        handle_error $env.ERROR_CODES.INVALID_ARGUMENT "Invalid file" $"Path: ($path)"
    }

    if not ($path | path type) == "file" {
        log "ERROR" $"Not a file: ($path)"
        handle_error $env.ERROR_CODES.INVALID_ARGUMENT "Invalid file" $"Path: ($path)"
    }
}

def run_platform_script [platform: string, script: string, ...args: string] {
    let script_file = get_platform_script $platform $script
    if $script_file == null {
        handle_error $env.ERROR_CODES.HANDLER_NOT_FOUND "Script not found" $"Platform: ($platform), Script: ($script)"
    }

    if $env.DRY_RUN {
        log "INFO" $"Would execute: ($script_file)"
        return
    }

    if $env.PARALLEL {
        run_parallel [$platform]
    } else {
        run_with_retry $script_file ...$args
    }
}

def handle_script [script_path: string, ...args: string] {
    # Validate script exists and is executable
    check_permissions $script_path

    # Get script handler
    let handler = get_script_handler $script_path

    # Run the script with appropriate handler
    match $handler {
        "bash" | "sh" => {
            validate_dependencies ["bash"]
            run_script $script_path ...$args
        }
        "nu" => {
            validate_dependencies ["nu"]
            run_script $script_path ...$args
        }
        "powershell" => {
            validate_dependencies ["powershell"]
            run_script $script_path ...$args
        }
        "python3" => {
            validate_dependencies ["python3"]
            run_script $script_path ...$args
        }
        _ => {
            validate_dependencies [$handler]
            run_script $script_path ...$args
        }
    }
}

# Export the functions
export-env {
    $env.SCRIPT_HANDLERS = {
        bash: "bash"
        nu: "nu"
        powershell: "powershell"
        python: "python3"
        node: "node"
        ruby: "ruby"
        perl: "perl"
        lua: "lua"
        php: "php"
        ts: "ts-node"
        fish: "fish"
        zsh: "zsh"
        ksh: "ksh"
        dash: "dash"
        vbs: "cscript"
        wsf: "cscript"
        cmd: "cmd"
        psm1: "powershell"
    }
}

# Main function to handle script operations
def main [] {
    let args = $in
    match $args.0 {
        "run" => { handle_script $args.1 $args.2... }
        "platform" => { run_platform_script $args.1 $args.2 $args.3... }
        _ => { print "Unknown handler operation" }
    }
} 