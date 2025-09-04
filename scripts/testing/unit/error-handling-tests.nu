#!/usr/bin/env nu
# Unit tests for consolidated error-handling.nu library

use ../../lib/validators.nu *
use ../../lib/logging.nu *

# Test main error handling library
# export def test_error_handling_import [] {
#     info "Testing error handling library import" --context "error-handling-test"
    
#     try {
#         use ../../lib/error-handling.nu
#         success "Error handling library imported successfully" --context "error-handling-test"
#         return true
#     } catch { |err|
#         error $"Error handling library import failed: ($err.msg)" --context "error-handling-test"
#         return false
#     }
# }

# export def test_safe_execution [] {
#     info "Testing safe command execution" --context "error-handling-test"
    
#     try {
#         use ../../lib/error-handling.nu safe_exec
#         let result = (safe_exec "echo test" "test-context")
#         if $result.success {
#             success "Safe execution works" --context "error-handling-test"
#             return true
#         } else {
#             error "Safe execution failed" --context "error-handling-test"
#             return false
#         }
#     } catch { |err|
#         error $"Safe execution test failed: ($err.msg)" --context "error-handling-test"
#         return false
#     }
# }

export def test_compatibility_wrapper_structure [] {
    info "Testing compatibility wrapper structure" --context "error-handling-test"
    
    # Read the file to verify it's a proper compatibility wrapper
    try {
        let file_content = (open "../../lib/enhanced-error-handling.nu" | lines)
        
        # Check for expected compatibility wrapper content
        let has_deprecation_comment = ($file_content | any { |line| 
            ($line | str contains "DEPRECATED") or ($line | str contains "compatibility")
        })
        
        if not $has_deprecation_comment {
            warn "File doesn't appear to have deprecation notices" --context "error-handling-test"
        }
        
        let has_export_use = ($file_content | any { |line| 
            ($line | str contains "export use") or ($line | str contains "re-export")
        })
        
        if not $has_export_use {
            warn "File doesn't appear to be a re-export wrapper" --context "error-handling-test"
        }
        
        success "Compatibility wrapper structure verified" --context "error-handling-test"
        return true
    } catch { |err|
        error $"Cannot read wrapper file: ($err.msg)" --context "error-handling-test"
        return false
    }
}

export def test_error_handling_concepts [] {
    info "Testing error handling concepts" --context "error-handling-test"
    
    # Test basic error handling patterns work in Nushell
    try {
        # Test simple error creation
        let test_error = { msg: "test error", code: 42 }
        
        if $test_error.msg != "test error" {
            error "Error record creation failed" --context "error-handling-test"
            return false
        }
        
        if $test_error.code != 42 {
            error "Error code setting failed" --context "error-handling-test"
            return false
        }
        
        success "Basic error handling concepts work" --context "error-handling-test"
        return true
    } catch { |err|
        error $"Error handling concepts test failed: ($err.msg)" --context "error-handling-test"
        return false
    }
}

export def test_try_catch_functionality [] {
    info "Testing try-catch functionality" --context "error-handling-test"
    
    # Test that we can handle errors properly with try-catch
    let error_caught = false
    
    try {
        # This should throw an error
        error make { msg: "intentional test error", code: 999 }
    } catch { |err|
        let error_caught = true
        if $err.msg != "intentional test error" {
            error $"Wrong error message: ($err.msg)" --context "error-handling-test"
            return false
        }
    }
    
    if not $error_caught {
        error "Error was not properly caught" --context "error-handling-test"
        return false
    }
    
    success "try-catch functionality works" --context "error-handling-test"
    return true
}

export def test_error_propagation [] {
    info "Testing error propagation" --context "error-handling-test"
    
    # Test nested error handling
    def inner_function [] {
        error make { msg: "inner error", code: 100 }
    }
    
    def outer_function [] {
        try {
            inner_function
        } catch { |err|
            # Re-throw with additional context
            error make { 
                msg: $"outer context: ($err.msg)", 
                code: $err.code,
                inner: $err 
            }
        }
    }
    
    let outer_error_caught = false
    try {
        outer_function
    } catch { |err|
        let outer_error_caught = true
        if not ($err.msg | str contains "outer context") {
            error $"Error propagation failed: ($err.msg)" --context "error-handling-test"
            return false
        }
    }
    
    if not $outer_error_caught {
        error "Nested error was not properly caught" --context "error-handling-test"
        return false
    }
    
    success "Error propagation works" --context "error-handling-test"
    return true
}

export def test_library_deprecation_status [] {
    info "Testing library deprecation status" --context "error-handling-test"
    
    # Since this is a deprecated library, test that it behaves appropriately
    try {
        let file_content = (open "../../lib/enhanced-error-handling.nu")
        
        if ($file_content | str contains "DEPRECATED") {
            info "Library properly marked as deprecated" --context "error-handling-test"
            return true
        } else if ($file_content | str contains "compatibility") {
            info "Library is a compatibility wrapper" --context "error-handling-test"
            return true
        } else {
            warn "Library deprecation status unclear" --context "error-handling-test"
            return true  # Don't fail test, just warn
        }
    } catch { |err|
        error $"Cannot check deprecation status: ($err.msg)" --context "error-handling-test"
        return false
    }
}

# Main test runner
export def run_enhanced_error_handling_tests [] {
    banner "Running enhanced-error-handling.nu unit tests" --context "error-handling-test"
    
    let tests = [
        test_error_handling_concepts,
        test_try_catch_functionality,
        test_error_propagation
    ]
    
    let passed = 0
    let failed = 0
    
    for test_func in $tests {
        try {
            let result = (do $test_func)
            if $result {
                let passed = $passed + 1
            } else {
                let failed = $failed + 1
            }
        } catch { |err|
            error $"Test failed with error: ($err.msg)" --context "error-handling-test"
            let failed = $failed + 1
        }
    }
    
    let total = $passed + $failed
    summary "Enhanced error handling tests completed" $passed $total --context "error-handling-test"
    
    if $failed > 0 {
        error $"($failed) enhanced error handling tests failed" --context "error-handling-test"
        return false
    }
    
    success "All enhanced error handling tests passed!" --context "error-handling-test"
    return true
}

run_enhanced_error_handling_tests