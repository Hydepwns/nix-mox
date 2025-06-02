#!/bin/sh
set -e
cd /etc/nixos
nix flake update
nixos-rebuild switch --flake . 