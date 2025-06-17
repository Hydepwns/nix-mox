{ pkgs, ... }:
let
  # Platform detection functions
  isLinux = system: builtins.elem system [ "x86_64-linux" "aarch64-linux" ];
  isDarwin = system: builtins.elem system [ "x86_64-darwin" "aarch64-darwin" ];

  self = {
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
      if !(isLinux system) then
        throw "Package ${pkg} is only available on Linux systems"
      else
        pkg;

    throwIfNotDarwin = system: pkg:
      if !(isDarwin system) then
        throw "Package ${pkg} is only available on Darwin systems"
      else
        pkg;

    # File operations
    readScript = path: builtins.readFile (pkgs.lib.cleanSourceWith {
      src = pkgs.lib.cleanSource ./.;
      filter = path: type: builtins.baseNameOf path == builtins.baseNameOf path;
    } + "/${path}");

    # Expose platform detection functions
    inherit isLinux isDarwin;
  };
in self
