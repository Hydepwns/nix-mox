#!/usr/bin/env nu

# EMI Detection and Hardware Interference Testing for nix-mox
# Detects USB/I2C errors, EMI issues, and hardware interference patterns

use ../../lib/logging.nu *
use ../../lib/validators.nu *
use ../../lib/command-wrapper.nu *
use ../../lib/secure-command.nu *

def show_banner [] {
    banner "EMI Detection System" "Hardware interference and USB/I2C error monitoring" --context "emi-detection"
}

# USB Error Detection
export def detect_usb_errors [] {
    info "Scanning for USB configuration errors..." --context "emi-detection"
    
    let usb_errors = try {
        safe_command_with_fallback "journalctl --since '1 hour ago' --no-pager | grep -E '(can\\'t set config| error \\-71| Invalid.*I2C| disabled by hub| EMI)'" ""
        | lines
        | where $it != ""
        | each { | line|
            {
                timestamp: ($line | str substring 0..15),
                message: $line,
                error_type: (classify_error $line),
                severity: (assess_severity $line)
            }
        }
    } catch {
        []
    }
    
    $usb_errors
}

# I2C Error Detection
export def detect_i2c_errors [] {
    info "Scanning for I2C communication errors..." --context "emi-detection"
    
    let i2c_errors = try {
        safe_command_with_fallback "journalctl --since '1 hour ago' --no-pager | grep -E '(i2c.*Invalid|0xffff| I2C.*error)'" ""
        | lines
        | where $it != ""
        | each { | line|
            {
                timestamp: ($line | str substring 0..15),
                message: $line,
                bus: (extract_i2c_bus $line),
                address: (extract_i2c_address $line),
                severity: "high"
            }
        }
    } catch {
        []
    }
    
    $i2c_errors
}

# USB Device Health Check
export def check_usb_device_health [] {
    info "Checking USB device health status..." --context "emi-detection"
    
    let usb_devices = try {
        glob "/sys/devices/pci*/*/usb*/*/product"
        | each { | product_file|
            let device_path = ($product_file | path dirname)
            try {
                let product = (open $product_file | str trim)
                let vendor_file = ($device_path | path join "idVendor")
                let product_id_file = ($device_path | path join "idProduct")
                let config_file = ($device_path | path join "bConfigurationValue")
                let authorized_file = ($device_path | path join "authorized")
                
                {
                    path: $device_path,
                    product: $product,
                    vendor: (if ($vendor_file | path exists) { open $vendor_file | str trim } else { "unknown" }),
                    product_id: (if ($product_id_file | path exists) { open $product_id_file | str trim } else { "unknown" }),
                    configured: (if ($config_file | path exists) { (open $config_file | str trim) != "0" } else { false }),
                    authorized: (if ($authorized_file | path exists) { (open $authorized_file | str trim) == "1" } else { false }),
                    port: ($device_path | path basename),
                    health_status: "unknown"
                }
            } catch {
                null
            }
        }
        | where $it != null
        | each { | device|
            $device | upsert health_status (assess_device_health $device)
        }
    } catch {
        []
    }
    
    $usb_devices
}

# EMI Pattern Detection
export def detect_emi_patterns [--duration: duration = 5min] {
    info $"Monitoring for EMI patterns over ($duration)..." --context "emi-detection"
    
    let start_time = (date now)
    let end_time = ($start_time | date format "%Y-%m-%d %H:%M:%S")
    
    # Monitor journalctl for EMI-related patterns
    let monitoring_result = try {
        let result = (secure_system $"timeout ($duration | into string) journalctl -f --no-pager | grep -E '(EMI| interference| disabled by hub| error \\-71|0xffff)' | head -20" --context "emi-monitor")
        $result.stdout
        | lines
        | where $it != ""
        | each { | line|
            {
                detected_at: (date now | date format "%Y-%m-%d %H:%M:%S"),
                pattern: $line,
                confidence: (calculate_emi_confidence $line)
            }
        }
    } catch {
        []
    }
    
    {
        monitoring_duration: $duration,
        patterns_detected: ($monitoring_result | length),
        patterns: $monitoring_result,
        emi_likelihood: (if ($monitoring_result | length) > 0 { "high" } else { "low" })
    }
}

# Hardware Stress Test for EMI Detection
export def run_emi_stress_test [] {
    info "Running hardware stress test to detect EMI sensitivity..." --context "emi-detection"
    
    let baseline_errors = (detect_usb_errors)
    info $"Baseline errors: (($baseline_errors | length))" --context "emi-detection"
    
    # Simulate activity that might trigger EMI issues
    info "Simulating hardware activity..." --context "emi-detection"
    try {
        # USB activity simulation
        let result = (secure_system "find /sys/bus/usb/devices -name authorized -exec cat {} \\; >/dev/null 2>&1" --context "usb-auth-check")
        $result.stdout 
        sleep 2sec
        
        # I2C bus scanning (if available)
        let i2c_result = (secure_system "find /sys/class/i2c-dev -type l 2>/dev/null | head -5" --context "i2c-scan")
        $i2c_result.stdout 
        sleep 2sec
    } catch { | err|
        warn $"Stress test partially failed: ($err)" --context "emi-detection"
    }
    
    let post_stress_errors = (detect_usb_errors)
    info $"Post-stress errors: (($post_stress_errors | length))" --context "emi-detection"
    
    {
        baseline_errors: ($baseline_errors | length),
        post_stress_errors: ($post_stress_errors | length),
        error_increase: (($post_stress_errors | length) - ($baseline_errors | length)),
        emi_sensitive: (($post_stress_errors | length) > ($baseline_errors | length))
    }
}

# Generate EMI Detection Report
export def generate_emi_report [] {
    info "Generating comprehensive EMI detection report..." --context "emi-detection"
    
    let usb_errors = (detect_usb_errors)
    let i2c_errors = (detect_i2c_errors) 
    let usb_health = (check_usb_device_health)
    let stress_test = (run_emi_stress_test)
    
    let report = {
        timestamp: (date now | date format "%Y-%m-%d %H:%M:%S"),
        usb_errors: {
            count: ($usb_errors | length),
            details: $usb_errors
        },
        i2c_errors: {
            count: ($i2c_errors | length), 
            details: $i2c_errors
        },
        usb_devices: {
            total: ($usb_health | length),
            healthy: ($usb_health | where health_status == "healthy" | length),
            issues: ($usb_health | where health_status != "healthy" | length),
            details: $usb_health
        },
        stress_test: $stress_test,
        overall_assessment: (assess_emi_risk $usb_errors $i2c_errors $usb_health $stress_test)
    }
    
    $report
}

# Helper Functions
def classify_error [line: string] {
    if ($line | str contains "can't set config") {
        "usb_config_error"
    } else if ($line | str contains "error -71") {
        "protocol_error" 
    } else if ($line | str contains "Invalid.*I2C") {
        "i2c_address_error"
    } else if ($line | str contains "EMI") {
        "emi_detected"
    } else {
        "unknown"
    }
}

def assess_severity [line: string] {
    if ($line | str contains "EMI") {
        "critical"
    } else if ($line | str contains "error -71") {
        "high"
    } else if ($line | str contains "0xffff") {
        "high"
    } else {
        "medium"
    }
}

def extract_i2c_bus [line: string] {
    try {
        $line | parse "i2c-{bus}" | get bus.0
    } catch {
        "unknown"
    }
}

def extract_i2c_address [line: string] {
    try {
        $line | parse "{address}" | get address.0 | str replace "0x" ""
    } catch {
        "unknown" 
    }
}

def assess_device_health [device: record] {
    if ($device.configured and $device.authorized) {
        "healthy"
    } else if (not $device.authorized) {
        "unauthorized"
    } else if (not $device.configured) {
        "configuration_failed"
    } else {
        "unknown"
    }
}

def calculate_emi_confidence [line: string] {
    let confidence_score = 0
    let confidence_score = (if ($line | str contains "EMI") { $confidence_score + 40 } else { $confidence_score })
    let confidence_score = (if ($line | str contains "disabled by hub") { $confidence_score + 30 } else { $confidence_score })
    let confidence_score = (if ($line | str contains "error -71") { $confidence_score + 25 } else { $confidence_score })
    let confidence_score = (if ($line | str contains "0xffff") { $confidence_score + 20 } else { $confidence_score })
    
    if $confidence_score >= 70 {
        "high"
    } else if $confidence_score >= 40 {
        "medium" 
    } else {
        "low"
    }
}

def assess_emi_risk [usb_errors: list, i2c_errors: list, usb_health: list, stress_test: record] {
    let risk_score = 0
    let risk_score = ($risk_score + ($usb_errors | length) * 10)
    let risk_score = ($risk_score + ($i2c_errors | length) * 15)
    let risk_score = ($risk_score + ($usb_health | where health_status != "healthy" | length) * 5)
    let risk_score = (if $stress_test.emi_sensitive { $risk_score + 25 } else { $risk_score })
    
    if $risk_score >= 50 {
        "high"
    } else if $risk_score >= 25 {
        "medium"
    } else {
        "low"
    }
}

# Main function
def main [
    --report (-r),                    # Generate full report
    --monitor (-m),                   # Monitor for EMI patterns
    --stress-test (-s),               # Run stress test
    --watch (-w)                      # Watch mode
] {
    show_banner
    
    if $report {
        let report = (generate_emi_report)
        print ($report | to yaml)
    } else if $monitor {
        detect_emi_patterns --duration 5min
    } else if $stress_test {
        run_emi_stress_test
    } else if $watch {
        while true {
            clear
            show_banner
            let quick_report = {
                usb_errors: (detect_usb_errors | length),
                i2c_errors: (detect_i2c_errors | length),  
                usb_devices: (check_usb_device_health | length)
            }
            print ($quick_report | to yaml)
            sleep 10sec
        }
    } else {
        # Quick status check
        info "Running quick EMI detection check..." --context "emi-detection"
        let usb_errors = (detect_usb_errors)
        let i2c_errors = (detect_i2c_errors)
        
        if (($usb_errors | length) == 0 and ($i2c_errors | length) == 0) {
            success "No EMI-related errors detected" --context "emi-detection"
        } else {
            warn $"Detected ($usb_errors | length) USB errors and ($i2c_errors | length) I2C errors" --context "emi-detection"
        }
    }
}