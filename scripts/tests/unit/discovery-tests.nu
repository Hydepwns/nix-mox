#!/usr/bin/env nu

# Discovery module tests
# Tests for scripts/lib/discovery.nu

use ../../lib/discovery.nu *
use ../lib/test-utils.nu *

def main [] {
    print "Running discovery module tests..."
    
    # Set up test environment
    setup_test_env
    
    # Test script discovery
    test_script_discovery
    
    # Test metadata extraction
    test_metadata_extraction
    
    # Test script filtering
    test_script_filtering
    
    # Test script validation
    test_script_validation
    
    # Test script search
    test_script_search
    
    print "Discovery module tests completed"
}

def test_script_discovery [] {
    print "Testing script discovery..."
    
    try {
        let scripts = discover_scripts "scripts"
        assert_true (($scripts | length) > 0) "Should discover scripts"
        assert_true ($scripts | all {|s| $s.path != null}) "All scripts should have paths"
        assert_true ($scripts | all {|s| $s.name != null}) "All scripts should have names"
        track_test "script_discovery_basic" "unit" "passed" 0.2
    } catch {
        track_test "script_discovery_basic" "unit" "failed" 0.2
    }
}

def test_metadata_extraction [] {
    print "Testing metadata extraction..."
    
    # Create a test script with metadata
    let test_script = "/tmp/nix-mox-test-discovery-script.nu"
    "#!/usr/bin/env nu
# Description: Test script for discovery
# Platform: linux
# Requires-Root: true
# Dependencies: git, curl

print 'Test script'" | save $test_script
    
    try {
        let metadata = extract_script_metadata $test_script
        assert_equal $metadata.description "Test script for discovery" "Should extract description"
        assert_equal $metadata.platform "linux" "Should extract platform"
        assert_equal $metadata.requires_root true "Should extract root requirement"
        assert_true ($metadata.dependencies | any {|d| $d == "git"}) "Should extract dependencies"
        track_test "metadata_extraction_complete" "unit" "passed" 0.2
    } catch {
        track_test "metadata_extraction_complete" "unit" "failed" 0.2
    }
    
    # Clean up
    rm -f $test_script
}

def test_script_filtering [] {
    print "Testing script filtering..."
    
    let test_scripts = [
        {name: "linux-script", platform: "linux", category: "core", requires_root: true},
        {name: "windows-script", platform: "windows", category: "tools", requires_root: false},
        {name: "darwin-script", platform: "darwin", category: "core", requires_root: false}
    ]
    
    # Test platform filtering
    let linux_scripts = get_scripts_by_platform $test_scripts "linux"
    assert_equal ($linux_scripts | length) 1 "Should filter by platform"
    assert_equal ($linux_scripts | get 0 | get name) "linux-script" "Should return correct script"
    track_test "script_filtering_platform" "unit" "passed" 0.1
    
    # Test category filtering
    let core_scripts = get_scripts_by_category $test_scripts "core"
    assert_equal ($core_scripts | length) 2 "Should filter by category"
    track_test "script_filtering_category" "unit" "passed" 0.1
    
    # Test root requirement filtering
    let root_scripts = get_root_scripts $test_scripts
    assert_equal ($root_scripts | length) 1 "Should filter by root requirement"
    assert_equal ($root_scripts | get 0 | get name) "linux-script" "Should return root-required script"
    track_test "script_filtering_root" "unit" "passed" 0.1
}

def test_script_validation [] {
    print "Testing script validation..."
    
    # Test valid script metadata
    let valid_script = {
        name: "valid-script",
        path: "/path/to/script",
        platform: "linux",
        category: "core",
        description: "A valid script",
        requires_root: false,
        dependencies: ["git"],
        executable: true
    }
    
    let valid_result = validate_script_metadata $valid_script
    assert_true $valid_result.valid "Valid script should pass validation"
    assert_equal ($valid_result.errors | length) 0 "Valid script should have no errors"
    track_test "script_validation_valid" "unit" "passed" 0.1
    
    # Test invalid script metadata
    let invalid_script = {
        name: "",
        platform: "invalid-platform",
        description: ""
    }
    
    let invalid_result = validate_script_metadata $invalid_script
    assert_false $invalid_result.valid "Invalid script should fail validation"
    assert_true (($invalid_result.errors | length) > 0) "Invalid script should have errors"
    track_test "script_validation_invalid" "unit" "passed" 0.1
}

def test_script_search [] {
    print "Testing script search..."
    
    let test_scripts = [
        {name: "install-linux", description: "Install packages on Linux", platform: "linux"},
        {name: "backup-files", description: "Backup important files", platform: "darwin"},
        {name: "setup-dev", description: "Development environment setup", platform: "linux"}
    ]
    
    # Test search by name
    let name_results = search_scripts $test_scripts "install"
    assert_equal ($name_results | length) 1 "Should find script by name"
    assert_equal ($name_results | get 0 | get name) "install-linux" "Should return correct script"
    track_test "script_search_name" "unit" "passed" 0.1
    
    # Test search by description
    let desc_results = search_scripts $test_scripts "backup"
    assert_equal ($desc_results | length) 1 "Should find script by description"
    assert_equal ($desc_results | get 0 | get name) "backup-files" "Should return correct script"
    track_test "script_search_description" "unit" "passed" 0.1
    
    # Test search with no results
    let no_results = search_scripts $test_scripts "nonexistent"
    assert_equal ($no_results | length) 0 "Should return no results for non-matching query"
    track_test "script_search_no_results" "unit" "passed" 0.1
}

if $env.PWD? == null {
    $env.PWD = (pwd)
}

main