# Script discovery module for nix-mox scripts
# Helps find and manage available scripts with metadata extraction
use logging.nu *
use ./unified-error-handling.nu *

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
        "scripts/storage"
        "scripts/maintenance"
        "scripts/analysis"
        "scripts/setup"
        "scripts/testing"
        "scripts/validation"
        "scripts/platforms"
        "scripts/lib"
        "scripts/common"
        "scripts/handlers"
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
        let requires_root = (extract_requires_root_from_content $content)

        # Extract dependencies
        let dependencies = (extract_dependencies_from_content $content)

        # Determine category
        let category = (extract_category_from_path $script_path)

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
        print $"Warning: Failed to extract metadata from script ($script_path): ($err)"
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

# Extract requires_root from script content
export def extract_requires_root_from_content [content: string] {
    let lines = ($content | lines)

    for line in $lines {
        let trimmed = ($line | str trim)
        if ($trimmed | str contains "requires_root:") {
            if ($trimmed | str contains "true") {
                return true
            } else if ($trimmed | str contains "false") {
                return false
            }
        }
    }

    false
}

# Extract dependencies from script content
export def extract_dependencies_from_content [content: string] {
    let lines = ($content | lines)
    mut dependencies = []

    for line in $lines {
        let trimmed = ($line | str trim)
        if ($trimmed | str contains "dependencies:") {
            # Simple extraction - could be enhanced
            let deps_str = ($trimmed | str replace "dependencies:" "" | str trim)
            if ($deps_str | str starts-with "[") and ($deps_str | str ends-with "]") {
                # Parse array format
                $dependencies = ($deps_str | str substring 1..-1 | split row "," | each { |it| $it | str trim })
            }
        }
    }

    $dependencies
}

# Extract category from script path
export def extract_category_from_path [script_path: string] {
    if ($script_path | str contains "core") {
        "core"
    } else if ($script_path | str contains "platform") {
        "platform"
    } else if ($script_path | str contains "tools") {
        "tools"
    } else if ($script_path | str contains "development") {
        "development"
    } else if ($script_path | str contains "deployment") {
        "deployment"
    } else if ($script_path | str contains "maintenance") {
        "maintenance"
    } else if ($script_path | str contains "testing") {
        "testing"
    } else {
        "general"
    }
}

# Check if file is executable
export def is_executable [file_path: string] {
    try {
        let perms = (ls $file_path | get mode.0)
        ($perms | str contains "x")
    } catch {
        false
    }
}

# Get scripts by category
export def get_scripts_by_category [scripts: list, category: string] {
    $scripts | where category == $category
}

# Get scripts by platform
export def get_scripts_by_platform [scripts: list, platform: string] {
    $scripts | where platform == $platform or platform == "all"
}

# Get scripts that require root
export def get_root_scripts [scripts: list] {
    $scripts | where requires_root == true
}

# Search scripts by name or description
export def search_scripts [scripts: list, query: string] {
    $scripts | where name =~ $query or description =~ $query
}

# Validate script metadata
export def validate_script_metadata [script: record] {
    let required_fields = ["name", "path", "description", "platform", "requires_root", "category"]
    mut errors = []

    for field in $required_fields {
        if not ($script | get $field | is-not-empty) {
            $errors = ($errors | append $"Missing required field: $field")
        }
    }

    if not ($script.path | path exists) {
        $errors = ($errors | append "Script file does not exist")
    }

    $errors
}

# Generate script summary
export def generate_script_summary [scripts: list] {
    let total = ($scripts | length)
    let categories = ($scripts | get category | uniq | length)
    let platforms = ($scripts | get platform | uniq | length)
    let root_scripts = ($scripts | where requires_root == true | length)

    {
        total_scripts: $total
        categories: $categories
        platforms: $platforms
        root_scripts: $root_scripts
        category_breakdown: ($scripts | group-by category | each { |it| { category: $it.0, count: ($it.1 | length) } })
    }
}
