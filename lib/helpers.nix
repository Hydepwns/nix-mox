{ pkgs, ... }:
let
  self = {
    # Platform detection
    isLinux = system: builtins.elem system [ "x86_64-linux" "aarch64-linux" ];
    isDarwin = system: builtins.elem system [ "x86_64-darwin" "aarch64-darwin" ];

    # Package creation helpers
    createShellApp = { name, runtimeInputs, text, meta }:
      pkgs.writeShellApplication {
        inherit name runtimeInputs text meta;
      };

    createTextFile = { name, destination, text, executable ? false }:
      pkgs.writeTextFile {
        inherit name destination text executable;
      };

    # Error handling
    throwIfNotLinux = system: pkg:
      if !(self.isLinux system) then
        throw "Package ${pkg} is only available on Linux systems"
      else
        pkg;

    throwIfNotDarwin = system: pkg:
      if !(self.isDarwin system) then
        throw "Package ${pkg} is only available on Darwin systems"
      else
        pkg;

    # File operations
    readScript = path: builtins.readFile path;
  };
in self
