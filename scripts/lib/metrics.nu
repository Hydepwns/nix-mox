#!/usr/bin/env nu

# Real-time metrics collection for nix-mox
# Prometheus-compatible metrics exporter

use logging.nu *
use performance.nu *
use error-handling.nu *

# Global metrics state
mut $METRICS_STATE = {
    enabled: false,
    port: 9200,
    endpoint: "/metrics",
    update_interval: 30,
    collectors: []
}

# Metric types
export def create_counter [name: string, help: string, labels: record = {}] {
    {
        type: "counter",
        name: $name,
        help: $help,
        labels: $labels,
        value: 0,
        created_at: (date now | into int)
    }
}

export def create_gauge [name: string, help: string, labels: record = {}] {
    {
        type: "gauge", 
        name: $name,
        help: $help,
        labels: $labels,
        value: 0,
        updated_at: (date now | into int)
    }
}

export def create_histogram [name: string, help: string, buckets: list = [0.1, 0.5, 1.0, 2.5, 5.0, 10.0]] {
    {
        type: "histogram",
        name: $name,
        help: $help,
        buckets: $buckets,
        counts: ($buckets | each { 0 }),
        sum: 0,
        count: 0,
        created_at: (date now | into int)
    }
}

# Core nix-mox metrics
export def init_core_metrics [] {
    let metrics = [
        (create_counter "nix_mox_script_executions_total" "Total number of script executions" {script: "unknown"}),
        (create_counter "nix_mox_script_failures_total" "Total number of script failures" {script: "unknown", error_type: "unknown"}),
        (create_histogram "nix_mox_script_duration_seconds" "Script execution duration in seconds"),
        (create_gauge "nix_mox_memory_usage_percent" "Memory usage percentage"),
        (create_gauge "nix_mox_cpu_usage_percent" "CPU usage percentage"),
        (create_gauge "nix_mox_disk_usage_percent" "Disk usage percentage"),
        (create_counter "nix_mox_errors_total" "Total errors by type" {type: "unknown"}),
        (create_counter "nix_mox_security_threats_total" "Security threats detected"),
        (create_counter "nix_mox_security_scans_total" "Security scans performed"),
        (create_counter "nix_mox_security_validations_total" "Security validations performed"),
        (create_gauge "nix_mox_test_suite_success_rate" "Test suite success rate"),
        (create_counter "nix_mox_config_validation_failures_total" "Configuration validation failures"),
        (create_counter "nix_mox_platform_errors_total" "Platform-specific errors" {platform: "unknown"})
    ]
    
    $METRICS_STATE.collectors = $metrics
    log "INFO" "Initialized nix-mox core metrics"
}

# Increment counter
export def increment_counter [name: string, labels: record = {}, value: int = 1] {
    let metric_index = ($METRICS_STATE.collectors | enumerate | where {|m| $m.item.name == $name and $m.item.labels == $labels} | get 0?.index)
    
    if $metric_index != null {
        $METRICS_STATE.collectors = ($METRICS_STATE.collectors | update $metric_index {|m| $m | update value ($m.value + $value)})
    } else {
        log "WARN" $"Metric not found: ($name) with labels ($labels)"
    }
}

# Set gauge value
export def set_gauge [name: string, value: float, labels: record = {}] {
    let metric_index = ($METRICS_STATE.collectors | enumerate | where {|m| $m.item.name == $name and $m.item.labels == $labels} | get 0?.index)
    
    if $metric_index != null {
        $METRICS_STATE.collectors = ($METRICS_STATE.collectors | update $metric_index {|m| 
            $m | update value $value | update updated_at (date now | into int)
        })
    } else {
        log "WARN" $"Gauge not found: ($name) with labels ($labels)"
    }
}

# Record histogram observation
export def observe_histogram [name: string, value: float] {
    let metric_index = ($METRICS_STATE.collectors | enumerate | where {|m| $m.item.name == $name} | get 0?.index)
    
    if $metric_index != null {
        let metric = ($METRICS_STATE.collectors | get $metric_index)
        let updated_metric = ($metric | update count ($metric.count + 1) | update sum ($metric.sum + $value))
        
        # Update bucket counts
        let updated_counts = ($metric.buckets | enumerate | each {|bucket|
            if $value <= $bucket.item {
                ($metric.counts | get $bucket.index) + 1
            } else {
                $metric.counts | get $bucket.index
            }
        })
        
        $METRICS_STATE.collectors = ($METRICS_STATE.collectors | update $metric_index ($updated_metric | update counts $updated_counts))
    }
}

# Real-time system metrics collection
export def collect_system_metrics [] {
    try {
        # Memory usage
        let memory_info = (sys mem)
        let memory_percent = (($memory_info.used | into float) / ($memory_info.total | into float)) * 100
        set_gauge "nix_mox_memory_usage_percent" $memory_percent
        
        # CPU usage (approximate)
        let cpu_info = (sys cpu | get 0)
        set_gauge "nix_mox_cpu_usage_percent" $cpu_info.cpu_usage
        
        # Disk usage
        let disk_info = (sys disks | get 0)
        let disk_percent = (($disk_info.used | into float) / ($disk_info.total | into float)) * 100
        set_gauge "nix_mox_disk_usage_percent" $disk_percent
        
        log "DEBUG" "Collected system metrics"
    } catch {
        log "WARN" "Failed to collect system metrics"
    }
}

# Script execution tracking
export def track_script_execution [script_name: string, duration: float, success: bool] {
    increment_counter "nix_mox_script_executions_total" {script: $script_name}
    observe_histogram "nix_mox_script_duration_seconds" $duration
    
    if not $success {
        increment_counter "nix_mox_script_failures_total" {script: $script_name}
    }
    
    log "DEBUG" $"Tracked script execution: ($script_name), duration: ($duration)s, success: ($success)"
}

# Error tracking integration
export def track_error [error_type: string, platform: string = "unknown"] {
    increment_counter "nix_mox_errors_total" {type: $error_type}
    
    if $platform != "unknown" {
        increment_counter "nix_mox_platform_errors_total" {platform: $platform}
    }
    
    log "DEBUG" $"Tracked error: ($error_type) on platform: ($platform)"
}

# Security metrics tracking
export def track_security_event [event_type: string] {
    match $event_type {
        "threat" => { increment_counter "nix_mox_security_threats_total" }
        "scan" => { increment_counter "nix_mox_security_scans_total" }
        "validation" => { increment_counter "nix_mox_security_validations_total" }
        _ => { log "WARN" $"Unknown security event type: ($event_type)" }
    }
}

# Test suite metrics
export def track_test_results [total: int, passed: int] {
    let success_rate = ($passed | into float) / ($total | into float)
    set_gauge "nix_mox_test_suite_success_rate" $success_rate
    log "DEBUG" $"Tracked test results: ($passed)/($total) = ($success_rate * 100)%"
}

# Configuration validation tracking
export def track_config_validation_failure [] {
    increment_counter "nix_mox_config_validation_failures_total"
}

# Prometheus format export
export def format_prometheus_metrics [] {
    let timestamp = (date now | into int)
    mut output = ""
    
    for metric in $METRICS_STATE.collectors {
        $output = $output + $"# HELP ($metric.name) ($metric.help)\n"
        $output = $output + $"# TYPE ($metric.name) ($metric.type)\n"
        
        match $metric.type {
            "counter" | "gauge" => {
                let labels_str = if ($metric.labels | is-empty) { "" } else {
                    let label_pairs = ($metric.labels | transpose key value | each {|l| $"($l.key)=\"($l.value)\""} | str join ",")
                    $"{($label_pairs)}"
                }
                $output = $output + $"($metric.name){($labels_str)} ($metric.value) ($timestamp)\n"
            }
            "histogram" => {
                # Bucket metrics
                for i in (seq 0 (($metric.buckets | length) - 1)) {
                    let bucket_value = ($metric.buckets | get $i)
                    let bucket_count = ($metric.counts | get $i)
                    $output = $output + $"($metric.name)_bucket{le=\"($bucket_value)\"} ($bucket_count) ($timestamp)\n"
                }
                # +Inf bucket
                $output = $output + $"($metric.name)_bucket{le=\"+Inf\"} ($metric.count) ($timestamp)\n"
                # Sum and count
                $output = $output + $"($metric.name)_sum ($metric.sum) ($timestamp)\n"
                $output = $output + $"($metric.name)_count ($metric.count) ($timestamp)\n"
            }
        }
        $output = $output + "\n"
    }
    
    $output
}

# HTTP metrics server
export def start_metrics_server [port: int = 9200] {
    $METRICS_STATE.enabled = true
    $METRICS_STATE.port = $port
    
    log "INFO" $"Starting metrics server on port ($port)"
    
    # This would need a proper HTTP server implementation
    # For now, we'll create a file-based export
    export_metrics_to_file
}

# File-based metrics export (fallback)
export def export_metrics_to_file [file_path: string = "/tmp/nix-mox-metrics.prom"] {
    let metrics_content = format_prometheus_metrics
    $metrics_content | save --force $file_path
    log "INFO" $"Exported metrics to ($file_path)"
}

# Background metrics collection daemon
export def start_metrics_collection [] {
    init_core_metrics
    
    log "INFO" "Starting background metrics collection"
    
    # Collect system metrics every 30 seconds
    while $METRICS_STATE.enabled {
        collect_system_metrics
        export_metrics_to_file
        sleep ($METRICS_STATE.update_interval)sec
    }
}

# Stop metrics collection
export def stop_metrics_collection [] {
    $METRICS_STATE.enabled = false
    log "INFO" "Stopped metrics collection"
}

# Get current metrics summary
export def get_metrics_summary [] {
    {
        enabled: $METRICS_STATE.enabled,
        port: $METRICS_STATE.port,
        collectors_count: ($METRICS_STATE.collectors | length),
        last_export: (if ("/tmp/nix-mox-metrics.prom" | path exists) { 
            (ls "/tmp/nix-mox-metrics.prom" | get 0.modified) 
        } else { 
            "never" 
        })
    }
}

# Integration helpers for existing modules
export def wrap_script_with_metrics [script_name: string, script_block: closure] {
    let start_time = (date now | into int)
    
    let result = try {
        do $script_block
        {success: true, error: null}
    } catch {|err|
        {success: false, error: $err}
    }
    
    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000
    
    track_script_execution $script_name $duration $result.success
    
    if not $result.success {
        track_error "EXECUTION" (detect_platform)
        error $result.error
    }
    
    log "INFO" $"Script ($script_name) completed in ($duration)s, success: ($result.success)"
}

# Auto-initialization
if ($env | get -i NIX_MOX_METRICS_ENABLED | default "false") == "true" {
    init_core_metrics
}