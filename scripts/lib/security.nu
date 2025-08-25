# Security module for nix-mox scripts
# Validates scripts for dangerous patterns and provides security recommendations
use logging.nu *
use ./unified-error-handling.nu *

# Security threat levels
export const THREAT_LEVELS = {
    LOW: "low"
    MEDIUM: "medium"
    HIGH: "high"
    CRITICAL: "critical"
}

# Dangerous command patterns
export const DANGEROUS_PATTERNS = {
    CRITICAL: ["rm -rf", "sudo rm -rf", "chmod 777", "chown root", "eval", "exec", "system", "shell_exec"]
    HIGH: ["sudo", "su -", "sudo su", "sudo -i", "sudo -s", "chmod 666", "chmod 777", "dd if=", "mkfs", "fdisk", "parted"]
    MEDIUM: ["curl -O", "wget -O", "scp", "rsync", "tar -xzf", "unzip", "gunzip", "bunzip2"]
    LOW: ["echo", "print", "cat", "ls", "find", "grep"]
}

# Security validation rules
export const SECURITY_RULES = {
    check_dangerous_patterns: true
    check_permissions: true
    check_dependencies: true
    check_network_access: true
    check_file_operations: true
    require_validation: false
}

# Validate script security
export def validate_script_security [script_path: string, rules: record = $SECURITY_RULES] {
    if not ($script_path | path exists) {
        return {
            secure: false
            threats: [{
                level: "CRITICAL"
                message: "Script file does not exist"
                pattern: "file_not_found"
            }]
            recommendations: ["Check script path and permissions"]
        }
    }

    let content = (open $script_path)
    mut threats = []
    mut recommendations = []

    # Check for dangerous patterns
    if $rules.check_dangerous_patterns {
        let pattern_threats = (check_dangerous_patterns $content)
        $threats = ($threats | append $pattern_threats)
    }

    # Check file permissions
    if $rules.check_permissions {
        let perm_threats = (check_file_permissions $script_path)
        $threats = ($threats | append $perm_threats)
    }

    # Check dependencies
    if $rules.check_dependencies {
        let dep_threats = (check_dependency_security $content)
        $threats = ($threats | append $dep_threats)
    }

    # Check network access
    if $rules.check_network_access {
        let net_threats = (check_network_access $content)
        $threats = ($threats | append $net_threats)
    }

    # Check file operations
    if $rules.check_file_operations {
        let file_threats = (check_file_operations $content)
        $threats = ($threats | append $file_threats)
    }

    # Generate recommendations
    $recommendations = (generate_security_recommendations $threats)

    # Determine overall security status
    let has_critical = ($threats | where level == "CRITICAL" | length) > 0
    let has_high = ($threats | where level == "HIGH" | length) > 0
    let secure = not ($has_critical or $has_high)

    {
        secure: $secure
        threats: $threats
        recommendations: $recommendations
        threat_summary: {
            critical: ($threats | where level == "CRITICAL" | length)
            high: ($threats | where level == "HIGH" | length)
            medium: ($threats | where level == "MEDIUM" | length)
            low: ($threats | where level == "LOW" | length)
        }
    }
}

# Check for dangerous patterns in script content
export def check_dangerous_patterns [content: string] {
    mut threats = []

    for level in ($DANGEROUS_PATTERNS | columns) {
        let patterns = $DANGEROUS_PATTERNS | get $level
        for pattern in $patterns {
            if ($content | str contains $pattern) {
                $threats = ($threats | append {
                    level: $level
                    message: $"Dangerous pattern detected: ($pattern)"
                    pattern: $pattern
                    recommendation: (get_pattern_recommendation $pattern)
                })
            }
        }
    }

    $threats
}

# Get recommendation for dangerous pattern
export def get_pattern_recommendation [pattern: string] {
    match $pattern {
        "rm -rf" => "Use safer alternatives like 'trash' or implement confirmation prompts"
        "sudo" => "Consider if elevated privileges are necessary, use specific sudo commands"
        "chmod 777" => "Use more restrictive permissions, consider 755 or 644"
        "eval" => "Avoid eval, use safer alternatives like parameter expansion"
        "exec" => "Consider using subprocess or function calls instead"
        _ => "Review this command for security implications"
    }
}

# Check file permissions
export def check_file_permissions [file_path: string] {
    mut threats = []

    let permission_result = try {
        let perms = (ls -l $file_path | get mode.0)

        # Check if world-writable
        if ($perms | str contains "w" and $perms | str contains "o") {
            $threats = ($threats | append {
                level: "HIGH"
                message: "File is world-writable"
                pattern: "world_writable"
                recommendation: "Remove world-write permissions, use 755 or 644"
            })
        }

        # Check if executable by others
        if ($perms | str contains "x" and $perms | str contains "o") {
            $threats = ($threats | append {
                level: "MEDIUM"
                message: "File is executable by others"
                pattern: "world_executable"
                recommendation: "Consider removing world-execute permissions"
            })
        }

        # Check if owned by root
        let owner = (ls -l $file_path | get name.0 | split row " " | get 2)
        if $owner == "root" {
            $threats = ($threats | append {
                level: "MEDIUM"
                message: "File is owned by root"
                pattern: "root_owned"
                recommendation: "Consider changing ownership to appropriate user"
            })
        }

        $threats
    } catch { |err|
        [{
            level: "MEDIUM"
            message: $"Could not check file permissions: ($err)"
            pattern: "permission_check_failed"
            recommendation: "Manually verify file permissions"
        }]
    }

    $permission_result
}

# Check dependency security
export def check_dependency_security [content: string] {
    mut threats = []

    # Check for potentially dangerous commands
    let dangerous_commands = ["nc", "netcat", "telnet", "ftp", "tftp", "rsh", "rlogin", "rexec"]
    for cmd in $dangerous_commands {
        if ($content | str contains $cmd) {
            $threats = ($threats | append {
                level: "MEDIUM"
                message: $"Potentially dangerous command: ($cmd)"
                pattern: $"dangerous_command_($cmd)"
                recommendation: $"Consider using safer alternatives to ($cmd)"
            })
        }
    }

    $threats
}

# Check network access patterns
export def check_network_access [content: string] {
    mut threats = []

    # Check for direct network access
    let network_patterns = ["curl http://", "wget http://", "nc -l", "netcat -l", "python -m http.server", "php -S", "ruby -run -e httpd"]
    for pattern in $network_patterns {
        if ($content | str contains $pattern) {
            $threats = ($threats | append {
                level: "MEDIUM"
                message: $"Network access detected: ($pattern)"
                pattern: "network_access"
                recommendation: "Review network access for security implications"
            })
        }
    }

    $threats
}

# Check file operations
export def check_file_operations [content: string] {
    mut threats = []

    # Check for potentially dangerous file operations
    let file_patterns = ["> /etc/", ">> /etc/", "> /var/", ">> /var/", "> /usr/", ">> /usr/", "> /boot/", ">> /boot/"]
    for pattern in $file_patterns {
        if ($content | str contains $pattern) {
            $threats = ($threats | append {
                level: "HIGH"
                message: $"Writing to system directory: ($pattern)"
                pattern: "system_write"
                recommendation: "Avoid writing directly to system directories"
            })
        }
    }

    $threats
}

# Generate security recommendations
export def generate_security_recommendations [threats: list] {
    mut recommendations = []

    let critical_count = ($threats | where level == "CRITICAL" | length)
    let high_count = ($threats | where level == "HIGH" | length)

    if $critical_count > 0 {
        $recommendations = ($recommendations | append "CRITICAL: Address all critical security threats before execution")
    }

    if $high_count > 0 {
        $recommendations = ($recommendations | append "HIGH: Review and address high-priority security concerns")
    }

    # Add specific recommendations from threats
    for threat in $threats {
        if ($threat.recommendation | is-not-empty) {
            $recommendations = ($recommendations | append $threat.recommendation)
        }
    }

    # Add general recommendations
    $recommendations = ($recommendations | append "Consider running scripts in a sandboxed environment")
    $recommendations = ($recommendations | append "Review script output and logs for unexpected behavior")
    $recommendations = ($recommendations | append "Keep scripts updated and review security patches")

    $recommendations | uniq
}

# Scan all scripts for security issues
export def scan_all_scripts [scripts_dir: string = "scripts"] {
    let all_scripts = (discover_scripts $scripts_dir)
    mut scan_results = []

    for script in $all_scripts {
        let security_result = (validate_script_security $script.path)
        $scan_results = ($scan_results | append {
            script: $script.name
            path: $script.path
            secure: $security_result.secure
            threats: $security_result.threats
            recommendations: $security_result.recommendations
            threat_summary: $security_result.threat_summary
        })
    }

    $scan_results
}

# Generate security report
export def generate_security_report [output_file: string = "logs/security-report.json"] {
    let scan_results = (scan_all_scripts)
    let total_scripts = ($scan_results | length)
    let secure_scripts = ($scan_results | where secure == true | length)
    let insecure_scripts = ($scan_results | where secure == false | length)

    let total_threats = ($scan_results | get threat_summary | each { |summary|
        $summary.critical + $summary.high + $summary.medium + $summary.low
    } | math sum)

    let report = {
        generated_at: (date now)
        summary: {
            total_scripts: $total_scripts
            secure_scripts: $secure_scripts
            insecure_scripts: $insecure_scripts
            security_score: (if $total_scripts > 0 { ($secure_scripts / $total_scripts) * 100 } else { 0 })
            total_threats: $total_threats
        }
        scripts: $scan_results
        recommendations: (generate_overall_recommendations $scan_results)
    }

    try {
        $report | to json | save $output_file
        info $"Security report generated: ($output_file)" "security"
        $report
    } catch { |err|
        error $"Failed to generate security report: ($err)" "security"
        null
    }
}

# Generate overall security recommendations
export def generate_overall_recommendations [scan_results: list] {
    mut recommendations = []

    let insecure_count = ($scan_results | where secure == false | length)
    let critical_threats = ($scan_results | get threat_summary | each { |summary| $summary.critical } | math sum)
    let high_threats = ($scan_results | get threat_summary | each { |summary| $summary.high } | math sum)

    if $insecure_count > 0 {
        $recommendations = ($recommendations | append $"Address security issues in ($insecure_count) scripts")
    }

    if $critical_threats > 0 {
        $recommendations = ($recommendations | append $"Fix ($critical_threats) critical security threats")
    }

    if $high_threats > 0 {
        $recommendations = ($recommendations | append $"Review ($high_threats) high-priority security concerns")
    }

    if ($recommendations | length) == 0 {
        $recommendations = ($recommendations | append "All scripts pass security validation")
    }

    $recommendations
}

# Log security event
export def log_security_event [event_type: string, script_path: string, details: record = {}] {
    let event_data = {
        timestamp: (timestamp),
        event_type: $event_type,
        script_path: $script_path,
        details: $details
    }
    
    # Log to security log file
    let security_log = "logs/security.log"
    try {
        $event_data | to json | save --append $security_log
    } catch { |err|
        error $"Failed to log security event: ($err)" "security"
    }
    
    # Also log to console
    warn $"Security event: ($event_type) in ($script_path)" "security"
    if ($details | columns | length) > 0 {
        debug $"Event details: ($details | to json)" "security"
    }
}

# Check if script is safe to execute
export def is_safe_to_execute [script_path: string, strict_mode: bool = false] {
    let security_result = (validate_script_security $script_path)

    if $strict_mode {
        # In strict mode, any threat prevents execution
        $security_result.secure
    } else {
        # In normal mode, only critical and high threats prevent execution
        let has_critical = ($security_result.threats | where level == "CRITICAL" | length) > 0
        let has_high = ($security_result.threats | where level == "HIGH" | length) > 0
        not ($has_critical or $has_high)
    }
}
