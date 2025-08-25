#!/usr/bin/env nu

# Consolidated chezmoi integration for nix-mox
# Updated to use the consolidated chezmoi.nu script instead of individual scripts

use ../lib/logging.nu
use ../lib/validators.nu *

def print_header [] {
    print "(ansi green_bold)Setting up chezmoi integration for nix-mox...(ansi reset)"
    print "(ansi dark_gray)Using consolidated chezmoi management script(ansi reset)\n"
}

def check_chezmoi_installed [] {
    let chezmoi_installed = (which chezmoi | length) > 0
    if not $chezmoi_installed {
        unified-error-handling error "Chezmoi is not installed. Please install it first." "integration"
        return false
    }
    unified-error-handling success "Chezmoi is installed" "integration"
    true
}

def create_chezmoi_aliases [] {
    unified-error-handling info "Creating chezmoi aliases for nix-mox..." "integration"
    
    let aliases = "
# Chezmoi integration aliases for nix-mox
alias cz='chezmoi'
alias cza='nu scripts/chezmoi.nu apply'
alias czd='nu scripts/chezmoi.nu diff'
alias cze='nu scripts/chezmoi.nu edit'
alias czu='nu scripts/chezmoi.nu sync'
alias czs='nu scripts/chezmoi.nu status'
alias czv='nu scripts/chezmoi.nu verify'

# Nix-mox specific chezmoi commands using consolidated script
alias nix-cz='nu scripts/chezmoi.nu apply'
alias nix-cz-diff='nu scripts/chezmoi.nu diff'
alias nix-cz-status='nu scripts/chezmoi.nu status'
alias nix-cz-sync='nu scripts/chezmoi.nu sync'
"
    
    try {
        $aliases | save scripts/chezmoi-aliases.nu
        unified-error-handling success "Chezmoi aliases created: scripts/chezmoi-aliases.nu" "integration"
        true
    } catch { |err|
        unified-error-handling error $"Failed to create aliases: ($err.msg)" "integration"
        false
    }
}

def validate_consolidated_script [] {
    unified-error-handling info "Validating consolidated chezmoi script..." "integration"
    
    # Check if the consolidated chezmoi script exists
    if not ("scripts/chezmoi.nu" | path exists) {
        unified-error-handling error "Consolidated chezmoi script not found at scripts/chezmoi.nu" "integration"
        return false
    }
    
    # Test that the consolidated script works
    try {
        let test_result = (nu scripts/chezmoi.nu help | complete)
        if $test_result.exit_code == 0 {
            unified-error-handling success "Consolidated chezmoi script is working" "integration"
            unified-error-handling info "Use: nu scripts/chezmoi.nu [apply|diff|sync|status|help]" "integration"
            true
        } else {
            unified-error-handling error "Consolidated chezmoi script failed test" "integration"
            false
        }
    } catch { |err|
        unified-error-handling error $"Failed to test chezmoi script: ($err.msg)" "integration"
        false
    }
}

def create_makefile_integration [] {
    unified-error-handling info "Validating Makefile integration..." "integration"
    
    let makefile_content = "
# Chezmoi integration targets (using consolidated script)
chezmoi-apply: ## Apply chezmoi configuration
	@echo \"🔄 Applying chezmoi configuration...\"
	@nu scripts/chezmoi.nu apply

chezmoi-diff: ## Show chezmoi differences
	@echo \"🔍 Checking chezmoi differences...\"
	@nu scripts/chezmoi.nu diff

chezmoi-sync: ## Sync chezmoi with remote repository
	@echo \"📡 Syncing chezmoi with remote repository...\"
	@nu scripts/chezmoi.nu sync

chezmoi-edit: ## Edit chezmoi configuration
	@echo \"✏️  Opening chezmoi configuration for editing...\"
	@nu scripts/chezmoi.nu edit

chezmoi-status: ## Show chezmoi status
	@echo \"📊 Showing chezmoi status...\"
	@nu scripts/chezmoi.nu status

chezmoi-verify: ## Verify chezmoi configuration
	@echo \"✅ Verifying chezmoi configuration...\"
	@nu scripts/chezmoi.nu verify
"
    
    # Check if Makefile already has chezmoi targets
    let makefile_has_targets = (open Makefile | str contains "chezmoi-apply")
    if $makefile_has_targets {
        unified-error-handling success "Makefile already contains chezmoi targets" "integration"
        true
    } else {
        unified-error-handling info "Makefile targets will need to be added manually" "integration"
        unified-error-handling info "Add the following targets to your Makefile:" "integration"
        print $makefile_content
        true
    }
}

def print_integration_summary [] {
    print "\n(ansi green_bold)🎉 Chezmoi integration setup completed!(ansi reset)\n"
    print "(ansi cyan_bold)Available commands:(ansi reset)"
    print "- `make chezmoi-apply` - Apply chezmoi configuration"
    print "- `make chezmoi-diff` - Show chezmoi differences"
    print "- `make chezmoi-sync` - Sync with remote repository"
    print "- `make chezmoi-edit` - Edit chezmoi configuration"
    print "- `make chezmoi-status` - Show chezmoi status"
    print "- `make chezmoi-verify` - Verify chezmoi configuration"
    
    print "\n(ansi cyan_bold)Direct script usage:(ansi reset)"
    print "- `nu scripts/chezmoi.nu apply` - Apply configuration"
    print "- `nu scripts/chezmoi.nu diff` - Show differences"
    print "- `nu scripts/chezmoi.nu sync` - Sync repository"
    print "- `nu scripts/chezmoi.nu status` - Show status"
    print "- `nu scripts/chezmoi.nu help` - Show all commands"
    
    print "\n(ansi yellow_bold)Next steps:(ansi reset)"
    print "1. Test the integration: `make chezmoi-diff`"
    print "2. Apply configuration: `make chezmoi-apply`"
    print "3. Check status: `make chezmoi-status`"
}

def main [] {
    print_header
    
    # Run integration steps
    if not (check_chezmoi_installed) { return }
    if not (validate_consolidated_script) { return }
    if not (create_chezmoi_aliases) { return }
    if not (create_makefile_integration) { return }
    
    print_integration_summary
    
    unified-error-handling success "Chezmoi integration completed successfully" "integration"
}

main