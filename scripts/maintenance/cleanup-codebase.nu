#!/usr/bin/env nu

# Comprehensive codebase cleanup and consistency checker
# Identifies dead code, broken references, and outdated documentation

def main [
    --fix  # Actually perform cleanup actions
    --verbose  # Show detailed output
] {
    print "🔍 Starting codebase audit and cleanup..."
    print ""
    
    let issues = []
    
    # Check for dead code and unused files
    print "📂 Checking for dead code and unused files..."
    let dead_files = find_dead_files
    if ($dead_files | length) > 0 {
        print $"  ❌ Found ($dead_files | length) dead/unused files:"
        for file in $dead_files {
            print $"     - ($file.path): ($file.reason)"
        }
        if $fix {
            print "  🗑️  Removing dead files..."
            for file in $dead_files {
                rm -rf $file.path
                print $"     ✅ Removed ($file.path)"
            }
        }
    } else {
        print "  ✅ No dead files found"
    }
    
    # Check for broken imports and references
    print ""
    print "🔗 Checking for broken imports and references..."
    let broken_refs = find_broken_references
    if ($broken_refs | length) > 0 {
        print $"  ❌ Found ($broken_refs | length) broken references:"
        for ref in $broken_refs {
            print $"     - ($ref.file):($ref.line): ($ref.reference)"
        }
    } else {
        print "  ✅ All references valid"
    }
    
    # Check for inconsistent module structure
    print ""
    print "🏗️ Checking module structure consistency..."
    let module_issues = check_module_structure
    if ($module_issues | length) > 0 {
        print $"  ❌ Found ($module_issues | length) module issues:"
        for issue in $module_issues {
            print $"     - ($issue)"
        }
    } else {
        print "  ✅ Module structure consistent"
    }
    
    # Check for outdated documentation
    print ""
    print "📚 Checking documentation accuracy..."
    let doc_issues = check_documentation
    if ($doc_issues | length) > 0 {
        print $"  ⚠️  Found ($doc_issues | length) documentation issues:"
        for issue in $doc_issues {
            print $"     - ($issue)"
        }
    } else {
        print "  ✅ Documentation up to date"
    }
    
    # Check for duplicate functionality
    print ""
    print "♻️ Checking for duplicate code..."
    let duplicates = find_duplicates
    if ($duplicates | length) > 0 {
        print $"  ⚠️  Found ($duplicates | length) duplicate files:"
        for dup in $duplicates {
            print $"     - ($dup)"
        }
    } else {
        print "  ✅ No duplicate code found"
    }
    
    # Summary
    print ""
    print ("=" * 60)
    print "📊 Audit Summary:"
    print $"  Dead files: ($dead_files | length)"
    print $"  Broken references: ($broken_refs | length)"
    print $"  Module issues: ($module_issues | length)"
    print $"  Documentation issues: ($doc_issues | length)"
    print $"  Duplicates: ($duplicates | length)"
    
    if not $fix {
        print ""
        print "💡 Run with --fix to automatically clean up issues"
    }
}

def find_dead_files [] {
    mut dead = []
    
    # Old backup directories
    if ($"($env.PWD)/config/nixos/gaming.bak" | path exists) {
        $dead = ($dead | append {
            path: $"($env.PWD)/config/nixos/gaming.bak"
            reason: "Backup of old gaming config - now using flakes/gaming"
        })
    }
    
    # Empty stub modules
    let stub_modules = [
        $"($env.PWD)/flakes/gaming/modules/steam.nix"
        $"($env.PWD)/flakes/gaming/modules/lutris.nix"
        $"($env.PWD)/flakes/gaming/modules/gamemode.nix"
        $"($env.PWD)/flakes/gaming/modules/mangohud.nix"
        $"($env.PWD)/flakes/gaming/modules/wine.nix"
        $"($env.PWD)/flakes/gaming/modules/controllers.nix"
        $"($env.PWD)/flakes/gaming/modules/performance.nix"
    ]
    
    for module in $stub_modules {
        if ($module | path exists) {
            let content = open $module
            if ($content | str contains "# This file can be expanded") or ($content | str length) < 200 {
                $dead = ($dead | append {
                    path: $module
                    reason: "Empty stub module - functionality in main module.nix"
                })
            }
        }
    }
    
    
    # Old home config
    if ($"($env.PWD)/config/home/home.nix" | path exists) {
        let content = open $"($env.PWD)/config/home/home.nix" | str trim
        if ($content | str length) < 50 {
            $dead = ($dead | append {
                path: $"($env.PWD)/config/home/home.nix"
                reason: "Empty home config - using gamer.nix instead"
            })
        }
    }
    
    # Unused personal configs
    let personal_configs = ls $"($env.PWD)/config/personal/*.nix" | get name
    for config in $personal_configs {
        # Check if referenced anywhere
        let refs = (do -i { 
            grep -r ($config | path basename) $env.PWD --include="*.nix" 2> /dev/null | lines | length
        } | default 0)
        if $refs == 0 {
            $dead = ($dead | append {
                path: $config
                reason: "Unreferenced personal config"
            })
        }
    }
    
    return $dead
}

def find_broken_references [] {
    mut broken = []
    
    # Check all .nix files for imports that don't exist
    let nix_files = (find $env.PWD -name "*.nix" -type f | lines)
    
    for file in $nix_files {
        if ($file | path exists) {
            let content = open $file
            let lines = $content | lines
            
            for line in ($lines | enumerate) {
                if ($line.item | str contains "import ") {
                    # Extract path from import statement
                    let parts = ($line.item | str replace "import " "" | str trim | split row " " | first)
                    if ($parts | str starts-with "./") or ($parts | str starts-with "../") {
                        let import_path = $parts | str trim
                        # Resolve relative path
                        let full_path = (($file | path dirname) | path join $import_path)
                        if not ($full_path | path exists) {
                            $broken = ($broken | append {
                                file: $file
                                line: $line.index
                                reference: $import_path
                            })
                        }
                    }
                }
            }
        }
    }
    
    return $broken
}

def check_module_structure [] {
    mut issues = []
    
    # Check if modules have proper structure
    let module_dirs = [
        $"($env.PWD)/modules/core"
        $"($env.PWD)/modules/gaming"
        $"($env.PWD)/modules/services"
        $"($env.PWD)/modules/storage"
    ]
    
    for dir in $module_dirs {
        if ($dir | path exists) {
            # Check for default.nix or index.nix
            let has_index = (($dir | path join "default.nix") | path exists) or (($dir | path join "index.nix") | path exists)
            if not $has_index {
                $issues = ($issues | append $"($dir): Missing default.nix or index.nix")
            }
        }
    }
    
    # Check flake structure
    if not ($"($env.PWD)/flake.lock" | path exists) {
        $issues = ($issues | append "Missing flake.lock - run 'nix flake update'")
    }
    
    return $issues
}

def check_documentation [] {
    mut issues = []
    
    # Check if README references match actual structure
    let readme = open $"($env.PWD)/README.md"
    
    # Check for outdated commands
    if ($readme | str contains "interactive-setup.nu") {
        let script_path = $"($env.PWD)/scripts/setup/interactive-setup.nu"
        if ($script_path | path exists) {
            # Check if it's actually broken
            let content = open $script_path
            if ($content | str contains "default:") {
                $issues = ($issues | append "README references broken interactive-setup.nu script")
            }
        }
    }
    
    # Check if documented features exist
    let documented_features = [
        "scripts/validation/pre-rebuild-safety-check.nu"
        "scripts/maintenance/safe-rebuild.nu"
        "scripts/setup/unified-setup.nu"
    ]
    
    for feature in $documented_features {
        let full_path = $"($env.PWD)/($feature)"
        if not ($full_path | path exists) {
            $issues = ($issues | append $"README references missing file: ($feature)")
        }
    }
    
    # Check CLAUDE.md accuracy
    if ($"($env.PWD)/CLAUDE.md" | path exists) {
        let claude_md = open $"($env.PWD)/CLAUDE.md"
        
        # Check for outdated module references
        if ($claude_md | str contains "config/nixos/gaming/") {
            if not ($"($env.PWD)/config/nixos/gaming" | path exists) {
                $issues = ($issues | append "CLAUDE.md references old gaming directory structure")
            }
        }
    }
    
    return $issues
}

def find_duplicates [] {
    mut duplicates = []
    
    # Check for duplicate configurations
    let configs = [
        [$"($env.PWD)/config/nixos/gaming.bak"
         $"($env.PWD)/flakes/gaming"]
    ]
    
    for pair in $configs {
        if ($pair.0 | path exists) and ($pair.1 | path exists) {
            $duplicates = ($duplicates | append $"($pair.0) duplicates ($pair.1)")
        }
    }
    
    return $duplicates
}

# Run the cleanup
main ...$args