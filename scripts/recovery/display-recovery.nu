#!/usr/bin/env nu

# Display Recovery Script for nix-mox
# Helps recover from black screen and display issues

def show_banner [] {
    print "(ansi red)🖥️  nix-mox Display Recovery(ansi reset)"
    print "(ansi yellow)==============================(ansi reset)"
    print ""
}

def check_current_state [] {
    print "(ansi blue)🔍 Checking current display state...(ansi reset)"
    
    let display_vars = {
        DISPLAY: ($env.DISPLAY? | default "not set")
        XDG_CURRENT_DESKTOP: ($env.XDG_CURRENT_DESKTOP? | default "not set")
        WAYLAND_DISPLAY: ($env.WAYLAND_DISPLAY? | default "not set")
    }
    
    print $"  Display: ($display_vars.DISPLAY)"
    print $"  Desktop: ($display_vars.XDG_CURRENT_DESKTOP)"
    print $"  Wayland: ($display_vars.WAYLAND_DISPLAY)"
    print ""
    
    $display_vars
}

def check_display_services [] {
    print "(ansi blue)🔍 Checking display services...(ansi reset)"
    
    let services = [
        "display-manager"
        "sddm"
        "gdm"
        "lightdm"
    ]
    
    let service_status = ($services | each {|service|
        let status = (try {
            systemctl is-active $service
        } catch {
            "inactive"
        })
        
        {
            service: $service
            status: $status
        }
    })
    
    $service_status | each {|s|
        let status_icon = if $s.status == "active" { "(ansi green)✅" } else { "(ansi red)❌" }
        print $"  ($status_icon) ($s.service): ($s.status)"
    }
    print ""
    
    $service_status
}

def check_gpu_drivers [] {
    print "(ansi blue)🔍 Checking GPU drivers...(ansi reset)"
    
    let nvidia_check = (try {
        nvidia-smi --query-gpu=name,driver_version --format=csv,noheader,nounits
    } catch {
        "NVIDIA driver not available"
    })
    
    let lspci_check = (try {
        lspci | grep -i vga
    } catch {
        "Could not check PCI devices"
    })
    
    print $"  NVIDIA: ($nvidia_check)"
    print $"  PCI: ($lspci_check)"
    print ""
    
    {
        nvidia: $nvidia_check
        pci: $lspci_check
    }
}

def emergency_display_fix [] {
    print "(ansi red)🚨 Emergency Display Fix(ansi reset)"
    print "This will attempt to restart display services..."
    print ""
    
    print "1. Stopping display manager..."
    try {
        sudo systemctl stop display-manager
        print "   ✅ Display manager stopped"
    } catch {
        print "   ⚠️  Could not stop display manager"
    }
    
    print "2. Restarting display manager..."
    try {
        sudo systemctl start display-manager
        print "   ✅ Display manager started"
    } catch {
        print "   ❌ Failed to start display manager"
    }
    
    print "3. Waiting for display to initialize..."
    sleep 5sec
    
    print "4. Checking display status..."
    let status = (try {
        systemctl is-active display-manager
    } catch {
        "unknown"
    })
    
    if $status == "active" {
        print "(ansi green)✅ Display manager is running(ansi reset)"
    } else {
        print "(ansi red)❌ Display manager is not running(ansi reset)"
    }
}

def console_recovery [] {
    print "(ansi yellow)💻 Console Recovery Mode(ansi reset)"
    print "If you're stuck at a black screen, try these steps:"
    print ""
    print "1. Press Ctrl+Alt+F1 to switch to console"
    print "2. Login as nixos user"
    print "3. Run: sudo systemctl restart display-manager"
    print "4. Press Ctrl+Alt+F7 to return to display"
    print ""
    print "If that doesn't work:"
    print "1. Press Ctrl+Alt+F1"
    print "2. Run: sudo nixos-rebuild boot --flake .#nixos"
    print "3. Reboot: sudo reboot"
    print ""
}

def main [] {
    show_banner
    
    let current_state = check_current_state
    let service_status = check_display_services
    let gpu_info = check_gpu_drivers
    
    print "(ansi yellow)📋 Recovery Options:(ansi reset)"
    print "1. Emergency display fix (restart services)"
    print "2. Console recovery instructions"
    print "3. Exit"
    print ""
    
    let choice = (input "Choose option (1-3): ")
    
    match $choice {
        "1" => {
            emergency_display_fix
        }
        "2" => {
            console_recovery
        }
        "3" => {
            print "Exiting..."
        }
        _ => {
            print "(ansi red)Invalid choice(ansi reset)"
        }
    }
}

# Run main function
main 