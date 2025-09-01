#!/usr/bin/env nu

# Import consolidated libraries
use ../lib/logging.nu *
use ../lib/command-wrapper.nu *
use ../lib/validators.nu *
use ../lib/secure-command.nu *

# nix-mox Health Check Script
# Comprehensive system health validation for nix-mox configurations

def show_banner [] {
  banner "nix-mox: Health Check" "System health validation and configuration check" --context "health-check"
}

# Check if a command exists
def validate_command [cmd: string] {
  validate_command $cmd | get success
}

# Check if a file exists
def validate_file [path: string] {
  validate_file $path | get success
}

# Check if a directory exists  
def validate_directory [path: string] {
  validate_directory $path | get success
}

# Comprehensive health check using consolidated validators
def run_health_checks [] {
  info "Starting comprehensive health check..." --context "health-check"
  
  # System validations
  let system_results = (run_validations (basic_system_validations))
  step 1 4 "System environment checks" --context "health-check"
  
  # Nix environment validations
  let nix_results = (run_validations (nix_environment_validations))
  step 2 4 "Nix environment checks" --context "health-check"
  
  # Gaming environment validations (optional)
  let gaming_results = (run_validations (gaming_setup_validations))
  step 3 4 "Gaming environment checks" --context "health-check"
  
  # Platform-specific checks
  let platform_results = (run_validations [
    { name: "platform", validator: {|| validate_platform ["linux" "nixos"] } }
  ])
  step 4 4 "Platform compatibility checks" --context "health-check"
  
  # Compile results
  let all_results = [
    { name: "System", results: $system_results },
    { name: "Nix", results: $nix_results },
    { name: "Gaming", results: $gaming_results },
    { name: "Platform", results: $platform_results }
  ]
  
  $all_results
}

# Generate health report
def generate_health_report [results: list<record>] {
  section "Health Check Summary" --context "health-check"
  
  let status_items = ($results | each { |category|
    let passed = $category.results.passed
    let total = $category.results.total
    let success = ($category.results.success)
    
    {
      name: $category.name,
      success: $success,
      message: $"($passed)/($total) checks passed"
    }
  })
  
  status_report $status_items --context "health-check"
  
  # Calculate overall health
  let total_passed = ($results | get results.passed | math sum)
  let total_checks = ($results | get results.total | math sum)
  
  summary "Overall Health" $total_passed $total_checks --context "health-check"
  
  # Return overall status
  { 
    success: ($results | all { |r| $r.results.success }),
    total_passed: $total_passed,
    total_checks: $total_checks
  }
}

# Check specific nix-mox components
def check_nixmox_components [] {
  info "Checking nix-mox specific components..." --context "health-check"
  
  let component_checks = [
    { name: "flake_file", validator: {|| null | validate_file_quiet "flake.nix" } },
    { name: "scripts_dir", validator: {|| null | validate_directory_quiet "scripts" } },
    { name: "consolidated_libs", validator: {|| null | validate_file_quiet "scripts/lib/logging.nu" } },
    { name: "makefile", validator: {|| null | validate_file_quiet "Makefile" } },
    { name: "treefmt_config", validator: {|| null | validate_file_quiet "treefmt.nix" } }
  ]
  
  run_validations $component_checks --context "health-check"
}

# Hardware health and EMI detection checks
def check_hardware_health [] {
  info "Checking hardware health and EMI interference..." --context "health-check"
  
  let hardware_checks = [
    { name: "emi_detection", validator: {|| optional_validator {|| validate_emi_status } } },
    { name: "usb_devices", validator: {|| optional_validator {|| validate_usb_health } } },
    { name: "i2c_communication", validator: {|| optional_validator {|| validate_i2c_health } } }
  ]
  
  run_validations $hardware_checks --context "health-check"
}

# EMI validation function (quiet version for optional use)
def validate_emi_status [] {
  |input|
  try {
    # Run quick EMI check using our detection system
    let emi_cmd_result = (secure_system "nu scripts/testing/hardware/emi-detection.nu 2>/dev/null || echo 'EMI check skipped'" --context "emi-health-check")
    let emi_result = $emi_cmd_result.stdout
    
    if not ($emi_result | str contains "errors detected") {
      validation_result true "No EMI interference detected"
    } else {
      validation_result false "EMI interference detected"
    }
  } catch {
    validation_result false "EMI detection failed"
  }
}

# USB device health validation (quiet version for optional use)
def validate_usb_health [] {
  |input|
  try {
    let usb_errors = (safe_command_with_fallback "journalctl --since '1 hour ago' --no-pager 2>/dev/null | grep -E 'error.*USB|can.*t set config' | wc -l || echo '0'" "0")
    let error_count = ($usb_errors | into int)
    
    if $error_count == 0 {
      validation_result true "No recent USB errors detected"
    } else {
      validation_result false $"USB errors detected: ($error_count)"
    }
  } catch {
    validation_result false "USB health check failed"
  }
}

# I2C communication validation (quiet version for optional use)
def validate_i2c_health [] {
  |input|
  try {
    let i2c_errors = (safe_command_with_fallback "journalctl --since '1 hour ago' --no-pager 2>/dev/null | grep -E 'i2c.*Invalid|0xffff' | wc -l || echo '0'" "0")
    let error_count = ($i2c_errors | into int)
    
    if $error_count == 0 {
      validation_result true "No recent I2C errors detected"
    } else {
      validation_result false $"I2C errors detected: ($error_count)"
    }
  } catch {
    validation_result false "I2C health check failed"
  }
}

# Performance and resource checks  
def check_system_resources [] {
  info "Checking system resources..." --context "health-check"
  
  let resource_checks = [
    { name: "disk_space", validator: {|| null | validate_disk_space 80 } },
    { name: "memory", validator: {|| null | validate_memory 80 } },
    { name: "network", validator: {|| optional_validator {|| validate_network_resilient "8.8.8.8" 2 } } }
  ]
  
  run_validations $resource_checks --context "health-check"
}

# Main health check function
def main [] {
  show_banner
  
  # Run all health checks
  let health_results = (run_health_checks)
  let component_results = (check_nixmox_components)
  let hardware_results = (check_hardware_health)
  let resource_results = (check_system_resources)
  
  # Generate comprehensive report
  let all_categories = $health_results | append [
    { name: "Components", results: $component_results },
    { name: "Hardware", results: $hardware_results },
    { name: "Resources", results: $resource_results }
  ]
  
  let final_report = (generate_health_report $all_categories)
  
  # Exit with appropriate code
  if $final_report.success {
    success "Health check completed successfully" --context "health-check"
    0
  } else {
    error "Health check identified issues" --context "health-check"
    1
  }
}

# Run main function if script is executed directly
if $nu.current-exe? == null {
  main
}