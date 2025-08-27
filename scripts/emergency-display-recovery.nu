#!/usr/bin/env nu
# Emergency Display Recovery Script
# Use this when you can't get past the lock screen after rebuild

use lib/logging.nu *

def main [
    --auto,                         # Run automatic recovery without prompts
    --minimal,                      # Minimal recovery (just get display working)
    --full,                         # Full recovery with all fixes
    --dry-run                       # Show what would be done
] {
    banner "🚨 Emergency Display Recovery" --context "recovery"
    
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
    section "Minimal Display Recovery" --context "recovery"
    
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
    section "Full Display Recovery" --context "recovery"
    
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
    section "Automatic Display Recovery" --context "recovery"
    
    # Analyze current state
    let display_running = (try { ^pgrep -f "sddm|X" | lines | length } catch { 0 }) > 0
    let nvidia_loaded = (try { ^lsmod | grep nvidia | lines | length } catch { 0 }) > 0
    let kde_running = (try { ^pgrep -f "plasma|kwin" | lines | length } catch { 0 }) > 0
    
    info $"Display Manager Running: ($display_running)" --context "recovery"
    info $"NVIDIA Modules Loaded: ($nvidia_loaded)" --context "recovery"  
    info $"KDE Processes Running: ($kde_running)" --context "recovery"
    
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
    section "Interactive Display Recovery" --context "recovery"
    
    info "Select recovery actions (you can run this script with flags for automatic recovery):" --context "recovery"
    info "" --context "recovery"
    info "Available recovery options:" --context "recovery"
    info "  --minimal    : Quick display recovery" --context "recovery"
    info "  --full       : Complete display reset" --context "recovery"
    info "  --auto       : Smart recovery based on system state" --context "recovery"
    info "  --dry-run    : Show what would be done without executing" --context "recovery"
    info "" --context "recovery"
    
    # Run auto recovery by default in interactive mode
    warn "Running automatic recovery in 5 seconds... (Ctrl+C to cancel)" --context "recovery"
    sleep 5sec
    auto_recovery $dry_run
}

# Execute a list of recovery commands
def execute_recovery_commands [commands: list, dry_run: bool] {
    for cmd in $commands {
        if $dry_run {
            info $"[DRY RUN] Would execute: ($cmd.name)" --context "recovery"
            debug $"  Command: ($cmd.command)" --context "recovery"
            debug $"  Description: ($cmd.description)" --context "recovery"
            continue
        }
        
        info $"Executing: ($cmd.name)" --context "recovery"
        debug $"Command: ($cmd.command)" --context "recovery"
        
        try {
            let result = (^bash -c $cmd.command | complete)
            
            if $result.exit_code == 0 {
                success $"✅ ($cmd.name) completed successfully" --context "recovery"
            } else {
                warn $"⚠️  ($cmd.name) completed with warnings (exit code: ($result.exit_code))" --context "recovery"
                if not ($result.stderr | is-empty) {
                    debug $"Error output: ($result.stderr)" --context "recovery"
                }
            }
        } catch { |err|
            error $"❌ ($cmd.name) failed: ($err.msg)" --context "recovery"
        }
        
        # Small delay between commands
        sleep 1sec
    }
    
    if not $dry_run {
        info "" --context "recovery"
        success "Recovery commands completed!" --context "recovery"
        info "Please wait a few seconds for the display manager to start." --context "recovery"
        info "If the lock screen still doesn't work, try:" --context "recovery"
        info "  1. Switch to a TTY (Ctrl+Alt+F2)" --context "recovery"
        info "  2. Log in and run: sudo systemctl restart sddm" --context "recovery"
        info "  3. Switch back to GUI (Ctrl+Alt+F1)" --context "recovery"
    }
}