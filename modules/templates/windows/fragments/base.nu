# Windows Template Fragment System - Base Configuration
# Main entry point that imports all essential fragments

# Load configuration from environment or use defaults
let config = {
    hostname: ($env.HOSTNAME? | default "windows-pc"),
    user: ($env.USER? | default "admin"),
    password: ($env.PASSWORD? | default "secure-password"),
    installPath: ($env.INSTALL_PATH? | default "C:\\Program Files"),
    gamesPath: ($env.GAMES_PATH? | default "D:\\Games"),
    features: ($env.FEATURES? | default "base" | split row ","),
    securityLevel: ($env.SECURITY_LEVEL? | default "medium"),
    performanceProfile: ($env.PERFORMANCE_PROFILE? | default "balanced"),
    ci: ($env.CI? | default "false"),
    dryRun: ($env.DRY_RUN? | default "false")
}

# CI/CD configuration
let isCI = $config.ci == "true"
let isDryRun = $config.dryRun == "true"
let logLevel = if $isCI { "debug" } else { "info" }

# Helper functions
def log [message: string] {
    let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
    if $logLevel == "debug" {
        print $"($timestamp) [DEBUG] ($message)"
    } else {
        print $"($timestamp) [INFO] ($message)"
    }
}

def log-error [message: string] {
    let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
    print $"($timestamp) [ERROR] ($message)"
}

def check-admin-privileges [] {
    log "Checking administrator privileges..."

    # Check if running as administrator
    let isAdmin = (whoami | str contains "Administrator")
    if not $isAdmin {
        log-error "Script must be run as Administrator"
        exit 1
    }

    log "Administrator privileges confirmed"
}

def check-windows-version [] {
    log "Checking Windows version..."

    let winVer = (systeminfo | findstr /B /C:"OS Version")
    log $"Windows version: ($winVer)"

    # Check if Windows 10 or later
    let majorVersion = (systeminfo | findstr /B /C:"OS Version" | parse "{*Version *}" | get Version.0 | split row "." | get 0)
    if ($majorVersion | into int) < 10 {
        log-error "Windows 10 or later is required"
        exit 1
    }

    log "Windows version is compatible"
}

def check-disk-space [] {
    log "Checking available disk space..."

    # Check C: drive space
    let freeSpace = (Get-PSDrive C | get free)
    let requiredSpace = 50GB

    if $freeSpace < $requiredSpace {
        log-error $"Insufficient disk space. Need at least ($requiredSpace) free, have ($freeSpace)"
        exit 1
    }

    log $"Available disk space: ($freeSpace)"
}

def setup-hostname [] {
    if $isDryRun {
        log "DRY RUN: Would set hostname to ($config.hostname)"
        return
    }

    log $"Setting hostname to ($config.hostname)..."

    try {
        wmic computersystem where name="%computername%" call rename name=($config.hostname)
        log "Hostname updated successfully"
    } catch {
        log-error "Failed to update hostname"
    }
}

def setup-user-account [] {
    if $isDryRun {
        log "DRY RUN: Would create user account ($config.user)"
        return
    }

    log $"Setting up user account ($config.user)..."

    try {
        # Create user account
        net user $config.user $config.password /add
        net localgroup administrators $config.user /add

        # Disable default admin account for security
        net user administrator /active:no

        log "User account created successfully"
    } catch {
        log-error "Failed to create user account"
    }
}

def setup-directories [] {
    if $isDryRun {
        log "DRY RUN: Would create installation directories"
        return
    }

    log "Creating installation directories..."

    try {
        # Create main installation directory
        if not ($config.installPath | path exists) {
            mkdir $config.installPath
        }

        # Create games directory
        if not ($config.gamesPath | path exists) {
            mkdir $config.gamesPath
        }

        log "Installation directories created"
    } catch {
        log-error "Failed to create directories"
    }
}

# Import essential fragments
def import-fragments [] {
    log "Importing essential fragments..."

    # Always import these base fragments
    source fragments/prerequisites.nu
    source fragments/networking.nu
    source fragments/security.nu
    source fragments/performance.nu
    source fragments/maintenance.nu

    # Import feature-specific fragments based on configuration
    if "gaming" in $config.features {
        log "Importing gaming fragment..."
        source fragments/gaming.nu
    }

    if "development" in $config.features {
        log "Importing development fragment..."
        source fragments/development.nu
    }

    if "multimedia" in $config.features {
        log "Importing multimedia fragment..."
        source fragments/multimedia.nu
    }

    if "productivity" in $config.features {
        log "Importing productivity fragment..."
        source fragments/productivity.nu
    }

    if "virtualization" in $config.features {
        log "Importing virtualization fragment..."
        source fragments/virtualization.nu
    }
}

# Main setup function
def main [] {
    log "Starting Windows configuration setup..."
    log $"CI Mode: ($isCI)"
    log $"Dry Run Mode: ($isDryRun)"
    log $"Configuration: ($config | to json)"

    # Run base setup steps
    check-admin-privileges
    check-windows-version
    check-disk-space
    setup-hostname
    setup-user-account
    setup-directories

    # Import and run fragments
    import-fragments

    log "Windows configuration setup completed successfully"
}

# Export main function and configuration
export def setup-windows [] {
    main
}

export-env {
    $env.WINDOWS_CONFIG = ($config | to json)
}

# Run main function if script is executed directly
if ($env.SCRIPT_NAME? | default "" | str contains "base.nu") {
    main
}
