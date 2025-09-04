#!/usr/bin/env nu
# Emergency Display Recovery Script
# Use this when you can't get past the lock screen after rebuild

# Simple logging functions for emergency recovery
def info [msg: string] { print $"[INFO] $msg" }
def debug [msg: string] { print $"[DEBUG] $msg" }

def main [
    --auto,                         # Run automatic recovery without prompts
    --minimal,                      # Minimal recovery (just get display working)
    --full,                         # Full recovery with all fixes
    --dry-run                       # Show what would be done
] {
    print "🚨 Emergency Display Recovery"
    
    if $minimal {
        minimal_recovery $dry_run
    } else if $full {
        full_recovery $dry_run
    } else if $auto {
        auto_recovery $dry_run
    } else {
        interactive_recovery $dry_run
    }
}

# Minimal recovery - just get display working
def minimal_recovery [dry_run: bool] {
    print "Minimal Display Recovery"
    
    let recovery_commands = [
        {
            name: "Stop Display Manager",
            command: "sudo systemctl stop sddm",
            description: "Stop SDDM to reset display state"
        },
        {
            name: "Kill KDE Processes",
            command: "pkill -f 'plasma|kwin|sddm'",
            description: "Kill any stuck KDE/SDDM processes"
        },
        {
            name: "Reload NVIDIA Modules", 
            command: "sudo modprobe -r nvidia_uvm nvidia_drm nvidia_modeset nvidia && sudo modprobe nvidia nvidia_modeset nvidia_drm nvidia_uvm",
            description: "Reload NVIDIA kernel modules"
        },
        {
            name: "Start Display Manager",
            command: "sudo systemctl start sddm",
            description: "Restart SDDM with fresh state"
        }
    ]
    
    execute_recovery_commands $recovery_commands $dry_run
}

# Full recovery with all display fixes
def full_recovery [dry_run: bool] {
    print "Full Display Recovery"
    
    let recovery_commands = [
        {
            name: "Stop Display Services",
            command: "sudo systemctl stop sddm",
            description: "Stop display manager"
        },
        {
            name: "Kill Display Processes",
            command: "sudo pkill -9 -f 'X|sddm|plasma|kwin'",
            description: "Force kill all display processes"
        },
        {
            name: "Clear KDE Cache",
            command: "rm -rf ~/.cache/plasma* ~/.cache/kde* ~/.cache/kwin*",
            description: "Remove potentially corrupted KDE cache"
        },
        {
            name: "Reset KDE Config (Backup First)",
            command: "mkdir -p ~/.config/backup && mv ~/.config/plasma* ~/.config/kde* ~/.config/kwin* ~/.config/backup/ 2>/dev/null || true",
            description: "Backup and reset KDE configuration"
        },
        {
            name: "Force X11 Session",
            command: "echo 'export XDG_SESSION_TYPE=x11' >> ~/.xprofile",
            description: "Force X11 session on next login"
        },
        {
            name: "Reload Graphics Stack",
            command: "sudo rmmod nvidia_uvm nvidia_drm nvidia_modeset nvidia && sudo modprobe nvidia nvidia_modeset nvidia_drm nvidia_uvm",
            description: "Completely reload NVIDIA driver stack"
        },
        {
            name: "Reset X11 Configuration",
            command: "sudo rm -f /tmp/.X*-lock /tmp/.X11-unix/X*",
            description: "Clean X11 lock files"
        },
        {
            name: "Start Display Manager",
            command: "sudo systemctl start sddm",
            description: "Restart display manager with clean state"
        }
    ]
    
    execute_recovery_commands $recovery_commands $dry_run
}

# Automatic recovery - smart recovery based on system state  
def auto_recovery [dry_run: bool] {
    print "Automatic Display Recovery"
    
    # Analyze current state
    let display_running = (try { ^pgrep -f "sddm|X" | lines | length } catch { 0 }) > 0
    let nvidia_loaded = (try { ^lsmod | grep nvidia | lines | length } catch { 0 }) > 0
    let kde_running = (try { ^pgrep -f "plasma|kwin" | lines | length } catch { 0 }) > 0
    
    print ("Display Manager Running: " + ($display_running | into string))
    print ("NVIDIA Modules Loaded: " + ($nvidia_loaded | into string))
    print ("KDE Processes Running: " + ($kde_running | into string))
    
    mut recovery_commands = []
    
    # Build recovery plan based on system state
    if $display_running {
        $recovery_commands = ($recovery_commands | append {
            name: "Stop Display Manager",
            command: "sudo systemctl stop sddm",
            description: "Stop running display manager"
        })
    }
    
    if $kde_running {
        $recovery_commands = ($recovery_commands | append {
            name: "Kill KDE Processes",
            command: "pkill -f 'plasma|kwin'",
            description: "Kill running KDE processes"
        })
    }
    
    if not $nvidia_loaded {
        $recovery_commands = ($recovery_commands | append {
            name: "Load NVIDIA Modules",
            command: "sudo modprobe nvidia nvidia_modeset nvidia_drm nvidia_uvm",
            description: "Load missing NVIDIA modules"
        })
    } else {
        $recovery_commands = ($recovery_commands | append {
            name: "Reload NVIDIA Modules",
            command: "sudo rmmod nvidia_uvm nvidia_drm nvidia_modeset nvidia && sudo modprobe nvidia nvidia_modeset nvidia_drm nvidia_uvm",
            description: "Reload NVIDIA modules"
        })
    }
    
    # Always clean cache and restart display manager
    $recovery_commands = ($recovery_commands | append {
        name: "Clean Display Cache",
        command: "rm -rf ~/.cache/sddm* /tmp/.X*-lock /tmp/.X11-unix/X*",
        description: "Clean display manager cache"
    })
    
    $recovery_commands = ($recovery_commands | append {
        name: "Start Display Manager", 
        command: "sudo systemctl start sddm",
        description: "Start display manager with clean state"
    })
    
    execute_recovery_commands $recovery_commands $dry_run
}

# Interactive recovery with user choices
def interactive_recovery [dry_run: bool] {
    print "Interactive Display Recovery"
    
    print "Select recovery actions (you can run this script with flags for automatic recovery):"
    print ""
    print "Available recovery options:"
    print "  --minimal    : Quick display recovery"
    print "  --full       : Complete display reset"
    print "  --auto       : Smart recovery based on system state"
    print "  --dry-run    : Show what would be done without executing"
    print ""
    
    # Run auto recovery by default in interactive mode
    print "Running automatic recovery in 5 seconds... (Ctrl+C to cancel)"
    sleep 5sec
    auto_recovery $dry_run
}

# Execute a list of recovery commands
def execute_recovery_commands [commands: list, dry_run: bool] {
    for cmd in $commands {
        if $dry_run {
            print ("Would execute: " + $cmd.name)
            print ("Command: " + $cmd.command)
            print ("Description: " + $cmd.description)
            continue
        }
        
        print ("Executing: " + $cmd.name)
        print ("Command: " + $cmd.command)
        
        try {
            let result = (^bash -c $cmd.command | complete)
            
            if $result.exit_code == 0 {
                print ("(" + $cmd.name + ") completed successfully")
            } else {
                print ("(" + $cmd.name + ") completed with warnings (exit code: " + ($result.exit_code | into string) + ")")
                if not ($result.stderr | is-empty) {
                    print ("Error output: " + $result.stderr)
                }
            }
        } catch { |err|
            print ("(" + $cmd.name + ") failed: " + $err.msg)
        }
        
        # Small delay between commands
        sleep 1sec
    }
    
    if not $dry_run {
        print ""
        print "Recovery commands completed!"
        print "Please wait a few seconds for the display manager to start."
        print "If the lock screen still doesn't work, try:"
        print "  1. Switch to a TTY (Ctrl+Alt+F2)"
        print "  2. Log in and run: sudo systemctl restart sddm"
        print "  3. Switch back to GUI (Ctrl+Alt+F1)"
    }
}