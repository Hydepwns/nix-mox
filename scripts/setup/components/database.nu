#!/usr/bin/env nu
# Component database for nix-mox setup system
# Extracted from scripts/setup/component-browser.nu

# =============================================================================
# COMPONENT DATABASE DEFINITIONS
# =============================================================================

export const COMPONENT_DB = {
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

# Helper functions for database queries
export def get_all_categories [] {
    $COMPONENT_DB | transpose category config | get category
}

export def get_category [category: string] {
    $COMPONENT_DB | get $category
}

export def get_component [category: string, component: string] {
    let category_config = ($COMPONENT_DB | get $category)
    $category_config.components | get $component
}