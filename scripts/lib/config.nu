# Configuration management module for nix-mox scripts
# Handles loading, validating, and managing configuration files
use logging.nu *
use error-handling.nu *

# Default configuration schema
export const DEFAULT_CONFIG = {
    logging: {
        level: "INFO"
        file: null
        format: "text"  # text, json, structured
        max_size: "10MB"
        retention_days: 30
    }
    platform: {
        auto_detect: true
        preferred: "auto"
        fallback: "linux"
    }
    scripts: {
        timeout: 300
        retry_attempts: 3
        retry_delay: 5
        parallel_limit: 4
    }
    security: {
        validate_scripts: true
        check_permissions: true
        allowed_commands: []
        blocked_patterns: ["rm -rf", "sudo", "chmod 777", "eval", "exec"]
    }
    performance: {
        enable_monitoring: true
        log_performance: true
        performance_threshold: 30  # seconds
    }
    paths: {
        logs: "logs"
        temp: "tmp"
        cache: "cache"
        config: "config"
    }
}

# Configuration file search paths (in order of precedence)
export const CONFIG_PATHS = [
    "./nix-mox.json"
    "./config/nix-mox.json"
    "~/.config/nix-mox/config.json"
    "/etc/nix-mox/config.json"
    "~/.nix-mox/config.json"
]

# Load configuration from file
export def load_config_file [path: string] {
    if not ($path | path exists) {
        return null
    }

    try {
        let content = (open $path)
        let config = ($content | from json)

        # Validate configuration
        let validation = (validate_config $config)
        if not $validation.valid {
            handle_script_error $"Invalid configuration in ($path): ($validation.errors | str join ', ')" "CONFIG_INVALID" { file: $path, errors: $validation.errors }
        }

        $config
    } catch { |err|
        handle_script_error $"Failed to load configuration from ($path): ($err)" "CONFIG_INVALID" { file: $path }
    }
}

# Load configuration from multiple sources with precedence
export def load_config [] {
    mut config = $DEFAULT_CONFIG

    # Load from each config path in order
    for path in $CONFIG_PATHS {
        let file_config = (load_config_file $path)
        if $file_config != null {
            $config = (merge_config $config $file_config)
            log_debug $"Loaded configuration from ($path)"
        }
    }

    # Apply environment variable overrides
    $config = (apply_env_overrides $config)

    # Final validation
    let validation = (validate_config $config)
    if not $validation.valid {
        handle_script_error $"Configuration validation failed: ($validation.errors | str join ', ')" "CONFIG_INVALID" { errors: $validation.errors }
    }

    $config
}

# Merge two configuration objects (deep merge)
export def merge_config [base: record, override: record] {
    mut result = $base

    for key in ($override | columns) {
        let value = $override | get $key

        let existing_value = try { $result | get $key } catch { null }
        if $existing_value != null {
            let base_value = $existing_value

            # Deep merge for nested objects
            if ($base_value | describe) == "record" and ($value | describe) == "record" {
                $result = ($result | upsert $key (merge_config $base_value $value))
            } else {
                $result = ($result | upsert $key $value)
            }
        } else {
            $result = ($result | upsert $key $value)
        }
    }

    $result
}

# Apply environment variable overrides
export def apply_env_overrides [config: record] {
    mut result = $config

    # Logging overrides
    if ($env.NIXMOX_LOG_LEVEL | is-not-empty) {
        $result = ($result | upsert logging.level $env.NIXMOX_LOG_LEVEL)
    }

    if ($env.NIXMOX_LOG_FILE | is-not-empty) {
        $result = ($result | upsert logging.file $env.NIXMOX_LOG_FILE)
    }

    # Platform overrides
    if ($env.NIXMOX_PLATFORM | is-not-empty) {
        $result = ($result | upsert platform.preferred $env.NIXMOX_PLATFORM)
    }

    # Script overrides
    if ($env.NIXMOX_TIMEOUT | is-not-empty) {
        $result = ($result | upsert scripts.timeout ($env.NIXMOX_TIMEOUT | into int))
    }

    if ($env.NIXMOX_RETRY_ATTEMPTS | is-not-empty) {
        $result = ($result | upsert scripts.retry_attempts ($env.NIXMOX_RETRY_ATTEMPTS | into int))
    }

    # Security overrides
    if ($env.NIXMOX_VALIDATE_SCRIPTS | is-not-empty) {
        $result = ($result | upsert security.validate_scripts ($env.NIXMOX_VALIDATE_SCRIPTS | into bool))
    }

    $result
}

# Validate configuration structure and values
export def validate_config [config: record] {
    mut errors = []

    # Check required top-level keys
    let required_keys = ["logging", "platform", "scripts", "security", "performance", "paths"]
    for key in $required_keys {
        let config_value = try { $config | get $key } catch { null }
        if $config_value == null {
            $errors = ($errors | append $"Missing required key: ($key)")
        }
    }

    # Validate logging configuration
    if ($config | get logging?) != null {
        let logging = $config | get logging
        let valid_levels = ["DEBUG", "INFO", "WARN", "ERROR"]

        if ($logging | get level?) != null {
            let level = $logging | get level
            if not ($valid_levels | any { |l| $l == $level }) {
                $errors = ($errors | append $"Invalid log level: ($level). Valid levels: ($valid_levels | str join ', ')")
            }
        }

        if ($logging | get retention_days?) != null {
            let retention = $logging | get retention_days
            if ($retention | into int) < 1 {
                $errors = ($errors | append "Retention days must be at least 1")
            }
        }
    }

    # Validate platform configuration
    if ($config | get platform?) != null {
        let platform = $config | get platform
        let valid_platforms = ["auto", "linux", "darwin", "windows"]

        if ($platform | get preferred?) != null {
            let preferred = $platform | get preferred
            if not ($valid_platforms | any { |p| $p == $preferred }) {
                $errors = ($errors | append $"Invalid platform: ($preferred). Valid platforms: ($valid_platforms | str join ', ')")
            }
        }
    }

    # Validate scripts configuration
    if ($config | get scripts?) != null {
        let scripts = $config | get scripts

        if ($scripts | get timeout?) != null {
            let timeout = $scripts | get timeout
            if ($timeout | into int) < 1 {
                $errors = ($errors | append "Script timeout must be at least 1 second")
            }
        }

        if ($scripts | get retry_attempts?) != null {
            let retries = $scripts | get retry_attempts
            if ($retries | into int) < 0 {
                $errors = ($errors | append "Retry attempts must be non-negative")
            }
        }
    }

    {
        valid: (($errors | length) == 0)
        errors: $errors
    }
}

# Save configuration to file
export def save_config [config: record, path: string] {
    try {
        # Validate before saving
        let validation = (validate_config $config)
        if not $validation.valid {
            handle_script_error $"Cannot save invalid configuration: ($validation.errors | str join ', ')" "CONFIG_INVALID" { errors: $validation.errors }
        }

        # Ensure directory exists
        let dir = ($path | path dirname)
        if not ($dir | path exists) {
            mkdir $dir
        }

        # Save configuration
        $config | to json | save $path
        log_info $"Configuration saved to ($path)"
    } catch { |err|
        handle_script_error $"Failed to save configuration to ($path): ($err)" "CONFIG_INVALID" { file: $path }
    }
}

# Get configuration value with fallback
export def get_config_value [config: record, path: string, default: any = null] {
    let keys = ($path | split row ".")
    mut current = $config

    for key in $keys {
        let current_value = try { $current | get $key } catch { null }
        if $current_value != null {
            $current = ($current | get $key)
        } else {
            return $default
        }
    }

    $current
}

# Set configuration value (deep update, recursive)
export def set_config_value [config: record, path: string, value: any] {
    let keys = ($path | split row ".")
    if ($keys | length) == 1 {
        $config | upsert ($keys | get 0) $value
    } else {
        let first = ($keys | get 0)
        let rest = ($keys | skip 1 | str join ".")
        let first_value = try { $config | get $first } catch { null }
        let sub = if $first_value == null {
            {}
        } else {
            $config | get $first
        }
        $config | upsert $first (set_config_value $sub $rest $value)
    }
}

# Create default configuration file
export def create_default_config [path: string = "./nix-mox.json"] {
    save_config $DEFAULT_CONFIG $path
}

# Show configuration summary
export def show_config_summary [config: record] {
    print $"\n(ansi cyan_bold)Configuration Summary:(ansi reset)"
    print $"  Log Level:  ($config.logging.level)"

    let logfile = if $config.logging.file != null {
        $config.logging.file
    } else {
        "stdout"
    }
    print $"  Log File: ($logfile)"
    print $"  Platform: ($config.platform.preferred)"
    print $"  Script Timeout: ($config.scripts.timeout)s"
    print $"  Retry Attempts: ($config.scripts.retry_attempts)"

    let security_validation = if $config.security.validate_scripts {
        "enabled"
    } else {
        "disabled"
    }
    print $"  Security Validation: ($security_validation)"

    let performance_monitoring = if $config.performance.enable_monitoring {
        "enabled"
    } else {
        "disabled"
    }
    print $"  Performance Monitoring: ($performance_monitoring)"
}

# Export configuration as environment variables
export def export_config_env [config: record] {
    $env.NIXMOX_LOG_LEVEL = $config.logging.level
    $env.NIXMOX_PLATFORM = $config.platform.preferred
    $env.NIXMOX_TIMEOUT = ($config.scripts.timeout | into string)
    $env.NIXMOX_RETRY_ATTEMPTS = ($config.scripts.retry_attempts | into string)
    $env.NIXMOX_VALIDATE_SCRIPTS = ($config.security.validate_scripts | into string)
    $env.NIXMOX_PERFORMANCE_MONITORING = ($config.performance.enable_monitoring | into string)
}
