{ pkgs }:

let
  errorHandler = pkgs.writeScriptBin "template-error-handler" ''
    #!${pkgs.bash}/bin/bash
    set -e

    logMessage() {
        local level="$1"
        local message="$2"
        local timestamp=$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] [$level] $message"
        echo "[$timestamp] [$level] $message" >> /var/log/nix-mox/template-errors.log
    }

    handleError() {
        local errorCode="$1"
        local errorMessage="$2"
        logMessage "ERROR" "Error $errorCode: $errorMessage"
        exit "$errorCode"
    }
  '';
in
pkgs.stdenv.mkDerivation {
  name = "nix-mox-error-handling";
  src = ./.;
  buildInputs = [ pkgs.coreutils ];

  installPhase = ''
    mkdir -p $out/bin
    cp ${errorHandler}/bin/template-error-handler $out/bin/
    chmod +x $out/bin/template-error-handler
  '';

  # Expose the functions as attributes
  passthru = {
    handleError = "${errorHandler}/bin/template-error-handler handleError";
    logMessage = "${errorHandler}/bin/template-error-handler logMessage";
  };
}
