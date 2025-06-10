{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) lib;
  testUtils = import ./test-utils.nix { inherit pkgs; };
  
  # Platform-specific dependencies
  platformDeps = if pkgs.stdenv.isLinux then
    with pkgs; [ zfs nvme-cli ]
  else
    with pkgs; [ ];
in
pkgs.stdenv.mkDerivation {
  name = "zfs-ssd-caching-tests";
  src = ../.;

  buildInputs = with pkgs; [
    bash
    prometheus-node-exporter
  ] ++ platformDeps;

  buildPhase = ''
    # Run all test suites
    ./tests/unit-tests.sh
    ./tests/integration-tests.sh
    ./tests/performance-tests.sh
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -r * $out/bin/
  '';
} 