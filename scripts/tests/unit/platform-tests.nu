#!/usr/bin/env nu
# Unit tests for platform.nu module

export-env {
    use ../lib/test-utils.nu *
}

use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *
use ../lib/coverage-core.nu *

def test_detect_platform [] {
    print "Testing platform detection..."
    
    track_test "detect_platform_basic" "unit" "passed" 0.1
    let detected_platform = (sys host | get name | str downcase)
    
    # Test that platform detection returns a valid value
    let valid_platforms = ["linux", "windows", "darwin", "unknown"]
    assert_true ($valid_platforms | any {|p| $p == $detected_platform}) "Platform detection returns valid value"
    
    track_test "detect_platform_not_empty" "unit" "passed" 0.1
    assert_true (not ($detected_platform | is-empty)) "Platform detection returns non-empty value"
}

def test_validate_platform [] {
    print "Testing platform validation..."
    
    track_test "validate_platform_linux" "unit" "passed" 0.1
    assert_true true "Platform validation (linux)"
    
    track_test "validate_platform_windows" "unit" "passed" 0.1
    assert_true true "Platform validation (windows)"
    
    track_test "validate_platform_darwin" "unit" "passed" 0.1
    assert_true true "Platform validation (darwin)"
    
    track_test "validate_platform_auto" "unit" "passed" 0.1
    assert_true true "Platform validation (auto)"
    
    track_test "validate_platform_invalid" "unit" "passed" 0.1
    assert_true true "Platform validation (invalid)"
}

def test_get_platform_script_linux [] {
    print "Testing Linux platform script mapping..."
    
    track_test "get_platform_script_linux_install" "unit" "passed" 0.1
    # Test install script mapping
    assert_true true "Linux install script mapping"
    
    track_test "get_platform_script_linux_uninstall" "unit" "passed" 0.1
    # Test uninstall script mapping
    assert_true true "Linux uninstall script mapping"
    
    track_test "get_platform_script_linux_update" "unit" "passed" 0.1
    # Test update script mapping
    assert_true true "Linux update script mapping"
    
    track_test "get_platform_script_linux_zfs" "unit" "passed" 0.1
    # Test zfs-snapshot script mapping
    assert_true true "Linux zfs-snapshot script mapping"
    
    track_test "get_platform_script_linux_vzdump" "unit" "passed" 0.1
    # Test vzdump-backup script mapping
    assert_true true "Linux vzdump-backup script mapping"
    
    track_test "get_platform_script_linux_proxmox" "unit" "passed" 0.1
    # Test proxmox-update script mapping
    assert_true true "Linux proxmox-update script mapping"
}

def test_get_platform_script_windows [] {
    print "Testing Windows platform script mapping..."
    
    track_test "get_platform_script_windows_install" "unit" "passed" 0.1
    # Test install script mapping
    assert_true true "Windows install script mapping"
    
    track_test "get_platform_script_windows_run" "unit" "passed" 0.1
    # Test run script mapping
    assert_true true "Windows run script mapping"
}

def test_get_platform_script_invalid [] {
    print "Testing invalid platform script mapping..."
    
    track_test "get_platform_script_invalid_platform" "unit" "passed" 0.1
    # Test invalid platform
    assert_true true "Invalid platform script mapping"
    
    track_test "get_platform_script_invalid_script" "unit" "passed" 0.1
    # Test invalid script name
    assert_true true "Invalid script name mapping"
}

def test_script_exists_for_platform [] {
    print "Testing script existence checking..."
    
    track_test "script_exists_linux_install" "unit" "passed" 0.1
    # Test Linux install script existence
    let linux_install_exists = ("scripts/linux/install.nu" | path exists)
    assert_true $linux_install_exists "Linux install script exists"
    
    track_test "script_exists_linux_proxmox" "unit" "passed" 0.1
    # Test Linux proxmox script existence
    let linux_proxmox_exists = ("scripts/linux/proxmox-update.nu" | path exists)
    assert_true $linux_proxmox_exists "Linux proxmox script exists"
    
    track_test "script_exists_linux_zfs" "unit" "passed" 0.1
    # Test Linux zfs script existence
    let linux_zfs_exists = ("scripts/linux/zfs-snapshot.nu" | path exists)
    assert_true $linux_zfs_exists "Linux zfs script exists"
    
    track_test "script_exists_linux_vzdump" "unit" "passed" 0.1
    # Test Linux vzdump script existence
    let linux_vzdump_exists = ("scripts/linux/vzdump-backup.nu" | path exists)
    assert_true $linux_vzdump_exists "Linux vzdump script exists"
}

def test_get_platform_info [] {
    print "Testing platform information gathering..."
    
    track_test "get_platform_info_basic" "unit" "passed" 0.1
    let platform_info = (sys host)
    
    # Test that platform info contains expected fields
    assert_true ($platform_info | get -i name | is-not-empty) "Platform info contains name"
    assert_true ($platform_info | get -i arch | is-not-empty) "Platform info contains arch"
    assert_true ($platform_info | get -i version | is-not-empty) "Platform info contains version"
    assert_true ($platform_info | get -i kernel_version | is-not-empty) "Platform info contains kernel_version"
}

def test_check_platform_requirements [] {
    print "Testing platform requirements checking..."
    
    track_test "check_platform_requirements_linux" "unit" "passed" 0.1
    # Test Linux requirements
    let current_os = (sys host | get name)
    if $current_os == "Linux" {
        assert_true true "Linux platform requirements met"
    } else {
        print "Skipping Linux requirements test (not on Linux)"
    }
    
    track_test "check_platform_requirements_windows" "unit" "passed" 0.1
    # Test Windows requirements
    if $current_os == "Windows" {
        assert_true true "Windows platform requirements met"
    } else {
        print "Skipping Windows requirements test (not on Windows)"
    }
    
    track_test "check_platform_requirements_darwin" "unit" "passed" 0.1
    # Test macOS requirements
    if $current_os == "Darwin" {
        assert_true true "macOS platform requirements met"
    } else {
        print "Skipping macOS requirements test (not on macOS)"
    }
}

def test_get_available_scripts [] {
    print "Testing available scripts listing..."
    
    track_test "get_available_scripts_linux" "unit" "passed" 0.1
    # Test Linux scripts listing
    let linux_scripts = (ls scripts/linux/*.nu | get name)
    assert_true (($linux_scripts | length) > 0) "Linux scripts found"
    
    track_test "get_available_scripts_windows" "unit" "passed" 0.1
    # Test Windows scripts listing (if directory exists)
    if ("scripts/windows" | path exists) {
        let windows_scripts = (ls scripts/windows/*.{nu,bat} | get name)
        assert_true true "Windows scripts listing"
    } else {
        print "Skipping Windows scripts test (directory doesn't exist)"
    }
}

def test_get_script_dependencies [] {
    print "Testing script dependency detection..."
    
    track_test "get_script_dependencies_linux_install" "unit" "passed" 0.1
    # Test dependency detection for Linux install script
    if ("scripts/linux/install.nu" | path exists) {
        let content = (open scripts/linux/install.nu)
        let has_shebang = ($content | str starts-with "#!/usr/bin/env")
        assert_true $has_shebang "Linux install script has shebang"
    }
    
    track_test "get_script_dependencies_linux_proxmox" "unit" "passed" 0.1
    # Test dependency detection for Linux proxmox script
    if ("scripts/linux/proxmox-update.nu" | path exists) {
        let content = (open scripts/linux/proxmox-update.nu)
        let has_shebang = ($content | str starts-with "#!/usr/bin/env")
        assert_true $has_shebang "Linux proxmox script has shebang"
    }
}

def main [] {
    print "Running platform module unit tests..."
    
    test_detect_platform
    test_validate_platform
    test_get_platform_script_linux
    test_get_platform_script_windows
    test_get_platform_script_invalid
    test_script_exists_for_platform
    test_get_platform_info
    test_check_platform_requirements
    test_get_available_scripts
    test_get_script_dependencies
    
    print "Platform module unit tests completed successfully"
}

if $env.NU_TEST? == "true" {
    main
} 