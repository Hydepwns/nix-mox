#!/usr/bin/env nu
# Linux-specific tests entrypoint

export-env {
  use ../lib/test-common.nu *
}

print "🔧 Running Linux storage guard..."
if (^nu scripts/storage/storage-guard.nu | complete | get exit_code) != 0 {
  print "❌ Storage guard failed"; exit 1
}
print "✅ Linux storage guard passed"
