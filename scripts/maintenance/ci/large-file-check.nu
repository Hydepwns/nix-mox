#!/usr/bin/env nu
# Large file detection pre-commit hook
# Prevents accidentally committing large files

use ../../lib/logging.nu *

# File size limits (in bytes)
const MAX_FILE_SIZE = 10485760  # 10MB default
const WARN_FILE_SIZE = 1048576  # 1MB warning threshold

# Main large file check function
export def check_large_files [
    --staged-only = false,      # Only check staged files
    --max-size: int = 10485760, # Max file size in bytes
    --verbose = false           # Show verbose output
] {
    let files_to_check = if $staged_only {
        # Get staged files
        try {
            let staged_files = (git diff --cached --name-only --diff-filter=ACMR | lines)
            if ($staged_files | length) == 0 {
                success "No files in staging area" --context "large-files"
                return 0
            }
            $staged_files
        } catch {
            warn "Could not get staged files" --context "large-files"
            return 0
        }
    } else {
        (glob "**/*" | where { |f| ($f | path type) == "file" })
    }
    
    mut large_files = []
    mut warning_files = []
    mut total_size = 0b
    
    for file in $files_to_check {
        if not ($file | path exists) or ($file | path type) != "file" {
            continue
        }
        
        # Skip .git directory
        if ($file | str contains ".git/") {
            continue
        }
        
        let file_size = try {
            (ls $file | get size | first)
        } catch {
            0
        }
        
        $total_size = ($total_size + $file_size)
        
        if $verbose {
            info $"Checking ($file) - ($file_size | into string) bytes" --context "large-files"
        }
        
        if ($file_size | into int) > $max_size {
            $large_files = ($large_files | append {
                file: $file,
                size: $file_size,
                size_mb: ($file_size | into int | $in / 1048576 | math round -p 2)
            })
        } else if ($file_size | into int) > $WARN_FILE_SIZE {
            $warning_files = ($warning_files | append {
                file: $file,
                size: $file_size,
                size_mb: ($file_size | into int | $in / 1048576 | math round -p 2)
            })
        }
    }
    
    # Report results
    if ($large_files | length) == 0 and ($warning_files | length) == 0 {
        success "No large files detected! ✅" --context "large-files"
        if $verbose {
            info $"Total size of staged files: ($total_size | into int | $in / 1048576 | math round -p 2) MB" --context "large-files"
        }
        return 0
    }
    
    if ($large_files | length) > 0 {
        error $"Found ($large_files | length) files exceeding size limit:" --context "large-files"
        for file in $large_files {
            error $"  📁 ($file.file)" --context "large-files"
            error $"    Size: ($file.size_mb) MB (limit: ($max_size / 1048576) MB)" --context "large-files"
        }
        error "" --context "large-files"
        error "Consider using Git LFS for large files or add them to .gitignore" --context "large-files"
    }
    
    if ($warning_files | length) > 0 {
        warn $"Found ($warning_files | length) large files (warning):" --context "large-files"
        for file in $warning_files {
            warn $"  📁 ($file.file) - ($file.size_mb) MB" --context "large-files"
        }
    }
    
    info $"Total size: ($total_size | into int | $in / 1048576 | math round -p 2) MB" --context "large-files"
    
    if ($large_files | length) > 0 {
        return 1
    } else {
        return 0
    }
}

# Generate size report for repository
export def size_report [] {
    banner "Repository Size Report" --context "large-files"
    
    # Get all files
    let all_files = (glob "**/*" | where { |f| ($f | path type) == "file" and not ($f | str contains ".git/") })
    
    mut size_by_extension = {}
    mut largest_files = []
    mut total_size = 0b
    
    for file in $all_files {
        let file_size = try {
            (ls $file | get size | first)
        } catch {
            0
        }
        
        $total_size = ($total_size + $file_size)
        
        # Track by extension
        let ext = if ($file | path parse | get extension) != "" {
            $file | path parse | get extension
        } else {
            "no-extension"
        }
        
        if $ext in $size_by_extension {
            let current = ($size_by_extension | get $ext)
            $size_by_extension = ($size_by_extension | upsert $ext ($current + $file_size))
        } else {
            $size_by_extension = ($size_by_extension | insert $ext $file_size)
        }
        
        # Track largest files
        $largest_files = ($largest_files | append {
            file: $file,
            size: $file_size,
            size_mb: ($file_size / 1048576 | math round -p 2)
        })
    }
    
    # Sort and report
    $largest_files = ($largest_files | sort-by size --reverse | take 10)
    
    info "📊 Repository Statistics:" --context "large-files"
    info $"  Total files: ($all_files | length)" --context "large-files"
    info $"  Total size: ($total_size | into int | $in / 1048576 | math round -p 2) MB" --context "large-files"
    
    info "" --context "large-files"
    info "📈 Size by file type:" --context "large-files"
    let sorted_extensions = ($size_by_extension | transpose key value | sort-by value --reverse | take 10)
    for ext in $sorted_extensions {
        info $"  .($ext.key): ($ext.value | $in / 1048576 | math round -p 2) MB" --context "large-files"
    }
    
    info "" --context "large-files"
    info "📁 Largest files:" --context "large-files"
    for file in $largest_files {
        info $"  ($file.file): ($file.size_mb) MB" --context "large-files"
    }
}

# Main function for CLI usage
def main [
    action: string = "check",  # check, report, or size-report
    --staged-only = false,
    --max-size: int = 10485760,
    --verbose = false
] {
    if $action == "check" {
        check_large_files --staged-only=$staged_only --max-size=$max_size --verbose=$verbose
    } else if $action == "report" {
        banner "Large File Check Report" --context "large-files"
        check_large_files --max-size=$max_size --verbose=$verbose
    } else if $action == "size-report" {
        size_report
    } else {
        error $"Unknown action: ($action). Use: check, report, or size-report" --context "large-files"
        exit 1
    }
}