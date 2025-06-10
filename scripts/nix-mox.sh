#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
PLATFORM="auto"
CI_MODE=false
SCRIPT="install"  # Default script to run
DRY_RUN=false
VERBOSE=false
FORCE=false
QUIET=false
LOG_FILE=""
PARALLEL=false
TIMEOUT=0
RETRY_COUNT=0
RETRY_DELAY=5

# Available scripts for each platform
declare -A LINUX_SCRIPTS=(
    ["install"]="install.sh"
    ["uninstall"]="uninstall.sh"
    ["update"]="nixos-flake-update.sh"
    ["zfs-snapshot"]="zfs-snapshot.sh"
    ["vzdump-backup"]="vzdump-backup.sh"
    ["proxmox-update"]="proxmox-update.sh"
)

declare -A WINDOWS_SCRIPTS=(
    ["install"]="install-steam-rust.nu"
    ["run"]="run-steam-rust.bat"
)

# Script type handlers
declare -A SCRIPT_HANDLERS=(
    # Shell scripts
    [".sh"]="bash"
    [".bash"]="bash"
    [".zsh"]="zsh"
    [".fish"]="fish"
    [".ksh"]="ksh"
    [".dash"]="dash"
    [".ash"]="busybox ash"
    
    # Windows scripts
    [".ps1"]="powershell -ExecutionPolicy Bypass -File"
    [".psm1"]="powershell -ExecutionPolicy Bypass -File"
    [".bat"]="cmd /c"
    [".cmd"]="cmd /c"
    [".vbs"]="cscript //nologo"
    [".wsf"]="cscript //nologo"
    
    # Modern scripting languages
    [".py"]="python3"
    [".py2"]="python2"
    [".py3"]="python3"
    [".rb"]="ruby"
    [".js"]="node"
    [".ts"]="ts-node"
    [".tsx"]="ts-node"
    [".nu"]="nu"
    [".lua"]="lua"
    [".pl"]="perl"
    [".php"]="php"
    [".php8"]="php8"
    [".php7"]="php7"
    [".php5"]="php5"
    
    # Compiled languages with direct execution
    [".exe"]=""
    [".bin"]=""
    [".out"]=""
    
    # JVM languages
    [".jar"]="java -jar"
    [".class"]="java"
    [".groovy"]="groovy"
    [".scala"]="scala"
    [".kt"]="kotlin"
    [".kts"]="kotlin"
    
    # .NET languages
    [".cs"]="dotnet script"
    [".fs"]="dotnet fsi"
    [".fsx"]="dotnet fsi"
    [".vb"]="dotnet script"
    
    # Web technologies
    [".html"]="open"  # Opens in default browser
    [".htm"]="open"
    [".xhtml"]="open"
    
    # Configuration and data formats
    [".json"]="jq ."  # Pretty print JSON
    [".yaml"]="yq ."  # Pretty print YAML
    [".yml"]="yq ."
    [".toml"]="tomlq ."  # Pretty print TOML
    [".xml"]="xmllint --format"  # Pretty print XML
    
    # Database scripts
    [".sql"]="sqlite3"  # Default to SQLite, can be overridden
    [".psql"]="psql"    # PostgreSQL
    [".mysql"]="mysql"  # MySQL
    
    # Documentation
    [".md"]="glow"  # Markdown viewer
    [".rst"]="rst2html"  # ReStructuredText to HTML
    [".adoc"]="asciidoctor"  # AsciiDoc
    
    # Build and package files
    [".nix"]="nix-instantiate --eval"
    [".jsonnet"]="jsonnet"
    [".hcl"]="hcl2json"  # HashiCorp Configuration Language
    
    # Specialized formats
    [".tex"]="pdflatex"  # LaTeX
    [".r"]="Rscript"     # R
    [".jl"]="julia"      # Julia
    [".go"]="go run"     # Go
    [".rs"]="rustc"      # Rust
    [".hs"]="runhaskell" # Haskell
    [".scm"]="guile"     # Scheme
    [".clj"]="clojure"   # Clojure
    [".ex"]="elixir"     # Elixir
    [".exs"]="elixir"    # Elixir script
    [".erl"]="escript"   # Erlang
    [".hrl"]="escript"   # Erlang header
    [".ml"]="ocaml"      # OCaml
    [".mli"]="ocaml"     # OCaml interface
    [".fsi"]="fsharpc"   # F# interface
    [".fs"]="fsharpc"    # F#
    [".fsx"]="fsharpi"   # F# script
    [".d"]="dmd"         # D
    [".nim"]="nim"       # Nim
    [".zig"]="zig"       # Zig
    [".v"]="v"           # V
    [".cr"]="crystal"    # Crystal
    [".rb"]="ruby"       # Ruby
    [".rbw"]="ruby"      # Ruby (Windows)
    [".rbx"]="ruby"      # Ruby (with extensions)
    [".rake"]="rake"     # Ruby Rake
    [".gemspec"]="gem build"  # Ruby gem specification
    [".podspec"]="pod"   # CocoaPods specification
    [".gradle"]="gradle" # Gradle
    [".sbt"]="sbt"       # SBT
    [".mvn"]="mvn"       # Maven
    [".pom"]="mvn"       # Maven POM
    [".ant"]="ant"       # Ant
    [".xml"]="ant"       # Ant XML
    [".properties"]="java -jar"  # Java properties
    [".conf"]="conf2json"  # Configuration to JSON
    [".ini"]="ini2json"    # INI to JSON
    [".env"]="dotenv"      # Environment variables
    [".tf"]="terraform"    # Terraform
    [".tfvars"]="terraform" # Terraform variables
    [".tfstate"]="terraform" # Terraform state
    [".tfplan"]="terraform" # Terraform plan
    [".tf.json"]="terraform" # Terraform JSON
    [".tfvars.json"]="terraform" # Terraform variables JSON
    [".tfstate.json"]="terraform" # Terraform state JSON
    [".tfplan.json"]="terraform" # Terraform plan JSON
    [".tfvars.hcl"]="terraform" # Terraform variables HCL
    [".tfstate.hcl"]="terraform" # Terraform state HCL
    [".tfplan.hcl"]="terraform" # Terraform plan HCL
    [".tfvars.tfvars"]="terraform" # Terraform variables TFVARS
    [".tfstate.tfvars"]="terraform" # Terraform state TFVARS
    [".tfplan.tfvars"]="terraform" # Terraform plan TFVARS
    [".tfvars.tfstate"]="terraform" # Terraform variables TFSTATE
    [".tfstate.tfstate"]="terraform" # Terraform state TFSTATE
    [".tfplan.tfstate"]="terraform" # Terraform plan TFSTATE
    [".tfvars.tfplan"]="terraform" # Terraform variables TFPLAN
    [".tfstate.tfplan"]="terraform" # Terraform state TFPLAN
    [".tfplan.tfplan"]="terraform" # Terraform plan TFPLAN
)

# Error handling and logging
declare -A ERROR_CODES=(
    [SUCCESS]=0
    [INVALID_ARGUMENT]=1
    [FILE_NOT_FOUND]=2
    [PERMISSION_DENIED]=3
    [HANDLER_NOT_FOUND]=4
    [DEPENDENCY_MISSING]=5
    [EXECUTION_FAILED]=6
    [TIMEOUT]=7
    [INVALID_STATE]=8
    [NETWORK_ERROR]=9
    [CONFIGURATION_ERROR]=10
)

# Check if we're running in CI
if [ "${CI:-false}" = "true" ]; then
    CI_MODE=true
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --script)
            SCRIPT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            QUIET=false
            shift
            ;;
        --quiet|-q)
            QUIET=true
            VERBOSE=false
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        --parallel|-p)
            PARALLEL=true
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --retry)
            RETRY_COUNT="$2"
            shift 2
            ;;
        --retry-delay)
            RETRY_DELAY="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            # Pass remaining arguments to the platform script
            break
            ;;
    esac
done

# Function to show help message
show_help() {
    echo "Usage: $0 [options] [script-arguments]"
    echo
    echo "Options:"
    echo "  --platform <platform>    Specify platform (linux, windows, or auto)"
    echo "  --script <script>        Specify script to run (default: install)"
    echo "  --dry-run               Show what would be done without making changes"
    echo "  --verbose, -v           Enable verbose output"
    echo "  --quiet, -q             Suppress all output except errors"
    echo "  --force, -f             Force execution even if conditions aren't ideal"
    echo "  --log-file <file>       Write output to specified log file"
    echo "  --parallel, -p          Run platform scripts in parallel (CI mode only)"
    echo "  --timeout <seconds>     Set timeout for script execution (0 = no timeout)"
    echo "  --retry <count>         Number of times to retry failed scripts"
    echo "  --retry-delay <seconds> Delay between retries (default: 5)"
    echo "  --help                  Show this help message"
    echo
    echo "Available scripts:"
    echo "  Linux:"
    for script in "${!LINUX_SCRIPTS[@]}"; do
        echo "    - $script (${LINUX_SCRIPTS[$script]})"
    done
    echo "  Windows:"
    for script in "${!WINDOWS_SCRIPTS[@]}"; do
        echo "    - $script (${WINDOWS_SCRIPTS[$script]})"
    done
    echo
    echo "Supported script types:"
    for ext in "${!SCRIPT_HANDLERS[@]}"; do
        echo "    - $ext (${SCRIPT_HANDLERS[$ext]})"
    done
}

# Function to detect the current platform
detect_platform() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

# Function to detect file type from content
detect_file_type() {
    local file=$1
    local first_line
    local mime_type
    
    # Check if file exists and is readable
    if [ ! -f "$file" ] || [ ! -r "$file" ]; then
        return 1
    fi
    
    # Try to get MIME type
    if command -v file >/dev/null 2>&1; then
        mime_type=$(file --mime-type -b "$file")
    fi
    
    # Read first line for shebang
    read -r first_line < "$file"
    
    # Check for shebang
    if [[ "$first_line" =~ ^#! ]]; then
        local interpreter
        interpreter=$(echo "$first_line" | cut -d' ' -f1 | cut -d'/' -f3)
        case "$interpreter" in
            "bash"|"sh"|"zsh"|"fish"|"ksh"|"dash"|"ash")
                echo "shell:$interpreter"
                return 0
                ;;
            "python"|"python2"|"python3")
                echo "python:$interpreter"
                return 0
                ;;
            "perl")
                echo "perl:perl"
                return 0
                ;;
            "ruby")
                echo "ruby:ruby"
                return 0
                ;;
            "node")
                echo "javascript:node"
                return 0
                ;;
            "php")
                echo "php:php"
                return 0
                ;;
            "lua")
                echo "lua:lua"
                return 0
                ;;
            *)
                echo "unknown:$interpreter"
                return 0
                ;;
        esac
    fi
    
    # Check MIME type
    case "$mime_type" in
        "text/x-shellscript")
            echo "shell:bash"
            return 0
            ;;
        "text/x-python")
            echo "python:python3"
            return 0
            ;;
        "text/x-perl")
            echo "perl:perl"
            return 0
            ;;
        "text/x-ruby")
            echo "ruby:ruby"
            return 0
            ;;
        "text/x-php")
            echo "php:php"
            return 0
            ;;
        "text/x-lua")
            echo "lua:lua"
            return 0
            ;;
        "application/json")
            echo "json:jq"
            return 0
            ;;
        "application/x-yaml")
            echo "yaml:yq"
            return 0
            ;;
        "text/xml")
            echo "xml:xmllint"
            return 0
            ;;
        "application/x-executable")
            echo "binary:"
            return 0
            ;;
    esac
    
    return 1
}

# Function to get script handler with enhanced detection
get_script_handler() {
    local script_file=$1
    local ext="${script_file##*.}"
    local handler="${SCRIPT_HANDLERS[".$ext"]:-}"
    local detected_type
    local detected_handler
    
    # First try to detect from content
    if detected_type=$(detect_file_type "$script_file"); then
        IFS=':' read -r type detected_handler <<< "$detected_type"
        case "$type" in
            "shell")
                handler="$detected_handler"
                ;;
            "python")
                handler="$detected_handler"
                ;;
            "perl")
                handler="$detected_handler"
                ;;
            "ruby")
                handler="$detected_handler"
                ;;
            "javascript")
                handler="$detected_handler"
                ;;
            "php")
                handler="$detected_handler"
                ;;
            "lua")
                handler="$detected_handler"
                ;;
            "json")
                handler="jq ."
                ;;
            "yaml")
                handler="yq ."
                ;;
            "xml")
                handler="xmllint --format"
                ;;
            "binary")
                handler=""
                ;;
        esac
    fi
    
    # Special handling for certain file types
    case "$ext" in
        "sql")
            # Check for database-specific extensions and content
            if [[ "$script_file" == *.psql.* ]] || grep -q "\\copy" "$script_file" 2>/dev/null; then
                handler="psql"
            elif [[ "$script_file" == *.mysql.* ]] || grep -q "DELIMITER" "$script_file" 2>/dev/null; then
                handler="mysql"
            elif grep -q "CREATE TABLE" "$script_file" 2>/dev/null; then
                # Try to detect SQL dialect from content
                if grep -q "BEGIN TRANSACTION" "$script_file" 2>/dev/null; then
                    handler="sqlite3"
                elif grep -q "SET search_path" "$script_file" 2>/dev/null; then
                    handler="psql"
                elif grep -q "SET NAMES" "$script_file" 2>/dev/null; then
                    handler="mysql"
                fi
            fi
            ;;
        "exe"|"bin"|"out")
            # Make executable files directly executable
            chmod +x "$script_file"
            handler=""
            ;;
        "sh"|"bash")
            # Check for specific shell requirements
            if grep -q "declare -A" "$script_file" 2>/dev/null; then
                handler="bash"  # Requires bash 4.0+
            elif grep -q "typeset -A" "$script_file" 2>/dev/null; then
                handler="ksh"   # Korn shell
            fi
            ;;
        "py")
            # Check Python version requirements
            if grep -q "from typing import" "$script_file" 2>/dev/null; then
                handler="python3"  # Type hints require Python 3
            elif grep -q "print\s*(" "$script_file" 2>/dev/null; then
                handler="python3"  # Print function requires Python 3
            fi
            ;;
        "js")
            # Check for Node.js requirements
            if grep -q "import\s*{" "$script_file" 2>/dev/null; then
                handler="node --experimental-modules"  # ES modules
            fi
            ;;
        "ts"|"tsx")
            # Check for TypeScript configuration
            if [ -f "tsconfig.json" ]; then
                handler="ts-node --project tsconfig.json"
            fi
            ;;
        "rb")
            # Check for Ruby version requirements
            if grep -q "require_relative" "$script_file" 2>/dev/null; then
                handler="ruby"  # Ruby 1.9+
            fi
            ;;
        "php")
            # Check PHP version requirements
            if grep -q "namespace" "$script_file" 2>/dev/null; then
                handler="php"  # PHP 5.3+
            fi
            ;;
    esac
    
    # Check for environment-specific handlers
    if [ -f ".env" ]; then
        case "$ext" in
            "py")
                if [ -f "requirements.txt" ]; then
                    handler="python3 -m pip install -r requirements.txt && python3"
                fi
                ;;
            "js")
                if [ -f "package.json" ]; then
                    handler="npm install && node"
                fi
                ;;
            "rb")
                if [ -f "Gemfile" ]; then
                    handler="bundle install && bundle exec ruby"
                fi
                ;;
        esac
    fi
    
    echo "$handler"
}

# Function to handle errors
handle_error() {
    local error_code=$1
    local error_message=$2
    local error_context=$3
    local error_details=$4
    
    # Log the error with context
    log "ERROR" "$error_message"
    if [ -n "$error_context" ]; then
        log "ERROR" "Context: $error_context"
    fi
    if [ -n "$error_details" ]; then
        log "ERROR" "Details: $error_details"
    fi
    
    # Add error to error log if enabled
    if [ -n "$LOG_FILE" ]; then
        {
            echo "=== Error Report ==="
            echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "Error Code: $error_code"
            echo "Message: $error_message"
            [ -n "$error_context" ] && echo "Context: $error_context"
            [ -n "$error_details" ] && echo "Details: $error_details"
            echo "==================="
        } >> "$LOG_FILE"
    fi
    
    # Provide recovery suggestions based on error type
    case "$error_code" in
        "${ERROR_CODES[FILE_NOT_FOUND]}")
            log "INFO" "Try checking if the file exists and is accessible"
            ;;
        "${ERROR_CODES[PERMISSION_DENIED]}")
            log "INFO" "Try running with elevated permissions or check file permissions"
            ;;
        "${ERROR_CODES[HANDLER_NOT_FOUND]}")
            log "INFO" "Try installing the required handler or use --platform to specify a different platform"
            ;;
        "${ERROR_CODES[DEPENDENCY_MISSING]}")
            log "INFO" "Try installing the missing dependencies using your system package manager"
            ;;
        "${ERROR_CODES[EXECUTION_FAILED]}")
            log "INFO" "Try running with --verbose for more details or check the script for errors"
            ;;
        "${ERROR_CODES[TIMEOUT]}")
            log "INFO" "Try increasing the timeout with --timeout or optimize the script"
            ;;
        "${ERROR_CODES[INVALID_STATE]}")
            log "INFO" "Try cleaning up any temporary files and retry"
            ;;
        "${ERROR_CODES[NETWORK_ERROR]}")
            log "INFO" "Check your network connection and try again"
            ;;
        "${ERROR_CODES[CONFIGURATION_ERROR]}")
            log "INFO" "Check your configuration files and environment variables"
            ;;
    esac
    
    return "$error_code"
}

# Function to check system requirements
check_system_requirements() {
    local script_file=$1
    local handler=$2
    local requirements=()
    local missing=()
    
    # Basic system requirements
    requirements=(
        "bash>=4.0"
        "coreutils"
        "grep"
        "sed"
        "awk"
    )
    
    # Add handler-specific requirements
    case "$handler" in
        *"python"*)
            requirements+=("python3>=3.6" "pip3")
            ;;
        *"node"*)
            requirements+=("node>=12.0" "npm")
            ;;
        *"ruby"*)
            requirements+=("ruby>=2.0" "gem")
            ;;
        *"php"*)
            requirements+=("php>=7.0")
            ;;
        *"jq"*)
            requirements+=("jq>=1.6")
            ;;
        *"yq"*)
            requirements+=("yq>=4.0")
            ;;
    esac
    
    # Check each requirement
    for req in "${requirements[@]}"; do
        IFS='>=' read -r cmd version <<< "$req"
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$req")
        elif [ -n "$version" ]; then
            # Version check logic here
            local current_version
            current_version=$("$cmd" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
            if [ "$(printf '%s\n' "$version" "$current_version" | sort -V | head -n1)" != "$version" ]; then
                missing+=("$req (current: $current_version)")
            fi
        fi
    done
    
    # Report missing requirements
    if [ ${#missing[@]} -gt 0 ]; then
        handle_error "${ERROR_CODES[DEPENDENCY_MISSING]}" \
            "Missing system requirements" \
            "Required for $script_file" \
            "Missing: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# Function to validate script file
validate_script_file() {
    local script_file=$1
    
    # Check if file exists
    if [ ! -f "$script_file" ]; then
        handle_error "${ERROR_CODES[FILE_NOT_FOUND]}" \
            "Script file not found" \
            "File: $script_file" \
            "Please check the file path and permissions"
        return 1
    fi
    
    # Check if file is readable
    if [ ! -r "$script_file" ]; then
        handle_error "${ERROR_CODES[PERMISSION_DENIED]}" \
            "Cannot read script file" \
            "File: $script_file" \
            "Please check file permissions"
        return 1
    fi
    
    # Check if file is empty
    if [ ! -s "$script_file" ]; then
        handle_error "${ERROR_CODES[INVALID_STATE]}" \
            "Script file is empty" \
            "File: $script_file" \
            "Please ensure the file contains valid content"
        return 1
    fi
    
    # Check for common script issues
    local issues=()
    
    # Check for DOS line endings
    if grep -q $'\r' "$script_file"; then
        issues+=("Contains DOS line endings")
    fi
    
    # Check for invalid characters
    if grep -q $'\t' "$script_file"; then
        issues+=("Contains tab characters")
    fi
    
    # Check for common syntax errors
    case "$script_file" in
        *.sh|*.bash)
            if ! bash -n "$script_file" 2>/dev/null; then
                issues+=("Contains shell syntax errors")
            fi
            ;;
        *.py)
            if ! python3 -m py_compile "$script_file" 2>/dev/null; then
                issues+=("Contains Python syntax errors")
            fi
            ;;
        *.js)
            if ! node --check "$script_file" 2>/dev/null; then
                issues+=("Contains JavaScript syntax errors")
            fi
            ;;
    esac
    
    # Report issues if any
    if [ ${#issues[@]} -gt 0 ]; then
        handle_error "${ERROR_CODES[INVALID_STATE]}" \
            "Script file has issues" \
            "File: $script_file" \
            "Issues: ${issues[*]}"
        return 1
    fi
    
    return 0
}

# Function to check handler is available with enhanced error handling
check_handler() {
    local handler=$1
    local script_file=$2
    
    # Validate script file first
    if ! validate_script_file "$script_file"; then
        return 1
    fi
    
    # If no handler needed (e.g., for executables)
    if [ -z "$handler" ]; then
        return 0
    fi
    
    # Extract the base command and arguments
    local base_cmd
    local args
    IFS=' ' read -r base_cmd args <<< "$handler"
    
    # Check system requirements
    if ! check_system_requirements "$script_file" "$handler"; then
        return 1
    fi
    
    # Check if the command exists
    if ! command -v "$base_cmd" >/dev/null 2>&1; then
        handle_error "${ERROR_CODES[HANDLER_NOT_FOUND]}" \
            "Required command not found" \
            "Command: $base_cmd" \
            "Required for handling $script_file"
        
        # Suggest installation commands for common handlers
        case "$base_cmd" in
            "python3")
                log "INFO" "You can install Python 3 using your system package manager"
                ;;
            "node")
                log "INFO" "You can install Node.js from https://nodejs.org/"
                ;;
            "ruby")
                log "INFO" "You can install Ruby using your system package manager or rbenv/rvm"
                ;;
            "php")
                log "INFO" "You can install PHP using your system package manager"
                ;;
            "jq")
                log "INFO" "You can install jq using your system package manager"
                ;;
            "yq")
                log "INFO" "You can install yq using your system package manager"
                ;;
        esac
        
        return 1
    fi
    
    # Check for required dependencies
    case "$base_cmd" in
        "python3")
            if [ -f "requirements.txt" ]; then
                if ! pip3 list | grep -q -f requirements.txt; then
                    handle_error "${ERROR_CODES[DEPENDENCY_MISSING]}" \
                        "Missing Python dependencies" \
                        "File: requirements.txt" \
                        "Run: pip3 install -r requirements.txt"
                    return 1
                fi
            fi
            ;;
        "node")
            if [ -f "package.json" ]; then
                if ! npm list | grep -q -f package.json; then
                    handle_error "${ERROR_CODES[DEPENDENCY_MISSING]}" \
                        "Missing Node.js dependencies" \
                        "File: package.json" \
                        "Run: npm install"
                    return 1
                fi
            fi
            ;;
        "ruby")
            if [ -f "Gemfile" ]; then
                if ! bundle check >/dev/null 2>&1; then
                    handle_error "${ERROR_CODES[DEPENDENCY_MISSING]}" \
                        "Missing Ruby dependencies" \
                        "File: Gemfile" \
                        "Run: bundle install"
                    return 1
                fi
            fi
            ;;
    esac
    
    return 0
}

# Function to run script with error handling
run_script() {
    local script_file=$1
    local handler=$2
    shift 2
    local args=("$@")
    
    # Set up error handling
    local error_output
    error_output=$(mktemp)
    local exit_code=0
    
    # Run the script with timeout if specified
    if [ "$TIMEOUT" -gt 0 ]; then
        if ! timeout "$TIMEOUT" "$handler" "$script_file" "${args[@]}" 2>"$error_output"; then
            exit_code=$?
            if [ $exit_code -eq 124 ]; then
                handle_error "${ERROR_CODES[TIMEOUT]}" \
                    "Script execution timed out" \
                    "Timeout: ${TIMEOUT}s" \
                    "Consider increasing the timeout or optimizing the script"
                return 1
            fi
        fi
    else
        if ! $handler "$script_file" "${args[@]}" 2>"$error_output"; then
            exit_code=$?
        fi
    fi
    
    # Check for errors
    if [ $exit_code -ne 0 ]; then
        local error_message
        error_message=$(cat "$error_output")
        handle_error "${ERROR_CODES[EXECUTION_FAILED]}" \
            "Script execution failed" \
            "Exit code: $exit_code" \
            "$error_message"
        rm -f "$error_output"
        return 1
    fi
    
    # Clean up
    rm -f "$error_output"
    return 0
}

# Function to run platform-specific script
run_platform_script() {
    local platform=$1
    local script_name=$2
    local script_path
    local script_file
    local retry_count=0
    
    # Get the script file based on platform
    if [ "$platform" = "linux" ]; then
        script_file="${LINUX_SCRIPTS[$script_name]:-}"
    else
        script_file="${WINDOWS_SCRIPTS[$script_name]:-}"
    fi
    
    if [ -z "$script_file" ]; then
        log "ERROR" "Script '$script_name' not found for platform $platform"
        return 1
    fi
    
    script_path="$SCRIPT_DIR/$platform/$script_file"
    
    if [ ! -f "$script_path" ]; then
        log "ERROR" "Script file not found: $script_path"
        return 1
    fi
    
    if [ "$VERBOSE" = true ]; then
        log "INFO" "Running script for platform: $platform"
        log "INFO" "Script: $script_name ($script_file)"
        log "INFO" "Full path: $script_path"
    fi
    
    # Build arguments array
    local args=()
    if [ "$DRY_RUN" = true ]; then
        args+=("--dry-run")
    fi
    if [ "$VERBOSE" = true ]; then
        args+=("--verbose")
    fi
    if [ "$FORCE" = true ]; then
        args+=("--force")
    fi
    if [ "$QUIET" = true ]; then
        args+=("--quiet")
    fi
    args+=("$@")
    
    # Get the appropriate handler for the script
    local handler
    handler=$(get_script_handler "$script_file")
    
    # Check if handler is available
    if ! check_handler "$handler" "$script_file"; then
        return 1
    fi
    
    # Execute the script with retries if specified
    while true; do
        if [ "$TIMEOUT" -gt 0 ]; then
            # Run with timeout
            if ! timeout "$TIMEOUT" "$handler" "$script_path" "${args[@]}"; then
                local exit_code=$?
                if [ $exit_code -eq 124 ]; then
                    log "ERROR" "Script execution timed out after ${TIMEOUT}s"
                    return 1
                fi
            fi
        else
            # Run without timeout
            "$handler" "$script_path" "${args[@]}"
        fi
        
        local exit_code=$?
        if [ "$exit_code" -eq 0 ] || [ "$retry_count" -ge "$RETRY_COUNT" ]; then
            return $exit_code
        fi
        
        retry_count=$((retry_count + 1))
        log "WARN" "Script failed, retrying ($retry_count/$RETRY_COUNT) in ${RETRY_DELAY}s..."
        sleep "$RETRY_DELAY"
    done
}

# Function to run scripts in parallel
run_parallel() {
    local pids=()
    local platforms=("$@")
    
    for platform in "${platforms[@]}"; do
        if [ -n "${LINUX_SCRIPTS[$SCRIPT]:-}" ] || [ -n "${WINDOWS_SCRIPTS[$SCRIPT]:-}" ]; then
            run_platform_script "$platform" "$SCRIPT" "$@" &
            pids+=($!)
        fi
    done
    
    local exit_code=0
    for pid in "${pids[@]}"; do
        wait "$pid" || exit_code=$?
    done
    
    return $exit_code
}

# Main logic
if [ "$PLATFORM" = "auto" ]; then
    if [ "$CI_MODE" = true ]; then
        # In CI, run both platforms
        log "INFO" "Running in CI mode - executing both Linux and Windows scripts"
        if [ "$PARALLEL" = true ]; then
            run_parallel "linux" "windows"
        else
            for platform in "linux" "windows"; do
                if [ -n "${LINUX_SCRIPTS[$SCRIPT]:-}" ] || [ -n "${WINDOWS_SCRIPTS[$SCRIPT]:-}" ]; then
                    run_platform_script "$platform" "$SCRIPT" "$@"
                fi
            done
        fi
    else
        # Auto-detect platform
        detected_platform=$(detect_platform)
        if [ "$detected_platform" = "unknown" ]; then
            log "ERROR" "Could not detect platform"
            exit 1
        fi
        run_platform_script "$detected_platform" "$SCRIPT" "$@"
    fi
else
    # Run specific platform
    run_platform_script "$PLATFORM" "$SCRIPT" "$@"
fi 