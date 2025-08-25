#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use ../../lib/logging.nu *

# Linux-specific tests entrypoint

export-env {
  use ../lib/testing.nu *
}

print "🔧 Running Linux storage guard..."
# Skip storage guard in CI/build environment where real devices don't exist
if ($env.CI? == "true" or $env.CI? == "1" or $env.NIX_BUILD_TOP? != null) {
  print "⏭️  Skipping storage guard in build environment"
} else {
  if (^nu scripts/storage/storage-guard.nu | complete | get exit_code) != 0 {
    print "❌ Storage guard failed"; exit 1
  }
  print "✅ Linux storage guard passed"
}
