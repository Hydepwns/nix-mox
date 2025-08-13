{ config, lib, pkgs, ... }:

with lib;

# Gaming audio configuration
# Handles PipeWire, PulseAudio, and audio optimizations

let
  cfg = config.services.gaming;
in
{
  config = mkIf (cfg.enable && cfg.audio.enable && pkgs.stdenv.hostPlatform.isx86_64) {
    # Audio configuration with low-latency optimizations
    services = {
      # PipeWire for modern audio with gaming optimizations
      pipewire = mkIf cfg.audio.pipewire {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = cfg.audio.jack;
        
        # Low-latency configuration for gaming using extraConfig
        extraConfig.pipewire = {
          "99-gaming-optimization" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = 32;
              "default.clock.min-quantum" = 32;
              "default.clock.max-quantum" = 32;
            };
          };
        };
        
        extraConfig.pipewire-pulse = {
          "99-gaming-pulse" = {
            "context.properties" = {
              "log.level" = 2;
            };
            "pulse.properties" = {
              "pulse.min.req" = "32/48000";
              "pulse.default.req" = "32/48000";
              "pulse.max.req" = "32/48000";
              "pulse.min.quantum" = "32/48000";
              "pulse.max.quantum" = "32/48000";
            };
          };
        };
      };

      # PulseAudio (legacy support)
      pulseaudio = mkIf cfg.audio.pulseaudio {
        enable = false;
        support32Bit = true;
        package = pkgs.pulseaudioFull;
      };
    };

    # System packages for audio tools
    environment.systemPackages = with pkgs; [
      # Audio tools (commented out as they're optional)
      # (mkIf cfg.audio.jack jack2)
      # (mkIf cfg.audio.jack qjackctl)
    ];
  };
} 