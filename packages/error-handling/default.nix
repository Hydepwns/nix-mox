{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "nix-mox-error-handling";
  src = ./.;

  installPhase = ''
    mkdir -p $out/bin
    cp error-handling.sh $out/bin/template-error-handler
    chmod +x $out/bin/template-error-handler
  '';
}
