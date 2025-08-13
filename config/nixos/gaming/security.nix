{ config, lib, pkgs, ... }:

with lib;

# Gaming security configuration
# Handles security settings for gaming applications

let
  cfg = config.services.gaming;
in
{
  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isx86_64) {
    # Security settings for gaming
    security = {
      # Allow real-time scheduling for audio
      rtkit.enable = true;

      # Allow access to /dev/snd for audio
      wrappers = {
        pulseaudio = {
          source = "${pkgs.pulseaudio}/bin/pulseaudio";
          capabilities = "cap_sys_nice+ep";
          owner = "root";
          group = "audio";
        };
      };
    };
  };
} 