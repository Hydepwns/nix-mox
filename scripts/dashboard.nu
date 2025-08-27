#!/usr/bin/env nu
# Functional dashboard and analysis system for nix-mox
# Consolidates multiple analysis scripts with composable data pipelines
# Uses functional patterns for data collection and presentation

use lib/logging.nu *
use lib/platform.nu *
use lib/validators.nu *
use lib/command-wrapper.nu *
use lib/script-template.nu *
use lib/testing.nu *

# Main dashboard dispatcher
def main [
    view: string = "overview",
    --refresh: int = 5,
    --output: string = "",
    --format: string = "terminal",
    --watch,
    --verbose,
    --context: string = "dashboard"
] {
    if ($verbose | default false) { $env.LOG_LEVEL = "DEBUG" }
    
    info $"nix-mox dashboard: Displaying ($view) view" --context $context
    
    # Dispatch to appropriate dashboard view
    match $view {
        "overview" => (overview_dashboard $refresh $watch $output $format),
        "system" => (system_dashboard $refresh $watch $output $format),
        "performance" => (performance_dashboard $refresh $watch $output $format),
        "testing" => (testing_dashboard $refresh $watch $output $format),
        "coverage" => (coverage_dashboard $refresh $watch $output $format),
        "security" => (security_dashboard $refresh $watch $output $format),
        "gaming" => (gaming_dashboard $refresh $watch $output $format),
        "analysis" => (analysis_dashboard $refresh $watch $output $format),
        "size" => (size_dashboard $refresh $watch $output $format),
        "project" => (project_dashboard $refresh $watch $output $format),
        "quick" => (quick_status_dashboard),
        "help" => { show_dashboard_help; return },
        _ => {
            error $"Unknown dashboard view: ($view). Use 'help' to see available views."
            return
        }
    }
}

# Data collection pipeline framework
export def collect_data [...collectors: string] {
    $collectors | par-each { |collector_name|
        try {
            # Call the collector function by name
            match $collector_name {
                "collect_basic_system_info" => (collect_basic_system_info),
                "collect_nix_status" => (collect_nix_status),
                "collect_disk_usage" => (collect_disk_usage),
                "collect_memory_usage" => (collect_memory_usage),
                "collect_service_status" => (collect_service_status),
                "collect_recent_activity" => (collect_recent_activity),
                "collect_detailed_hardware_info" => (collect_detailed_hardware_info),
                "collect_network_info" => (collect_network_info),
                "collect_process_info" => (collect_process_info),
                "collect_environment_info" => (collect_environment_info),
                "collect_cpu_metrics" => (collect_cpu_metrics),
                "collect_memory_metrics" => (collect_memory_metrics),
                "collect_disk_metrics" => (collect_disk_metrics),
                "collect_network_metrics" => (collect_network_metrics),
                "collect_nix_performance" => (collect_nix_performance),
                "collect_test_results" => (collect_test_results),
                "collect_coverage_data" => (collect_coverage_data),
                "collect_quality_metrics" => (collect_quality_metrics),
                "collect_security_status" => (collect_security_status),
                "collect_vulnerability_scan" => (collect_vulnerability_scan),
                "collect_audit_logs" => (collect_audit_logs),
                "collect_gpu_info" => (collect_gpu_info),
                "collect_gaming_services" => (collect_gaming_services),
                "collect_audio_status" => (collect_audio_status),
                "collect_controller_status" => (collect_controller_status),
                "collect_package_analysis" => (collect_package_analysis),
                "collect_size_analysis" => (collect_size_analysis),
                "collect_dependency_analysis" => (collect_dependency_analysis),
                "collect_performance_analysis" => (collect_performance_analysis),
                _ => {
                    warn $"Unknown collector: ($collector_name)" --context "data-collector"
                    {}
                }
            }
        } catch { |err|
            warn $"Data collection failed for ($collector_name): ($err.msg)" --context "data-collector"
            {}
        }
    } | reduce --fold {} { |item, acc| $acc | merge $item }
}

# Overview dashboard - high-level system status
def overview_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_overview_data)
    
    if $watch {
        loop {
            clear
            display_overview $data $format
            sleep ($refresh | into duration --unit sec)
            let data = (collect_overview_data)
        }
    } else {
        display_overview $data $format
        
        if not ($output | is-empty) {
            save_dashboard_data $data $output
        }
    }
}

# System dashboard - detailed system information
def system_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_system_data)
    
    if $watch {
        loop {
            clear
            display_system $data $format
            sleep ($refresh | into duration --unit sec)
            let data = (collect_system_data)
        }
    } else {
        display_system $data $format
        
        if not ($output | is-empty) {
            save_dashboard_data $data $output
        }
    }
}

# Performance dashboard - performance metrics and analysis
def performance_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_performance_data)
    
    if $watch {
        loop {
            clear
            display_performance $data $format
            sleep ($refresh | into duration --unit sec)
            let data = (collect_performance_data)
        }
    } else {
        display_performance $data $format
        
        if not ($output | is-empty) {
            save_dashboard_data $data $output
        }
    }
}

# Testing dashboard - test results and coverage
def testing_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_testing_data)
    display_testing $data $format
    
    if not ($output | is-empty) {
        save_dashboard_data $data $output
    }
}

# Coverage dashboard - dedicated test coverage reporting
def coverage_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_coverage_data)
    display_coverage $data $format
    
    if not ($output | is-empty) {
        save_dashboard_data $data $output
    }
}

# Security dashboard - security status and threats
def security_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_security_data)
    display_security $data $format
    
    if not ($output | is-empty) {
        save_dashboard_data $data $output
    }
}

# Gaming dashboard - gaming system status
def gaming_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_gaming_data)
    display_gaming $data $format
    
    if not ($output | is-empty) {
        save_dashboard_data $data $output
    }
}

# Analysis dashboard - comprehensive system analysis
def analysis_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_analysis_data)
    display_analysis $data $format
    
    if not ($output | is-empty) {
        save_dashboard_data $data $output
    }
}

# Data collection functions using functional composition
def collect_overview_data [] {
    collect_data "collect_basic_system_info" "collect_nix_status" "collect_disk_usage" "collect_memory_usage" "collect_service_status" "collect_recent_activity"
}

def collect_system_data [] {
    collect_data "collect_basic_system_info" "collect_detailed_hardware_info" "collect_network_info" "collect_process_info" "collect_environment_info"
}

def collect_performance_data [] {
    collect_data "collect_cpu_metrics" "collect_memory_metrics" "collect_disk_metrics" "collect_network_metrics" "collect_nix_performance"
}

def collect_testing_data [] {
    collect_data "collect_test_results" "collect_coverage_data" "collect_quality_metrics"
}

def collect_coverage_data [] {
    info "Collecting comprehensive coverage data" --context "coverage-dashboard"
    
    try {
        # Generate coverage data using the fixed coverage.nu script
        # Try multiple paths to find the coverage script
        let coverage_paths = [
            "scripts/coverage.nu",           # From project root
            "coverage.nu",                   # From scripts directory
            "../coverage.nu",                # From subdirectory
            "./scripts/coverage.nu"         # Explicit relative path
        ]
        
        mut coverage_script = ""
        for path in $coverage_paths {
            if ($path | path exists) {
                $coverage_script = $path
                break
            }
        }
        
        if ($coverage_script | str length) == 0 {
            error "coverage.nu script not found in expected locations" --context "coverage-dashboard"
            return {
                error: "coverage.nu script not found",
                coverage: { summary: { coverage_percentage: 0, files_analyzed: 0 } },
                metrics: { test_files: 0, lib_files: 0, coverage_ratio: 0 }
            }
        }
        
        info $"Using coverage script: ($coverage_script)" --context "coverage-dashboard"
        let lcov_result = (^nu $coverage_script "lcov" | complete)
        let json_result = (^nu $coverage_script "json" | complete)
        
        # Parse coverage results
        let coverage_summary = if ($json_result.exit_code == 0) {
            try {
                # Try multiple paths for coverage output
                let json_paths = [
                    "coverage-tmp/coverage.json",
                    "./coverage-tmp/coverage.json",
                    "../coverage-tmp/coverage.json"
                ]
                
                mut json_data = { summary: { coverage_percentage: 0, files_analyzed: 0 } }
                for json_path in $json_paths {
                    if ($json_path | path exists) {
                        $json_data = (open $json_path)
                        break
                    }
                }
                $json_data
            } catch {
                { summary: { coverage_percentage: 0, files_analyzed: 0 } }
            }
        } else {
            { summary: { coverage_percentage: 0, files_analyzed: 0 } }
        }
        
        # Collect additional test metrics
        let test_files = (glob "scripts/testing/**/*.nu" | length)
        let lib_files = (glob "scripts/lib/*.nu" | length)
        let coverage_ratio = if $lib_files > 0 { ($test_files * 100 / $lib_files | math round) } else { 0 }
        
        {
            metadata: {
                generated_at: (date now),
                generator: "nix-mox coverage dashboard",
                version: "1.0.0"
            },
            coverage: $coverage_summary,
            metrics: {
                test_files: $test_files,
                lib_files: $lib_files,
                coverage_ratio: $coverage_ratio,
                lcov_status: ($lcov_result.exit_code == 0),
                json_status: ($json_result.exit_code == 0)
            },
            reports: {
                lcov_available: (["coverage-tmp/lcov.info", "./coverage-tmp/lcov.info"] | any { |p| $p | path exists }),
                json_available: (["coverage-tmp/coverage.json", "./coverage-tmp/coverage.json"] | any { |p| $p | path exists }),
                html_available: (["coverage-tmp/html/index.html", "./coverage-tmp/html/index.html"] | any { |p| $p | path exists })
            }
        }
    } catch { |err|
        error $"Coverage data collection failed: ($err.msg)" --context "coverage-dashboard"
        {
            metadata: {
                generated_at: (date now),
                generator: "nix-mox coverage dashboard",
                version: "1.0.0"
            },
            error: $err.msg,
            coverage: { summary: { coverage_percentage: 0, files_analyzed: 0 } },
            metrics: { test_files: 0, lib_files: 0, coverage_ratio: 0 }
        }
    }
}

def collect_security_data [] {
    collect_data "collect_security_status" "collect_vulnerability_scan" "collect_audit_logs"
}

def collect_gaming_data [] {
    collect_data "collect_gpu_info" "collect_gaming_services" "collect_audio_status" "collect_controller_status"
}

def collect_analysis_data [] {
    # Use the comprehensive analysis functions from analysis.nu library
    use lib/analysis.nu *
    
    info "Collecting comprehensive system analysis data" --context "analysis"
    
    let package_analysis = (analyze_package_sizes)
    let code_quality = (analyze_code_quality)
    let security_analysis = (analyze_security_posture)
    let system_info = (collect_comprehensive_system_info)
    
    {
        metadata: {
            generated_at: (date now),
            generator: "nix-mox dashboard analysis",
            version: "2.0.0"
        },
        system: $system_info,
        packages: $package_analysis,
        code_quality: $code_quality,
        security: $security_analysis
    }
}

# Comprehensive system information collector for analysis
def collect_comprehensive_system_info [] {
    let platform = (get_platform)
    let platform_report = (platform_report)
    
    {
        platform: $platform,
        detailed_info: $platform_report,
        nix_info: {
            version: (try { (nix --version | lines | get 0) } catch { "unknown" }),
            store_health: (try { 
                let check = (nix store ping | complete)
                if $check.exit_code == 0 { "healthy" } else { "unhealthy" }
            } catch { "error" })
        }
    }
}

# Individual data collectors
def collect_basic_system_info [] {
    let platform = (get_platform)
    let uptime = try { (uptime | str trim) } catch { "unknown" }
    
    {
        system: {
            platform: $platform.normalized,
            architecture: $platform.arch,
            hostname: $platform.hostname,
            uptime: $uptime,
            timestamp: (date now)
        }
    }
}

def collect_nix_status [] {
    let nix_version = try {
        (nix --version | lines | get 0)
    } catch {
        "Nix not available"
    }
    
    let flake_status = if ("flake.nix" | path exists) {
        try {
            let check_result = (nix flake check --no-build | complete)
            if $check_result.exit_code == 0 { "valid" } else { "invalid" }
        } catch {
            "error"
        }
    } else {
        "no flake"
    }
    
    {
        nix: {
            version: $nix_version,
            flake_status: $flake_status,
            store_health: (check_nix_store_health)
        }
    }
}

def collect_disk_usage [] {
    try {
        let df_output = (df -h | from ssv -a)
        let root_usage = ($df_output | where filesystem == "/" | get 0)
        
        {
            disk: {
                root_used: $root_usage.use%,
                root_available: $root_usage.avail,
                root_size: $root_usage.size
            }
        }
    } catch {
        { disk: { error: "failed to collect disk usage" } }
    }
}

def collect_memory_usage [] {
    try {
        let mem_info = (sys mem)
        let usage_percent = (($mem_info.used / $mem_info.total) * 100 | math round)
        
        {
            memory: {
                total: ($mem_info.total | into string),
                used: ($mem_info.used | into string),  
                available: ($mem_info.available | into string),
                usage_percent: $usage_percent
            }
        }
    } catch {
        { memory: { error: "failed to collect memory usage" } }
    }
}

def collect_service_status [] {
    let platform = (get_platform)
    
    if $platform.is_linux and (which systemctl | is-not-empty) {
        try {
            let failed_services = (systemctl --failed --no-pager -q | complete)
            let service_count = ($failed_services.stdout | lines | length)
            
            {
                services: {
                    failed_count: $service_count,
                    status: (if $service_count == 0 { "healthy" } else { "issues" })
                }
            }
        } catch {
            { services: { error: "failed to check services" } }
        }
    } else {
        { services: { status: "not available" } }
    }
}

def collect_recent_activity [] {
    try {
        let git_activity = if (".git" | path exists) {
            (git log --oneline -5 | complete)
        } else {
            { stdout: "No git repository" }
        }
        
        {
            activity: {
                recent_commits: ($git_activity.stdout | lines | length),
                last_commit: ($git_activity.stdout | lines | get ?0 | default "none")
            }
        }
    } catch {
        { activity: { error: "failed to collect activity" } }
    }
}

def collect_detailed_hardware_info [] {
    let platform = (get_platform)
    
    let cpu_info = try {
        if $platform.is_linux {
            (cat /proc/cpuinfo | grep "model name" | head -1 | split column ":" | get column2 | str trim)
        } else {
            (sys cpu | get 0 | get brand)
        }
    } catch {
        "unknown"
    }
    
    {
        hardware: {
            cpu: $cpu_info,
            cpu_cores: (sys cpu | length)
        }
    }
}

def collect_network_info [] {
    try {
        let network_test = (ping -c 1 8.8.8.8 | complete)
        let connectivity = if $network_test.exit_code == 0 { "connected" } else { "disconnected" }
        
        {
            network: {
                connectivity: $connectivity,
                interfaces: (collect_network_interfaces)
            }
        }
    } catch {
        { network: { error: "failed to collect network info" } }
    }
}

def collect_network_interfaces [] {
    let platform = (get_platform)
    
    try {
        if $platform.is_linux {
            (ip link show | grep "state UP" | wc -l | into int)
        } else {
            1  # Default assumption
        }
    } catch {
        0
    }
}

def collect_process_info [] {
    try {
        let process_count = (ps | length)
        
        {
            processes: {
                total: $process_count,
                top_cpu: (collect_top_processes "cpu"),
                top_memory: (collect_top_processes "mem")
            }
        }
    } catch {
        { processes: { error: "failed to collect process info" } }
    }
}

def collect_top_processes [sort_by: string] {
    try {
        (ps | sort-by cpu | reverse | first 3 | get name)
    } catch {
        []
    }
}

def collect_environment_info [] {
    {
        environment: {
            shell: ($env | get SHELL? | default "unknown" | path basename),
            user: ($env | get USER? | default "unknown"),
            is_ci: (is_ci),
            is_docker: (is_docker),
            is_wsl: (is_wsl)
        }
    }
}

def collect_cpu_metrics [] {
    try {
        let cpu_usage = (sys cpu | get cpu_usage | math avg)
        
        {
            cpu_metrics: {
                usage_percent: ($cpu_usage | math round --precision 1),
                load_average: (collect_load_average)
            }
        }
    } catch {
        { cpu_metrics: { error: "failed to collect CPU metrics" } }
    }
}

def collect_load_average [] {
    let platform = (get_platform)
    
    try {
        if $platform.is_linux {
            (cat /proc/loadavg | split column " " | get column1 | into float)
        } else {
            0.0
        }
    } catch {
        0.0
    }
}

def collect_memory_metrics [] {
    try {
        let mem_info = (sys mem)
        let swap_info = (sys mem | get swap)
        
        {
            memory_metrics: {
                physical: {
                    total: ($mem_info.total | into string),
                    used: ($mem_info.used | into string),
                    free: ($mem_info.free | into string),
                    usage_percent: (($mem_info.used / $mem_info.total) * 100 | math round)
                },
                swap: {
                    total: ($swap_info.total | into string),
                    used: ($swap_info.used | into string),
                    usage_percent: (if $swap_info.total > 0 { 
                        ($swap_info.used / $swap_info.total) * 100 | math round 
                    } else { 
                        0 
                    })
                }
            }
        }
    } catch {
        { memory_metrics: { error: "failed to collect memory metrics" } }
    }
}

def collect_disk_metrics [] {
    try {
        let disk_info = (sys disks)
        
        {
            disk_metrics: {
                disks: ($disk_info | each { |disk|
                    {
                        name: $disk.name,
                        usage_percent: (($disk.used / $disk.total) * 100 | math round),
                        free: ($disk.free | into string),
                        total: ($disk.total | into string)
                    }
                })
            }
        }
    } catch {
        { disk_metrics: { error: "failed to collect disk metrics" } }
    }
}

def collect_network_metrics [] {
    {
        network_metrics: {
            connectivity_check: (test_network_connectivity)
        }
    }
}

def collect_nix_performance [] {
    try {
        let nix_store_size = try { 
            (run-external "du" "-sh" "/nix/store" | complete | get stdout | lines | get 0 | split column "\t" | get column1 | default "unknown")
        } catch { 
            "unknown" 
        }
        
        {
            nix_performance: {
                store_size: $nix_store_size,
                generations: (count_nix_generations)
            }
        }
    } catch {
        { nix_performance: { error: "failed to collect Nix performance data" } }
    }
}

def collect_test_results [] {
    let test_files = (glob "coverage-tmp/**/*test*.json" | default [])
    
    if ($test_files | length) > 0 {
        try {
            let latest_test = ($test_files | sort | last)
            let test_data = (open $latest_test | from json)
            
            {
                testing: {
                    last_run: ($test_data | get timestamp? | default "unknown"),
                    total_tests: ($test_data | get total? | default 0),
                    passed: ($test_data | get passed? | default 0),
                    failed: ($test_data | get failed? | default 0)
                }
            }
        } catch {
            { testing: { error: "failed to parse test results" } }
        }
    } else {
        { testing: { status: "no test results found" } }
    }
}

def collect_coverage_data [] {
    let coverage_files = (glob "coverage-tmp/**/*coverage*.json" | default [])
    
    if ($coverage_files | length) > 0 {
        try {
            let latest_coverage = ($coverage_files | sort | last)
            let coverage_data = (open $latest_coverage | from json)
            
            {
                coverage: {
                    percentage: ($coverage_data | get percentage? | default 0),
                    lines_covered: ($coverage_data | get lines_covered? | default 0),
                    total_lines: ($coverage_data | get total_lines? | default 0)
                }
            }
        } catch {
            { coverage: { error: "failed to parse coverage data" } }
        }
    } else {
        { coverage: { status: "no coverage data found" } }
    }
}

def collect_quality_metrics [] {
    {
        quality: {
            status: "quality metrics collection not implemented"
        }
    }
}

def collect_security_status [] {
    {
        security: {
            status: "security status collection not implemented"
        }
    }
}

def collect_vulnerability_scan [] {
    {
        vulnerabilities: {
            status: "vulnerability scanning not implemented"
        }
    }
}

def collect_audit_logs [] {
    {
        audit: {
            status: "audit log collection not implemented"
        }
    }
}

def collect_gpu_info [] {
    let platform = (get_platform)
    
    if $platform.is_linux {
        try {
            let gpu_info = (lspci | grep -i "vga\|3d\|display" | complete)
            let nvidia_smi = if (which nvidia-smi | is-not-empty) {
                (nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits | complete)
            } else {
                { stdout: "" }
            }
            
            {
                gaming: {
                    gpu_detected: ($gpu_info.exit_code == 0),
                    gpu_info: ($gpu_info.stdout | lines | get ?0 | default "unknown"),
                    nvidia_available: (which nvidia-smi | is-not-empty),
                    gpu_usage: ($nvidia_smi.stdout | default "not available")
                }
            }
        } catch {
            { gaming: { error: "failed to collect GPU info" } }
        }
    } else {
        { gaming: { status: "gaming metrics not available on this platform" } }
    }
}

def collect_gaming_services [] {
    let gaming_services = ["steam", "lutris", "gamescope"]
    let available = ($gaming_services | where {|service| which $service | is-not-empty })
    
    {
        gaming_services: {
            available: $available,
            count: ($available | length)
        }
    }
}

def collect_audio_status [] {
    let platform = (get_platform)
    
    if $platform.is_linux {
        let audio_systems = ["pulseaudio", "pipewire", "alsa"]
        let available = ($audio_systems | where {|system| which $system | is-not-empty })
        
        {
            audio: {
                systems_available: $available,
                primary: ($available | get ?0 | default "none")
            }
        }
    } else {
        { audio: { status: "audio status not available on this platform" } }
    }
}

def collect_controller_status [] {
    let platform = (get_platform)
    
    if $platform.is_linux {
        let controller_support = ("/dev/input" | path exists) and (which jstest | is-not-empty)
        
        {
            controllers: {
                support_available: $controller_support,
                devices: (if $controller_support {
                    try { (ls /dev/input/js* | length) } catch { 0 }
                } else { 0 })
            }
        }
    } else {
        { controllers: { status: "controller status not available on this platform" } }
    }
}

def collect_package_analysis [] {
    {
        packages: {
            status: "package analysis not implemented"
        }
    }
}

def collect_size_analysis [] {
    try {
        let nix_store_size = try { 
            (run-external "du" "-sh" "/nix/store" | complete | get stdout | lines | get 0 | split column "\t" | get column1 | default "unknown")
        } catch { 
            "unknown" 
        }
        
        {
            sizes: {
                nix_store: $nix_store_size,
                current_generation: "calculation not implemented"
            }
        }
    } catch {
        { sizes: { error: "failed to collect size analysis" } }
    }
}

def collect_dependency_analysis [] {
    {
        dependencies: {
            status: "dependency analysis not implemented"
        }
    }
}

def collect_performance_analysis [] {
    {
        performance_analysis: {
            status: "performance analysis not implemented"
        }
    }
}

# Helper functions
def check_nix_store_health [] {
    try {
        let store_check = (nix store ping | complete)
        if $store_check.exit_code == 0 { "healthy" } else { "unhealthy" }
    } catch {
        "error"
    }
}

def test_network_connectivity [] {
    try {
        let ping_result = (ping -c 1 -W 3 8.8.8.8 | complete)
        if $ping_result.exit_code == 0 { "connected" } else { "disconnected" }
    } catch {
        "error"
    }
}

def count_nix_generations [] {
    try {
        let generations = (nix-env --list-generations | complete)
        if $generations.exit_code == 0 {
            ($generations.stdout | lines | length)
        } else {
            0
        }
    } catch {
        0
    }
}

# Display functions with compact table format
def display_overview [data: record, format: string] {
    print "nix-mox overview"
    print "================"
    print ""
    
    # Collect all overview statistics
    mut stats = []
    
    # System info
    if "system" in $data {
        let sys = ($data | get system)
        $stats = ($stats | append {metric: "platform", value: $"($sys.platform) ($sys.architecture)"})
        $stats = ($stats | append {metric: "hostname", value: $sys.hostname})
        $stats = ($stats | append {metric: "uptime", value: $sys.uptime})
    }
    
    # Nix status
    if "nix" in $data {
        let nix = ($data | get nix)
        $stats = ($stats | append {metric: "nix", value: $nix.version})
        $stats = ($stats | append {metric: "flake", value: $nix.flake_status})
        $stats = ($stats | append {metric: "store", value: $nix.store_health})
    }
    
    # Resource usage
    if "disk" in $data and "memory" in $data {
        let disk = ($data | get disk)
        let memory = ($data | get memory)
        $stats = ($stats | append {metric: "disk", value: ($disk | get root_used? | default 'unknown')})
        $stats = ($stats | append {metric: "memory", value: $"($memory | get usage_percent? | default 'unknown')%"})
    }
    
    # Services
    if "services" in $data {
        let services = ($data | get services)
        $stats = ($stats | append {metric: "services", value: $services.status})
    }
    
    # Activity
    if "activity" in $data {
        let activity = ($data | get activity)
        $stats = ($stats | append {metric: "commits", value: $"($activity.recent_commits) recent"})
        $stats = ($stats | append {metric: "last-commit", value: $activity.last_commit})
    }
    
    # Print compact table
    if ($stats | length) > 0 {
        for stat in $stats {
            print $"($stat.metric | fill -a l -w 12) : ($stat.value)"
        }
    }
}

def display_system [data: record, format: string] {
    print "=== System Information ==="
    print ""
    print ($data | to yaml)
}

def display_performance [data: record, format: string] {
    print "=== Performance Metrics ==="
    print ""
    print ($data | to yaml)
}

def display_testing [data: record, format: string] {
    print "=== Testing Dashboard ==="
    print ""
    print ($data | to yaml)
}

def display_coverage [data: record, format: string] {
    banner "nix-mox Coverage Dashboard" --context "coverage"
    print ""
    
    if "error" in $data {
        error $"Coverage collection failed: ($data.error)" --context "coverage"
        return
    }
    
    # Display coverage summary
    section "Coverage Summary" --context "coverage"
    
    let coverage_pct = ($data.coverage.summary.coverage_percentage | default 0)
    let files_analyzed = ($data.coverage.summary.files_analyzed | default 0)
    
    # Coverage status with color coding
    let coverage_status = if $coverage_pct >= 80 { 
        $"✅ ($coverage_pct)% (Excellent)" 
    } else if $coverage_pct >= 60 { 
        $"⚠️  ($coverage_pct)% (Good)" 
    } else if $coverage_pct >= 40 { 
        $"⚠️  ($coverage_pct)% (Needs Improvement)" 
    } else { 
        $"❌ ($coverage_pct)% (Poor)" 
    }
    
    info $"Overall Coverage: ($coverage_status)" --context "coverage"
    info $"Files Analyzed: ($files_analyzed)" --context "coverage"
    
    # Test metrics
    section "Test Metrics" --context "coverage"
    info $"Test Files: ($data.metrics.test_files)" --context "coverage"
    info $"Library Files: ($data.metrics.lib_files)" --context "coverage"
    info $"Test-to-Library Ratio: ($data.metrics.coverage_ratio)%" --context "coverage"
    
    # Report availability
    section "Available Reports" --context "coverage"
    let lcov_status = if $data.reports.lcov_available { "✅ Available" } else { "❌ Not Generated" }
    let json_status = if $data.reports.json_available { "✅ Available" } else { "❌ Not Generated" }
    let html_status = if $data.reports.html_available { "✅ Available" } else { "❌ Not Generated" }
    
    info $"LCOV Report: ($lcov_status)" --context "coverage"
    info $"JSON Report: ($json_status)" --context "coverage" 
    info $"HTML Report: ($html_status)" --context "coverage"
    
    # Coverage generation status
    section "Generation Status" --context "coverage"
    let lcov_gen = if $data.metrics.lcov_status { "✅ Success" } else { "❌ Failed" }
    let json_gen = if $data.metrics.json_status { "✅ Success" } else { "❌ Failed" }
    
    info $"LCOV Generation: ($lcov_gen)" --context "coverage"
    info $"JSON Generation: ($json_gen)" --context "coverage"
    
    # Show file coverage details if available
    if "files" in $data.coverage {
        section "File Coverage Details" --context "coverage"
        
        let low_coverage = ($data.coverage.files | where { |file|
            ("error" not in $file) and ($file.lines.coverage_percentage < 60)
        })
        
        if ($low_coverage | length) > 0 {
            warn "Files with low coverage (<60%):" --context "coverage"
            for file in $low_coverage {
                warn $"  ($file.file): ($file.lines.coverage_percentage)%" --context "coverage"
            }
        } else {
            success "All files have good coverage!" --context "coverage"
        }
    }
    
    # Usage instructions
    section "Coverage Reports" --context "coverage"
    info "To generate fresh coverage reports:" --context "coverage"
    info "  nu coverage.nu lcov     - Generate LCOV report" --context "coverage"
    info "  nu coverage.nu html     - Generate HTML report" --context "coverage"
    info "  nu coverage.nu all      - Generate all formats" --context "coverage"
    
    if $data.reports.html_available {
        success "View HTML report: open coverage-tmp/html/index.html" --context "coverage"
    }
}

def display_security [data: record, format: string] {
    print "=== Security Dashboard ==="
    print ""
    print ($data | to yaml)
}

def display_gaming [data: record, format: string] {
    print "=== Gaming Dashboard ==="
    print ""
    print ($data | to yaml)
}

def display_analysis [data: record, format: string] {
    # Use the improved analysis report formatting from analysis.nu
    use lib/analysis.nu render_analysis_dashboard
    
    render_analysis_dashboard $data $format
}

def save_dashboard_data [data: record, output_path: string] {
    try {
        $data | to json | save $output_path
        info $"Dashboard data saved: ($output_path)" --context "dashboard"
    } catch { |err|
        error $"Failed to save dashboard data: ($err.msg)" --context "dashboard"
    }
}

# Size analysis dashboard - package and store size analysis
def size_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_size_analysis_data)
    
    if $watch {
        loop {
            clear
            display_size_analysis $data $format
            sleep ($refresh | into duration --unit sec)
            let data = (collect_size_analysis_data)
        }
    } else {
        display_size_analysis $data $format
        if $output != "" {
            save_dashboard_data $data $output $format
        }
    }
}

# Project status dashboard - git, flake, and development status
def project_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_project_status_data)
    
    if $watch {
        loop {
            clear
            display_project_status $data $format
            sleep ($refresh | into duration --unit sec)
            let data = (collect_project_status_data)
        }
    } else {
        display_project_status $data $format
        if $output != "" {
            save_dashboard_data $data $output $format
        }
    }
}

# Quick status dashboard - minimal non-interactive status check
def quick_status_dashboard [] {
    let system_info = (collect_basic_system_info)
    let nix_status = (collect_nix_status)
    let disk_usage = (collect_disk_usage)
    
    print "🚀 nix-mox Quick Status"
    print "======================="
    print $"System: (($system_info.basic_system.hostname) // 'unknown')"
    print $"Uptime: (($system_info.basic_system.uptime) // 'unknown')"
    print $"Nix Generations: (($nix_status.nix_status.generations) // 'unknown')"
    print $"Disk Usage: (($disk_usage.disk_usage | each { |d| $"($d.mount): ($d.usage_percent)%" } | str join ', ') // 'unknown')"
    print ""
}

# Collect size analysis data
def collect_size_analysis_data [] {
    collect_data "collect_size_analysis" "collect_package_analysis" "collect_dependency_analysis"
}

# Collect project status data  
def collect_project_status_data [] {
    let git_status = try {
        let status = (run-external "git" "status" "--porcelain" | complete)
        let branch = (run-external "git" "branch" "--show-current" | complete | get stdout | str trim)
        let commits_ahead = (run-external "git" "rev-list" "--count" "origin/main..HEAD" | complete | get stdout | str trim)
        
        {
            branch: $branch,
            modified_files: ($status.stdout | lines | where { |l| $l | str starts-with " M" } | length),
            untracked_files: ($status.stdout | lines | where { |l| $l | str starts-with "??" } | length),
            commits_ahead: $commits_ahead
        }
    } catch {
        { branch: "unknown", modified_files: 0, untracked_files: 0, commits_ahead: 0 }
    }
    
    let flake_status = try {
        let flake_check = (run-external "nix" "flake" "check" "--no-build" | complete)
        { valid: ($flake_check.exit_code == 0) }
    } catch {
        { valid: false }
    }
    
    {
        project_status: {
            git: $git_status,
            flake: $flake_status,
            timestamp: (date now | format date "%Y-%m-%d %H:%M:%S")
        }
    }
}

# Display size analysis
def display_size_analysis [data: record, format: string] {
    if $format == "json" {
        $data | to json --indent 2
    } else {
        print "📊 Package Size Analysis"
        print "========================"
        
        if "size_analysis" in $data {
            let analysis = $data.size_analysis
            if "largest_packages" in $analysis {
                print "\n📦 Largest Packages:"
                $analysis.largest_packages | each { |pkg|
                    print $"  • ($pkg.name): ($pkg.size)"
                }
            }
        }
        
        if "dependency_analysis" in $data {
            print "\n🔗 Dependencies:"
            let deps = $data.dependency_analysis
            if "total_dependencies" in $deps {
                print $"  Total: ($deps.total_dependencies)"
            }
        }
    }
}

# Display project status
def display_project_status [data: record, format: string] {
    if $format == "json" {
        $data | to json --indent 2
    } else {
        print "📁 Project Status Dashboard"
        print "==========================="
        
        if "project_status" in $data {
            let status = $data.project_status
            
            if "git" in $status {
                print "\n🔀 Git Status:"
                print $"  Branch: ($status.git.branch)"
                print $"  Modified: ($status.git.modified_files) files"
                print $"  Untracked: ($status.git.untracked_files) files"
                print $"  Commits ahead: ($status.git.commits_ahead)"
            }
            
            if "flake" in $status {
                print "\n❄️  Flake Status:"
                print $"  Valid: (if $status.flake.valid { '✅' } else { '❌' })"
            }
            
            print $"\n⏰ Last Updated: ($status.timestamp)"
        }
    }
}

def show_dashboard_help [] {
    format_help "nix-mox dashboard" "Functional dashboard and analysis system" "nu dashboard.nu <view> [options]" [
        { name: "overview", description: "High-level system overview (default)" }
        { name: "system", description: "Detailed system information" }
        { name: "performance", description: "Performance metrics and analysis" }
        { name: "testing", description: "Test results and coverage" }
        { name: "coverage", description: "Dedicated test coverage dashboard" }
        { name: "security", description: "Security status and threats" }
        { name: "gaming", description: "Gaming system status" }
        { name: "analysis", description: "Comprehensive system analysis" }
        { name: "size", description: "Package and store size analysis" }
        { name: "project", description: "Project and git status" }
        { name: "quick", description: "Quick non-interactive status check" }
    ] [
        { name: "refresh", description: "Refresh interval in seconds (default: 5)" }
        { name: "output", description: "Save data to JSON file" }
        { name: "format", description: "Output format (terminal, json, yaml)" }
        { name: "watch", description: "Continuous monitoring mode" }
        { name: "verbose", description: "Enable verbose output" }
    ] [
        { command: "nu dashboard.nu overview", description: "Show system overview" }
        { command: "nu dashboard.nu performance --watch", description: "Monitor performance continuously" }
        { command: "nu dashboard.nu system --output system-report.json", description: "Generate system report" }
    ]
}

# If script is run directly, call main with arguments
# Note: Direct execution not supported in Nushell 0.104.0+
# Use: nu dashboard.nu <view> [options] instead