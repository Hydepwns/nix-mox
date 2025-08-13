#!/usr/bin/env nu

# Safety and backup module for display tests
# Handles backup creation, safety checks, and recovery procedures

use ../../lib/test-utils.nu *
use ../../lib/test-common.nu *

export def setup_safety_backups [backup_dir: string] {
    print $"($env.CYAN)💾 Setting up safety backups... ($env.NC)"
    
    let backup_config = {
        backup_dir: $backup_dir
        timestamp: (date now | format date "%Y%m%d_%H%M%S")
        files_backed_up: []
        backup_successful: false
        error: null
    }

    try {
        # Create backup directory
        mkdir -p $backup_dir
        
        # Backup critical configuration files
        let critical_files = [
            "/etc/nixos/configuration.nix"
            "/etc/nixos/hardware-configuration.nix"
            "/etc/nixos/gaming.nix"
            "/etc/nixos/gaming-tools.nix"
        ]

        for file in $critical_files {
            if ($file | path exists) {
                let backup_path = $"($backup_dir)/($file | path basename).($backup_config.timestamp).backup"
                cp $file $backup_path
                $backup_config | upsert files_backed_up ($backup_config.files_backed_up | append $backup_path)
            }
        }

        $backup_config | upsert backup_successful true
    } catch { |err|
        $backup_config | upsert error $err
    }

    $backup_config
}

export def perform_safety_checks [] {
    print $"($env.CYAN)🛡️  Performing safety checks... ($env.NC)"
    
    let safety_checks = {
        system_accessible: false
        display_functional: false
        backup_available: false
        recovery_possible: false
        warnings: []
        recommendations: []
    }

    # Check if system is accessible
    let system_check = try {
        safe_command "whoami"
        true
    } catch {
        false
    }
    $safety_checks | upsert system_accessible $system_check

    # Check if display is functional
    let display_check = try {
        safe_command "echo $env.DISPLAY"
        true
    } catch {
        false
    }
    $safety_checks | upsert display_functional $display_check

    # Check if backup directory exists
    let backup_check = try {
        let backup_dir = "/tmp/nix-mox-display-backups"
        ls $backup_dir | length
        true
    } catch {
        false
    }
    $safety_checks | upsert backup_available $backup_check

    # Check if recovery is possible
    let recovery_check = try {
        safe_command "which nixos-rebuild"
        true
    } catch {
        false
    }
    $safety_checks | upsert recovery_possible $recovery_check

    # Generate warnings and recommendations
    if not $safety_checks.system_accessible {
        $safety_checks | upsert warnings ($safety_checks.warnings | append "System access compromised")
    }

    if not $safety_checks.display_functional {
        $safety_checks | upsert warnings ($safety_checks.warnings | append "Display may not be functional")
        $safety_checks | upsert recommendations ($safety_checks.recommendations | append "Test display functionality before proceeding")
    }

    if not $safety_checks.backup_available {
        $safety_checks | upsert warnings ($safety_checks.warnings | append "No backup available")
        $safety_checks | upsert recommendations ($safety_checks.recommendations | append "Create backup before making changes")
    }

    if not $safety_checks.recovery_possible {
        $safety_checks | upsert warnings ($safety_checks.warnings | append "Recovery tools not available")
        $safety_checks | upsert recommendations ($safety_checks.recommendations | append "Ensure nixos-rebuild is available")
    }

    $safety_checks
}

export def assess_risk_level [hardware_info: record, config_analysis: record, safety_checks: record] {
    print $"($env.CYAN)⚠️  Assessing risk level... ($env.NC)"
    
    let risk_assessment = {
        overall_risk: "low"
        risk_score: 0
        factors: []
        recommendations: []
        safe_to_proceed: true
    }

    # Calculate risk score based on various factors
    let risk_score = 0

    # Hardware risk factors
    if $hardware_info.risk_level == "high" {
        $risk_assessment | upsert risk_score ($risk_assessment.risk_score + 5)
        $risk_assessment | upsert factors ($risk_assessment.factors | append "High-risk hardware detected")
    } else if $hardware_info.risk_level == "medium" {
        $risk_assessment | upsert risk_score ($risk_assessment.risk_score + 3)
        $risk_assessment | upsert factors ($risk_assessment.factors | append "Medium-risk hardware detected")
    }

    # Configuration risk factors
    let config_issues = ($config_analysis.issues | length)
    $risk_assessment | upsert risk_score ($risk_assessment.risk_score + $config_issues * 2)
    if $config_issues > 0 {
        $risk_assessment | upsert factors ($risk_assessment.factors | append $"($config_issues) configuration issues found")
    }

    # Safety risk factors
    let safety_warnings = ($safety_checks.warnings | length)
    $risk_assessment | upsert risk_score ($risk_assessment.risk_score + $safety_warnings)
    if $safety_warnings > 0 {
        $risk_assessment | upsert factors ($risk_assessment.factors | append $"($safety_warnings) safety warnings")
    }

    # Determine overall risk level
    let overall_risk = if $risk_assessment.risk_score >= 10 {
        "high"
    } else if $risk_assessment.risk_score >= 5 {
        "medium"
    } else {
        "low"
    }

    $risk_assessment | upsert overall_risk $overall_risk

    # Determine if safe to proceed
    let safe_to_proceed = if $overall_risk == "high" {
        false
    } else if $overall_risk == "medium" {
        $safety_checks.backup_available and $safety_checks.recovery_possible
    } else {
        true
    }

    $risk_assessment | upsert safe_to_proceed $safe_to_proceed

    # Generate recommendations
    if $overall_risk == "high" {
        $risk_assessment | upsert recommendations ($risk_assessment.recommendations | append "High risk detected - manual intervention required")
        $risk_assessment | upsert recommendations ($risk_assessment.recommendations | append "Review all warnings and issues before proceeding")
    } else if $overall_risk == "medium" {
        $risk_assessment | upsert recommendations ($risk_assessment.recommendations | append "Medium risk detected - proceed with caution")
        $risk_assessment | upsert recommendations ($risk_assessment.recommendations | append "Ensure backups are available")
    } else {
        $risk_assessment | upsert recommendations ($risk_assessment.recommendations | append "Low risk - safe to proceed")
    }

    $risk_assessment
}

export def create_recovery_plan [backup_info: record, risk_assessment: record] {
    print $"($env.CYAN)🔄 Creating recovery plan... ($env.NC)"
    
    {
        backup_location: $backup_info.backup_dir
        backup_files: $backup_info.files_backed_up
        risk_level: $risk_assessment.overall_risk
        recovery_steps: [
            "1. If display issues occur, reboot into recovery mode"
            "2. Restore configuration from backup files"
            "3. Run nixos-rebuild switch to apply changes"
            "4. Test display functionality"
            "5. If issues persist, restore from previous working configuration"
        ]
        emergency_commands: [
            "nixos-rebuild boot --rollback"
            "nixos-rebuild switch --rollback"
            "systemctl isolate rescue.target"
        ]
    }
} 