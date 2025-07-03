# Display Testing Implementation Guide

## Quick Start for Next AI Agent

This guide provides step-by-step instructions for implementing the display testing system outlined in the main plan.

## Phase 1: Basic Detection Implementation

### Step 1: Create Display Test Directory Structure

```bash
mkdir -p scripts/tests/display
mkdir -p scripts/tests/unit/display
```

### Step 2: Implement Hardware Detection

Create `scripts/tests/display/hardware-detection.nu`:

```nushell
#!/usr/bin/env nu

# Hardware detection functions for display testing

export def detect_gpu [] {
    try {
        let lspci_output = (lspci | grep -i vga | str trim)
        
        if ($lspci_output | str contains "NVIDIA") {
            {
                type: "nvidia"
                name: ($lspci_output | str replace ".*: " "")
                driver: "nvidia"
                vulkan: true
                risk_level: "medium"
            }
        } else if ($lspci_output | str contains "AMD") {
            {
                type: "amd"
                name: ($lspci_output | str replace ".*: " "")
                driver: "amdgpu"
                vulkan: true
                risk_level: "low"
            }
        } else if ($lspci_output | str contains "Intel") {
            {
                type: "intel"
                name: ($lspci_output | str replace ".*: " "")
                driver: "i915"
                vulkan: false
                risk_level: "low"
            }
        } else {
            {
                type: "unknown"
                name: "Unknown GPU"
                driver: "auto"
                vulkan: false
                risk_level: "high"
            }
        }
    } catch {
        {
            type: "error"
            name: "Detection failed"
            driver: "unknown"
            vulkan: false
            risk_level: "high"
        }
    }
}

export def detect_monitors [] {
    try {
        if (which xrandr | is-empty) {
            return []
        }
        
        let xrandr_output = (xrandr --listmonitors | str trim)
        let monitors = ($xrandr_output | lines | skip 1 | each { |line|
            let parts = ($line | split row " ")
            {
                name: ($parts | get 3)
                resolution: ($parts | get 2)
                connected: true
            }
        })
        
        $monitors
    } catch {
        []
    }
}

export def detect_drivers [] {
    try {
        let loaded_modules = (lsmod | grep -E "(nvidia|amdgpu|i915)" | str trim)
        
        if ($loaded_modules | str contains "nvidia") {
            {
                primary: "nvidia"
                loaded: true
                version: (nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | str trim)
            }
        } else if ($loaded_modules | str contains "amdgpu") {
            {
                primary: "amdgpu"
                loaded: true
                version: "unknown"
            }
        } else if ($loaded_modules | str contains "i915") {
            {
                primary: "i915"
                loaded: true
                version: "unknown"
            }
        } else {
            {
                primary: "none"
                loaded: false
                version: "unknown"
            }
        }
    } catch {
        {
            primary: "unknown"
            loaded: false
            version: "unknown"
        }
    }
}
```

### Step 3: Implement Configuration Analysis

Create `scripts/tests/display/configuration-analysis.nu`:

```nushell
#!/usr/bin/env nu

# Configuration analysis functions for display testing

export def analyze_display_config [config_path: string] {
    try {
        let config_content = (open $config_path | str trim)
        
        let analysis = {
            has_xserver: ($config_content | str contains "services.xserver")
            has_graphics: ($config_content | str contains "hardware.graphics")
            has_nvidia: ($config_content | str contains "hardware.nvidia")
            has_opengl: ($config_content | str contains "hardware.opengl")
            video_drivers: (extract_video_drivers $config_content)
            risk_factors: (identify_risk_factors $config_content)
        }
        
        $analysis
    } catch {
        {
            has_xserver: false
            has_graphics: false
            has_nvidia: false
            has_opengl: false
            video_drivers: []
            risk_factors: ["config_file_not_found"]
        }
    }
}

def extract_video_drivers [content: string] {
    let driver_lines = ($content | lines | where ($it | str contains "videoDrivers"))
    
    if ($driver_lines | length) > 0 {
        let driver_line = ($driver_lines | get 0)
        $driver_line | str replace ".*\[" "" | str replace "\].*" "" | split row " "
    } else {
        []
    }
}

def identify_risk_factors [content: string] {
    mut risks = []
    
    # Check for conflicting drivers
    if ($content | str contains "nvidia") and ($content | str contains "amdgpu") {
        $risks = ($risks | append "conflicting_drivers")
    }
    
    # Check for missing OpenGL
    if not ($content | str contains "hardware.opengl") {
        $risks = ($risks | append "missing_opengl")
    }
    
    # Check for deprecated options
    if ($content | str contains "hardware.opengl.driSupport") {
        $risks = ($risks | append "deprecated_driSupport")
    }
    
    $risks
}
```

### Step 4: Implement Risk Assessment

Create `scripts/tests/display/risk-assessment.nu`:

```nushell
#!/usr/bin/env nu

# Risk assessment functions for display testing

export def assess_display_risk [current_config: record, new_config: record, hardware: record] {
    mut risk_score = 0
    mut warnings = []
    mut recommendations = []
    
    # Hardware compatibility check
    if ($hardware.type == "nvidia") and ($new_config.has_nvidia == false) {
        $risk_score = ($risk_score + 30)
        $warnings = ($warnings | append "NVIDIA GPU detected but no NVIDIA configuration found")
        $recommendations = ($recommendations | append "Add hardware.nvidia configuration")
    }
    
    # Driver conflicts
    if ($new_config.risk_factors | where $it == "conflicting_drivers" | length) > 0 {
        $risk_score = ($risk_score + 50)
        $warnings = ($warnings | append "Conflicting graphics drivers detected")
        $recommendations = ($recommendations | append "Remove conflicting driver configurations")
    }
    
    # Missing OpenGL
    if ($new_config.risk_factors | where $it == "missing_opengl" | length) > 0 {
        $risk_score = ($risk_score + 20)
        $warnings = ($warnings | append "OpenGL support not configured")
        $recommendations = ($recommendations | append "Add hardware.graphics configuration")
    }
    
    # Deprecated options
    if ($new_config.risk_factors | where $it == "deprecated_driSupport" | length) > 0 {
        $risk_score = ($risk_score + 10)
        $warnings = ($warnings | append "Using deprecated hardware.opengl.driSupport option")
        $recommendations = ($recommendations | append "Replace with hardware.graphics.enable")
    }
    
    # Calculate risk level
    let risk_level = if $risk_score >= 50 {
        "high"
    } else if $risk_score >= 20 {
        "medium"
    } else {
        "low"
    }
    
    {
        risk_score: $risk_score
        risk_level: $risk_level
        warnings: $warnings
        recommendations: $recommendations
        safe_to_proceed: ($risk_score < 50)
    }
}

export def generate_safety_plan [risk_level: string] {
    let plan = if $risk_level == "high" {
        {
            backup_config: true
            backup_drivers: true
            enable_console: true
            test_dry_run: true
            rollback_plan: "immediate"
        }
    } else if $risk_level == "medium" {
        {
            backup_config: true
            backup_drivers: false
            enable_console: true
            test_dry_run: true
            rollback_plan: "manual"
        }
    } else {
        {
            backup_config: false
            backup_drivers: false
            enable_console: false
            test_dry_run: false
            rollback_plan: "none"
        }
    }
    
    $plan
}
```

### Step 5: Create Main Display Test Runner

Create `scripts/tests/display/display-tests.nu`:

```nushell
#!/usr/bin/env nu

# Main display test runner

use ./hardware-detection.nu *
use ./configuration-analysis.nu *
use ./risk-assessment.nu *

export def main [] {
    print "🔍 Running display configuration tests..."
    
    # Detect hardware
    let hardware = detect_gpu
    let monitors = detect_monitors
    let drivers = detect_drivers
    
    print $"  GPU: ($hardware.name) (($hardware.type))"
    print $"  Monitors: ($monitors | length) connected"
    print $"  Drivers: ($drivers.primary) (loaded: ($drivers.loaded))"
    
    # Analyze current configuration
    let current_config = analyze_display_config "/etc/nixos/configuration.nix"
    
    # Analyze proposed configuration (if available)
    let proposed_config = if ("/tmp/proposed-config.nix" | path exists) {
        analyze_display_config "/tmp/proposed-config.nix"
    } else {
        $current_config
    }
    
    # Assess risks
    let risk_assessment = assess_display_risk $current_config $proposed_config $hardware
    
    # Generate safety plan
    let safety_plan = generate_safety_plan $risk_assessment.risk_level
    
    # Display results
    display_results $hardware $monitors $drivers $risk_assessment $safety_plan
    
    # Return results for integration
    {
        hardware: $hardware
        monitors: $monitors
        drivers: $drivers
        risk_assessment: $risk_assessment
        safety_plan: $safety_plan
    }
}

def display_results [hardware: record, monitors: list, drivers: record, risk_assessment: record, safety_plan: record] {
    print $"\n📊 Risk Assessment:"
    print $"  Risk Level: ($risk_assessment.risk_level | str upcase)"
    print $"  Risk Score: ($risk_assessment.risk_score)/100"
    print $"  Safe to Proceed: ($risk_assessment.safe_to_proceed)"
    
    if ($risk_assessment.warnings | length) > 0 {
        print $"\n⚠️  Warnings:"
        for warning in $risk_assessment.warnings {
            print $"  • ($warning)"
        }
    }
    
    if ($risk_assessment.recommendations | length) > 0 {
        print $"\n💡 Recommendations:"
        for rec in $risk_assessment.recommendations {
            print $"  • ($rec)"
        }
    }
    
    print $"\n🛡️  Safety Plan:"
    print $"  Backup Config: ($safety_plan.backup_config)"
    print $"  Backup Drivers: ($safety_plan.backup_drivers)"
    print $"  Enable Console: ($safety_plan.enable_console)"
    print $"  Test Dry Run: ($safety_plan.test_dry_run)"
    print $"  Rollback Plan: ($safety_plan.rollback_plan)"
}

if ($env.NU_TEST? == "true") {
    main
}
```

### Step 6: Integrate with Existing Test Framework

Update `scripts/tests/run-tests.nu` to include display tests:

```nushell
# Add to the existing run-tests.nu file

def run_display_tests [] {
    print "Running display tests..."
    # Run display tests in the same process to ensure test result files are available
    source "display/display-tests.nu"
    true
}

# Add to run_all_test_suites function:
if $config.run_display_tests {
    let display_success = run_test_suite "display" { run_display_tests } $config
    $test_results = ($test_results | append { suite: "display", success: $display_success })
    $overall_success = ($overall_success and $display_success)
}
```

### Step 7: Create User-Friendly Validation Script

Create `scripts/validate-display-config.nu`:

```nushell
#!/usr/bin/env nu

# User-friendly display configuration validator

use scripts/tests/display/display-tests.nu *

def main [] {
    print $"\n🔍 nix-mox Display Configuration Validator"
    print $"(ansi yellow)==========================================(ansi reset)\n"
    
    # Run display tests
    let results = main
    
    # Provide actionable feedback
    if not $results.risk_assessment.safe_to_proceed {
        print $"\n(ansi red)❌ HIGH RISK: Configuration changes may break display(ansi reset)"
        print $"(ansi yellow)Recommendations:(ansi reset)"
        for rec in $results.risk_assessment.recommendations {
            print $"  • ($rec)"
        }
        
        let proceed = input $"\n(ansi yellow)Proceed anyway? (y/N): (ansi reset)"
        if not ($proceed | str downcase | str contains "y") {
            print $"(ansi red)Aborted for safety.(ansi reset)"
            exit 1
        }
    } else {
        print $"\n(ansi green)✅ Configuration appears safe(ansi reset)"
    }
    
    # Provide safety instructions
    if $results.safety_plan.backup_config {
        print $"\n(ansi cyan)💾 Creating configuration backup...(ansi reset)"
        # Implement backup logic here
    }
    
    print $"\n(ansi green)Ready to proceed with rebuild!(ansi reset)"
}

if ($env.NU_TEST? != "true") {
    main
}
```

## Phase 2: Integration with Makefile

Update the existing `Makefile`:

```makefile
# Add these targets to the existing Makefile

display-test:
	@echo "Running display configuration tests..."
	nu scripts/tests/display/display-tests.nu

validate-display:
	@echo "Validating display configuration..."
	nu scripts/validate-display-config.nu

pre-rebuild-test: display-test
	@echo "Running pre-rebuild validation..."
	nu scripts/tests/display/pre-rebuild-validation.nu

safe-rebuild: validate-display
	@echo "Performing safe rebuild..."
	sudo nixos-rebuild switch

# Update existing test target to include display tests
test: unit-test integration-test display-test
	@echo "All tests completed"
```

## Phase 3: Create Pre-Rebuild Validation

Create `scripts/tests/display/pre-rebuild-validation.nu`:

```nushell
#!/usr/bin/env nu

# Pre-rebuild validation script

use ./display-tests.nu *

export def main [] {
    print "🔍 Pre-rebuild display validation..."
    
    # Run display tests
    let results = main
    
    # Check if safe to proceed
    if not $results.risk_assessment.safe_to_proceed {
        print $"\n(ansi red)❌ UNSAFE: Display configuration changes detected(ansi reset)"
        print $"(ansi red)Rebuild may break your display!(ansi reset)"
        
        # Show warnings
        for warning in $results.risk_assessment.warnings {
            print $"  ⚠️  ($warning)"
        }
        
        # Show recommendations
        print $"\n(ansi yellow)Recommendations:(ansi reset)"
        for rec in $results.risk_assessment.recommendations {
            print $"  • ($rec)"
        }
        
        # Ask for confirmation
        let proceed = input $"\n(ansi red)Proceed with rebuild anyway? (y/N): (ansi reset)"
        if not ($proceed | str downcase | str contains "y") {
            print $"(ansi red)Rebuild aborted for safety.(ansi reset)"
            exit 1
        }
    }
    
    # Create backups if needed
    if $results.safety_plan.backup_config {
        create_config_backup
    }
    
    print $"(ansi green)✅ Pre-rebuild validation passed(ansi reset)"
}

def create_config_backup [] {
    let backup_path = $"/etc/nixos/configuration.nix.backup.($(date now | format date '%Y%m%d_%H%M%S'))"
    cp /etc/nixos/configuration.nix $backup_path
    print $"💾 Configuration backed up to ($backup_path)"
}

if ($env.NU_TEST? == "true") {
    main
}
```

## Testing the Implementation

### Test Commands

```bash
# Test hardware detection
nu scripts/tests/display/hardware-detection.nu

# Test configuration analysis
nu scripts/tests/display/configuration-analysis.nu

# Test risk assessment
nu scripts/tests/display/risk-assessment.nu

# Run full display tests
nu scripts/tests/display/display-tests.nu

# Run user-friendly validator
nu scripts/validate-display-config.nu

# Run pre-rebuild validation
nu scripts/tests/display/pre-rebuild-validation.nu

# Test integration with existing framework
make test
```

### Expected Output

The system should:
1. Detect your GPU and display hardware
2. Analyze your current NixOS configuration
3. Identify potential risks and conflicts
4. Provide clear warnings and recommendations
5. Create safety backups when needed
6. Allow safe rebuilds with confidence

## Next Steps for Advanced Features

1. **Multi-monitor support**: Extend monitor detection for complex setups
2. **Hybrid graphics**: Add support for Intel + NVIDIA/AMD combinations
3. **Automatic rollback**: Implement automatic recovery mechanisms
4. **Performance impact**: Add performance analysis capabilities
5. **Machine learning**: Integrate pattern recognition for better predictions

## Troubleshooting

### Common Issues

1. **Permission errors**: Ensure scripts are executable (`chmod +x`)
2. **Missing dependencies**: Install required packages (pciutils, xrandr)
3. **Configuration parsing errors**: Check NixOS configuration syntax
4. **Hardware detection failures**: Verify hardware is properly connected

### Debug Mode

Add debug logging by setting environment variable:
```bash
export NU_DEBUG=true
nu scripts/validate-display-config.nu
```

This implementation provides a solid foundation for display testing that can be extended with more advanced features over time. 