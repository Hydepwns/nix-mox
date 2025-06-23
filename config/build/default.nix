{
  # Infisical configuration
  infisical = {
    version = "0.22.0";
    hashes = {
      "x86_64-linux" = "sha256:0j906p5j3q5qxqxzv8z2w3f8g1zsqwyq5j5d1d6h7yq1cc6y7352";
      "aarch64-linux" = "sha256:1nwv9i5ahq6z09aqgq0z7pf2z3i9zylwgy9wjjdf2bmz7r5k1sga";
      "x86_64-darwin" = "sha256:12wwn9f38vif8g4xsmb3is99gq7i9c5k8a3m3z6v9v395q8c5211";
      "aarch64-darwin" = "sha256:0q4r8kw7flg19q3nalb7cfc8g7k4g1v8cwv39b2a7p2q5k4w51c7";
    };
    platforms = {
      "x86_64-linux" = "linux_amd64";
      "aarch64-linux" = "linux_arm64";
      "x86_64-darwin" = "darwin_amd64";
      "aarch64-darwin" = "darwin_arm64";
    };
  };

  # Common package metadata
  meta = {
    platforms = {
      linux = [ "x86_64-linux" "aarch64-linux" ];
      darwin = [ "x86_64-darwin" "aarch64-darwin" ];
    };
  };
}
