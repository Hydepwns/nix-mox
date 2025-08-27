#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use ../../lib/logging.nu *

# Display Testing Module for nix-mox
# This module provides comprehensive display configuration testing and validation

export-env {
    use ../../lib/testing.nu *
}

# Import modular components
use ./modules/hardware.nu *
use ./modules/config.nu *
use ./modules/safety.nu *

# --- Display Testing Configuration ---

def setup_display_test_config [] {
    {
        enable_hardware_detection: true
        enable_config_analysis: true
        enable_risk_assessment: true
        enable_safety_backups: true
        enable_interactive_mode: true
        backup_config_dir: "/tmp/nix-mox-display-backups"
        max_risk_score: 7
        timeout: 60
        verbose: false
    }
}

# --- Main Display Testing Functions ---

export def main [] {
    print "(ansi green)🖥️  nix-mox Display Tests(ansi reset)"
    print "(ansi yellow)==========================(ansi reset)\n"

    # Set up test environment
    let config = setup_display_test_config
    # Set up environment variables for colors and error handling
    $env.GREEN = (ansi green)
    $env.RED = (ansi red)
    $env.YELLOW = (ansi yellow)
    $env.BLUE = (ansi blue)
    $env.CYAN = (ansi cyan)
    $env.NC = (ansi reset)
    $env.LAST_ERROR = ""
    
    # Ensure TEST_TEMP_DIR is set
    if not ($env | get -o TEST_TEMP_DIR | is-not-empty) {
        $env.TEST_TEMP_DIR = "coverage-tmp/nix-mox-tests"
    }

    if not ($env.TEST_TEMP_DIR | path exists) {
        mkdir $env.TEST_TEMP_DIR
    }

    # Run hardware detection
    print "(ansi blue)🔍 Hardware Detection Phase(ansi reset)"
    let gpu_info = detect_gpu_hardware
    let display_info = detect_display_environment
    let compatibility = analyze_hardware_compatibility $gpu_info $display_info

    # Run configuration analysis
    print "\n(ansi blue)⚙️  Configuration Analysis Phase(ansi reset)"
    let config_analysis = analyze_display_config
    let config_validation = validate_display_config $config_analysis
    let config_report = generate_config_report $config_analysis $config_validation

    # Run safety checks
    print "\n(ansi blue)🛡️  Safety Assessment Phase(ansi reset)"
    let backup_info = setup_safety_backups $config.backup_config_dir
    let safety_checks = perform_safety_checks
    let risk_assessment = assess_risk_level $gpu_info $config_analysis $safety_checks
    let recovery_plan = create_recovery_plan $backup_info $risk_assessment

    # Generate comprehensive report
    let final_report = generate_final_report $gpu_info $display_info $compatibility $config_report $safety_checks $risk_assessment $recovery_plan

    # Display results
    display_results $final_report

    # Track display test results
    track_test "display_hardware_detection" "display" (if $gpu_info.detected { "passed" } else { "failed" }) 0.1
    track_test "display_config_analysis" "display" (if $config_report.summary.valid { "passed" } else { "failed" }) 0.1
    track_test "display_safety_assessment" "display" (if $risk_assessment.safe_to_proceed { "passed" } else { "failed" }) 0.1
    track_test "display_overall" "display" (if $risk_assessment.safe_to_proceed { "passed" } else { "failed" }) 0.1

    # Return appropriate success status
    if $risk_assessment.safe_to_proceed {
        print "(ansi green)✅ Display tests completed - safe to proceed(ansi reset)"
        true
    } else {
        print "(ansi red)❌ Display tests completed - manual intervention required(ansi reset)"
        false
    }
}

def generate_final_report [gpu_info: record, display_info: record, compatibility: record, config_report: record, safety_checks: record, risk_assessment: record, recovery_plan: record] {
    {
        timestamp: (date now | format date "%Y-%m-%d %H:%M:%S")
        hardware: {
            gpu: $gpu_info
            display: $display_info
            compatibility: $compatibility
        }
        configuration: $config_report
        safety: {
            checks: $safety_checks
            risk_assessment: $risk_assessment
            recovery_plan: $recovery_plan
        }
        summary: {
            overall_status: (if $risk_assessment.safe_to_proceed { "safe" } else { "unsafe" })
            risk_level: $risk_assessment.overall_risk
            issues_found: ($config_report.details.issues | length)
            warnings_found: ($config_report.details.warnings | length)
            recommendations_count: ($config_report.suggestions | length)
        }
    }
}

def display_results [report: record] {
    print "\n(ansi blue)📊 Display Test Results(ansi reset)"
    print "(ansi blue)=====================(ansi reset)\n"

    # Hardware summary
    print $"GPU: ($report.hardware.gpu.name) (($report.hardware.gpu.type))"
    print $"Display Server: ($report.hardware.display.display_server)"
    print $"Desktop: ($report.hardware.display.desktop)"
    print $"Compatibility: ($report.hardware.compatibility.gpu_supported and $report.hardware.compatibility.display_supported)"

    # Configuration summary
    print $"\nConfiguration Status: (if $report.configuration.summary.valid { '(ansi green)Valid' } else { '(ansi red)Invalid' })(ansi reset)"
    print $"Files Analyzed: ($report.configuration.summary.files_analyzed)"
    print $"Issues Found: ($report.configuration.summary.issues_found)"
    print $"Warnings Found: ($report.configuration.summary.warnings_found)"

    # Safety summary
    print $"\nRisk Level: (ansi yellow)($report.safety.risk_assessment.overall_risk)(ansi reset)"
    print $"Safe to Proceed: (if $report.safety.risk_assessment.safe_to_proceed { '(ansi green)Yes' } else { '(ansi red)No' })(ansi reset)"

    # Display issues if any
    if ($report.configuration.details.issues | length) > 0 {
        print "\n(ansi red)🚨 Critical Issues:(ansi reset)"
        $report.configuration.details.issues | each { |issue|
            print $"  • $issue"
        }
    }

    # Display warnings if any
    if ($report.configuration.details.warnings | length) > 0 {
        print "\n(ansi yellow)⚠️  Warnings:(ansi reset)"
        $report.configuration.details.warnings | each { |warning|
            print $"  • $warning"
        }
    }

    # Display recommendations
    if ($report.configuration.suggestions | length) > 0 {
        print "\n(ansi blue)💡 Recommendations:(ansi reset)"
        $report.configuration.suggestions | each { |suggestion|
            print $"  • $suggestion"
        }
    }

    # Display recovery information if needed
    if $report.safety.risk_assessment.overall_risk != "low" {
        print "\n(ansi cyan)🔄 Recovery Information:(ansi reset)"
        print $"Backup Location: ($report.safety.recovery_plan.backup_location)"
        print $"Risk Level: ($report.safety.recovery_plan.risk_level)"
        print "Recovery Steps:"
        $report.safety.recovery_plan.recovery_steps | each { |step|
            print $"  $step"
        }
    }
}

# Interactive mode for user confirmation
export def interactive_mode [] {
    print "(ansi yellow)🤔 Interactive Mode - Confirm before proceeding(ansi reset)"
    print "This will run display tests and ask for confirmation before any changes.\n"
    
    let response = (input "Do you want to proceed with display tests? (y/N): ")
    if ($response | str downcase) == "y" or ($response | str downcase) == "yes" {
        main
    } else {
        print "(ansi yellow)Display tests cancelled by user(ansi reset)"
        exit 0
    }
}

# Quick test mode for basic checks
export def quick_test [] {
    print "(ansi blue)⚡ Quick Display Test(ansi reset)"
    print "(ansi blue)===================(ansi reset)\n"

    let gpu_info = detect_gpu_hardware
    let display_info = detect_display_environment
    
    print $"GPU: ($gpu_info.name) (($gpu_info.type))"
    print $"Display: ($display_info.display_server)"
    print $"Desktop: ($display_info.desktop)"
    
    if $gpu_info.detected and ($display_info.display_server == "X11" or $display_info.display_server == "Wayland") {
        print "(ansi green)✅ Basic display setup appears functional(ansi reset)"
        exit 0
    } else {
        print "(ansi red)❌ Basic display setup has issues(ansi reset)"
        exit 1
    }
}

# Test runner for CI/CD
export def run_tests [] {
    if ($env | get -o INTERACTIVE | default "false") == "true" {
        interactive_mode
    } else if ($env | get -o QUICK | default "false") == "true" {
        quick_test
    } else {
        main
    }
}

# Always run tests when sourced
run_tests
