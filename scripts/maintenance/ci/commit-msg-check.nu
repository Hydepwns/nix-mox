#!/usr/bin/env nu
# Commit message format validation hook
# Enforces conventional commit message standards

use ../../lib/logging.nu *

# Conventional commit types
const COMMIT_TYPES = [
    "feat",     # New feature
    "fix",      # Bug fix
    "docs",     # Documentation changes
    "style",    # Code style changes (formatting, etc)
    "refactor", # Code refactoring
    "perf",     # Performance improvements
    "test",     # Adding or updating tests
    "build",    # Build system changes
    "ci",       # CI/CD changes
    "chore",    # Maintenance tasks
    "revert",   # Revert previous commit
    "wip"       # Work in progress
]

# Main commit message validation function
export def validate_commit_msg [
    message: string,            # The commit message to validate
    --verbose = false           # Show verbose output
] {
    let lines = ($message | lines)
    
    if ($lines | length) == 0 {
        error "Empty commit message" --context "commit-msg"
        return 1
    }
    
    let first_line = ($lines | first)
    mut errors = []
    mut warnings = []
    
    # Check first line length (should be <= 72 characters)
    if ($first_line | str length) > 72 {
        $errors = ($errors | append "First line exceeds 72 characters")
    }
    
    # Check for conventional commit format
    let conventional_result = check_conventional_format $first_line
    if not $conventional_result.valid {
        $errors = ($errors | append $conventional_result.error)
    }
    
    # Check for imperative mood (should start with verb)
    if not (check_imperative_mood $first_line) {
        $warnings = ($warnings | append "Consider using imperative mood (e.g., 'Add' instead of 'Added')")
    }
    
    # Check body format if present
    if ($lines | length) > 1 {
        # Second line should be blank
        if ($lines | length) > 1 and (($lines | get 1) | str trim) != "" {
            $warnings = ($warnings | append "Second line should be blank")
        }
        
        # Check body line length (should wrap at 72 characters)
        for line_idx in 2..(($lines | length) - 1) {
            let line = ($lines | get $line_idx)
            if ($line | str length) > 72 {
                $warnings = ($warnings | append $"Line ($line_idx + 1) exceeds 72 characters")
            }
        }
    }
    
    # Check for issue references
    let has_issue_ref = check_issue_references $message
    if $verbose and not $has_issue_ref {
        $warnings = ($warnings | append "No issue reference found (e.g., #123, fixes #456)")
    }
    
    # Report results
    if ($errors | length) == 0 and ($warnings | length) == 0 {
        success "Commit message format is valid! ✅" --context "commit-msg"
        return 0
    }
    
    if ($errors | length) > 0 {
        error "Commit message validation failed:" --context "commit-msg"
        for err in $errors {
            error $"  ❌ ($err)" --context "commit-msg"
        }
    }
    
    if ($warnings | length) > 0 {
        warn "Commit message warnings:" --context "commit-msg"
        for warning in $warnings {
            warn $"  ⚠️  ($warning)" --context "commit-msg"
        }
    }
    
    if ($errors | length) > 0 {
        error "" --context "commit-msg"
        error "Expected format: <type>(<scope>): <subject>" --context "commit-msg"
        error $"Valid types: ($COMMIT_TYPES | str join ', ')" --context "commit-msg"
        error "" --context "commit-msg"
        error "Example: feat(auth): add OAuth2 support" --context "commit-msg"
        return 1
    } else {
        return 0
    }
}

# Check if message follows conventional commit format
def check_conventional_format [first_line: string] {
    # Pattern: type(scope): description or type: description
    let parts = ($first_line | split row ":")
    
    if ($parts | length) < 2 {
        return {
            valid: false,
            error: "Missing ':' separator (format: 'type: description' or 'type(scope): description')"
        }
    }
    
    let type_part = ($parts | first | str trim)
    let description = ($parts | skip 1 | str join ":" | str trim)
    
    # Check for scope
    let has_scope = ($type_part | str contains "(") and ($type_part | str contains ")")
    
    let commit_type = if $has_scope {
        let type_match = ($type_part | split row "(" | first)
        $type_match
    } else {
        $type_part
    }
    
    # Validate commit type
    if not ($commit_type in $COMMIT_TYPES) {
        return {
            valid: false,
            error: $"Invalid commit type '($commit_type)'. Valid types: ($COMMIT_TYPES | str join ', ')"
        }
    }
    
    # Check description
    if ($description | str length) == 0 {
        return {
            valid: false,
            error: "Missing commit description after ':'"
        }
    }
    
    # Check if description starts with lowercase
    let first_char = ($description | str substring 0..1)
    if $first_char != ($first_char | str downcase) {
        return {
            valid: false,
            error: "Description should start with lowercase letter"
        }
    }
    
    return {
        valid: true,
        error: ""
    }
}

# Check if message uses imperative mood
def check_imperative_mood [first_line: string] {
    # Extract description part
    let description = if ($first_line | str contains ":") {
        $first_line | split row ":" | skip 1 | str join ":" | str trim
    } else {
        $first_line
    }
    
    # Common non-imperative patterns
    let non_imperative = ["added", "fixed", "updated", "changed", "removed", "deleted", "created"]
    
    for word in $non_imperative {
        if ($description | str downcase | str starts-with $word) {
            return false
        }
    }
    
    true
}

# Check for issue references
def check_issue_references [message: string] {
    ($message | str contains "#")
}

# Read commit message from file (for commit-msg hook)
export def validate_commit_file [
    file: string,               # Path to commit message file
    --verbose = false
] {
    if not ($file | path exists) {
        error $"Commit message file not found: ($file)" --context "commit-msg"
        return 1
    }
    
    let message = (open $file)
    
    # Filter out comments (lines starting with #)
    let filtered_lines = ($message | lines | where { |line| not ($line | str starts-with "#") })
    let filtered_message = ($filtered_lines | str join "\n")
    
    validate_commit_msg $filtered_message --verbose=$verbose
}

# Main function for CLI usage
def main [
    action: string = "validate",  # validate or examples
    message?: string,              # Message to validate (for testing)
    --file: string = "",          # File containing commit message
    --verbose = false
] {
    if $action == "validate" {
        if $file != "" {
            validate_commit_file $file --verbose=$verbose
        } else if $message != null {
            validate_commit_msg $message --verbose=$verbose
        } else {
            error "Please provide either --file or a message to validate" --context "commit-msg"
            exit 1
        }
    } else if $action == "examples" {
        banner "Commit Message Examples" --context "commit-msg"
        info "✅ Valid examples:" --context "commit-msg"
        info "  feat: add user authentication" --context "commit-msg"
        info "  fix(auth): resolve login timeout issue" --context "commit-msg"
        info "  docs: update API documentation" --context "commit-msg"
        info "  refactor(core): simplify data processing logic" --context "commit-msg"
        info "" --context "commit-msg"
        info "❌ Invalid examples:" --context "commit-msg"
        info "  Added new feature (missing type)" --context "commit-msg"
        info "  feat: Added user auth (should be lowercase)" --context "commit-msg"
        info "  feature: add auth (invalid type)" --context "commit-msg"
        info "" --context "commit-msg"
        info $"Valid types: ($COMMIT_TYPES | str join ', ')" --context "commit-msg"
    } else {
        error $"Unknown action: ($action). Use: validate or examples" --context "commit-msg"
        exit 1
    }
}