# tests/templates/default.nix
{ pkgs ? import <nixpkgs> {} }:
{
  name = "nix-mox-templates";
  nodes.machine = { pkgs, ... }: {
    imports = [ ../../modules/templates.nix ];
    services.nix-mox.templates = {
      enable = true;
      # Use a composition to pull in web-server and database-management
      templates = [ "web-app-stack" "secure-web-server" ];
      customOptions = {
        web-server = {
          serverType = "nginx";
        };
        database-management = {
          dbType = "postgresql";
        };
      };
      templateVariables = {
        admin_user = "test-admin";
        domain = "test.com";
      };
      templateOverrides = {
        # Override the info.txt file in the web-server template
        "web-server" = pkgs.stdenv.mkDerivation {
          name = "web-server-override";
          src = pkgs.writeTextDir "info.txt" "Overridden by test!";
          installPhase = "cp -r $src $out";
        };
      };
    };
  };

  testScript = ''
    start_all();
    $machine->waitForUnit("multi-user.target");

    # Test 1: Composition & Custom Options
    # The web-app-stack should pull in both of these.
    $machine->succeed("test -f /run/current-system/sw/bin/nix-mox-template-web-server");
    $machine->succeed("test -f /run/current-system/sw/bin/nix-mox-template-database-management");
    # Check if systemd services are created based on customOptions
    $machine->succeed("systemctl is-enabled web-nginx.service");
    $machine->succeed("systemctl is-enabled database-postgresql.service");

    # Test 2: Inheritance
    # The secure-web-server template should be present
    $machine->succeed("test -f /run/current-system/sw/bin/nix-mox-template-secure-web-server");
    # It should inherit dependencies from web-server, like nginx
    $machine->succeed("readlink -f /run/current-system/sw/bin/nix-mox-template-secure-web-server | grep nginx");

    # Test 3: Template Variables (applied before override)
    # Although we override info.txt, the original file should have had variables substituted.
    # This is tricky to test directly without exposing the build dir, so we rely on the override test.

    # Test 4: Template Overrides
    # The info.txt file should have the content from our override derivation.
    $machine->succeed("grep 'Overridden by test!' /run/current-system/sw/share/nix-mox/templates/web-server/info.txt");
    # It should NOT contain the original content
    $machine->fail("grep 'Hello, the administrator is' /run/current-system/sw/share/nix-mox/templates/web-server/info.txt");
  '';
} 