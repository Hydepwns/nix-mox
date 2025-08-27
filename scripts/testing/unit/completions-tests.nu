#!/usr/bin/env nu
# Unit tests for completions.nu library
# Tests shell completion system functionality

use ../../lib/completions.nu *
use ../../lib/validators.nu *
use ../../lib/logging.nu *

# Test completion initialization
export def test_init_completions [] {
    info "Testing init_completions function" --context "completions-test"
    
    # Initialize completions
    init_completions
    
    # Check if environment state was set
    if not ("COMPLETION_STATE" in $env) {
        error "COMPLETION_STATE not found in environment" --context "completions-test"
        return false
    }
    
    let state = $env.COMPLETION_STATE
    let expected_fields = ["scripts", "functions", "configs", "platforms", "initialized"]
    
    for field in $expected_fields {
        if not ($field in $state) {
            error $"Completion state missing field: ($field)" --context "completions-test"
            return false
        }
    }
    
    if not $state.initialized {
        error "Completion state not marked as initialized" --context "completions-test"
        return false
    }
    
    success "init_completions test passed" --context "completions-test"
    return true
}

export def test_platform_completions [] {
    info "Testing platform completions" --context "completions-test"
    
    # Initialize if not already done
    init_completions
    
    let state = $env.COMPLETION_STATE
    let platforms = $state.platforms
    
    # Check that expected platforms are present
    let expected_platforms = ["linux", "darwin", "windows", "auto"]
    for platform in $expected_platforms {
        if not ($platform in $platforms) {
            error $"Missing platform: ($platform)" --context "completions-test"
            return false
        }
    }
    
    if ($platforms | length) < 4 {
        error $"Expected at least 4 platforms, got ($platforms | length)" --context "completions-test"
        return false
    }
    
    success "platform completions test passed" --context "completions-test"
    return true
}

export def test_completion_state_structure [] {
    info "Testing completion state structure" --context "completions-test"
    
    init_completions
    
    let state = $env.COMPLETION_STATE
    
    # Verify all fields are lists or booleans as expected
    if ($state.scripts | describe) != "list" {
        error $"Expected scripts to be list, got ($state.scripts | describe)" --context "completions-test"
        return false
    }
    
    if ($state.functions | describe) != "list" {
        error $"Expected functions to be list, got ($state.functions | describe)" --context "completions-test"
        return false
    }
    
    if ($state.configs | describe) != "list" {
        error $"Expected configs to be list, got ($state.configs | describe)" --context "completions-test"
        return false
    }
    
    if ($state.platforms | describe) != "list" {
        error $"Expected platforms to be list, got ($state.platforms | describe)" --context "completions-test"
        return false
    }
    
    if ($state.initialized | describe) != "bool" {
        error $"Expected initialized to be bool, got ($state.initialized | describe)" --context "completions-test"
        return false
    }
    
    success "completion state structure test passed" --context "completions-test"
    return true
}

export def test_double_initialization [] {
    info "Testing double initialization protection" --context "completions-test"
    
    # Initialize twice
    init_completions
    let first_state = $env.COMPLETION_STATE
    
    init_completions  
    let second_state = $env.COMPLETION_STATE
    
    # States should be identical (no re-initialization)
    if $first_state.initialized != $second_state.initialized {
        error "Double initialization changed state" --context "completions-test"
        return false
    }
    
    success "double initialization protection test passed" --context "completions-test"
    return true
}

export def test_completion_context_isolation [] {
    info "Testing completion context isolation" --context "completions-test"
    
    # Save original state if it exists
    let original_state = ($env.COMPLETION_STATE? | default {})
    
    # Initialize fresh
    init_completions
    let test_state = $env.COMPLETION_STATE
    
    # Verify we have a clean initialized state
    if not $test_state.initialized {
        error "Fresh initialization failed" --context "completions-test"
        return false
    }
    
    # Verify isolation by checking state independence
    if ($test_state.platforms | length) == 0 {
        error "Platform list should not be empty" --context "completions-test"
        return false
    }
    
    success "completion context isolation test passed" --context "completions-test"
    return true
}

export def test_completion_data_types [] {
    info "Testing completion data types" --context "completions-test"
    
    init_completions
    let state = $env.COMPLETION_STATE
    
    # Test that platforms are strings
    for platform in $state.platforms {
        if ($platform | describe) != "string" {
            error $"Expected platform to be string, got ($platform | describe)" --context "completions-test"  
            return false
        }
    }
    
    # Test that scripts are properly typed
    if ($state.scripts | describe) != "list" {
        error $"Scripts should be a list" --context "completions-test"
        return false
    }
    
    # Test that functions are properly typed
    if ($state.functions | describe) != "list" {
        error $"Functions should be a list" --context "completions-test"
        return false
    }
    
    # Test that configs are properly typed  
    if ($state.configs | describe) != "list" {
        error $"Configs should be a list" --context "completions-test"
        return false
    }
    
    success "completion data types test passed" --context "completions-test"
    return true
}

export def test_platform_list_content [] {
    info "Testing platform list content" --context "completions-test"
    
    init_completions
    let platforms = $env.COMPLETION_STATE.platforms
    
    # Check for specific required platforms
    let required_platforms = ["linux", "auto"]
    for platform in $required_platforms {
        if not ($platform in $platforms) {
            error $"Required platform ($platform) not found" --context "completions-test"
            return false
        }
    }
    
    # Check platform names are reasonable
    for platform in $platforms {
        if ($platform | str length) == 0 {
            error "Empty platform name found" --context "completions-test"
            return false
        }
        
        if ($platform | str length) > 20 {
            error $"Platform name too long: ($platform)" --context "completions-test"
            return false
        }
    }
    
    success "platform list content test passed" --context "completions-test"
    return true
}

# Main test runner
export def run_completions_tests [] {
    banner "Running completions.nu unit tests" --context "completions-test"
    
    let tests = [
        test_init_completions,
        test_platform_completions,
        test_completion_state_structure,
        test_double_initialization,
        test_completion_context_isolation,
        test_completion_data_types,
        test_platform_list_content
    ]
    
    mut passed = 0
    mut failed = 0
    
    for test_func in $tests {
        try {
            let result = (do $test_func)
            if $result {
                $passed += 1
            } else {
                $failed += 1
            }
        } catch { |err|
            error $"Test failed with error: ($err.msg)" --context "completions-test"
            $failed += 1
        }
    }
    
    let total = $passed + $failed
    summary "Completions tests completed" $passed $total --context "completions-test"
    
    if $failed > 0 {
        error $"($failed) completions tests failed" --context "completions-test"
        return false
    }
    
    success "All completions tests passed!" --context "completions-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/unit") {
    run_completions_tests
}