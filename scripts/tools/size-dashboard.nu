#!/usr/bin/env nu

# nix-mox Size Analysis Dashboard
# Web-based interactive dashboard for analyzing package sizes and dependencies

def log_info [message: string] {
    print $"📊  ($message)"
}

def log_success [message: string] {
    print $"✅  ($message)"
}

def log_warning [message: string] {
    print $"⚠️   ($message)"
}

def log_error [message: string] {
    print $"❌  ($message)"
}

# Analyze package sizes and dependencies
def analyze_package_sizes [] {
    log_info "Analyzing package sizes and dependencies..."

    let packages = ["proxmox-update", "vzdump-backup", "zfs-snapshot", "nixos-flake-update", "install", "uninstall"]

    let analysis = ($packages | each { |pkg|
        try {
            # Get package path
            let package_path = (nix flake show .#"($pkg)" --json | from json | get packages | get 0 | get outputs | get out | get path)

            # Get closure information
            let closure_info = (nix path-info --closure-size $package_path --json | from json)
            let closure_size = ($closure_info | get size | math sum)

            # Get individual package size
            let package_info = (nix path-info --size $package_path --json | from json)
            let package_size = ($package_info | get size | math sum)

            # Calculate dependency size
            let deps_size = ($closure_size - $package_size)

            # Get dependency count
            let deps_count = ($closure_info | length)

            # Get build time estimate
            let build_time = (if $pkg in ["vzdump-backup", "zfs-snapshot"] { "heavy" } else { "light" })

            {
                name: $pkg
                package_size: $package_size
                deps_size: $deps_size
                total_size: $closure_size
                deps_count: $deps_count
                build_time: $build_time
                size_formatted: ($closure_size | into filesize)
                package_size_formatted: ($package_size | into filesize)
                deps_size_formatted: ($deps_size | into filesize)
            }
        } catch {
            log_error $"Could not analyze package ($pkg)"
            {
                name: $pkg
                package_size: 0
                deps_size: 0
                total_size: 0
                deps_count: 0
                build_time: "unknown"
                size_formatted: "0 B"
                package_size_formatted: "0 B"
                deps_size_formatted: "0 B"
            }
        }
    })

    $analysis
}

# Generate HTML dashboard
def generate_html_dashboard [analysis: list] {
    let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
    let total_size = ($analysis | get total_size | math sum | into filesize)
    let total_packages = ($analysis | length)
    let total_deps = ($analysis | get deps_count | math sum)
    let heavy_builds = ($analysis | where build_time == "heavy" | length)

    let table_rows = ($analysis | each { |pkg|
        let build_class = (if $pkg.build_time == "heavy" { "size-heavy" } else { "size-light" })
        $"<tr><td><strong>($pkg.name)</strong></td><td><span class=\"size-badge\">($pkg.size_formatted)</span></td><td>($pkg.package_size_formatted)</td><td>($pkg.deps_size_formatted)</td><td>($pkg.deps_count)</td><td><span class=\"size-badge ($build_class)\">($pkg.build_time)</span></td></tr>"
    } | str join "\n")

    # Create a simple HTML template
    let html = $"<!DOCTYPE html>
<html>
<head>
    <title>nix-mox Size Analysis</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        .header {{ background: #2c3e50; color: white; padding: 20px; text-align: center; }}
        .stats {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }}
        .stat-card {{ background: #f8f9fa; padding: 15px; border-radius: 5px; text-align: center; }}
        .package-table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
        .package-table th, .package-table td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
        .package-table th {{ background: #2c3e50; color: white; }}
        .size-badge {{ padding: 2px 6px; border-radius: 3px; font-size: 0.8em; }}
        .size-light {{ background: #d5f4e6; color: #27ae60; }}
        .size-heavy {{ background: #fadbd8; color: #e74c3c; }}
    </style>
</head>
<body>
    <div class=\"header\">
        <h1>📊 nix-mox Size Analysis</h1>
        <p>Generated on ($timestamp)</p>
    </div>

    <div class=\"stats\">
        <div class=\"stat-card\">
            <h3>Total Packages</h3>
            <p>($total_packages)</p>
        </div>
        <div class=\"stat-card\">
            <h3>Total Size</h3>
            <p>($total_size)</p>
        </div>
        <div class=\"stat-card\">
            <h3>Total Dependencies</h3>
            <p>($total_deps)</p>
        </div>
        <div class=\"stat-card\">
            <h3>Heavy Builds</h3>
            <p>($heavy_builds)</p>
        </div>
    </div>

    <table class=\"package-table\">
        <thead>
            <tr>
                <th>Package</th>
                <th>Total Size</th>
                <th>Package Size</th>
                <th>Dependencies</th>
                <th>Deps Count</th>
                <th>Build Type</th>
            </tr>
        </thead>
        <tbody>
($table_rows)
        </tbody>
    </table>
</body>
</html>"

    $html
}

# Generate JSON API endpoint
def generate_json_api [analysis: list] {
    let api_data = {
        metadata: {
            generated_at: (date now | format date "%Y-%m-%dT%H:%M:%SZ")
            version: "1.0.0"
            total_packages: ($analysis | length)
            total_size: ($analysis | get total_size | math sum | into filesize)
        }
        packages: $analysis
        summary: {
            by_build_time: ($analysis | group-by build_time | each { |group|
                {
                    build_time: $group.group
                    count: ($group.items | length)
                    total_size: ($group.items | get total_size | math sum | into filesize)
                }
            })
            largest_packages: ($analysis | sort-by total_size | reverse | take 3)
            most_dependencies: ($analysis | sort-by deps_count | reverse | take 3)
        }
    }

    $api_data
}

# Start web server
def start_dashboard [port: int = 8080] {
    print $"Starting size analysis dashboard on port ($port)..."

    # Generate analysis data
    let analysis = (analyze_package_sizes)

    # Generate HTML dashboard
    let html = (generate_html_dashboard $analysis)
    $html | save size-dashboard.html

    # Generate JSON API
    let api_data = (generate_json_api $analysis)
    $api_data | to json --indent 2 | save size-api.json

    print "Dashboard files generated:"
    print "  - size-dashboard.html (Interactive dashboard)"
    print "  - size-api.json (JSON API data)"

    # Start simple HTTP server
    try {
        print "Starting HTTP server..."
        python3 -m http.server $port &
        let server_pid = $env.LAST_BACKGROUND_JOB_PID

        print $"Dashboard available at: http://localhost:($port)/size-dashboard.html"
        print "Press Ctrl+C to stop the server"

        # Wait for user to stop
        read -s "Press Enter to stop the server..."

        # Stop server
        kill $server_pid
        print "Server stopped"
    } catch {
        print "Could not start HTTP server. You can open size-dashboard.html in your browser manually."
    }
}

# Export functions
export def analyze [] {
    analyze_package_sizes
}

export def generate-html [] {
    let analysis = (analyze_package_sizes)
    let html = (generate_html_dashboard $analysis)
    $html | save size-dashboard.html
    print "HTML dashboard saved to size-dashboard.html"
}

export def generate-api [] {
    let analysis = (analyze_package_sizes)
    let api_data = (generate_json_api $analysis)
    $api_data | to json --indent 2 | save size-api.json
    print "JSON API data saved to size-api.json"
}

export def serve [port: int = 8080] {
    start_dashboard $port
}

export def run [] {
    start_dashboard
}
