#!/usr/bin/env nu

# Gaming Configuration Validator for nix-mox
# Validates gaming setup and provides recommendations

def main [] {
    print $"(ansi green)🔍 nix-mox Gaming Configuration Validator(ansi reset)"
    print $"(ansi yellow)==========================================(ansi reset)\n"

    # Run validations
    let validations = {
        system: (validate_system_requirements)
        graphics: (validate_graphics_config)
        audio: (validate_audio_config)
        performance: (validate_performance_config)
        gaming: (validate_gaming_tools)
        security: (validate_security_config)
    }

    # Calculate overall score
    let score = (calculate_score $validations)

    # Display results
    display_validation_results $validations $score

    # Provide recommendations
    provide_recommendations $validations $score
}

def safe_command [cmd: string] {
    try {
        nu -c $cmd | str trim
    } catch {
        ""
    }
}

def safe_int [value: any] {
    try {
        $value | into int
    } catch {
        0
    }
}

def validate_system_requirements [] {
    print $"(ansi cyan)💻 System Requirements...(ansi reset)"
    mut results = {}

    # Check CPU cores
    let cpu_cores = (nproc | into int | default 0)
    if $cpu_cores >= 8 {
        $results = ($results | upsert cpu "Excellent" | upsert cpu_score 2)
        print $"  ✅ CPU: Excellent ($cpu_cores) cores"
    } else if $cpu_cores >= 4 {
        $results = ($results | upsert cpu "Good" | upsert cpu_score 1)
        print $"  ⚠️  CPU: Good ($cpu_cores) cores - 8+ recommended"
    } else {
        $results = ($results | upsert cpu "Insufficient" | upsert cpu_score 0)
        print $"  ❌ CPU: Insufficient ($cpu_cores) cores - 4+ required"
    }

    # Check memory
    let mem_gb = (safe_int (safe_command "free -g | grep Mem | awk '{print $2}'"))
    if $mem_gb >= 16 {
        $results = ($results | upsert memory "Excellent" | upsert memory_score 2)
        print $"  ✅ Memory: Excellent ($mem_gb) GB"
    } else if $mem_gb >= 8 {
        $results = ($results | upsert memory "Good" | upsert memory_score 1)
        print $"  ⚠️  Memory: Good ($mem_gb) GB - 16GB+ recommended"
    } else {
        $results = ($results | upsert memory "Insufficient" | upsert memory_score 0)
        print $"  ❌ Memory: Insufficient ($mem_gb) GB - 8GB+ required"
    }

    # Check storage
    let storage_gb = (safe_int (safe_command "df -h / | tail -n 1 | awk '{print $4}' | str replace 'G' ''"))
    if $storage_gb >= 100 {
        $results = ($results | upsert storage "Excellent" | upsert storage_score 1)
        print $"  ✅ Storage: Excellent ($storage_gb) GB free"
    } else if $storage_gb >= 50 {
        $results = ($results | upsert storage "Good" | upsert storage_score 1)
        print $"  ⚠️  Storage: Good ($storage_gb) GB free - 100GB+ recommended"
    } else {
        $results = ($results | upsert storage "Insufficient" | upsert storage_score 0)
        print $"  ❌ Storage: Insufficient ($storage_gb) GB free - 50GB+ required"
    }

    $results
}

def validate_graphics_config [] {
    print $"(ansi cyan)🎨 Graphics Configuration...(ansi reset)"
    mut results = {}

    # Check GPU
    let gpu_info = (safe_command "lspci | grep -i vga")
    if ($gpu_info | str contains "NVIDIA") {
        $results = ($results | upsert gpu "NVIDIA" | upsert gpu_score 2)
        print "  ✅ GPU: NVIDIA detected"
    } else if ($gpu_info | str contains "AMD") {
        $results = ($results | upsert gpu "AMD" | upsert gpu_score 2)
        print "  ✅ GPU: AMD detected"
    } else if ($gpu_info | str contains "Intel") {
        $results = ($results | upsert gpu "Intel" | upsert gpu_score 1)
        print "  ⚠️  GPU: Intel detected - gaming performance may be limited"
    } else {
        $results = ($results | upsert gpu "Unknown" | upsert gpu_score 0)
        print "  ❌ GPU: Unknown or not detected"
    }

    # Check OpenGL
    let opengl_version = (safe_command "glxinfo | grep 'OpenGL version'")
    if ($opengl_version | str length) > 0 {
        $results = ($results | upsert opengl $opengl_version | upsert opengl_score 1)
        print $"  ✅ OpenGL: ($opengl_version)"
    } else {
        $results = ($results | upsert opengl "Not available" | upsert opengl_score 0)
        print "  ❌ OpenGL: Not available"
    }

    # Check Vulkan
    let vulkan_gpu = (safe_command "vulkaninfo | grep 'GPU' | head -n 1")
    if ($vulkan_gpu | str length) > 0 {
        $results = ($results | upsert vulkan $vulkan_gpu | upsert vulkan_score 1)
        print $"  ✅ Vulkan: ($vulkan_gpu)"
    } else {
        $results = ($results | upsert vulkan "Not available" | upsert vulkan_score 0)
        print "  ❌ Vulkan: Not available"
    }

    $results
}

def validate_audio_config [] {
    print $"(ansi cyan)🔊 Audio Configuration...(ansi reset)"
    mut results = {}

    # Check audio system
    let audio_system = (safe_command "pactl info | grep 'Server Name'")
    if ($audio_system | str length) > 0 {
        $results = ($results | upsert system $audio_system | upsert system_score 1)
        print $"  ✅ Audio System: ($audio_system)"
    } else {
        $results = ($results | upsert system "Not detected" | upsert system_score 0)
        print "  ❌ Audio System: Not detected"
    }

    # Check PipeWire
    let pipewire_check = (safe_command "which pipewire-pulse")
    if ($pipewire_check | str length) > 0 {
        $results = ($results | upsert pipewire "Available" | upsert pipewire_score 1)
        print "  ✅ PipeWire: Available (recommended for gaming)"
    } else {
        $results = ($results | upsert pipewire "Not available" | upsert pipewire_score 0)
        print "  ⚠️  PipeWire: Not available - PulseAudio fallback"
    }

    $results
}

def validate_performance_config [] {
    print $"(ansi cyan)⚡ Performance Configuration...(ansi reset)"
    mut results = {}

    # Check GameMode
    let gamemode_status = (safe_command "gamemoded -s")
    if ($gamemode_status | str length) > 0 {
        $results = ($results | upsert gamemode $gamemode_status | upsert gamemode_score 1)
        print $"  ✅ GameMode: ($gamemode_status)"
    } else {
        $results = ($results | upsert gamemode "Not available" | upsert gamemode_score 0)
        print "  ❌ GameMode: Not available"
    }

    # Check CPU governor
    let cpu_governor = (safe_command "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor")
    if ($cpu_governor | str contains "performance") {
        $results = ($results | upsert governor "Performance" | upsert governor_score 1)
        print "  ✅ CPU Governor: Performance mode"
    } else {
        $results = ($results | upsert governor $cpu_governor | upsert governor_score 0)
        print $"  ⚠️  CPU Governor: ($cpu_governor) - performance mode recommended"
    }

    # Check MangoHud
    let mangohud_check = (safe_command "which mangohud")
    if ($mangohud_check | str length) > 0 {
        $results = ($results | upsert mangohud "Available" | upsert mangohud_score 1)
        print "  ✅ MangoHud: Available for performance monitoring"
    } else {
        $results = ($results | upsert mangohud "Not available" | upsert mangohud_score 0)
        print "  ⚠️  MangoHud: Not available"
    }

    $results
}

def validate_gaming_tools [] {
    print $"(ansi cyan)🎮 Gaming Tools...(ansi reset)"
    mut results = {}

    # Check Steam
    let steam_check = (safe_command "which steam")
    if ($steam_check | str length) > 0 {
        $results = ($results | upsert steam "Available" | upsert steam_score 1)
        print "  ✅ Steam: Available"
    } else {
        $results = ($results | upsert steam "Not available" | upsert steam_score 0)
        print "  ❌ Steam: Not available"
    }

    # Check Lutris
    let lutris_check = (safe_command "which lutris")
    if ($lutris_check | str length) > 0 {
        $results = ($results | upsert lutris "Available" | upsert lutris_score 1)
        print "  ✅ Lutris: Available"
    } else {
        $results = ($results | upsert lutris "Not available" | upsert lutris_score 0)
        print "  ❌ Lutris: Not available"
    }

    # Check Wine
    let wine_version = (safe_command "wine --version")
    if ($wine_version | str length) > 0 {
        $results = ($results | upsert wine $wine_version | upsert wine_score 1)
        print $"  ✅ Wine: ($wine_version)"
    } else {
        $results = ($results | upsert wine "Not available" | upsert wine_score 0)
        print "  ❌ Wine: Not available"
    }

    $results
}

def validate_security_config [] {
    print $"(ansi cyan)🔒 Security Configuration...(ansi reset)"
    mut results = {}

    # Check firewall
    let ufw_status = (safe_command "ufw status | head -n 1")
    if ($ufw_status | str length) > 0 {
        $results = ($results | upsert firewall $ufw_status | upsert firewall_score 1)
        print $"  ✅ Firewall: ($ufw_status)"
    } else {
        $results = ($results | upsert firewall "Not configured" | upsert firewall_score 0)
        print "  ⚠️  Firewall: Not configured"
    }

    # Check gaming ports
    let gaming_ports = [27015, 27016, 27017, 27018, 27019, 27020]  # Steam ports
    let open_ports = (safe_command "ss -tuln | grep LISTEN | awk '{print $5}' | cut -d: -f2")
    mut blocked_ports = 0
    for port in $gaming_ports {
        if ($open_ports | str contains ($port | into string)) {
            $blocked_ports = ($blocked_ports + 1)
        }
    }

    if $blocked_ports == 0 {
        $results = ($results | upsert ports "Secure" | upsert ports_score 1)
        print "  ✅ Gaming Ports: Properly secured"
    } else {
        $results = ($results | upsert ports "Some open" | upsert ports_score 0)
        print "  ⚠️  Gaming Ports: Some ports may be open"
    }

    $results
}

def calculate_score [validations: record] {
    mut total_score = 0
    mut max_score = 0

    # Calculate scores from each validation
    for category in ($validations | columns) {
        let category_data = $validations | get $category
        if ($category_data | describe | str starts-with "record") {
            for field in ($category_data | columns) {
                if ($field | str ends-with "_score") {
                    let score = $category_data | get $field
                    $total_score = ($total_score + $score)
                    $max_score = ($max_score + 1)
                }
            }
        }
    }

    {
        score: $total_score
        max_score: $max_score
        percentage: (if $max_score == 0 { 0 } else { (($total_score / $max_score) * 100 | into int) })
    }
}

def display_validation_results [validations: record, score: record] {
    print $"\n(ansi green)📊 Validation Results Summary(ansi reset)"
    print $"(ansi yellow)============================(ansi reset)\n"
    print $"Overall Score: ($score.score)/($score.max_score) ($score.percentage)%"

    if $score.percentage >= 90 {
        print $"(ansi green)🎉 Excellent gaming configuration!(ansi reset)"
    } else if $score.percentage >= 75 {
        print $"(ansi yellow)👍 Good gaming configuration(ansi reset)"
    } else if $score.percentage >= 60 {
        print $"(ansi yellow)⚠️  Acceptable gaming configuration(ansi reset)"
    } else {
        print $"(ansi red)❌ Gaming configuration needs improvement(ansi reset)"
    }
    print ""
}

def provide_recommendations [validations: record, score: record] {
    print $"(ansi cyan)💡 Recommendations:(ansi reset)\n"

    # System recommendations
    let system = $validations.system
    if ($system | describe) == 'record' {
        if ($system.cpu_score | default 0) < 2 {
            print "  🔧 Consider upgrading to 8+ CPU cores for better gaming performance"
        }
        if ($system.memory_score | default 0) < 2 {
            print "  🔧 Consider upgrading to 16GB+ RAM for modern gaming"
        }
    }

    # Graphics recommendations
    let graphics = $validations.graphics
    if ($graphics | describe) == 'record' {
        if ($graphics.opengl_score | default 0) == 0 {
            print "  🎨 Install graphics drivers for OpenGL support"
        }
        if ($graphics.vulkan_score | default 0) == 0 {
            print "  🎨 Install Vulkan drivers for modern gaming"
        }
    }

    # Performance recommendations
    let performance = $validations.performance
    if ($performance | describe) == 'record' {
        if ($performance.gamemode_score | default 0) == 0 {
            print "  ⚡ Enable GameMode for automatic performance optimization"
        }
        if ($performance.governor_score | default 0) == 0 {
            print "  ⚡ Set CPU governor to performance mode for gaming"
        }
    }

    # Gaming tools recommendations
    let gaming = $validations.gaming
    if ($gaming | describe) == 'record' {
        if ($gaming.steam_score | default 0) == 0 {
            print "  🎮 Install Steam for the best gaming experience"
        }
        if ($gaming.wine_score | default 0) == 0 {
            print "  🎮 Install Wine for Windows game compatibility"
        }
    }

    print $"\n(ansi yellow)📚 For detailed setup instructions, see: docs/guides/gaming.md(ansi reset)"
}

# Run the validator
main
