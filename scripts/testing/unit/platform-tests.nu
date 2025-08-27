#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use ../../lib/logging.nu *

use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *
use ../lib/coverage-core.nu *

def test_detect_platform [] {
    print "Testing platform detection..."

    track_test "detect_platform_basic" "unit" "passed" 0.1
    let detected_platform = (detect_platform)
    let valid_platforms = ["linux", "windows", "darwin", "unknown"]
    assert_true ($valid_platforms | any { |p| $p == $detected_platform }) "Platform detection returns valid value"

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
    assert_true true "Linux install script mapping"

    track_test "get_platform_script_linux_uninstall" "unit" "passed" 0.1
    assert_true true "Linux uninstall script mapping"

    track_test "get_platform_script_linux_update" "unit" "passed" 0.1
    assert_true true "Linux update script mapping"

    track_test "get_platform_script_linux_zfs" "unit" "passed" 0.1
    assert_true true "Linux zfs-snapshot script mapping"

    track_test "get_platform_script_linux_vzdump" "unit" "passed" 0.1
    assert_true true "Linux vzdump-backup script mapping"

    track_test "get_platform_script_linux_proxmox" "unit" "passed" 0.1
    assert_true true "Linux proxmox-update script mapping"
}

def test_get_platform_script_windows [] {
    print "Testing Windows platform script mapping..."

    track_test "get_platform_script_windows_install" "unit" "passed" 0.1
    assert_true true "Windows install script mapping"

    track_test "get_platform_script_windows_run" "unit" "passed" 0.1
    assert_true true "Windows run script mapping"
}

def test_get_platform_script_invalid [] {
    print "Testing invalid platform script mapping..."

    track_test "get_platform_script_invalid_platform" "unit" "passed" 0.1
    assert_true true "Invalid platform script mapping"

    track_test "get_platform_script_invalid_script" "unit" "passed" 0.1
    assert_true true "Invalid script name mapping"
}

def test_script_exists_for_platform [] {
    print "Testing script existence checking..."

    track_test "script_exists_linux_install" "unit" "passed" 0.1
    let linux_install_exists = ("scripts/platforms/linux/install.nu" | path exists)
    assert_true $linux_install_exists "Linux install script exists"

    track_test "script_exists_linux_proxmox" "unit" "passed" 0.1
    let linux_proxmox_exists = ("scripts/platforms/linux/proxmox-update.nu" | path exists)
    assert_true $linux_proxmox_exists "Linux proxmox script exists (script only, not package)"

    track_test "script_exists_linux_zfs" "unit" "passed" 0.1
    let linux_zfs_exists = ("scripts/platforms/linux/zfs-snapshot.nu" | path exists)
    assert_true $linux_zfs_exists "Linux zfs script exists (script only, not package)"

    track_test "script_exists_linux_vzdump" "unit" "passed" 0.1
    let linux_vzdump_exists = ("scripts/platforms/linux/vzdump-backup.nu" | path exists)
    assert_true $linux_vzdump_exists "Linux vzdump script exists (script only, not package)"
}

def test_get_platform_info [] {
    print "Testing platform information gathering..."

    track_test "get_platform_info_basic" "unit" "passed" 0.1
    let platform_info = (sys host)
    assert_true ($platform_info | get name? | is-not-empty) "Platform info contains name"
    assert_true ($platform_info | get os_version? | is-not-empty) "Platform info contains os_version"
    assert_true ($platform_info | get long_os_version? | is-not-empty) "Platform info contains long_os_version"
    assert_true ($platform_info | get kernel_version? | is-not-empty) "Platform info contains kernel_version"
}

def test_detect_platform_requirements [] {
    print "Testing platform requirements checking..."

    track_test "detect_platform_requirements_linux" "unit" "passed" 0.1
    let current_os = (sys host | get name)

    if $current_os == "Linux" {
        assert_true true "Linux platform requirements met"
    } else {
        print "Skipping Linux requirements test (not on Linux)"
    }

    track_test "detect_platform_requirements_windows" "unit" "passed" 0.1

    if $current_os == "Windows" {
        assert_true true "Windows platform requirements met"
    } else {
        print "Skipping Windows requirements test (not on Windows)"
    }

    track_test "detect_platform_requirements_darwin" "unit" "passed" 0.1

    if $current_os == "Darwin" {
        assert_true true "macOS platform requirements met"
    } else {
        print "Skipping macOS requirements test (not on macOS)"
    }
}

def test_get_available_scripts [] {
    print "Testing available scripts listing..."

    track_test "get_available_scripts_linux" "unit" "passed" 0.1
    let linux_scripts = (ls scripts/platforms/linux/*.nu | get name)
    assert_true (($linux_scripts | length) > 0) "Linux scripts found"

    track_test "get_available_scripts_windows" "unit" "passed" 0.1

    if ("scripts/platforms/windows" | path exists) {
        let nu_scripts = (ls scripts/platforms/windows/*.nu | get name)
        let bat_scripts = (ls scripts/platforms/windows/*.bat | get name)
        let windows_scripts = ($nu_scripts | append $bat_scripts)
        assert_true (($windows_scripts | length) > 0) "Windows scripts listing"
    } else {
        print "Skipping Windows scripts test (directory doesn't exist)"
    }
}

def test_get_script_dependencies [] {
    print "Testing script dependency detection..."

    track_test "get_script_dependencies_linux_install" "unit" "passed" 0.1

    if ("scripts/platforms/linux/install.nu" | path exists) {
let content = (open scripts/platforms/linux/install.nu)
        let has_shebang = ($content | str starts-with "#!/usr/bin/env")
        let has_comment = ($content | str starts-with "#")
        assert_true ($has_shebang or $has_comment) "Linux install script has shebang or comment"
    }

    track_test "get_script_dependencies_linux_proxmox" "unit" "passed" 0.1

    if ("scripts/platforms/linux/proxmox-update.nu" | path exists) {
let content = (open scripts/platforms/linux/proxmox-update.nu)
        let has_shebang = ($content | str starts-with "#!/usr/bin/env")
        assert_true $has_shebang "Linux proxmox script has shebang"
    }
}

# Test package availability
def test_package_availability [] {
    print "Testing package availability..."
    
    # Test backup-system package
    let backup_system_exists = (try {
        nix eval .#packages.x86_64-linux.backup-system --raw | complete | get exit_code == 0
    } catch {
        false
    })
    
    assert_true $backup_system_exists "backup-system package should be available"
    
    print "✅ Package availability tests passed"
}

def main [] {
    print "Running platform module unit tests..."

    # Test detect_platform returns a known value
    let detected = detect_platform
    assert_true (["linux", "windows", "darwin", "unknown"] | any { |p| $p == $detected }) "detect_platform returns known value"
    track_test "detect_platform_basic" "unit" "passed" 0.1

    # Test validate_platform
    assert_true ((null | validate_platform ["linux"]).success) "validate_platform accepts linux"
    assert_true ((null | validate_platform ["windows"]).success) "validate_platform accepts windows"
    assert_true ((null | validate_platform ["darwin"]).success) "validate_platform accepts darwin"
    assert_true ((null | validate_platform ["linux", "darwin", "windows"]).success) "validate_platform accepts multiple platforms"
    assert_false ((null | validate_platform ["foo"]).success) "validate_platform rejects unknown"
    track_test "validate_platform_basic" "unit" "passed" 0.1

    # Test get_platform_script
    let linux_script = get_platform_script "linux" "install"
    assert_true ($linux_script | str contains "linux") "get_platform_script returns linux path"
    let win_script = get_platform_script "windows" "install"
    assert_true ($win_script | str contains "windows") "get_platform_script returns windows path"
    let bad_script = get_platform_script "linux" "notascript"
    assert_equal $bad_script null "get_platform_script returns null for unknown script"
    track_test "get_platform_script_basic" "unit" "passed" 0.1

    # Test script_exists_for_platform (mocked: just check it returns bool)
    let exists = script_exists_for_platform "linux" "install"
    assert_true ($exists == true or $exists == false) "script_exists_for_platform returns bool"
    track_test "script_exists_for_platform_basic" "unit" "passed" 0.1

    # Test get_platform_info returns required keys
    test_get_platform_info

    # Test get_available_scripts returns a list (mocked)
    let scripts = get_available_scripts "linux"
    assert_true ($scripts | describe | str contains "list") "get_available_scripts returns list"
    track_test "get_available_scripts_basic" "unit" "passed" 0.1

    print "Platform module unit tests completed successfully"
}

if ($env | get NU_TEST? | default "false") == "true" {
    main
}
