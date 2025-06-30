# Script discovery module for nix-mox scripts
# Helps find and manage available scripts with metadata extraction

use ./common.nu *
use ./logging.nu *

# Script metadata structure
export const SCRIPT_METADATA = {
    name: ""
    path: ""
    description: ""
    platform: "all"
    requires_root: false
    dependencies: []
    timeout: 300
    category: "general"
}

# Script categories
export const SCRIPT_CATEGORIES = {
    CORE: "core"
    PLATFORM: "platform"
    TOOLS: "tools"
    DEVELOPMENT: "development"
    DEPLOYMENT: "deployment"
    MAINTENANCE: "maintenance"
    TESTING: "testing"
}

# Discover all available scripts
export def discover_scripts [base_path: string = "scripts"] {
    mut all_scripts = []

    # Discover scripts in different directories
    let script_dirs = [
        "scripts/core"
        "scripts/platform"
        "scripts/tools"
        "scripts/linux"
        "scripts/windows"
        "scripts/common"
    ]

    for dir in $script_dirs {
        if ($dir | path exists) {
            let scripts = (discover_scripts_in_dir $dir)
            $all_scripts = ($all_scripts | append $scripts)
        }
    }

    # Also check root scripts directory
    if ($base_path | path exists) {
        let root_scripts = (discover_scripts_in_dir $base_path)
        $all_scripts = ($all_scripts | append $root_scripts)
    }

    $all_scripts
}

# Discover scripts in a specific directory
export def discover_scripts_in_dir [dir_path: string] {
    if not ($dir_path | path exists) {
        return []
    }

    let script_extensions = ["*.nu", "*.sh", "*.bat", "*.ps1"]
    mut scripts = []

    for ext in $script_extensions {
        let pattern = $"($dir_path)/($ext)"
        let files = (glob $pattern)

        for file in $files {
            let metadata = (extract_script_metadata $file)
            if $metadata != null {
                $scripts = ($scripts | append $metadata)
            }
        }
    }

    $scripts
}

# Extract metadata from a script file
export def extract_script_metadata [script_path: string] {
    if not ($script_path | path exists) {
        return null
    }

    try {
        let content = (open $script_path)
        let filename = ($script_path | path basename)
        let name = ($filename | str replace ".nu" "" | str replace ".sh" "" | str replace ".bat" "" | str replace ".ps1" "")

        # Extract description from comments
        let description = (extract_description_from_content $content)

        # Extract platform from path or content
        let platform = (extract_platform_from_path $script_path)

        # Check if script requires root
        let requires_root = (check_requires_root $content)

        # Extract dependencies
        let dependencies = (extract_dependencies $content)

        # Determine category
        let category = (determine_script_category $script_path)

        # Check if executable
        let executable = (is_executable $script_path)

        {
            name: $name
            path: $script_path
            description: $description
            platform: $platform
            requires_root: $requires_root
            dependencies: $dependencies
            category: $category
            executable: $executable
            size: (ls $script_path | get size.0)
            modified: (ls $script_path | get modified.0)
        }
    } catch { |err|
        warn "Failed to extract metadata from script" {
            script_path: $script_path
            error: $err
        }
        null
    }
}

# Extract description from script content
export def extract_description_from_content [content: string] {
    # Look for common comment patterns
    let lines = ($content | lines)

    for line in $lines {
        let trimmed = ($line | str trim)

        # Look for description in comments
        if ($trimmed | str starts-with "#") {
            let comment = ($trimmed | str substring 1.. | str trim)
            if ($comment | str length) > 10 and not ($comment | str starts-with "!") {
                return $comment
            }
        }

        # Look for specific description markers
        if ($trimmed | str contains "Description:") {
            return ($trimmed | str replace "Description:" "" | str trim)
        }

        if ($trimmed | str contains "Purpose:") {
            return ($trimmed | str replace "Purpose:" "" | str trim)
        }
    }

    "No description available"
}

# Extract platform from script path
export def extract_platform_from_path [script_path: string] {
    if ($script_path | str contains "linux") {
        "linux"
    } else if ($script_path | str contains "windows") {
        "windows"
    } else if ($script_path | str contains "darwin") {
        "darwin"
    } else if ($script_path | str contains "platform") {
        "multi"
    } else {
        "all"
    }
}

# Check if script requires root privileges
export def check_requires_root [content: string] {
    let root_indicators = [
        "sudo"
        "root"
        "privileges"
        "elevated"
        "admin"
    ]

    for indicator in $root_indicators {
        if ($content | str contains $indicator) {
            return true
        }
    }

    false
}

# Extract dependencies from script content
export def extract_dependencies [content: string] {
    mut deps = []

    # Look for shebang lines
    let shebang_lines = ($content | lines | where { |line| $line | str starts-with "#!" })
    for line in $shebang_lines {
        let interpreter = ($line | str replace "#!" "" | str trim | split row " " | get 0)
        $deps = ($deps | append $interpreter)
    }

    # Look for common command dependencies
    let common_commands = [
        "nix"
        "nixos-rebuild"
        "zfs"
        "systemctl"
        "docker"
        "kubectl"
        "git"
        "curl"
        "wget"
    ]

    for cmd in $common_commands {
        if ($content | str contains $cmd) {
            $deps = ($deps | append $cmd)
        }
    }

    $deps | uniq
}

# Determine script category based on path and content
export def determine_script_category [script_path: string] {
    if ($script_path | str contains "core") {
        $SCRIPT_CATEGORIES.CORE
    } else if ($script_path | str contains "platform") {
        $SCRIPT_CATEGORIES.PLATFORM
    } else if ($script_path | str contains "tools") {
        $SCRIPT_CATEGORIES.TOOLS
    } else if ($script_path | str contains "test") {
        $SCRIPT_CATEGORIES.TESTING
    } else if ($script_path | str contains "deploy") {
        $SCRIPT_CATEGORIES.DEPLOYMENT
    } else if ($script_path | str contains "dev") {
        $SCRIPT_CATEGORIES.DEVELOPMENT
    } else if ($script_path | str contains "maintain") {
        $SCRIPT_CATEGORIES.MAINTENANCE
    } else {
        $SCRIPT_CATEGORIES.TOOLS
    }
}

# Check if file is executable
export def is_executable [file_path: string] {
    if not ($file_path | path exists) {
        return false
    }

    try {
        let perms = (ls -l $file_path | get mode.0)
        ($perms | str contains "x")
    } catch {
        false
    }
}

# Get scripts by category
export def get_scripts_by_category [category: string] {
    let all_scripts = (discover_scripts)
    $all_scripts | where category == $category
}

# Get scripts by platform
export def get_scripts_by_platform [platform: string] {
    let all_scripts = (discover_scripts)
    $all_scripts | where platform in [$platform "all" "multi"]
}

# Search scripts by name or description
export def search_scripts [query: string] {
    let all_scripts = (discover_scripts)
    $all_scripts | where { |script|
        (($script.name | str downcase | str contains ($query | str downcase)) or
        ($script.description | str downcase | str contains ($query | str downcase)))
    }
}

# Get script dependencies
export def get_script_dependencies [script_path: string] {
    let metadata = (extract_script_metadata $script_path)
    if $metadata != null {
        $metadata.dependencies
    } else {
        []
    }
}

# Check if script dependencies are available
export def check_script_dependencies [script_path: string] {
    let dependencies = (get_script_dependencies $script_path)
    mut available = []
    mut missing = []

    for dep in $dependencies {
        if (which $dep | length) > 0 {
            $available = ($available | append $dep)
        } else {
            $missing = ($missing | append $dep)
        }
    }

    {
        available: $available
        missing: $missing
        all_available: (($missing | length | into int) == 0)
    }
}

# Generate script documentation
export def generate_script_docs [output_dir: string = "docs/scripts"] {
    let all_scripts = (discover_scripts)

    # Ensure output directory exists
    if not ($output_dir | path exists) {
        mkdir $output_dir
    }

    # Generate markdown documentation
    let markdown = generate_markdown_docs $all_scripts
    $markdown | save $"($output_dir)/scripts-reference.md"

    # Generate JSON index
    $all_scripts | to json | save $"($output_dir)/scripts-index.json"

    # Generate category-specific docs
    for category in ($SCRIPT_CATEGORIES | values) {
        let category_scripts = (get_scripts_by_category $category)
        if ($category_scripts | length) > 0 {
            let category_doc = generate_category_doc $category $category_scripts
            $category_doc | save $"($output_dir)/($category)-scripts.md"
        }
    }

    info "Script documentation generated" {
        output_dir: $output_dir
        total_scripts: ($all_scripts | length)
    }
}

# Generate markdown documentation
export def generate_markdown_docs [scripts: list] {
    mut markdown = []

    $markdown = ($markdown | append "# nix-mox Scripts Reference")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append "This document provides a comprehensive reference for all available scripts in the nix-mox toolkit.")
    $markdown = ($markdown | append "")

    # Generate table of contents
    $markdown = ($markdown | append "## Table of Contents")
    $markdown = ($markdown | append "")

    for category in ($SCRIPT_CATEGORIES | values) {
        let category_scripts = ($scripts | where category == $category)
        if ($category_scripts | length) > 0 {
            $markdown = ($markdown | append $"- [$category Scripts](#$category-scripts)")
        }
    }

    $markdown = ($markdown | append "")

    # Generate category sections
    for category in ($SCRIPT_CATEGORIES | values) {
        let category_scripts = ($scripts | where category == $category)
        if ($category_scripts | length) > 0 {
            $markdown = ($markdown | append $"## $category Scripts")
            $markdown = ($markdown | append "")

            for script in $category_scripts {
                $markdown = ($markdown | append $"### $script.name")
                $markdown = ($markdown | append "")
                $markdown = ($markdown | append $"**Path:** `$script.path`")
                $markdown = ($markdown | append $"**Description:** $script.description")
                $markdown = ($markdown | append $"**Platform:** $script.platform")
                $markdown = ($markdown | append $"**Requires Root:** $script.requires_root")
                $markdown = ($markdown | append "")

                if ($script.dependencies | length) > 0 {
                    $markdown = ($markdown | append $"**Dependencies:** ($script.dependencies | str join ', ')")
                    $markdown = ($markdown | append "")
                }
            }
        }
    }

    $markdown | str join "\n"
}

# Generate category-specific documentation
export def generate_category_doc [category: string, scripts: list] {
    mut markdown = []

    $markdown = ($markdown | append $"# $category Scripts")
    $markdown = ($markdown | append "")
    $markdown = ($markdown | append $"This document lists all scripts in the $category category.")
    $markdown = ($markdown | append "")

    for script in $scripts {
        $markdown = ($markdown | append $"## $script.name")
        $markdown = ($markdown | append "")
        $markdown = ($markdown | append $script.description)
        $markdown = ($markdown | append "")
        $markdown = ($markdown | append $"**Usage:** `$script.path`")
        $markdown = ($markdown | append "")
    }

    $markdown | str join "\n"
}

# Get script suggestions for auto-completion
export def get_script_suggestions [partial: string] {
    let all_scripts = (discover_scripts)
    $all_scripts | where { |script|
        (($script.name | str starts-with $partial) or
        ($script.name | str contains $partial))
    } | get name
}

# Validate script configuration
export def validate_script_config [script_path: string] {
    let metadata = (extract_script_metadata $script_path)
    if $metadata == null {
        return { valid: false, errors: ["Failed to extract metadata"] }
    }

    mut errors = []

    # Check if script exists
    if not ($script_path | path exists) {
        $errors = ($errors | append "Script file does not exist")
    }

    # Check if script is executable
    if not $metadata.executable {
        $errors = ($errors | append "Script is not executable")
    }

    # Check dependencies
    let dep_check = (check_script_dependencies $script_path)
    if not $dep_check.all_available {
        $errors = ($errors | append $"Missing dependencies: ($dep_check.missing | str join ', ')")
    }

    {
        valid: (($errors | length | into int) == 0)
        errors: $errors
        metadata: $metadata
    }
}
