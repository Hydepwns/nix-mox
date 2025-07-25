# nix-mox API Reference

> Complete function documentation for all nix-mox modules

## 🎯 Overview

This API reference covers all exported functions from the nix-mox library modules:
- **Core Functions** - Essential system operations
- **Platform Detection** - Cross-platform compatibility  
- **Configuration Management** - Settings and preferences
- **Error Handling** - Structured error management
- **Performance Monitoring** - Metrics and optimization
- **Security Validation** - Threat detection and prevention
- **Logging System** - Structured logging with levels

## 📚 Core Modules API

### platform.nu - Platform Detection & Management

#### `detect_platform() -> string`
Detects the current operating system platform.

**Returns:** Platform identifier (`"linux"`, `"darwin"`, `"windows"`)

**Example:**
```nu
let platform = detect_platform
print $"Running on: ($platform)"
```

---

#### `get_platform_info() -> record`
Returns detailed platform information including OS version, architecture, and capabilities.

**Returns:** Record with platform details
```nu
{
    platform: string,      # Platform identifier
    os_version: string,     # OS version string
    architecture: string,   # CPU architecture
    kernel_version: string, # Kernel version (Linux/macOS)
    capabilities: list      # Platform-specific features
}
```

**Example:**
```nu
let info = get_platform_info
print $"OS: ($info.platform) ($info.os_version)"
print $"Arch: ($info.architecture)"
```

---

#### `is_linux() -> bool`
Returns true if running on Linux.

**Example:**
```nu
if is_linux {
    print "Configuring Linux-specific features"
}
```

---

#### `is_macos() -> bool`
Returns true if running on macOS/Darwin.

---

#### `is_windows() -> bool`  
Returns true if running on Windows.

---

#### `get_cpu_info() -> record`
Returns detailed CPU information.

**Returns:**
```nu
{
    model: string,          # CPU model name
    cores: int,            # Number of physical cores
    threads: int,          # Number of logical threads
    architecture: string,   # CPU architecture
    features: list         # Supported CPU features
}
```

---

#### `get_memory_info() -> record`
Returns system memory information.

**Returns:**
```nu
{
    total: int,            # Total RAM in bytes
    available: int,        # Available RAM in bytes
    usage_percent: float   # Memory usage percentage
}
```

### logging.nu - Structured Logging System

#### `log_info(message: string) -> null`
Logs an informational message.

**Parameters:**
- `message`: The message to log

**Example:**
```nu
log_info "System initialization completed"
```

---

#### `log_warn(message: string) -> null`
Logs a warning message.

**Example:**
```nu
log_warn "Configuration file not found, using defaults"
```

---

#### `log_error(message: string) -> null`
Logs an error message.

**Example:**
```nu
log_error "Failed to connect to database"
```

---

#### `log_debug(message: string) -> null`
Logs a debug message (only shown when debug logging is enabled).

**Example:**
```nu
log_debug "Processing configuration file: config.toml"
```

---

#### `set_log_level(level: string) -> null`
Sets the global logging level.

**Parameters:**
- `level`: Logging level (`"DEBUG"`, `"INFO"`, `"WARN"`, `"ERROR"`)

**Example:**
```nu
set_log_level "DEBUG"
```

---

#### `get_log_level() -> string`
Returns the current logging level.

**Example:**
```nu
let level = get_log_level
print $"Current log level: ($level)"
```

### error-handling.nu - Structured Error Management

#### `create_error(type: string, message: string, context?: record) -> record`
Creates a structured error record.

**Parameters:**
- `type`: Error type/category
- `message`: Human-readable error message  
- `context`: Optional additional context data

**Returns:** Error record
```nu
{
    id: string,           # Unique error ID
    type: string,         # Error type
    message: string,      # Error message
    timestamp: datetime,  # When error occurred
    context: record,      # Additional context
    suggestions: list     # Recovery suggestions
}
```

**Example:**
```nu
let error = create_error "NETWORK" "Failed to connect to server" {
    host: "example.com",
    port: 80,
    timeout: 30
}
```

---

#### `handle_script_error(message: string, type: string, context?: record) -> null`
Handles and logs a script error with structured information.

**Parameters:**
- `message`: Error description
- `type`: Error category
- `context`: Optional context data

**Example:**
```nu
try {
    # Risky operation
} catch {|err|
    handle_script_error "Operation failed" "EXECUTION" {
        operation: "file_copy",
        source: "/tmp/source",
        destination: "/tmp/dest",
        error: $err
    }
}
```

---

#### `get_error_suggestions(error_type: string) -> list<string>`
Returns recovery suggestions for a given error type.

**Parameters:**
- `error_type`: The type of error

**Returns:** List of suggestion strings

**Example:**
```nu
let suggestions = get_error_suggestions "NETWORK"
for suggestion in $suggestions {
    print $"💡 ($suggestion)"
}
```

### config.nu - Configuration Management

#### `load_config(config_path?: string) -> record`
Loads nix-mox configuration from file.

**Parameters:**
- `config_path`: Optional path to config file (defaults to standard locations)

**Returns:** Configuration record

**Example:**
```nu
let config = load_config
let log_level = get_config_value $config "logging.level" "INFO"
```

---

#### `get_config_value(config: record, path: string, default?: any) -> any`
Gets a configuration value using dot notation path.

**Parameters:**
- `config`: Configuration record
- `path`: Dot-separated configuration path (e.g., "logging.level")
- `default`: Default value if path not found

**Example:**
```nu
let config = load_config
let timeout = get_config_value $config "network.timeout" 30
```

---

#### `set_config_value(config: record, path: string, value: any) -> record`
Sets a configuration value and returns updated config.

**Parameters:**
- `config`: Configuration record
- `path`: Dot-separated configuration path
- `value`: Value to set

**Returns:** Updated configuration record

**Example:**
```nu
let config = load_config
let updated_config = set_config_value $config "logging.level" "DEBUG"
```

---

#### `create_default_config() -> record`
Creates a default configuration record with sensible defaults.

**Returns:** Default configuration record

**Example:**
```nu
let config = create_default_config
save_config $config "config/nix-mox.toml"
```

---

#### `save_config(config: record, path: string) -> null`
Saves configuration to file.

**Parameters:**
- `config`: Configuration record to save
- `path`: File path to save to

**Example:**
```nu
let config = create_default_config
save_config $config "config/my-config.toml"
```

### performance.nu - Performance Monitoring

#### `start_performance_monitor(operation: string, context?: record) -> string`
Starts performance monitoring for an operation.

**Parameters:**
- `operation`: Name of the operation being monitored
- `context`: Optional context data

**Returns:** Monitor ID for ending the measurement

**Example:**
```nu
let monitor_id = start_performance_monitor "database_query" {
    query_type: "SELECT",
    table: "users"
}

# ... perform operation ...

end_performance_monitor $monitor_id
```

---

#### `end_performance_monitor(monitor_id: string) -> record`
Ends performance monitoring and returns metrics.

**Parameters:**
- `monitor_id`: ID returned from `start_performance_monitor`

**Returns:** Performance metrics record
```nu
{
    operation: string,     # Operation name
    duration: float,       # Duration in seconds
    memory_used: int,      # Memory usage in bytes
    cpu_usage: float,      # CPU usage percentage
    context: record        # Original context data
}
```

---

#### `get_system_performance() -> record`
Gets current system performance metrics.

**Returns:** System performance record
```nu
{
    cpu_usage: float,      # Current CPU usage %
    memory_usage: float,   # Current memory usage %
    disk_usage: record,    # Disk usage by mount point
    load_average: list,    # System load averages
    uptime: int           # System uptime in seconds
}
```

---

#### `benchmark_operation(operation: closure) -> record`
Benchmarks a code block and returns performance metrics.

**Parameters:**
- `operation`: Closure containing code to benchmark

**Returns:** Benchmark results

**Example:**
```nu
let results = benchmark_operation {
    # Code to benchmark
    for i in 1..1000 {
        math sqrt $i
    }
}
print $"Operation took ($results.duration) seconds"
```

### security.nu - Security Validation

#### `validate_script_security(script_path: string) -> record`
Validates a script for security threats and dangerous patterns.

**Parameters:**
- `script_path`: Path to script file to validate

**Returns:** Security validation result
```nu
{
    is_safe: bool,         # Overall safety assessment
    threats: list,         # List of detected threats
    warnings: list,        # List of warnings
    suggestions: list      # Security improvement suggestions
}
```

**Example:**
```nu
let result = validate_script_security "scripts/deploy.nu"
if not $result.is_safe {
    print "⚠️ Security issues detected:"
    for threat in $result.threats {
        print $"  - ($threat.description)"
    }
}
```

---

#### `scan_for_threats(content: string) -> list`
Scans text content for security threats.

**Parameters:**
- `content`: Text content to scan

**Returns:** List of detected threats

**Example:**
```nu
let script_content = open "suspicious-script.nu"
let threats = scan_for_threats $script_content
for threat in $threats {
    print $"Threat: ($threat.type) - ($threat.description)"
}
```

---

#### `is_command_dangerous(command: string) -> bool`
Checks if a command is potentially dangerous.

**Parameters:**
- `command`: Command string to check

**Returns:** True if command is dangerous

**Example:**
```nu
if is_command_dangerous "rm -rf /" {
    print "🚨 Dangerous command detected!"
}
```

---

#### `get_security_recommendations() -> list<string>`
Returns general security recommendations for nix-mox usage.

**Returns:** List of security recommendation strings

**Example:**
```nu
let recommendations = get_security_recommendations
for rec in $recommendations {
    print $"💡 ($rec)"
}
```

### metrics.nu - Metrics Collection & Monitoring

#### `init_core_metrics() -> null`
Initializes the core metrics collection system.

**Example:**
```nu
init_core_metrics
print "Metrics system initialized"
```

---

#### `increment_counter(name: string, labels?: record) -> null`
Increments a counter metric.

**Parameters:**
- `name`: Metric name
- `labels`: Optional labels for the metric

**Example:**
```nu
increment_counter "nix_mox_script_executions_total" {script: "setup.nu"}
```

---

#### `set_gauge(name: string, value: float, labels?: record) -> null`
Sets a gauge metric value.

**Parameters:**
- `name`: Metric name
- `value`: Numeric value to set
- `labels`: Optional labels for the metric

**Example:**
```nu
set_gauge "nix_mox_memory_usage_percent" 45.2 {component: "monitoring"}
```

---

#### `observe_histogram(name: string, value: float, labels?: record) -> null`
Records an observation in a histogram metric.

**Parameters:**
- `name`: Metric name
- `value`: Value to observe
- `labels`: Optional labels for the metric

**Example:**
```nu
observe_histogram "nix_mox_script_duration_seconds" 2.5 {script: "setup.nu"}
```

---

#### `track_script_execution(script_name: string, duration: float, success: bool) -> null`
Records metrics for script execution.

**Parameters:**
- `script_name`: Name of the script
- `duration`: Execution duration in seconds
- `success`: Whether execution was successful

**Example:**
```nu
let start_time = date now
# ... script execution ...
let duration = ((date now) - $start_time) / 1sec
track_script_execution "my-script" $duration true
```

---

#### `format_prometheus_metrics() -> string`
Formats all collected metrics in Prometheus exposition format.

**Returns:** Prometheus-formatted metrics string

**Example:**
```nu
let metrics = format_prometheus_metrics
print $metrics
# or save to file for Prometheus scraping
$metrics | save "/tmp/nix-mox-metrics.prom"
```

---

#### `export_metrics_to_file(path: string) -> null`
Exports metrics to a file in Prometheus format.

**Parameters:**
- `path`: File path to export to

**Example:**
```nu
export_metrics_to_file "/var/lib/nix-mox/metrics.prom"
```

### discovery.nu - Resource Discovery

#### `discover_scripts(directory: string) -> list`
Discovers all Nushell scripts in a directory and extracts metadata.

**Parameters:**
- `directory`: Directory to search for scripts

**Returns:** List of script information records
```nu
[{
    name: string,          # Script name
    path: string,          # Full path to script
    description: string,   # Script description from comments
    functions: list        # Exported functions
}]
```

**Example:**
```nu
let scripts = discover_scripts "scripts/core"
for script in $scripts {
    print $"Found: ($script.name) - ($script.description)"
}
```

---

#### `find_config_files(pattern: string) -> list<string>`
Finds configuration files matching a pattern.

**Parameters:**
- `pattern`: Glob pattern to match

**Returns:** List of configuration file paths

**Example:**
```nu
let configs = find_config_files "config/**/*.nix"
for config in $configs {
    print $"Config: ($config)"
}
```

---

#### `discover_system_services() -> list`
Discovers available system services.

**Returns:** List of service information records

**Example:**
```nu
let services = discover_system_services
let nginx = ($services | where name == "nginx" | first)
print $"Nginx status: ($nginx.status)"
```

## 🔧 Utility Functions

### Common Patterns

#### Configuration Loading Pattern
```nu
def load_with_fallback [config_path?: string] {
    try {
        load_config $config_path
    } catch {
        log_warn "Failed to load config, using defaults"
        create_default_config
    }
}
```

#### Error Handling Pattern
```nu
def safe_operation [operation: closure] {
    try {
        $operation | call
    } catch {|err|
        handle_script_error "Operation failed" "EXECUTION" {
            error: $err,
            operation: "safe_operation"
        }
    }
}
```

#### Performance Monitoring Pattern
```nu
def monitored_operation [name: string, operation: closure] {
    let monitor_id = start_performance_monitor $name
    try {
        let result = ($operation | call)
        end_performance_monitor $monitor_id
        $result
    } catch {|err|
        end_performance_monitor $monitor_id
        error make {msg: $"Operation ($name) failed: ($err)"}
    }
}
```

## 🧪 Testing API

### test-utils.nu - Testing Utilities

#### `assert_true(condition: bool, message: string) -> null`
Asserts that a condition is true.

**Parameters:**
- `condition`: Boolean condition to test
- `message`: Error message if assertion fails

**Example:**
```nu
assert_true (2 + 2 == 4) "Basic math should work"
```

---

#### `assert_equal(actual: any, expected: any, message: string) -> null`
Asserts that two values are equal.

**Example:**
```nu
let result = get_platform_info
assert_equal $result.platform "linux" "Should detect Linux platform"
```

---

#### `track_test(name: string, suite: string, status: string, duration: float) -> null`
Records test execution metrics.

**Parameters:**
- `name`: Test name
- `suite`: Test suite name
- `status`: Test status ("passed", "failed", "skipped")
- `duration`: Test duration in seconds

**Example:**
```nu
def test_platform_detection [] {
    let start = date now
    let platform = detect_platform
    let duration = ((date now) - $start) / 1sec
    
    assert_true ($platform in ["linux", "darwin", "windows"]) "Valid platform detected"
    track_test "platform_detection" "unit" "passed" $duration
}
```

## 📊 Integration Examples

### Complete Script Template
```nu
#!/usr/bin/env nu

# Example nix-mox script using multiple APIs
use ../lib/platform.nu *
use ../lib/logging.nu *
use ../lib/error-handling.nu *
use ../lib/config.nu *
use ../lib/performance.nu *
use ../lib/metrics.nu *

def main [] {
    # Initialize systems
    init_core_metrics
    set_log_level "INFO"
    
    log_info "Starting example script..."
    
    # Load configuration
    let config = try {
        load_config
    } catch {
        log_warn "Using default configuration"
        create_default_config
    }
    
    # Monitor performance
    let monitor_id = start_performance_monitor "example_operation"
    
    try {
        # Platform-specific logic
        let platform = detect_platform
        match $platform {
            "linux" => handle_linux_setup $config
            "darwin" => handle_macos_setup $config
            _ => {
                handle_script_error "Unsupported platform" "PLATFORM" {
                    platform: $platform
                }
            }
        }
        
        # Track success metrics
        increment_counter "example_script_success_total"
        log_info "Script completed successfully"
        
    } catch {|err|
        handle_script_error "Script execution failed" "EXECUTION" {
            error: $err,
            config_path: (get_config_value $config "config.path" "unknown")
        }
        increment_counter "example_script_failures_total"
    } finally {
        let metrics = end_performance_monitor $monitor_id
        observe_histogram "example_script_duration_seconds" $metrics.duration
        export_metrics_to_file "/tmp/example-metrics.prom"
    }
}

def handle_linux_setup [config: record] {
    log_info "Configuring Linux-specific features..."
    # Linux setup logic
}

def handle_macos_setup [config: record] {
    log_info "Configuring macOS-specific features..."
    # macOS setup logic
}

if ($env.PWD? != null) {
    main
}
```

## 📚 Error Codes Reference

### Standard Error Types
- `PLATFORM` - Platform detection or compatibility issues
- `CONFIGURATION` - Configuration loading or validation errors
- `NETWORK` - Network connectivity or API issues
- `FILESYSTEM` - File system operations errors
- `PERMISSION` - Permission or access control issues
- `SECURITY` - Security validation failures
- `EXECUTION` - General script execution errors
- `VALIDATION` - Input validation or data format errors

### Common Error Patterns
```nu
# Network timeout
create_error "NETWORK" "Connection timeout" {
    host: "example.com",
    timeout: 30,
    suggestion: "Check network connectivity"
}

# Configuration missing
create_error "CONFIGURATION" "Config file not found" {
    path: "/etc/nix-mox/config.toml",
    suggestion: "Run 'nix-mox setup' to create configuration"
}

# Permission denied
create_error "PERMISSION" "Access denied" {
    path: "/etc/nixos/configuration.nix",
    required_permission: "write",
    suggestion: "Run with sudo or fix file permissions"
}
```

## 🎯 Best Practices

1. **Always use structured error handling** with `handle_script_error`
2. **Initialize metrics system** in main scripts with `init_core_metrics`
3. **Use appropriate log levels** (DEBUG for development, INFO for production)
4. **Validate configuration** before using values
5. **Monitor performance** of critical operations
6. **Handle platform differences** gracefully
7. **Provide meaningful error messages** with context
8. **Track metrics** for monitoring and debugging
9. **Use security validation** for user-provided input
10. **Follow naming conventions** for consistency