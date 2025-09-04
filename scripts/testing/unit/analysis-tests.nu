#!/usr/bin/env nu
# Comprehensive tests for analysis.nu library

use ../../lib/analysis.nu *
use ../../lib/logging.nu *
use ../lib/test-utils.nu *

# Test collect_system_info
def test_collect_system_info [] {
    info "Testing collect_system_info function" --context "test"
    
    let sys_info = (collect_system_info)
    
    # Verify basic structure
    assert_true ("hostname" in ($sys_info | columns)) "should have hostname"
    assert_true ("uptime" in ($sys_info | columns)) "should have uptime"
    assert_true ("memory" in ($sys_info | columns)) "should have memory info"
    assert_true ("disk" in ($sys_info | columns)) "should have disk info"
    assert_true ("cpu" in ($sys_info | columns)) "should have cpu info"
    
    # Verify data types
    assert_true (($sys_info.hostname | describe) == "string") "hostname should be string"
    assert_true (($sys_info.memory | describe) == "record") "memory should be record"
    assert_true (($sys_info.disk | describe) == "record") "disk should be record"
    
    { success: true, message: "collect_system_info tests passed" }
}

# Test analyze_disk_usage
def test_analyze_disk_usage [] {
    info "Testing analyze_disk_usage function" --context "test"
    
    let disk_analysis = (analyze_disk_usage)
    
    # Should return a list of disk info
    assert_true ($disk_analysis | describe | str starts-with "list") "should return list"
    assert_true (($disk_analysis | length) > 0) "should have at least one disk"
    
    # Check structure of first disk entry
    let first_disk = ($disk_analysis | first)
    assert_true ("filesystem" in ($first_disk | columns)) "should have filesystem"
    assert_true ("size" in ($first_disk | columns)) "should have size"
    assert_true ("used" in ($first_disk | columns)) "should have used"
    assert_true ("usage_percent" in ($first_disk | columns)) "should have usage_percent"
    
    # Verify usage_percent is reasonable
    assert_true ($first_disk.usage_percent >= 0) "usage should be >= 0"
    assert_true ($first_disk.usage_percent <= 100) "usage should be <= 100"
    
    { success: true, message: "analyze_disk_usage tests passed" }
}

# Test analyze_memory_usage
def test_analyze_memory_usage [] {
    info "Testing analyze_memory_usage function" --context "test"
    
    let mem_analysis = (analyze_memory_usage)
    
    # Verify structure
    assert_true ("total" in ($mem_analysis | columns)) "should have total"
    assert_true ("used" in ($mem_analysis | columns)) "should have used"
    assert_true ("free" in ($mem_analysis | columns)) "should have free"
    assert_true ("usage_percent" in ($mem_analysis | columns)) "should have usage_percent"
    
    # Verify reasonable values
    assert_true ($mem_analysis.total > 0) "total memory should be positive"
    assert_true ($mem_analysis.usage_percent >= 0) "usage should be >= 0"
    assert_true ($mem_analysis.usage_percent <= 100) "usage should be <= 100"
    
    # Basic math check
    let calculated_usage = ($mem_analysis.used / $mem_analysis.total * 100)
    let diff = ($calculated_usage - $mem_analysis.usage_percent | math abs)
    assert_true ($diff < 1.0) "calculated usage should match reported"
    
    { success: true, message: "analyze_memory_usage tests passed" }
}

# Test analyze_cpu_usage
def test_analyze_cpu_usage [] {
    info "Testing analyze_cpu_usage function" --context "test"
    
    let cpu_analysis = (analyze_cpu_usage)
    
    # Verify structure
    assert_true ("cores" in ($cpu_analysis | columns)) "should have cores count"
    assert_true ("load_avg" in ($cpu_analysis | columns)) "should have load average"
    assert_true ("usage_percent" in ($cpu_analysis | columns)) "should have usage percent"
    
    # Verify reasonable values
    assert_true ($cpu_analysis.cores > 0) "should have at least 1 core"
    assert_true ($cpu_analysis.usage_percent >= 0) "usage should be >= 0"
    assert_true ($cpu_analysis.usage_percent <= 100) "usage should be <= 100"
    
    # Load average should be array of 3 values
    assert_equal (($cpu_analysis.load_avg | length) == 3) "load_avg should have 3 values"
    assert_true ($cpu_analysis.load_avg | all { |load| $load >= 0 }) "load values should be >= 0"
    
    { success: true, message: "analyze_cpu_usage tests passed" }
}

# Test analyze_network_interfaces
def test_analyze_network_interfaces [] {
    info "Testing analyze_network_interfaces function" --context "test"
    
    let net_analysis = (analyze_network_interfaces)
    
    # Should return a list
    assert_true ($net_analysis | describe | str starts-with "list") "should return list"
    assert_true (($net_analysis | length) > 0) "should have at least one interface"
    
    # Check structure of first interface
    let first_iface = ($net_analysis | first)
    assert_true ("name" in ($first_iface | columns)) "should have name"
    assert_true ("status" in ($first_iface | columns)) "should have status"
    
    # Should have at least loopback interface
    let has_lo = ($net_analysis | any { |iface| $iface.name == "lo" })
    assert_true ($has_lo) "should have loopback interface"
    
    { success: true, message: "analyze_network_interfaces tests passed" }
}

# Test analyze_processes
def test_analyze_processes [] {
    info "Testing analyze_processes function" --context "test"
    
    let proc_analysis = (analyze_processes --limit 10)
    
    # Should return a list
    assert_true ($proc_analysis | describe | str starts-with "list") "should return list"
    assert_true (($proc_analysis | length) > 0) "should have processes"
    assert_true (($proc_analysis | length) <= 10) "should respect limit"
    
    # Check structure of first process
    let first_proc = ($proc_analysis | first)
    assert_true ("pid" in ($first_proc | columns)) "should have pid"
    assert_true ("name" in ($first_proc | columns)) "should have name"
    assert_true ("cpu_percent" in ($first_proc | columns)) "should have cpu_percent"
    assert_true ("memory_percent" in ($first_proc | columns)) "should have memory_percent"
    
    # Verify data types
    assert_true (($first_proc.pid | describe) == "int") "pid should be integer"
    assert_true (($first_proc.cpu_percent | describe) == "float") "cpu_percent should be float"
    
    { success: true, message: "analyze_processes tests passed" }
}

# Test generate_performance_report
def test_generate_performance_report [] {
    info "Testing generate_performance_report function" --context "test"
    
    let report = (generate_performance_report)
    
    # Verify report structure
    assert_true ("timestamp" in ($report | columns)) "should have timestamp"
    assert_true ("system" in ($report | columns)) "should have system info"
    assert_true ("performance" in ($report | columns)) "should have performance metrics"
    assert_true ("summary" in ($report | columns)) "should have summary"
    
    # Check performance section
    let perf = $report.performance
    assert_true ("cpu" in ($perf | columns)) "should have cpu metrics"
    assert_true ("memory" in ($perf | columns)) "should have memory metrics"
    assert_true ("disk" in ($perf | columns)) "should have disk metrics"
    assert_true ("network" in ($perf | columns)) "should have network metrics"
    
    # Check summary has health assessment
    assert_true ("overall_health" in ($report.summary | columns)) "should have overall health"
    assert_true (($report.summary.overall_health in ["excellent", "good", "fair", "poor"])) "health should be valid category"
    
    { success: true, message: "generate_performance_report tests passed" }
}

# Test analyze_storage_usage
def test_analyze_storage_usage [] {
    info "Testing analyze_storage_usage function" --context "test"
    
    let storage_analysis = (analyze_storage_usage)
    
    # Verify structure
    assert_true ("total_size" in ($storage_analysis | columns)) "should have total_size"
    assert_true ("used_size" in ($storage_analysis | columns)) "should have used_size"
    assert_true ("free_size" in ($storage_analysis | columns)) "should have free_size"
    assert_true ("usage_percent" in ($storage_analysis | columns)) "should have usage_percent"
    assert_true ("filesystems" in ($storage_analysis | columns)) "should have filesystems list"
    
    # Verify reasonable values
    assert_true ($storage_analysis.total_size > 0) "total size should be positive"
    assert_true ($storage_analysis.usage_percent >= 0) "usage should be >= 0"
    assert_true ($storage_analysis.usage_percent <= 100) "usage should be <= 100"
    
    # Basic math check
    let sum = ($storage_analysis.used_size + $storage_analysis.free_size)
    let diff = ($sum - $storage_analysis.total_size | math abs)
    assert_true ($diff < 1000000000) "used + free should approximately equal total" # Allow 1GB tolerance
    
    { success: true, message: "analyze_storage_usage tests passed" }
}

# Test analyze_security_status
def test_analyze_security_status [] {
    info "Testing analyze_security_status function" --context "test"
    
    let security_analysis = (analyze_security_status)
    
    # Verify structure
    assert_true ("firewall" in ($security_analysis | columns)) "should have firewall status"
    assert_true ("updates" in ($security_analysis | columns)) "should have updates status"
    assert_true ("permissions" in ($security_analysis | columns)) "should have permissions check"
    assert_true ("score" in ($security_analysis | columns)) "should have security score"
    
    # Verify security score is reasonable
    assert_true ($security_analysis.score >= 0) "score should be >= 0"
    assert_true ($security_analysis.score <= 100) "score should be <= 100"
    
    { success: true, message: "analyze_security_status tests passed" }
}

# Test get_hardware_info
def test_get_hardware_info [] {
    info "Testing get_hardware_info function" --context "test"
    
    let hw_info = (get_hardware_info)
    
    # Verify structure
    assert_true ("cpu" in ($hw_info | columns)) "should have cpu info"
    assert_true ("memory" in ($hw_info | columns)) "should have memory info"
    assert_true ("storage" in ($hw_info | columns)) "should have storage info"
    
    # Check CPU info
    let cpu = $hw_info.cpu
    assert_true ("model" in ($cpu | columns)) "should have cpu model"
    assert_true ("cores" in ($cpu | columns)) "should have core count"
    assert_true ($cpu.cores > 0) "should have at least 1 core"
    
    # Check memory info
    let memory = $hw_info.memory
    assert_true ("total" in ($memory | columns)) "should have total memory"
    assert_true ($memory.total > 0) "should have positive memory amount"
    
    { success: true, message: "get_hardware_info tests passed" }
}

# Test format_bytes
def test_format_bytes [] {
    info "Testing format_bytes function" --context "test"
    
    # Test various sizes
    assert_equal (format_bytes 1024) "1.0 KiB" "1024 bytes should be 1.0 KiB"
    assert_equal (format_bytes 1048576) "1.0 MiB" "1MB should be 1.0 MiB"
    assert_equal (format_bytes 1073741824) "1.0 GiB" "1GB should be 1.0 GiB"
    
    # Test small values
    assert_equal (format_bytes 512) "512 B" "small values should show in bytes"
    assert_equal (format_bytes 0) "0 B" "zero should show as 0 B"
    
    # Test large values
    let result = (format_bytes 1099511627776)  # 1TB
    assert_contains $result "TiB" "large values should show in TiB"
    
    { success: true, message: "format_bytes tests passed" }
}

# Main test runner
def main [] {
    print "Running analysis.nu test suite..."
    
    let test_results = [
        (test_collect_system_info)
        (test_analyze_disk_usage)
        (test_analyze_memory_usage)
        (test_analyze_cpu_usage)
        (test_analyze_network_interfaces)
        (test_analyze_processes)
        (test_generate_performance_report)
        (test_analyze_storage_usage)
        (test_analyze_security_status)
        (test_get_hardware_info)
        (test_format_bytes)
    ]
    
    let all_passed = ($test_results | all { |r| $r.success })
    let passed_count = ($test_results | where success == true | length)
    let total_count = ($test_results | length)
    
    if $all_passed {
        print $"All analysis.nu tests passed! ($passed_count) of ($total_count)"
    } else {
        let failed_tests = ($test_results | where success == false)
        print $"Some tests failed: ($failed_tests | length) of ($total_count)"
        for test in $failed_tests {
            print $"  - ($test.message)"
        }
    }
    
    { success: $all_passed, passed: $passed_count, total: $total_count }
    return $all_passed
}
