#!/usr/bin/env nu
# Linux-specific tests entrypoint

export-env {
  use ../lib/test-common.nu *
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
