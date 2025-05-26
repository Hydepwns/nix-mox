# install-steam-rust.nu
# Usage: nu install-steam-rust.nu [--dry-run] [--help]
#
# Options:
#   --dry-run   Show what would be done, but make no changes
#   --help      Show this help message

let dry_run = ($in | get dry-run | default false)
let help = ($in | get help | default false)
let mut errors = []

if $help {
  print "Install Steam and prompt for Rust (Facepunch) installation.\n\nOptions:\n  --dry-run   Show what would be done, but make no changes\n  --help      Show this help message\n"
  exit 0
}

# Download Steam installer
let steam_installer = $"($env.TEMP)\\SteamSetup.exe"
if $dry_run {
  print "[DRY RUN] Would download Steam installer to: $steam_installer"
} else {
  print "Downloading Steam installer..."
  let result = (http get "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe" | save $steam_installer | complete)
  if $result.exit_code != 0 {
    print "[ERROR] Failed to download Steam installer."
    $errors = ($errors | append "download")
  } else {
    print "[OK] Downloaded Steam installer."
  }
}

# Install Steam silently
if $dry_run {
  print "[DRY RUN] Would run Steam installer silently."
} else {
  print "Installing Steam silently..."
  let result = (run-external $steam_installer "/S" | complete)
  if $result.exit_code != 0 {
    print "[ERROR] Steam installer failed."
    $errors = ($errors | append "install")
  } else {
    print "[OK] Steam installed."
  }
}

# Wait for install to finish
if $dry_run {
  print "[DRY RUN] Would wait 30 seconds for install."
} else {
  print "Waiting for install to finish..."
  sleep 30sec
}

# Start Steam to initialize (will prompt for login)
if $dry_run {
  print "[DRY RUN] Would start Steam to initialize."
} else {
  print "Starting Steam to initialize..."
  let result = (run-external "C:\\Program Files (x86)\\Steam\\Steam.exe" | complete)
  if $result.exit_code != 0 {
    print "[ERROR] Failed to start Steam."
    $errors = ($errors | append "start_steam")
  } else {
    print "[OK] Steam started."
  }
  sleep 30sec
}

# Kill Steam process (if running)
if $dry_run {
  print "[DRY RUN] Would kill Steam process if running."
} else {
  print "Killing Steam process if running..."
  let procs = (ps | where name == "Steam.exe")
  if ($procs | is-empty) {
    print "[OK] No Steam process running."
  } else {
    let kill_results = ($procs | each { kill $in.pid | complete })
    if ($kill_results | any { $in.exit_code != 0 }) {
      print "[WARN] Could not kill all Steam processes."
      $errors = ($errors | append "kill_steam")
    } else {
      print "[OK] Steam process(es) killed."
    }
  }
}

if $dry_run {
  print "[DRY RUN] No changes were made."
}

if ($errors | is-empty) {
  print "[SUCCESS] Steam installed. Please log in to Steam and install Rust (Facepunch, appid 252490) via the Steam client."
  exit 0
} else {
  print $"[FAIL] The following steps failed: ($errors | str join ", ")"
  exit 1
} 