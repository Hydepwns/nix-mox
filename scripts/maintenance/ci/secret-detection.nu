#!/usr/bin/env nu
# Secret detection pre-commit hook
# Scans for API keys, passwords, tokens, and other sensitive data

use ../../lib/logging.nu

# Main secret detection function
export def detect_secrets [
    --staged-only = false,      # Only check staged files
    --verbose = false           # Show verbose output
] {
    let files_to_check = if $staged_only {
        # Get staged files
        try {
            let staged_files = (git diff --cached --name-only --diff-filter=ACMR | lines)
            if ($staged_files | length) == 0 {
                success "No files in staging area"
                return 0
            }
            $staged_files
        } catch {
            warn "Could not get staged files, checking all files"
            (glob "**/*" | where { |f| ($f | path type) == "file" })
        }
    } else {
        (glob "**/*" | where { |f| ($f | path type) == "file" })
    }
    
    mut found_secrets = []
    
    for file in $files_to_check {
        if not ($file | path exists) or ($file | path type) != "file" {
            continue
        }
        
        # Skip binary files and certain directories
        if (should_skip_file $file) {
            continue
        }
        
        if $verbose {
            info $"Scanning ($file)..."
        }
        
        let content = try { open $file } catch { continue }
        let secrets = scan_for_secrets $file $content
        
        if ($secrets | length) > 0 {
            $found_secrets = ($found_secrets | append $secrets)
        }
    }
    
    # Report results
    if ($found_secrets | length) == 0 {
        success "No secrets detected! ✅"
        return 0
    }
    
    error $"⚠️  Found ($found_secrets | length) potential secrets:"
    for secret in $found_secrets {
        error $"  📁 ($secret.file):($secret.line)"
        error $"    Type: ($secret.type)"
        error $"    Pattern: ($secret.pattern)" --context "secrets"
    }
    
    error ""
    error "Please remove these secrets before committing!"
    error "Consider using environment variables or a secrets manager."
    
    return 1
}

# Check if file should be skipped
def should_skip_file [file: string] {
    # Skip certain directories and files
    let skip_dirs = [".git", "node_modules", ".nix", "result", "target", "dist", "scripts/maintenance/ci"]
    for dir in $skip_dirs {
        if ($file | str contains $dir) {
            return true
        }
    }
    
    # Skip binary file extensions
    let binary_exts = [".png", ".jpg", ".jpeg", ".gif", ".pdf", ".zip", ".tar", ".gz", ".exe", ".dll", ".so"]
    for ext in $binary_exts {
        if ($file | str ends-with $ext) {
            return true
        }
    }
    
    false
}

# Scan file content for secrets
def scan_for_secrets [file: string, content: string] {
    mut secrets = []
    let lines = ($content | lines)
    
    # Define secret patterns
    let patterns = [
        { regex: "api[_-]?key.*=.*['\"][a-zA-Z0-9]{20,}", type: "API Key" },
        { regex: "token.*=.*['\"][a-zA-Z0-9]{20,}", type: "Token" },
        { regex: "password.*=.*['\"][^'\"]{8,}", type: "Password" },
        { regex: "AKIA[0-9A-Z]{16}", type: "AWS Access Key" },
        { regex: "ghp_[a-zA-Z0-9]{36}", type: "GitHub Token" },
        { regex: "-----BEGIN.*PRIVATE KEY-----", type: "Private Key" },
        { regex: "postgres://[^:]+:[^@]+@", type: "Database URL" },
        { regex: "mysql://[^:]+:[^@]+@", type: "Database URL" },
        { regex: "mongodb://[^:]+:[^@]+@", type: "Database URL" },
        { regex: "ssh-rsa AAAA[0-9A-Za-z+/]+", type: "SSH Public Key" }
    ]
    
    for line_idx in 0..(($lines | length) - 1) {
        let line = ($lines | get $line_idx)
        let line_num = ($line_idx + 1)
        
        # Skip comments
        if ($line | str trim | str starts-with "#") or ($line | str trim | str starts-with "//") {
            continue
        }
        
        for pattern in $patterns {
            if ($line | str downcase | str contains ($pattern.type | str downcase)) {
                # Found potential secret keyword, record it
                $secrets = ($secrets | append {
                    file: $file,
                    line: $line_num,
                    type: $pattern.type,
                    pattern: ($line | str substring 0..50)
                })
                break
            }
        }
    }
    
    $secrets
}

# Main function for CLI usage
def main [
    action: string = "scan",  # scan or report
    --staged-only = false,
    --verbose = false
] {
    if $action == "scan" {
        detect_secrets --staged-only=$staged_only --verbose=$verbose
    } else if $action == "report" {
        print "Secret Detection Report"
        info "Scanning repository for potential secrets..."
        detect_secrets --verbose=$verbose
    } else {
        error $"Unknown action: ($action). Use: scan or report"
        exit 1
    }
}