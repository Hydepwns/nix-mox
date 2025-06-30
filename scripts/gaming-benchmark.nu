#!/usr/bin/env nu

# Gaming Performance Benchmark for nix-mox
# Tests graphics, audio, and system performance

def main [] {
    print $"(ansi green)🎮 nix-mox Gaming Performance Benchmark(ansi reset)"
    print $"(ansi yellow)==========================================(ansi reset)\n"
    
    # Check if in gaming environment
    if (which steam | is-empty) {
        print $"(ansi red)❌ Gaming tools not found. Run: nix develop .#gaming(ansi reset)\n"
        exit 1
    }
    
    # Run benchmarks
    let results = {
        graphics: benchmark_graphics
        audio: benchmark_audio
        system: benchmark_system
        gaming: benchmark_gaming_tools
    }
    
    # Display results
    display_results $results
    
    # Generate report
    generate_report $results
}

def benchmark_graphics [] {
    print $"(ansi cyan)🎨 Graphics Benchmark...(ansi reset)"
    
    let results = {}
    
    # Test OpenGL
    if (which glxinfo | is-empty) == false {
        let glx_version = (glxinfo | grep "OpenGL version" | str trim)
        $results = ($results | upsert opengl $glx_version)
        print $"  ✅ OpenGL: ($glx_version)"
    } else {
        $results = ($results | upsert opengl "Not available")
        print "  ❌ OpenGL: Not available"
    }
    
    # Test Vulkan
    if (which vulkaninfo | is-empty) == false {
        let vulkan_gpu = (vulkaninfo | grep "GPU" | head -n 1 | str trim)
        $results = ($results | upsert vulkan $vulkan_gpu)
        print $"  ✅ Vulkan: ($vulkan_gpu)"
    } else {
        $results = ($results | upsert vulkan "Not available")
        print "  ❌ Vulkan: Not available"
    }
    
    # Test glmark2
    if (which glmark2 | is-empty) == false {
        print "  🏃 Running glmark2 benchmark..."
        let glmark_score = (timeout 30 glmark2 --fullscreen 2>/dev/null | grep "glmark2 Score" | awk '{print $3}' | str trim)
        if ($glmark_score | is-empty) {
            $results = ($results | upsert glmark2 "Timeout/Error")
            print "  ⚠️  glmark2: Timeout or error"
        } else {
            $results = ($results | upsert glmark2 $glmark_score)
            print $"  ✅ glmark2 Score: ($glmark_score)"
        }
    } else {
        $results = ($results | upsert glmark2 "Not installed")
        print "  ⚠️  glmark2: Not installed"
    }
    
    $results
}

def benchmark_audio [] {
    print $"(ansi cyan)🔊 Audio Benchmark...(ansi reset)"
    
    let results = {}
    
    # Test audio system
    if (which pactl | is-empty) == false {
        let audio_info = (pactl info | grep "Server Name" | str trim)
        $results = ($results | upsert system $audio_info)
        print $"  ✅ Audio System: ($audio_info)"
    } else {
        $results = ($results | upsert system "Not detected")
        print "  ❌ Audio System: Not detected"
    }
    
    # Test latency
    if (which pw-top | is-empty) == false {
        let latency = (pw-top --once 2>/dev/null | grep "latency" | head -n 1 | str trim)
        $results = ($results | upsert latency $latency)
        print $"  ✅ Latency: ($latency)"
    } else {
        $results = ($results | upsert latency "Not available")
        print "  ⚠️  Latency: Not available"
    }
    
    $results
}

def benchmark_system [] {
    print $"(ansi cyan)⚡ System Benchmark...(ansi reset)"
    
    let results = {}
    
    # CPU info
    let cpu_model = (lscpu | grep "Model name" | awk -F': ' '{print $2}' | str trim)
    let cpu_cores = (nproc)
    $results = ($results | upsert cpu $"($cpu_model) ($cpu_cores cores)")
    print $"  ✅ CPU: ($cpu_model) ($cpu_cores cores)"
    
    # Memory
    let mem_total = (free -h | grep Mem | awk '{print $2}')
    let mem_available = (free -h | grep Mem | awk '{print $7}')
    $results = ($results | upsert memory $"($mem_total) total, ($mem_available) available")
    print $"  ✅ Memory: ($mem_total) total, ($mem_available) available"
    
    # GPU
    let gpu_info = (lspci | grep -i vga | str trim)
    $results = ($results | upsert gpu $gpu_info)
    print $"  ✅ GPU: ($gpu_info)"
    
    # GameMode
    if (which gamemoded | is-empty) == false {
        let gamemode_status = (gamemoded -s | str trim)
        $results = ($results | upsert gamemode $gamemode_status)
        print $"  ✅ GameMode: ($gamemode_status)"
    } else {
        $results = ($results | upsert gamemode "Not available")
        print "  ⚠️  GameMode: Not available"
    }
    
    $results
}

def benchmark_gaming_tools [] {
    print $"(ansi cyan)🎮 Gaming Tools Benchmark...(ansi reset)"
    
    let results = {}
    
    # Steam
    if (which steam | is-empty) == false {
        $results = ($results | upsert steam "Available")
        print "  ✅ Steam: Available"
    } else {
        $results = ($results | upsert steam "Not available")
        print "  ❌ Steam: Not available"
    }
    
    # Lutris
    if (which lutris | is-empty) == false {
        $results = ($results | upsert lutris "Available")
        print "  ✅ Lutris: Available"
    } else {
        $results = ($results | upsert lutris "Not available")
        print "  ❌ Lutris: Not available"
    }
    
    # Wine
    if (which wine | is-empty) == false {
        let wine_version = (wine --version | str trim)
        $results = ($results | upsert wine $wine_version)
        print $"  ✅ Wine: ($wine_version)"
    } else {
        $results = ($results | upsert wine "Not available")
        print "  ❌ Wine: Not available"
    }
    
    # MangoHud
    if (which mangohud | is-empty) == false {
        $results = ($results | upsert mangohud "Available")
        print "  ✅ MangoHud: Available"
    } else {
        $results = ($results | upsert mangohud "Not available")
        print "  ⚠️  MangoHud: Not available"
    }
    
    $results
}

def display_results [results: record] {
    print $"\n(ansi green)📊 Benchmark Results Summary(ansi reset)"
    print $"(ansi yellow)==========================(ansi reset)\n"
    
    # Graphics
    print $"(ansi cyan)🎨 Graphics:(ansi reset)"
    print $"  OpenGL: ($results.graphics.opengl)"
    print $"  Vulkan: ($results.graphics.vulkan)"
    print $"  glmark2: ($results.graphics.glmark2)\n"
    
    # Audio
    print $"(ansi cyan)🔊 Audio:(ansi reset)"
    print $"  System: ($results.audio.system)"
    print $"  Latency: ($results.audio.latency)\n"
    
    # System
    print $"(ansi cyan)⚡ System:(ansi reset)"
    print $"  CPU: ($results.system.cpu)"
    print $"  Memory: ($results.system.memory)"
    print $"  GPU: ($results.system.gpu)"
    print $"  GameMode: ($results.system.gamemode)\n"
    
    # Gaming Tools
    print $"(ansi cyan)🎮 Gaming Tools:(ansi reset)"
    print $"  Steam: ($results.gaming.steam)"
    print $"  Lutris: ($results.gaming.lutris)"
    print $"  Wine: ($results.gaming.wine)"
    print $"  MangoHud: ($results.gaming.mangohud)\n"
}

def generate_report [results: record] {
    let timestamp = (date now | format date '%Y-%m-%d_%H-%M-%S')
    let report_file = $"gaming-benchmark-($timestamp).json"
    
    $results | to json | save $report_file
    
    print $"(ansi green)📄 Report saved to: ($report_file)(ansi reset)"
    print $"(ansi yellow)💡 Use this report to track performance improvements over time(ansi reset)\n"
}

# Run the benchmark
main 