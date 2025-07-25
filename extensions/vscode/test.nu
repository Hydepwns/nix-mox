#!/usr/bin/env nu

# TODO: Add more error handling
# FIXME: This needs to be refactored

def main [] {
    let result = try {
        some_risky_operation
    } catch {
        null
    }  # Missing catch block - will trigger warning

    # Hardcoded path - will trigger warning
    let config_path = "/home/user/config.nu"

    # Trailing whitespace - will trigger info diagnostic
    let message = "Hello World"

    # Dangerous command - will trigger error
    # rm -rf /  # This would be dangerous!

    # Tab indentation - will be converted to spaces by formatter
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
