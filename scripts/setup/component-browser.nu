#!/usr/bin/env nu

# Import unified libraries
use ../lib/unified-checks.nu
use ../lib/unified-error-handling.nu

# Component Browser for nix-mox
# Browse and preview available configuration components
# Usage: nu component-browser.nu [--category CATEGORY] [--component COMPONENT]

use ../lib/unified-logging.nu *
use ../lib/unified-error-handling.nu *

# Color definitions
const GREEN = "ansi green"
const YELLOW = "ansi yellow"
const CYAN = "ansi cyan"
const RED = "ansi red"
const NC = "ansi reset"

# --- Component Database ---
const COMPONENT_DB = {
    development: {
        name: "Development Tools"
        description: "IDEs, compilers, debuggers, and development utilities"
        icon: "💻"
        components: {
            editors: {
                name: "Code Editors & IDEs"
                description: "Professional code editors and integrated development environments"
                icon: "📝"
                packages: {
                    vscode: {
                        name: "Visual Studio Code"
                        description: "Popular code editor with extensive extensions"
                        category: "Editor"
                        size: "Medium"
                        dependencies: []
                    }
                    vim: {
                        name: "Vim"
                        description: "Highly configurable text editor"
                        category: "Editor"
                        size: "Small"
                        dependencies: []
                    }
                    neovim: {
                        name: "Neovim"
                        description: "Modern Vim fork with better extensibility"
                        category: "Editor"
                        size: "Small"
                        dependencies: []
                    }
                    "jetbrains.idea-community": {
                        name: "IntelliJ IDEA Community"
                        description: "Java IDE with advanced features"
                        category: "IDE"
                        size: "Large"
                        dependencies: ["jdk"]
                    }
                    "jetbrains.pycharm-community": {
                        name: "PyCharm Community"
                        description: "Python IDE with debugging and testing"
                        category: "IDE"
                        size: "Large"
                        dependencies: ["python3"]
                    }
                }
                services: {
                    docker: {
                        name: "Docker"
                        description: "Container platform for development"
                        config: "virtualisation.docker.enable = true;"
                    }
                    ssh: {
                        name: "SSH Server"
                        description: "Secure shell for remote development"
                        config: "services.openssh.enable = true;"
                    }
                }
            }
            languages: {
                name: "Programming Languages"
                description: "Compilers, interpreters, and language tools"
                icon: "🔧"
                packages: {
                    rustc: {
                        name: "Rust Compiler"
                        description: "Systems programming language"
                        category: "Language"
                        size: "Medium"
                        dependencies: []
                    }
                    cargo: {
                        name: "Cargo"
                        description: "Rust package manager"
                        category: "Tool"
                        size: "Small"
                        dependencies: ["rustc"]
                    }
                    python3: {
                        name: "Python 3"
                        description: "General-purpose programming language"
                        category: "Language"
                        size: "Medium"
                        dependencies: []
                    }
                    nodejs: {
                        name: "Node.js"
                        description: "JavaScript runtime"
                        category: "Language"
                        size: "Medium"
                        dependencies: []
                    }
                    go: {
                        name: "Go"
                        description: "Google's programming language"
                        category: "Language"
                        size: "Medium"
                        dependencies: []
                    }
                    jdk: {
                        name: "Java Development Kit"
                        description: "Java development environment"
                        category: "Language"
                        size: "Large"
                        dependencies: []
                    }
                    gcc: {
                        name: "GNU Compiler Collection"
                        description: "C/C++ compiler"
                        category: "Compiler"
                        size: "Large"
                        dependencies: []
                    }
                    clang: {
                        name: "Clang"
                        description: "LLVM-based C/C++ compiler"
                        category: "Compiler"
                        size: "Large"
                        dependencies: []
                    }
                }
            }
            tools: {
                name: "Development Tools"
                description: "Build tools, version control, and utilities"
                icon: "🛠️"
                packages: {
                    git: {
                        name: "Git"
                        description: "Distributed version control system"
                        category: "VCS"
                        size: "Small"
                        dependencies: []
                    }
                    docker: {
                        name: "Docker"
                        description: "Container platform"
                        category: "Container"
                        size: "Large"
                        dependencies: []
                    }
                    cmake: {
                        name: "CMake"
                        description: "Cross-platform build system"
                        category: "Build"
                        size: "Medium"
                        dependencies: []
                    }
                    ninja: {
                        name: "Ninja"
                        description: "Fast build system"
                        category: "Build"
                        size: "Small"
                        dependencies: []
                    }
                    gdb: {
                        name: "GDB"
                        description: "GNU debugger"
                        category: "Debug"
                        size: "Medium"
                        dependencies: []
                    }
                    lldb: {
                        name: "LLDB"
                        description: "LLVM debugger"
                        category: "Debug"
                        size: "Medium"
                        dependencies: []
                    }
                }
            }
        }
    }
    gaming: {
        name: "Gaming & Entertainment"
        description: "Gaming platforms, performance tools, and media"
        icon: "🎮"
        components: {
            platforms: {
                name: "Gaming Platforms"
                description: "Game stores and launchers"
                icon: "🏪"
                packages: {
                    steam: {
                        name: "Steam"
                        description: "Valve's gaming platform"
                        category: "Platform"
                        size: "Large"
                        dependencies: []
                    }
                    lutris: {
                        name: "Lutris"
                        description: "Open gaming platform"
                        category: "Platform"
                        size: "Medium"
                        dependencies: []
                    }
                    heroic: {
                        name: "Heroic Games Launcher"
                        description: "Epic Games Store client"
                        category: "Platform"
                        size: "Medium"
                        dependencies: []
                    }
                }
                services: {
                    steam: {
                        name: "Steam Services"
                        description: "Steam platform configuration"
                        config: "programs.steam.enable = true;"
                    }
                }
            }
            performance: {
                name: "Performance Tools"
                description: "Gaming performance optimization and monitoring"
                icon: "⚡"
                packages: {
                    gamemode: {
                        name: "GameMode"
                        description: "Dynamic performance optimization"
                        category: "Performance"
                        size: "Small"
                        dependencies: []
                    }
                    mangohud: {
                        name: "MangoHud"
                        description: "Vulkan overlay for monitoring"
                        category: "Monitoring"
                        size: "Small"
                        dependencies: []
                    }
                    htop: {
                        name: "htop"
                        description: "Interactive process viewer"
                        category: "Monitoring"
                        size: "Small"
                        dependencies: []
                    }
                    radeontop: {
                        name: "RadeonTop"
                        description: "AMD GPU monitoring"
                        category: "Monitoring"
                        size: "Small"
                        dependencies: []
                    }
                }
            }
            media: {
                name: "Media & Entertainment"
                description: "Video players, music, and streaming"
                icon: "🎬"
                packages: {
                    vlc: {
                        name: "VLC Media Player"
                        description: "Versatile media player"
                        category: "Player"
                        size: "Medium"
                        dependencies: []
                    }
                    mpv: {
                        name: "mpv"
                        description: "Lightweight media player"
                        category: "Player"
                        size: "Small"
                        dependencies: []
                    }
                    spotify: {
                        name: "Spotify"
                        description: "Music streaming service"
                        category: "Streaming"
                        size: "Medium"
                        dependencies: []
                    }
                    "obs-studio": {
                        name: "OBS Studio"
                        description: "Streaming and recording software"
                        category: "Streaming"
                        size: "Large"
                        dependencies: []
                    }
                }
            }
            communication: {
                name: "Gaming Communication"
                description: "Voice chat and communication tools"
                icon: "🎤"
                packages: {
                    discord: {
                        name: "Discord"
                        description: "Gaming chat platform"
                        category: "Chat"
                        size: "Medium"
                        dependencies: []
                    }
                    teamspeak_client: {
                        name: "TeamSpeak Client"
                        description: "Voice communication"
                        category: "Voice"
                        size: "Medium"
                        dependencies: []
                    }
                    mumble: {
                        name: "Mumble"
                        description: "Open source voice chat"
                        category: "Voice"
                        size: "Small"
                        dependencies: []
                    }
                }
                services: {
                    pipewire: {
                        name: "PipeWire"
                        description: "Audio system for gaming"
                        config: "services.pipewire.enable = true;"
                    }
                    rtkit: {
                        name: "RealtimeKit"
                        description: "Real-time scheduling"
                        config: "security.rtkit.enable = true;"
                    }
                }
            }
        }
    }
    productivity: {
        name: "Productivity & Communication"
        description: "Communication tools, office apps, utilities"
        icon: "📊"
        components: {
            communication: {
                name: "Communication"
                description: "Messaging, email, and collaboration tools"
                icon: "💬"
                packages: {
                    discord: {
                        name: "Discord"
                        description: "Chat and voice platform"
                        category: "Chat"
                        size: "Medium"
                        dependencies: []
                    }
                    "signal-desktop": {
                        name: "Signal Desktop"
                        description: "Secure messaging"
                        category: "Chat"
                        size: "Medium"
                        dependencies: []
                    }
                    "telegram-desktop": {
                        name: "Telegram Desktop"
                        description: "Messaging platform"
                        category: "Chat"
                        size: "Medium"
                        dependencies: []
                    }
                    thunderbird: {
                        name: "Thunderbird"
                        description: "Email client"
                        category: "Email"
                        size: "Medium"
                        dependencies: []
                    }
                }
            }
            office: {
                name: "Office & Productivity"
                description: "Office suites, note-taking, and task management"
                icon: "📄"
                packages: {
                    libreoffice: {
                        name: "LibreOffice"
                        description: "Office productivity suite"
                        category: "Office"
                        size: "Large"
                        dependencies: []
                    }
                    obsidian: {
                        name: "Obsidian"
                        description: "Knowledge management"
                        category: "Notes"
                        size: "Medium"
                        dependencies: []
                    }
                    joplin: {
                        name: "Joplin"
                        description: "Note-taking and to-do"
                        category: "Notes"
                        size: "Medium"
                        dependencies: []
                    }
                }
            }
            utilities: {
                name: "Utilities"
                description: "File managers, system monitors, backup tools"
                icon: "🔧"
                packages: {
                    ranger: {
                        name: "Ranger"
                        description: "Terminal file manager"
                        category: "File Manager"
                        size: "Small"
                        dependencies: []
                    }
                    btop: {
                        name: "btop"
                        description: "Resource monitor"
                        category: "Monitoring"
                        size: "Small"
                        dependencies: []
                    }
                    timeshift: {
                        name: "Timeshift"
                        description: "System restore tool"
                        category: "Backup"
                        size: "Medium"
                        dependencies: []
                    }
                }
            }
        }
    }
    system: {
        name: "System & Security"
        description: "System utilities, security, monitoring"
        icon: "🛡️"
        components: {
            monitoring: {
                name: "System Monitoring"
                description: "Resource monitors and system information"
                icon: "📊"
                packages: {
                    htop: {
                        name: "htop"
                        description: "Interactive process viewer"
                        category: "Monitor"
                        size: "Small"
                        dependencies: []
                    }
                    btop: {
                        name: "btop"
                        description: "Modern resource monitor"
                        category: "Monitor"
                        size: "Small"
                        dependencies: []
                    }
                    neofetch: {
                        name: "Neofetch"
                        description: "System information display"
                        category: "Info"
                        size: "Small"
                        dependencies: []
                    }
                    inxi: {
                        name: "inxi"
                        description: "System information tool"
                        category: "Info"
                        size: "Small"
                        dependencies: []
                    }
                }
            }
            security: {
                name: "Security Tools"
                description: "Firewall, encryption, security utilities"
                icon: "🔒"
                packages: {
                    ufw: {
                        name: "UFW"
                        description: "Uncomplicated firewall"
                        category: "Firewall"
                        size: "Small"
                        dependencies: []
                    }
                    gpg: {
                        name: "GnuPG"
                        description: "Encryption and signing"
                        category: "Crypto"
                        size: "Small"
                        dependencies: []
                    }
                    pass: {
                        name: "Pass"
                        description: "Password manager"
                        category: "Security"
                        size: "Small"
                        dependencies: ["gpg"]
                    }
                }
            }
            networking: {
                name: "Networking"
                description: "VPN, network tools, remote access"
                icon: "🌐"
                packages: {
                    tailscale: {
                        name: "Tailscale"
                        description: "VPN mesh network"
                        category: "VPN"
                        size: "Medium"
                        dependencies: []
                    }
                    openvpn: {
                        name: "OpenVPN"
                        description: "VPN client"
                        category: "VPN"
                        size: "Medium"
                        dependencies: []
                    }
                    wireshark: {
                        name: "Wireshark"
                        description: "Network protocol analyzer"
                        category: "Analysis"
                        size: "Large"
                        dependencies: []
                    }
                }
                services: {
                    tailscale: {
                        name: "Tailscale Service"
                        description: "Tailscale VPN service"
                        config: "services.tailscale.enable = true;"
                    }
                }
            }
        }
    }
}

def main [] {
    let args = $env._args
    
    # Parse arguments
    mut category = ""
    mut component = ""
    mut show_help = false
    
    for arg in $args {
        match $arg {
            "--category" => {
                let index = ($args | enumerate | where item == "--category" | get index | first)
                $category = ($args | skip ($index + 1) | first)
            }
            "--component" => {
                let index = ($args | enumerate | where item == "--component" | get index | first)
                $component = ($args | skip ($index + 1) | first)
            }
            "--help" | "-h" => {
                $show_help = true
            }
            _ => {}
        }
    }
    
    if $show_help {
        usage
    } else if $category != "" and $component != "" {
        show_component_details $category $component
    } else if $category != "" {
        show_category_details $category
    } else {
        show_main_menu
    }
}

def show_main_menu [] {
    print $"\n($GREEN)🔍 nix-mox Component Browser($NC)"
    print "================================"
    print ""
    print "Browse available configuration components:"
    print ""
    
    for category in ($COMPONENT_DB | transpose category config | get category) {
        let config = ($COMPONENT_DB | get $category)
        print $"($config.icon) ($YELLOW)($config.name)($NC)"
        print $"   ($config.description)"
        print ""
    }
    
    print "Usage:"
    print "  nu component-browser.nu --category CATEGORY"
    print "  nu component-browser.nu --category CATEGORY --component COMPONENT"
    print ""
    print "Examples:"
    print "  nu component-browser.nu --category development"
    print "  nu component-browser.nu --category gaming --component platforms"
    print ""
}

def show_category_details [category: string] {
    if not ($COMPONENT_DB | get $category | is-empty) {
        let config = ($COMPONENT_DB | get $category)
        
        print $"\n($config.icon) ($YELLOW)($config.name)($NC)"
        print $"($config.description)"
        print "=" * ($config.name | str length + 10)
        print ""
        
        for component in ($config.components | transpose name details | get name) {
            let details = ($config.components | get $component)
            
            print $"($details.icon) ($CYAN)($details.name)($NC)"
            print $"   ($details.description)"
            print ""
            
            # Show packages
            if not ($details.packages | is-empty) {
                print "   📦 Packages:"
                for package in ($details.packages | transpose name pkg | get name) {
                    let pkg = ($details.packages | get $package)
                    print $"     • ($pkg.name) - ($pkg.description) [($pkg.size)]"
                }
                print ""
            }
            
            # Show services
            if not ($details.services | is-empty) {
                print "   ⚙️  Services:"
                for service in ($details.services | transpose name svc | get name) {
                    let svc = ($details.services | get $service)
                    print $"     • ($svc.name) - ($svc.description)"
                }
                print ""
            }
        }
        
        print "To see detailed information about a specific component:"
        print $"  nu component-browser.nu --category ($category) --component COMPONENT_NAME"
        print ""
    } else {
        print $"\n($RED)❌ Category '($category)' not found.($NC)"
        print ""
        print "Available categories:"
        for cat in ($COMPONENT_DB | transpose category config | get category) {
            print $"  • ($cat)"
        }
        print ""
    }
}

def show_component_details [category: string, component: string] {
    if not ($COMPONENT_DB | get $category | is-empty) {
        let category_config = ($COMPONENT_DB | get $category)
        
        if not ($category_config.components | get $component | is-empty) {
            let comp_config = ($category_config.components | get $component)
            
            print $"\n($comp_config.icon) ($YELLOW)($comp_config.name)($NC)"
            print $"($comp_config.description)"
            print "=" * ($comp_config.name | str length + 10)
            print ""
            
            # Show packages in detail
            if not ($comp_config.packages | is-empty) {
                print "📦 Packages:"
                print "-----------"
                for package in ($comp_config.packages | transpose name pkg | get name) {
                    let pkg = ($comp_config.packages | get $package)
                    
                    print $"\n($CYAN)($pkg.name)($NC) [($pkg.category)]"
                    print $"   Description: ($pkg.description)"
                    print $"   Size: ($pkg.size)"
                    if ($pkg.dependencies | length) > 0 {
                        print $"   Dependencies: ($pkg.dependencies | str join ', ')"
                    } else {
                        print "   Dependencies: None"
                    }
                }
                print ""
            }
            
            # Show services in detail
            if not ($comp_config.services | is-empty) {
                print "⚙️  Services:"
                print "------------"
                for service in ($comp_config.services | transpose name svc | get name) {
                    let svc = ($comp_config.services | get $service)
                    
                    print $"\n($CYAN)($svc.name)($NC)"
                    print $"   Description: ($svc.description)"
                    print $"   Configuration:"
                    print $"     ($svc.config)"
                }
                print ""
            }
            
            # Show installation example
            print "📋 Installation Example:"
            print "----------------------"
            print "To include this component in your configuration:"
            print ""
            print "1. Run the enhanced setup:"
            print "   nu scripts/setup/enhanced-setup.nu"
            print ""
            print "2. Select the appropriate category and component"
            print ""
            print "3. Or manually add to your configuration.nix:"
            if not ($comp_config.packages | is-empty) {
                print "   environment.systemPackages = with pkgs; ["
                for package in ($comp_config.packages | transpose name pkg | get name) {
                    print $"     ($package)"
                }
                print "   ];"
            }
            if not ($comp_config.services | is-empty) {
                for service in ($comp_config.services | transpose name svc | get name) {
                    let svc = ($comp_config.services | get $service)
                    print $"   ($svc.config)"
                }
            }
            print ""
        } else {
            print $"\n($RED)❌ Component '($component)' not found in category '($category)'.($NC)"
            print ""
            print "Available components in ($category):"
            for comp in ($category_config.components | transpose name details | get name) {
                print $"  • ($comp)"
            }
            print ""
        }
    } else {
        print $"\n($RED)❌ Category '($category)' not found.($NC)"
        print ""
        print "Available categories:"
        for cat in ($COMPONENT_DB | transpose category config | get category) {
            print $"  • ($cat)"
        }
        print ""
    }
}

def usage [] {
    print "Usage: nu component-browser.nu [OPTIONS]"
    print ""
    print "Browse and preview nix-mox configuration components."
    print ""
    print "Options:"
    print "  --category CATEGORY    Show details for a specific category"
    print "  --component COMPONENT  Show details for a specific component (requires --category)"
    print "  --help, -h            Show this help message"
    print ""
    print "Categories:"
    for category in ($COMPONENT_DB | transpose category config | get category) {
        let config = ($COMPONENT_DB | get $category)
        print $"  ($category) - ($config.name)"
    }
    print ""
    print "Examples:"
    print "  nu component-browser.nu"
    print "  nu component-browser.nu --category development"
    print "  nu component-browser.nu --category gaming --component platforms"
    exit 0
}

# --- Execution ---
try {
    main
} catch { |err|
    print $"❌ Component browser failed: ($err)"
    exit 1
}
