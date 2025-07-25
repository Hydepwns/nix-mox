# performance.nu - Performance monitoring module for nix-mox scripts
# Tracks execution times, resource usage, and provides performance analytics
use ./common.nu
use ./logging.nu

# Performance metrics storage
export const PERFORMANCE_METRICS = {
    operations: []
    resource_usage: []
    thresholds: {
        slow_operation: 30  # seconds
        high_memory: 80     # percentage
        high_cpu: 80        # percentage
    }
}

# Start performance monitoring for an operation
export def start_performance_monitor [operation: string, context: record = {}] {
    let start_time = (date now)
    let start_memory = (sys | get mem.used)
    let start_cpu = (sys | get cpu.usage_percent)
    let monitor_id = (random uuid)

    let monitor_data = {
        id: $monitor_id
        operation: $operation
        start_time: $start_time
        start_memory: $start_memory
        start_cpu: $start_cpu
        context: $context
        status: "running"
    }

    # Store monitor data
    $env.PERFORMANCE_MONITOR = $monitor_data

    let debug_context = {
        operation: $operation
        monitor_id: $monitor_id
        context: $context
    }

    logging::debug "Performance monitoring started" $debug_context
    $monitor_id
}

# End performance monitoring and calculate metrics
export def end_performance_monitor [monitor_id: string] {
    if ($env.PERFORMANCE_MONITOR | is-empty) {
        log_warn "No performance monitor found to end"
        return null
    }

    let monitor_data = $env.PERFORMANCE_MONITOR
    let end_time = (date now)
    let end_memory = (sys | get mem.used)
    let end_cpu = (sys | get cpu.usage_percent)

    # Calculate durations
    let duration = (($end_time | into datetime) - ($monitor_data.start_time | into datetime) | into duration)
    let duration_sec = ($duration | into int | into float) / 1000.0

    # Calculate resource usage
    let memory_delta = $end_memory - $monitor_data.start_memory
    let cpu_avg = (($monitor_data.start_cpu + $end_cpu) / 2)

    # Create performance metrics
    let metrics = {
        id: $monitor_id
        operation: $monitor_data.operation
        start_time: $monitor_data.start_time
        end_time: $end_time
        duration: $duration
        duration_seconds: $duration_sec
        memory_start: $monitor_data.start_memory
        memory_end: $end_memory
        memory_delta: $memory_delta
        cpu_start: $monitor_data.start_cpu
        cpu_end: $end_cpu
        cpu_average: $cpu_avg
        context: $monitor_data.context
        status: "completed"
    }

    # Log performance metrics
    log_performance $monitor_data.operation $duration {
        monitor_id: $monitor_id
        memory_delta: $memory_delta
        cpu_average: $cpu_avg
        context: $monitor_data.context
    }

    # Check for performance issues
    check_performance_issues $metrics

    # Store metrics for analysis
    store_performance_metrics $metrics

    # Clear monitor data
    $env.PERFORMANCE_MONITOR = null

    $metrics
}

# Check for performance issues and alert
export def check_performance_issues [metrics: record] {
    let thresholds = $PERFORMANCE_METRICS.thresholds

    # Check for slow operations
    if $metrics.duration_seconds > $thresholds.slow_operation {
        log_warn "Slow operation detected" {
            operation: $metrics.operation
            duration: $metrics.duration
            threshold: $"($thresholds.slow_operation)s"
            monitor_id: $metrics.id
        }
    }

    # Check for high memory usage
    let memory_percent = ($metrics.memory_end / (sys | get mem.total) * 100)
    if $memory_percent > $thresholds.high_memory {
        log_warn "High memory usage detected" {
            operation: $metrics.operation
            memory_percent: $memory_percent
            threshold: $"($thresholds.high_memory)%"
            monitor_id: $metrics.id
        }
    }

    # Check for high CPU usage
    if $metrics.cpu_average > $thresholds.high_cpu {
        log_warn "High CPU usage detected" {
            operation: $metrics.operation
            cpu_average: $metrics.cpu_average
            threshold: $"($thresholds.high_cpu)%"
            monitor_id: $metrics.id
        }
    }
}

# Store performance metrics for analysis
export def store_performance_metrics [metrics: record] {
    let metrics_file = ($env.PERFORMANCE_METRICS_FILE | default "logs/performance.json")

    # Ensure directory exists
    let metrics_dir = ($metrics_file | path dirname)
    if not ($metrics_dir | path exists) {
        mkdir $metrics_dir
    }

    # Append metrics to file
    try {
        $metrics | to json | save --append $metrics_file
    } catch { |err|
        log_error "Failed to store performance metrics" {
            error: $err
            metrics_file: $metrics_file
        }
    }
}

# Get performance statistics
export def get_performance_stats [metrics_file: string = "logs/performance.json"] {
    if not ($metrics_file | path exists) {
        return {
            total_operations: 0
            average_duration: 0
            slow_operations: 0
            memory_usage: { average: 0, peak: 0 }
            cpu_usage: { average: 0, peak: 0 }
        }
    }

    try {
        let metrics = (open $metrics_file | lines | each { |line| $line | from json })

        if ($metrics | length) == 0 {
            return {
                total_operations: 0
                average_duration: 0
                slow_operations: 0
                memory_usage: { average: 0, peak: 0 }
                cpu_usage: { average: 0, peak: 0 }
            }
        }

        # Calculate statistics
        let total_operations = ($metrics | length)
        let average_duration = ($metrics | get duration_seconds | math avg)
        let slow_operations = ($metrics | where duration_seconds > $PERFORMANCE_METRICS.thresholds.slow_operation | length)
        let memory_average = ($metrics | get memory_end | math avg)
        let memory_peak = ($metrics | get memory_end | math max)
        let cpu_average = ($metrics | get cpu_average | math avg)
        let cpu_peak = ($metrics | get cpu_average | math max)

        {
            total_operations: $total_operations
            average_duration: $average_duration
            slow_operations: $slow_operations
            memory_usage: { average: $memory_average, peak: $memory_peak }
            cpu_usage: { average: $cpu_average, peak: $cpu_peak }
        }
    } catch { |err|
        log_error "Failed to get performance stats" {
            error: $err
            metrics_file: $metrics_file
        }
        {
            total_operations: 0
            average_duration: 0
            slow_operations: 0
            memory_usage: { average: 0, peak: 0 }
            cpu_usage: { average: 0, peak: 0 }
        }
    }
}

# Get performance report for specific operation
export def get_operation_performance [operation: string, metrics_file: string = "logs/performance.json"] {
    if not ($metrics_file | path exists) {
        return null
    }

    try {
        let metrics = (open $metrics_file | lines | each { |line| $line | from json })
        let operation_metrics = ($metrics | where operation == $operation)

        if ($operation_metrics | length) == 0 {
            return null
        }

        let total_runs = ($operation_metrics | length)
        let average_duration = ($operation_metrics | get duration_seconds | math avg)
        let min_duration = ($operation_metrics | get duration_seconds | math min)
        let max_duration = ($operation_metrics | get duration_seconds | math max)
        let average_memory = ($operation_metrics | get memory_end | math avg)
        let average_cpu = ($operation_metrics | get cpu_average | math avg)

        {
            operation: $operation
            total_runs: $total_runs
            duration: { average: $average_duration, min: $min_duration, max: $max_duration }
            memory: { average: $average_memory }
            cpu: { average: $average_cpu }
            recent_runs: ($operation_metrics | last 5)
        }
    } catch { |err|
        log_error "Failed to get operation performance" {
            error: $err
            operation: $operation
            metrics_file: $metrics_file
        }
        null
    }
}

# Clean old performance metrics
export def clean_performance_metrics [days: int = 30, metrics_file: string = "logs/performance.json"] {
    if not ($metrics_file | path exists) {
        return
    }

    try {
        let cutoff_date = ((date now) - ($days * 24hr))
        let metrics = (open $metrics_file | lines | each { |line| $line | from json })
        let recent_metrics = ($metrics | where { |metric|
            let metric_date = ($metric.start_time | into datetime)
            $metric_date > $cutoff_date
        })

        # Save filtered metrics back
        $recent_metrics | each { |metric| $metric | to json } | save $metrics_file

        let removed_count = ($metrics | length) - ($recent_metrics | length)
        log_info "Cleaned performance metrics" {
            removed_count: $removed_count
            days: $days
            remaining_count: ($recent_metrics | length)
        }
    } catch { |err|
        log_error "Failed to clean performance metrics" {
            error: $err
            metrics_file: $metrics_file
        }
    }
}

# Performance decorator for functions
export def measure_performance [operation: string, context: record = {}] {
    # Simplified performance monitoring - just return the operation name
    # Users can wrap their functions manually with start/end monitoring
    $operation
}

# Get system resource usage
export def get_system_resources [] {
    let memory = (sys | get mem)
    let cpu = (sys | get cpu)
    let disk = (df | where filesystem =~ "/" | get used_pct.0 | into float)

    {
        memory: {
            total: $memory.total
            used: $memory.used
            available: $memory.available
            used_percent: (($memory.used / $memory.total) * 100)
        }
        cpu: {
            usage_percent: $cpu.usage_percent
            count: $cpu.count
        }
        disk: {
            used_percent: $disk
        }
        timestamp: (date now)
    }
}

# Monitor system resources over time
export def monitor_system_resources [duration: duration, interval: duration = 1sec] {
    let end_time = ((date now) + $duration)
    mut resources = []

    while ((date now) < $end_time) {
        let resource_data = (get_system_resources)
        $resources = ($resources | append $resource_data)
        sleep $interval
    }

    $resources
}

# Generate performance report
export def generate_performance_report [output_file: string = "logs/performance-report.json"] {
    let stats = (get_performance_stats)
    let system_resources = (get_system_resources)
    let report = {
        generated_at: (date now)
        summary: $stats
        system_resources: $system_resources
        recommendations: (generate_performance_recommendations $stats)
    }

    try {
        $report | to json | save $output_file
        log_info "Performance report generated" { output_file: $output_file }
        $report
    } catch { |err|
        log_error "Failed to generate performance report" { error: $err }
        null
    }
}

# Generate performance recommendations
export def generate_performance_recommendations [stats: record] {
    mut recommendations = []

    if $stats.average_duration > 10 {
        $recommendations = ($recommendations | append "Consider optimizing slow operations")
    }

    if $stats.slow_operations > 0 {
        $recommendations = ($recommendations | append "Review and optimize slow operations")
    }

    if $stats.memory_usage.average > 70 {
        $recommendations = ($recommendations | append "Monitor memory usage and consider optimization")
    }

    if $stats.cpu_usage.average > 70 {
        $recommendations = ($recommendations | append "Consider parallelization or resource scaling")
    }

    if ($recommendations | length) == 0 {
        $recommendations = ($recommendations | append "Performance is within acceptable ranges")
    }

    $recommendations
}
