#!/usr/bin/env nu

# Test script for VS Code extension development
# Contains example code patterns for testing extension features

def main [] {
    # Test error handling
    let result = try {
        test_operation
    } catch { |err|
        print $"Operation failed: ($err)"
        null
    }

    # Test configuration path handling
    let config_path = ($env.HOME | path join "config.nu")

    # Test message formatting
    let message = "Hello World"

    # Test conditional logic
    if ($result | is-not-empty) {
        print "Result found"
    }
}

# Test function with proper error handling
def safe_operation [] {
    try {
        let result = some_operation
        return $result
    } catch {|err|
        print $"Error: $err"
        return null
    }
}
