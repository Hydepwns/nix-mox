#!/usr/bin/env nu

# nix-mox Size Analysis Dashboard
# Web-based interactive dashboard for analyzing package sizes and dependencies

def log_info [message: string] {
    print $"📊 ($message)"
}

def log_success [message: string] {
    print $"✅ ($message)"
}

def log_warning [message: string] {
    print $"⚠️  ($message)"
}

def log_error [message: string] {
    print $"❌ ($message)"
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
            log_warning $"Could not analyze package ($pkg)"
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
    let table_rows = ($analysis | each { |pkg|
        let build_class = (if $pkg.build_time == "heavy" { "size-heavy" } else { "size-light" })
        $"<tr>
            <td><strong>($pkg.name)</strong></td>
            <td><span class=\"size-badge\">($pkg.size_formatted)</span></td>
            <td>($pkg.package_size_formatted)</td>
            <td>($pkg.deps_size_formatted)</td>
            <td>($pkg.deps_count)</td>
            <td><span class=\"size-badge ($build_class)\">($pkg.build_time)</span></td>
        </tr>"
    } | str join "\n")
    let html = '
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>nix-mox Size Analysis Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 30px;
            background: #f8f9fa;
        }
        
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            text-align: center;
        }
        
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 5px;
        }
        
        .stat-label {
            color: #7f8c8d;
            font-size: 0.9em;
        }
        
        .charts {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            padding: 30px;
        }
        
        .chart-container {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .chart-title {
            font-size: 1.3em;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 20px;
            text-align: center;
        }
        
        .table-container {
            padding: 30px;
            background: #f8f9fa;
        }
        
        .package-table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .package-table th {
            background: #2c3e50;
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
        }
        
        .package-table td {
            padding: 12px 15px;
            border-bottom: 1px solid #ecf0f1;
        }
        
        .package-table tr:hover {
            background: #f8f9fa;
        }
        
        .size-badge {
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.8em;
            font-weight: bold;
        }
        
        .size-light { background: #d5f4e6; color: #27ae60; }
        .size-heavy { background: #fadbd8; color: #e74c3c; }
        
        .footer {
            background: #2c3e50;
            color: white;
            padding: 20px;
            text-align: center;
            font-size: 0.9em;
        }
        
        @media (max-width: 768px) {
            .charts {
                grid-template-columns: 1fr;
            }
            
            .stats {
                grid-template-columns: repeat(2, 1fr);
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 nix-mox Size Analysis</h1>
            <p>Comprehensive package size and dependency analysis dashboard</p>
            <p style="margin-top: 10px; font-size: 0.9em;">Generated on ' + ($timestamp | into string) + '</p>
        </div>
        
        <div class="stats">
            <div class="stat-card">
                <div class="stat-value">' + ($total_packages | into string) + '</div>
                <div class="stat-label">Total Packages</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">' + ($total_size | into string) + '</div>
                <div class="stat-label">Total Size</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">' + (($analysis | get deps_count | math sum) | into string) + '</div>
                <div class="stat-label">Total Dependencies</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">' + (($analysis | where build_time == "heavy" | length) | into string) + '</div>
                <div class="stat-label">Heavy Builds</div>
            </div>
        </div>
        
        <div class="charts">
            <div class="chart-container">
                <div class="chart-title">Package Sizes Comparison</div>
                <canvas id="sizeChart" width="400" height="300"></canvas>
            </div>
            <div class="chart-container">
                <div class="chart-title">Dependencies Distribution</div>
                <canvas id="depsChart" width="400" height="300"></canvas>
            </div>
        </div>
        
        <div class="table-container">
            <h2 style="margin-bottom: 20px; color: #2c3e50;">📦 Package Details</h2>
            <table class="package-table">
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
' + $table_rows + '
                </tbody>
            </table>
        </div>
        
        <div class="footer">
            <p>Generated by nix-mox Size Analysis Dashboard | <a href="https://github.com/Hydepwns/nix-mox" style="color: #3498db;">View on GitHub</a></p>
        </div>
    </div>
    
    <script>
        // Chart.js configuration
        const analysisData = ' + ($analysis | to json | into string) + ';
        const packages = analysisData.map(p => p.name);
        const sizes = analysisData.map(p => p.total_size);
        const deps = analysisData.map(p => p.deps_count);
        const colors = ["#3498db", "#e74c3c", "#2ecc71", "#f39c12", "#9b59b6", "#1abc9c"];
        
        // Size comparison chart
        const sizeCtx = document.getElementById("sizeChart").getContext("2d");
        new Chart(sizeCtx, {
            type: "bar",
            data: {
                labels: packages,
                datasets: [{
                    label: "Total Size (bytes)",
                    data: sizes,
                    backgroundColor: colors,
                    borderColor: colors.map(c => c + "80"),
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            callback: function(value) {
                                return (value / 1024 / 1024).toFixed(1) + " MB";
                            }
                        }
                    }
                }
            }
        });
        
        // Dependencies chart
        const depsCtx = document.getElementById("depsChart").getContext("2d");
        new Chart(depsCtx, {
            type: "doughnut",
            data: {
                labels: packages,
                datasets: [{
                    data: deps,
                    backgroundColor: colors,
                    borderColor: "#fff",
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: "bottom"
                    }
                }
            }
        });
    </script>
</body>
</html>
'
    
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
    log_info $"Starting size analysis dashboard on port ($port)..."
    
    # Generate analysis data
    let analysis = (analyze_package_sizes)
    
    # Generate HTML dashboard
    let html = (generate_html_dashboard $analysis)
    $html | save size-dashboard.html
    
    # Generate JSON API
    let api_data = (generate_json_api $analysis)
    $api_data | to json --indent 2 | save size-api.json
    
    log_success "Dashboard files generated:"
    print "  - size-dashboard.html (Interactive dashboard)"
    print "  - size-api.json (JSON API data)"
    
    # Start simple HTTP server
    try {
        log_info "Starting HTTP server..."
        python3 -m http.server $port &
        let server_pid = $env.LAST_BACKGROUND_JOB_PID
        
        log_success $"Dashboard available at: http://localhost:($port)/size-dashboard.html"
        log_info "Press Ctrl+C to stop the server"
        
        # Wait for user to stop
        read -s "Press Enter to stop the server..."
        
        # Stop server
        kill $server_pid
        log_success "Server stopped"
    } catch {
        log_warning "Could not start HTTP server. You can open size-dashboard.html in your browser manually."
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
    log_success "HTML dashboard saved to size-dashboard.html"
}

export def generate-api [] {
    let analysis = (analyze_package_sizes)
    let api_data = (generate_json_api $analysis)
    $api_data | to json --indent 2 | save size-api.json
    log_success "JSON API data saved to size-api.json"
}

export def serve [port: int = 8080] {
    start_dashboard $port
}

export def run [] {
    start_dashboard
} 