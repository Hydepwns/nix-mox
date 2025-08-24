#!/usr/bin/env nu

# Chezmoi Integration Script for nix-mox
# Integrates chezmoi with nix-mox workflows and provides convenient commands

use ../lib/unified-error-handling.nu

def show_banner [] {
    print "\n(ansi blue_bold)🔗 nix-mox: Chezmoi Integration(ansi reset)"
    print "(ansi dark_gray)Integrating chezmoi with nix-mox workflows(ansi reset)\n"
}

def check_chezmoi_installed [] {
    let chezmoi_installed = (which chezmoi | length) > 0
    if not $chezmoi_installed {
        unified-error-handling log_error "Chezmoi is not installed. Please install it first." "integration"
        return false
    }
    unified-error-handling log_success "Chezmoi is installed" "integration"
    true
}

def create_chezmoi_aliases [] {
    unified-error-handling log_info "Creating chezmoi aliases for nix-mox..." "integration"
    
    let aliases = "
# Chezmoi integration aliases for nix-mox
alias cz='chezmoi'
alias cza='chezmoi apply'
alias czd='chezmoi diff'
alias cze='chezmoi edit'
alias czu='chezmoi update'
alias czs='chezmoi status'
alias czv='chezmoi verify'

# Nix-mox specific chezmoi commands
alias nix-cz='chezmoi apply --source-path ~/.local/share/chezmoi'
alias nix-cz-diff='chezmoi diff --source-path ~/.local/share/chezmoi'
alias nix-cz-edit='chezmoi edit --source-path ~/.local/share/chezmoi'
"
    
    try {
        $aliases | save scripts/chezmoi-aliases.nu
        unified-error-handling log_success "Chezmoi aliases created: scripts/chezmoi-aliases.nu" "integration"
        true
    } catch { |err|
        unified-error-handling log_error $"Failed to create aliases: ($err.msg)" "integration"
        false
    }
}

def create_chezmoi_workflow_scripts [] {
    unified-error-handling log_info "Creating chezmoi workflow scripts..." "integration"
    
    # Create chezmoi apply script
    let apply_script = "#!/usr/bin/env nu

# Apply chezmoi configuration
# This script applies chezmoi templates to the system

use ../../../../lib/unified-error-handling.nu

def main [] {
    unified-error-handling log_info \"Applying chezmoi configuration...\" \"chezmoi-apply\"
    
    let result = (unified-error-handling safe_exec \"chezmoi apply\" \"chezmoi-apply\")
    if \$result.success {
        unified-error-handling log_success \"Chezmoi configuration applied successfully\" \"chezmoi-apply\"
        unified-error-handling exit_with_success \"Configuration applied\" \"chezmoi-apply\"
    } else {
        unified-error-handling log_error \"Failed to apply chezmoi configuration\" \"chezmoi-apply\"
        unified-error-handling exit_with_error \"Configuration failed\" 1 \"chezmoi-apply\"
    }
}

main
"
    
    # Create chezmoi diff script
    let diff_script = "#!/usr/bin/env nu

# Show chezmoi differences
# This script shows what changes chezmoi would make

use ../../../../lib/unified-error-handling.nu

def main [] {
    unified-error-handling log_info \"Checking chezmoi differences...\" \"chezmoi-diff\"
    
    let result = (unified-error-handling safe_exec \"chezmoi diff\" \"chezmoi-diff\")
    if \$result.success {
        if (\$result.output | str length) > 0 {
            print \$result.output
            unified-error-handling log_warning \"Differences found - run 'make chezmoi-apply' to apply them\" \"chezmoi-diff\"
        } else {
            unified-error-handling log_success \"No differences found - system is up to date\" \"chezmoi-diff\"
        }
    } else {
        unified-error-handling log_error \"Failed to check chezmoi differences\" \"chezmoi-diff\"
        unified-error-handling exit_with_error \"Diff check failed\" 1 \"chezmoi-diff\"
    }
}

main
"
    
    # Create chezmoi sync script
    let sync_script = "#!/usr/bin/env nu

# Sync chezmoi with remote repository
# This script updates chezmoi from the remote dotfiles repository

use ../../../../lib/unified-error-handling.nu

def main [] {
    unified-error-handling log_info \"Syncing chezmoi with remote repository...\" \"chezmoi-sync\"
    
    let result = (unified-error-handling safe_exec \"chezmoi update\" \"chezmoi-sync\")
    if \$result.success {
        unified-error-handling log_success \"Chezmoi synced successfully\" \"chezmoi-sync\"
        unified-error-handling log_info \"Run 'make chezmoi-apply' to apply any new changes\" \"chezmoi-sync\"
        unified-error-handling exit_with_success \"Sync completed\" \"chezmoi-sync\"
    } else {
        unified-error-handling log_error \"Failed to sync chezmoi\" \"chezmoi-sync\"
        unified-error-handling exit_with_error \"Sync failed\" 1 \"chezmoi-sync\"
    }
}

main
"
    
    try {
        $apply_script | save scripts/chezmoi-apply.nu
        $diff_script | save scripts/chezmoi-diff.nu
        $sync_script | save scripts/chezmoi-sync.nu
        
        # Make scripts executable
        chmod +x scripts/chezmoi-apply.nu
        chmod +x scripts/chezmoi-diff.nu
        chmod +x scripts/chezmoi-sync.nu
        
        unified-error-handling log_success "Chezmoi workflow scripts created" "integration"
        true
    } catch { |err|
        unified-error-handling log_error $"Failed to create workflow scripts: ($err.msg)" "integration"
        false
    }
}

def update_makefile [] {
    unified-error-handling log_info "Updating Makefile with chezmoi targets..." "integration"
    
    let chezmoi_targets = '
# Chezmoi integration targets
chezmoi-apply: ## Apply chezmoi configuration
	@echo "🔄 Applying chezmoi configuration..."
	@nu scripts/chezmoi-apply.nu

chezmoi-diff: ## Show chezmoi differences
	@echo "🔍 Checking chezmoi differences..."
	@nu scripts/chezmoi-diff.nu

chezmoi-sync: ## Sync chezmoi with remote repository
	@echo "📡 Syncing chezmoi with remote repository..."
	@nu scripts/chezmoi-sync.nu

chezmoi-edit: ## Edit chezmoi configuration
	@echo "✏️  Opening chezmoi configuration for editing..."
	@chezmoi edit

chezmoi-status: ## Show chezmoi status
	@echo "📊 Showing chezmoi status..."
	@chezmoi status

chezmoi-verify: ## Verify chezmoi configuration
	@echo "✅ Verifying chezmoi configuration..."
	@chezmoi verify

chezmoi-setup: ## Complete chezmoi setup and integration
	@echo "🔗 Setting up chezmoi integration..."
	@nu scripts/setup/chezmoi-integration.nu
'
    
    try {
        $chezmoi_targets | save -a Makefile
        unified-error-handling log_success "Makefile updated with chezmoi targets" "integration"
        true
    } catch { |err|
        unified-error-handling log_error $"Failed to update Makefile: ($err.msg)" "integration"
        false
    }
}

def create_integration_report [] {
    unified-error-handling log_info "Creating integration report..." "integration"
    
    let report = "
# Chezmoi Integration Report
Generated: $(date now | format date '%Y-%m-%d %H:%M:%S')

## Integration Components

### ✅ Chezmoi Aliases
- Created: scripts/chezmoi-aliases.nu
- Provides convenient shortcuts for chezmoi commands

### ✅ Workflow Scripts
- Created: scripts/chezmoi-apply.nu
- Created: scripts/chezmoi-diff.nu  
- Created: scripts/chezmoi-sync.nu
- Provides nix-mox integrated chezmoi workflows

### ✅ Makefile Integration
- Added chezmoi targets to Makefile
- Provides convenient make commands for chezmoi operations

## Available Commands

### Make Commands
- `make chezmoi-apply` - Apply chezmoi configuration
- `make chezmoi-diff` - Show chezmoi differences
- `make chezmoi-sync` - Sync with remote repository
- `make chezmoi-edit` - Edit chezmoi configuration
- `make chezmoi-status` - Show chezmoi status
- `make chezmoi-verify` - Verify chezmoi configuration

- `make chezmoi-setup` - Complete setup

### Direct Scripts
- `nu scripts/chezmoi-apply.nu` - Apply configuration
- `nu scripts/chezmoi-diff.nu` - Show differences
- `nu scripts/chezmoi-sync.nu` - Sync repository

## Next Steps

1. Test the integration: `make chezmoi-diff`
2. Apply configuration: `make chezmoi-apply`
3. Set up remote repository sync
4. Configuration management complete
5. Use chezmoi for all user configurations

## Benefits

- **Unified Workflow**: Chezmoi integrated with nix-mox
- **Cross-Platform**: Works on macOS, Linux, Windows
- **Version Control**: Git-based configuration management
- **Templates**: Dynamic configuration based on environment
- **Atomic Updates**: Safe, reversible configuration changes
"
    
    try {
        $report | save CHEZMOI_INTEGRATION_REPORT.md
        unified-error-handling log_success "Integration report created: CHEZMOI_INTEGRATION_REPORT.md" "integration"
        true
    } catch { |err|
        unified-error-handling log_error $"Failed to create report: ($err.msg)" "integration"
        false
    }
}

def main [] {
    show_banner
    
    # Check prerequisites
    if not (check_chezmoi_installed) {
        unified-error-handling exit_with_error "Prerequisites not met" 1 "integration"
    }
    
    # Perform integration steps
    unified-error-handling log_info "Step 1: Creating chezmoi aliases" "integration"
    let step1_success = (create_chezmoi_aliases)
    
    unified-error-handling log_info "Step 2: Creating workflow scripts" "integration"
    let step2_success = (create_chezmoi_workflow_scripts)
    
    unified-error-handling log_info "Step 3: Updating Makefile" "integration"
    let step3_success = (update_makefile)
    
    unified-error-handling log_info "Step 4: Creating integration report" "integration"
    let step4_success = (create_integration_report)
    
    # Count successes
    mut success_count = 0
    let total_steps = 4
    
    if $step1_success { $success_count = $success_count + 1 }
    if $step2_success { $success_count = $success_count + 1 }
    if $step3_success { $success_count = $success_count + 1 }
    if $step4_success { $success_count = $success_count + 1 }
    
    # Summary
    print "\n(ansi blue_bold)📊 Integration Summary(ansi reset)"
    print "(ansi dark_gray)══════════════════════════════════════════════════════════════(ansi reset)\n"
    print $"✅ Completed: ($success_count)/($total_steps) steps"
    
    if $success_count == $total_steps {
        unified-error-handling log_success "Integration completed successfully!" "integration"
        unified-error-handling log_info "Review CHEZMOI_INTEGRATION_REPORT.md for available commands" "integration"
        unified-error-handling log_info "Try: make chezmoi-diff" "integration"
        unified-error-handling exit_with_success "Integration completed" "integration"
    } else {
        unified-error-handling log_warning "Integration completed with some failures" "integration"
        unified-error-handling log_info "Review the output above and CHEZMOI_INTEGRATION_REPORT.md" "integration"
        unified-error-handling exit_with_error "Integration had failures" 1 "integration"
    }
}

# Run the integration
main 