#!/usr/bin/env nu

# Import unified libraries
use ../../../lib/validators.nu
use ../../../lib/logging.nu *


# Configuration analysis module for display tests
# Handles configuration parsing, validation, and risk assessment

use ../../lib/test-utils.nu *
use ../../../lib/testing.nu *

export def analyze_display_config [] {
    print $"($env.CYAN)⚙️  Analyzing display configuration... ($env.NC)"
    
    let config_files = [
        "/etc/nixos/configuration.nix"
        "/etc/nixos/hardware-configuration.nix"
        "~/.config/nixpkgs/config.nix"
    ]

    let config_analysis = {
        files_found: []
        files_missing: []
        issues: []
        warnings: []
        recommendations: []
    }

    # Check each configuration file
    for file in $config_files {
        let expanded_path = (if ($file | str starts-with "~") {
            $file | str replace "~" $env.HOME
        } else {
            $file
        })
        
        if ($expanded_path | path exists) {
            $config_analysis | upsert files_found ($config_analysis.files_found | append $expanded_path)
        } else {
            $config_analysis | upsert files_missing ($config_analysis.files_missing | append $expanded_path)
        }
    }

    # Analyze found configuration files
    for file in $config_analysis.files_found {
        let file_analysis = (analyze_config_file $file)
        $config_analysis | upsert issues ($config_analysis.issues | append $file_analysis.issues)
        $config_analysis | upsert warnings ($config_analysis.warnings | append $file_analysis.warnings)
        $config_analysis | upsert recommendations ($config_analysis.recommendations | append $file_analysis.recommendations)
    }

    $config_analysis
}

def analyze_config_file [file_path: string] {
    let content = try {
        open --raw $file_path
    } catch {
        ""
    }

    let analysis = {
        issues: []
        warnings: []
        recommendations: []
    }

    # Check for common display-related issues
    if ($content | str contains "services.xserver.enable = true") {
        $analysis | upsert warnings ($analysis.warnings | append "X11 server enabled - consider Wayland for modern systems")
    }

    if ($content | str contains "hardware.nvidia") {
        $analysis | upsert warnings ($analysis.warnings | append "NVIDIA configuration detected - ensure proper driver setup")
    }

    if ($content | str contains "services.displayManager") {
        $analysis | upsert warnings ($analysis.warnings | append "Display manager configured - verify compatibility")
    }

    # Check for missing essential configurations
    if not ($content | str contains "hardware.opengl") {
        $analysis | upsert issues ($analysis.issues | append "OpenGL configuration missing")
        $analysis | upsert recommendations ($analysis.recommendations | append "Add hardware.opengl.enable = true")
    }

    if not ($content | str contains "services.xserver.videoDrivers") {
        $analysis | upsert warnings ($analysis.warnings | append "Video drivers not explicitly configured")
        $analysis | upsert recommendations ($analysis.recommendations | append "Consider explicitly setting video drivers")
    }

    $analysis
}

export def validate_display_config [config_analysis: record] {
    print $"($env.CYAN)✅ Validating display configuration... ($env.NC)"
    
    let validation = {
        valid: true
        risk_score: 0
        critical_issues: 0
        warnings: 0
        suggestions: []
    }

    # Count issues and calculate risk score
    let issue_count = ($config_analysis.issues | length)
    let warning_count = ($config_analysis.warnings | length)
    
    $validation | upsert critical_issues $issue_count
    $validation | upsert warnings $warning_count
    $validation | upsert risk_score ($issue_count * 3 + $warning_count)
    $validation | upsert suggestions ($config_analysis.recommendations)

    # Mark as invalid if there are critical issues
    if $issue_count > 0 {
        $validation | upsert valid false
    }

    # Add risk level assessment
    let risk_level = if $validation.risk_score >= 10 {
        "high"
    } else if $validation.risk_score >= 5 {
        "medium"
    } else {
        "low"
    }

    $validation | upsert risk_level $risk_level
}

export def generate_config_report [config_analysis: record, validation: record] {
    print $"($env.CYAN)📋 Generating configuration report... ($env.NC)"
    
    {
        summary: {
            valid: $validation.valid
            risk_level: $validation.risk_level
            risk_score: $validation.risk_score
            files_analyzed: ($config_analysis.files_found | length)
            files_missing: ($config_analysis.files_missing | length)
            issues_found: $validation.critical_issues
            warnings_found: $validation.warnings
        }
        details: {
            files_found: $config_analysis.files_found
            files_missing: $config_analysis.files_missing
            issues: $config_analysis.issues
            warnings: $config_analysis.warnings
            recommendations: $config_analysis.recommendations
        }
        suggestions: $validation.suggestions
    }
} 