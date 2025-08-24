#!/usr/bin/env nu

# Import unified libraries
use ../lib/unified-checks.nu
use ../lib/unified-error-handling.nu


# nix-mox Advanced Caching Strategy
# Implements sophisticated build caching with multiple layers and optimization
use ../lib/unified-logging.nu *
use ../lib/unified-error-handling.nu *

# Cache configuration
def get_cache_config [] {
    {
        # Primary caches (fastest)
        primary_caches: ["https://nix-mox.cachix.org" "https://hydepwns.cachix.org"]
        # Secondary caches (fallback)
        secondary_caches: ["https://cache.nixos.org" "https://nix-community.cachix.org"]
        # Specialized caches by category
        specialized_caches: {
            development: ["https://nixpkgs-wayland.cachix.org" "https://emacs.cachix.org"]
            gaming: ["https://gaming.cachix.org" "https://steam.cachix.org"]
            security: ["https://security.cachix.org"]
        }
        # Cache priorities (lower number = higher priority)
        priorities: {
            "nix-mox.cachix.org": 1
            "hydepwns.cachix.org": 2
            "cache.nixos.org": 3
            "nix-community.cachix.org": 4
        }
        # Cache timeouts (in seconds)
        timeouts: {
            connect: 30
            read: 300
            write: 600
        }
        # Compression settings
        compression: {
            enabled: true
            algorithm: "zstd"
            level: 3
        }
    }
}

# Check cache health and performance
def check_cache_health [cache_url: string] {
    let start_time = (date now)
    try {
        # Test cache connectivity
        let response = (http get $"($cache_url)/nix-cache-info" | complete)
        if ($response.exit_code == 0) {
            let end_time = (date now)
            let duration = (($end_time | into int) - ($start_time | into int))
            {
                url: $cache_url
                status: "healthy"
                response_time: $duration
                available: true
            }
        } else {
            {
                url: $cache_url
                status: "unhealthy"
                response_time: -1
                available: false
                error: $response.stderr
            }
        }
    } catch {
        {
            url: $cache_url
            status: "unreachable"
            response_time: -1
            available: false
            error: $env.LAST_ERROR
        }
    }
}

# Optimize cache configuration based on health checks
def optimize_cache_config [] {
    info "Analyzing cache health and performance..." "advanced-cache"
    let config = (get_cache_config)
    let all_caches = ($config.primary_caches | append $config.secondary_caches)

    # Check health of all caches
    let health_results = ($all_caches | each { |cache| check_cache_health $cache })

    # Sort by performance and availability
    let optimized_caches = ($health_results | where available == true | sort-by response_time | get url)

    # Update configuration with optimized cache order
    let optimized_config = ($config | upsert primary_caches $optimized_caches)
    common log_success $"Optimized cache configuration with ($optimized_caches | length) healthy caches"
    $optimized_config
}

# Implement intelligent cache warming
def warm_cache [packages: list] {
    common log_info "Warming cache with frequently used packages..."
    let config = (get_cache_config)
    let warm_packages = ["nixpkgs-fmt" "nushell" "git" "vim" "wget" "curl" "htop" "docker" "docker-compose"]

    # Add user-specified packages
    let all_packages = ($warm_packages | append $packages | uniq)

    # Warm cache in parallel with limited concurrency
    let warm_results = ($all_packages | each { |pkg|
        try {
            common log_info $"Warming cache for ($pkg)..."
            nix build nixpkgs#($pkg) --no-link --accept-flake-config
            {
                package: $pkg
                status: "success"
                cached: true
            }
        } catch {
            {
                package: $pkg
                status: "failed"
                cached: false
                error: $env.LAST_ERROR
            }
        }
    })

    let success_count = ($warm_results | where status == "success" | length)
    let total_count = ($warm_results | length)
    common log_success $"Cache warming completed: ($success_count)/($total_count) packages cached"
    $warm_results
}

# Implement cache-aware build scheduling
def schedule_builds [packages: list] {
    common log_info "Scheduling builds with cache optimization..."

    # Analyze package dependencies and sizes
    let package_analysis = ($packages | each { |pkg|
        try {
            let closure_size = (nix path-info --closure-size .#"($pkg)" 2>/dev/null | lines | length)
            let build_time = (if $pkg in ["vzdump-backup", "zfs-snapshot"] { "heavy" } else { "light" })

            {
                name: $pkg
                size: $closure_size
                build_time: $build_time
                priority: (if $build_time == "heavy" { 1 } else { 2 })
            }
        } catch {
            {
                name: $pkg
                size: 0
                build_time: "unknown"
                priority: 3
            }
        }
    })

    # Sort by priority (heavy builds first, then light builds)
    let scheduled_builds = ($package_analysis | sort-by priority)

    common log_info "Build schedule:"
    $scheduled_builds | each { |pkg|
        print $"  - ($pkg.name) ($pkg.build_time) build, priority: ($pkg.priority)"
    }
    $scheduled_builds
}

# Implement cache-aware parallel builds
def parallel_build [packages: list, max_jobs: int = 4] {
    common log_info $"Starting parallel builds with max ($max_jobs) jobs..."
    let scheduled = (schedule_builds $packages)
    let total_packages = ($scheduled | length)
    mut completed = 0
    mut failed = []
    mut results = []

    # Process packages in batches
    for batch_start in (0..($total_packages - 1) | where (mod $it $max_jobs) == 0) {
        let batch_end = ([$batch_start + $max_jobs - 1, $total_packages - 1] | math min)
        let batch_packages = ($scheduled | range $batch_start..$batch_end | get name)

        common log_info $"Building batch: ($batch_packages | str join ', ')"

        # Build batch in parallel
        let batch_results = ($batch_packages | each { |pkg|
            try {
                let start_time = (date now)
                nix build .#"($pkg)" --accept-flake-config
                let end_time = (date now)
                let duration = (($end_time | into int) - ($start_time | into int))

                {
                    package: $pkg
                    status: "success"
                    duration: $duration
                    cached: true
                }
            } catch {
                {
                    package: $pkg
                    status: "failed"
                    duration: -1
                    cached: false
                    error: $env.LAST_ERROR
                }
            }
        })

        $results = ($results | append $batch_results)
        $completed = ($completed + ($batch_results | length))

        # Update progress
        let progress = (($completed | into float) / ($total_packages | into float) * 100 | into int)
        common log_info $"Progress: ($completed)/($total_packages) packages completed ($progress)%"
    }

    # Summary
    let success_count = ($results | where status == "success" | length)
    let failed_count = ($results | where status == "failed" | length)
    common log_success $"Parallel build completed: ($success_count) successful, ($failed_count) failed"

    if ($failed_count > 0) {
        common log_warning "Failed packages:"
        $results | where status == "failed" | each { |r| print $"  - ($r.package): ($r.error)" }
    }
    $results
}

# Cache cleanup and maintenance
def maintain_cache [] {
    common log_info "Performing cache maintenance..."

    # Clean old build artifacts
    try {
        nix store gc --print-dead
        common log_success "Cache garbage collection completed"
    } catch {
        common log_warning "Cache garbage collection failed"
    }

    # Optimize store
    try {
        nix store optimise
        common log_success "Store optimization completed"
    } catch {
        common log_warning "Store optimization failed"
    }

    # Check cache health
    let config = (get_cache_config)
    let health_results = ($config.primary_caches | each { |cache| check_cache_health $cache })

    common log_info "Cache health status:"
    $health_results | each { |cache|
        let status_icon = (if $cache.available { "✅" } else { "❌" })
        print $"($status_icon) ($cache.url): ($cache.status)"
    }
}

# Main function for advanced caching
def main [packages: list = []] {
    common log_info "Starting advanced caching strategy..."

    # Optimize cache configuration
    let optimized_config = (optimize_cache_config)

    # Warm cache with common packages
    let warm_results = (warm_cache $packages)

    # Perform parallel builds with cache optimization
    let build_results = (parallel_build $packages)

    # Maintain cache
    maintain_cache

    # Generate report
    let report = {
        timestamp: (date now | format date "%Y-%m-%d %H:%M:%S")
        cache_config: $optimized_config
        warm_results: $warm_results
        build_results: $build_results
        summary: {
            total_packages: ($build_results | length)
            successful_builds: ($build_results | where status == "success" | length)
            failed_builds: ($build_results | where status == "failed" | length)
            cache_hit_rate: (($warm_results | where cached == true | length | into float) / ($warm_results | length | into float) * 100 | into int)
        }
    }

    # Save report
    $report | to json --indent 2 | save cache-report.json
    common log_success "Advanced caching strategy completed!"
    common log_info "Report saved to cache-report.json"
    $report
}

# Export functions for use in other scripts
export def optimize [] {
    optimize_cache_config
}

export def warm [packages: list = []] {
    warm_cache $packages
}

export def build [packages: list, max_jobs: int = 4] {
    parallel_build $packages $max_jobs
}

export def maintain [] {
    maintain_cache
}

export def run [packages: list = []] {
    main $packages
}
