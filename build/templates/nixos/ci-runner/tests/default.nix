{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) lib;
  testUtils = import ./test-utils.nix { inherit pkgs; };
in
pkgs.stdenv.mkDerivation {
  name = "ci-runner-tests";
  src = ../.;

  buildInputs = with pkgs; [
    bash
    coreutils
  ];

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