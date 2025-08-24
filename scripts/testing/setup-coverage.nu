#!/usr/bin/env nu

# Import unified libraries
use ../lib/unified-checks.nu
use ../lib/unified-logging.nu *
use ../lib/unified-error-handling.nu *

# Comprehensive coverage setup for nix-mox
# Supports multiple coverage approaches for Nushell and Nix projects
export-env {
    use ./lib/test-coverage.nu *
    use ./lib/coverage-core.nu *
}

def main [
    --approach: string = "lcov"  # Coverage approach: lcov, grcov, tarpaulin, or custom
    --format: string = "lcov"    # Output format: lcov, cobertura, html, json
    --verbose                    # Enable verbose output
] {
    print "🔧 Setting up coverage for nix-mox..."
    print $"Approach: ($approach)"
    print $"Format: ($format)"

    # Set up environment
    setup_coverage_env

    match $approach {
        "lcov" => { setup_lcov_coverage $format $verbose }
        "grcov" => { setup_grcov_coverage $format $verbose }
        "tarpaulin" => { setup_tarpaulin_coverage $format $verbose }
        "custom" => { setup_custom_coverage $format $verbose }
        _ => { error make {msg: $"Unsupported approach '($approach)'. Use: lcov, grcov, tarpaulin, or custom"} }
    }
}

def setup_coverage_env [] {
    # Ensure coverage directories exist
    if not ("coverage-tmp" | path exists) {
        mkdir "coverage-tmp"
    }
    if not ("coverage-tmp/nix-mox-tests" | path exists) {
        mkdir "coverage-tmp/nix-mox-tests"
    }

    # Set environment variables
    $env.TEST_TEMP_DIR = "coverage-tmp/nix-mox-tests"
    $env.COVERAGE_DIR = "coverage-tmp"
}

def setup_lcov_coverage [format: string, verbose: bool] {
    print "📊 Setting up LCOV coverage..."

    if $verbose {
        print "LCOV is a standard coverage format that Codecov understands"
        print "This approach generates coverage based on test execution"
    }

    # Generate LCOV report
    try {
        # Use relative path from the current script location
        let script_dir = (pwd | path join "scripts" "tests")
        cd $script_dir
        source "generate-lcov.nu"
        cd -
        print "✅ LCOV coverage setup completed"
    } catch {
        print "❌ Failed to setup LCOV coverage: ($env.LAST_ERROR)"
        exit 1
    }
}

def setup_grcov_coverage [format: string, verbose: bool] {
    print "📊 Setting up grcov coverage (Rust-based)..."

    if $verbose {
        print "grcov is a Rust coverage tool that works well with Nushell"
        print "This requires Rust toolchain to be installed"
    }

    # Check if Rust is available
    let rust_available = (try { cargo --version | length | $in > 0 } catch { false })
    if not $rust_available {
        print "⚠️ Rust/Cargo not found. Install Rust to use grcov coverage."
        print "💡 Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    }

    # Install grcov if not available
    let grcov_available = (try { grcov --version | length | $in > 0 } catch { false })
    if not $grcov_available {
        print "Installing grcov..."
        try {
            cargo install grcov
            print "✅ grcov installed successfully"
        } catch {
            print "❌ Failed to install grcov: ($env.LAST_ERROR)"
            exit 1
        }
    }

    # Generate coverage with grcov
    try {
        # Set up Rust coverage environment
        $env.CARGO_INCREMENTAL = "0"
        $env.RUSTFLAGS = "-Cinstrument-coverage"
        $env.LLVM_PROFILE_FILE = "cargo-test-%p-%m.profraw"

        # Run tests with coverage instrumentation
        print "Running tests with coverage instrumentation..."
        cargo test

        # Generate coverage report
        print "Generating grcov coverage report..."
        grcov . --binary-path ./target/debug/ -s . -t $format --branch --ignore-not-existing --ignore '../*' --ignore "/*" -o $"coverage-tmp/coverage.($format)"
        print "✅ grcov coverage setup completed"
    } catch {
        print "❌ Failed to setup grcov coverage: ($env.LAST_ERROR)"
        exit 1
    }
}

def setup_tarpaulin_coverage [format: string, verbose: bool] {
    print "📊 Setting up tarpaulin coverage (Rust-based)..."

    if $verbose {
        print "tarpaulin is a Rust coverage tool that's easier to use than grcov"
    }

    # Check if Rust is available
    let rust_available = (try { cargo --version | length | $in > 0 } catch { false })
    if not $rust_available {
        print "⚠️ Rust/Cargo not found. Install Rust to use tarpaulin coverage."
        exit 1
    }

    # Install tarpaulin if not available
    let tarpaulin_available = (try { cargo tarpaulin --version | length | $in > 0 } catch { false })
    if not $tarpaulin_available {
        print "Installing tarpaulin..."
        try {
            cargo install cargo-tarpaulin
            print "✅ tarpaulin installed successfully"
        } catch {
            print "❌ Failed to install tarpaulin: ($env.LAST_ERROR)"
            exit 1
        }
    }

    # Generate coverage with tarpaulin
    try {
        print "Running tarpaulin coverage..."
        cargo tarpaulin --out $format --output-dir coverage-tmp

        # Rename output file to standard name
        let output_file = (ls coverage-tmp/*.lcov | get name | first | default "")
        if not ($output_file | is-empty) {
            mv $output_file "coverage-tmp/coverage.lcov"
        }
        print "✅ tarpaulin coverage setup completed"
    } catch {
        print "❌ Failed to setup tarpaulin coverage: ($env.LAST_ERROR)"
        exit 1
    }
}

def setup_custom_coverage [format: string, verbose: bool] {
    print "📊 Setting up custom coverage (test-based)..."

    if $verbose {
        print "Custom coverage generates reports based on test execution results"
        print "This is what you were using before - test pass/fail coverage"
    }

    # Run tests and generate coverage
    try {
        # Run tests
        print "Running tests..."
        source "run-tests.nu"

        # Generate coverage report
        print "Generating custom coverage report..."
        source "generate-lcov.nu"
        print "✅ Custom coverage setup completed"
    } catch {
        print "❌ Failed to setup custom coverage: ($env.LAST_ERROR)"
        exit 1
    }
}

# Helper functions for CI/CD
export def ci_setup_coverage [] {
    print "🔧 Setting up coverage for CI..."
    # Use LCOV approach for CI (most compatible with Codecov)
    main --approach lcov --format lcov
}

export def local_setup_coverage [] {
    print "🔧 Setting up coverage for local development..."
    # Try grcov first, fallback to LCOV
    try {
        main --approach grcov --format lcov --verbose
    } catch {
        print "⚠️ grcov failed, falling back to LCOV..."
        main --approach lcov --format lcov --verbose
    }
}

if ($env | get -i NU_TEST | default "false") == "true" {
    # Test mode - do nothing
}
