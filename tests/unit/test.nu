# Test module for nix-mox
use std assert

# Test argument parsing
def test_argparse [] {
    print "Testing argument parsing..."
    
    # Test help flag
    let help_output = (nu scripts/nix-mox.nu --help)
    assert ($help_output | str contains "Usage:")
    
    # Test platform detection
    let platform_output = (nu scripts/nix-mox.nu --platform auto --dry-run)
    assert ($platform_output | str contains "Detected platform:")
    
    # Test script execution
    let script_output = (nu scripts/nix-mox.nu --script install --dry-run)
    assert ($script_output | str contains "Would execute")
}

# Test platform detection
def test_platform [] {
    print "Testing platform detection..."
    
    # Test auto platform detection
    let auto_output = (nu scripts/nix-mox.nu --platform auto --dry-run)
    assert ($auto_output | str contains "Detected platform:")
    
    # Test specific platform
    let darwin_output = (nu scripts/nix-mox.nu --platform darwin --dry-run)
    assert ($darwin_output | str contains "Platform: darwin")
}

# Test script handling
def test_scripts [] {
    print "Testing script handling..."
    
    # Test install script
    let install_output = (nu scripts/nix-mox.nu --script install --dry-run)
    assert ($install_output | str contains "Would execute")
    
    # Test update script
    let update_output = (nu scripts/nix-mox.nu --script update --dry-run)
    assert ($update_output | str contains "Would execute")
    
    # Test ZFS snapshot script
    let zfs_output = (nu scripts/nix-mox.nu --script zfs-snapshot --dry-run)
    assert ($zfs_output | str contains "Would execute")
}

# Test logging
def test_logging [] {
    print "Testing logging functionality..."
    
    # Create temporary log file
    let temp_log = (mktemp)
    
    # Test logging to file
    nu scripts/nix-mox.nu --script install --dry-run --log $temp_log
    assert ((open $temp_log | str contains "Would execute"))
    
    # Clean up
    rm $temp_log
}

# Test error handling
def test_errors [] {
    print "Testing error handling..."
    
    # Test invalid platform
    let invalid_platform = (do { nu scripts/nix-mox.nu --platform invalid --dry-run } | complete | get stderr)
    assert ($invalid_platform | str contains "Invalid platform")
    
    # Test invalid script
    let invalid_script = (do { nu scripts/nix-mox.nu --script invalid --dry-run } | complete | get stderr)
    assert ($invalid_script | str contains "Invalid script")
}

# Main test runner
def main [] {
    print "Starting nix-mox tests..."
    
    # Run all tests
    test_argparse
    test_platform
    test_scripts
    test_logging
    test_errors
    
    print "All tests passed!"
}

# Run tests if this file is executed directly
if $env.NU_TEST == "true" {
    main
} 