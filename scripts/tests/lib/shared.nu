# Shared test utilities for nix-mox
# Place any functions or exports needed by both test-utils.nu and test-common.nu here.

export def assert_equal [expected: any, actual: any, message: string] {
    if $expected == $actual {
        print "✓ $message"
        true
    } else {
        print "✗ $message"
        print "  Expected: $expected"
        print "  Actual: $actual"
        false
    }
}

export def assert_true [condition: bool, message: string] {
    if $condition {
        print "✓ $message"
        true
    } else {
        print "✗ $message"
        false
    }
}

export def assert_false [condition: bool, message: string] {
    if not $condition {
        print "✓ $message"
        true
    } else {
        print "✗ $message"
        false
    }
}
