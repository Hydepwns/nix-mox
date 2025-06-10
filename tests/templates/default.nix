# tests/templates/default.nix
{
  name = "nix-mox-templates";
  nodes.machine = { pkgs, ... }: 
    let
      # Define a dummy override source
      override-src = pkgs.stdenv.mkDerivation {
        name = "web-server-override";
        src = pkgs.writeTextDir "info.txt" "Overridden by test!";
        installPhase = "cp -r $src $out";
      };
    in
  {
    imports = [ ../../modules/templates.nix ];
    services.nix-mox.templates = {
      enable = true;
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
        "web-server" = override-src;
      };
    };
  };

  testScript = ''
    start_all();
    $machine->waitForUnit("multi-user.target");

    # Test 1: Composition & Custom Options
    $machine->succeed("test -f /run/current-system/sw/bin/nix-mox-template-web-server");
    $machine->succeed("test -f /run/current-system/sw/bin/nix-mox-template-database-management");
    $machine->succeed("systemctl is-enabled web-nginx.service");
    $machine->succeed("systemctl is-enabled database-postgresql.service");

    # Test 2: Inheritance
    $machine->succeed("test -f /run/current-system/sw/bin/nix-mox-template-secure-web-server");
    $machine->succeed("readlink -f /run/current-system/sw/bin/nix-mox-template-secure-web-server | grep nginx");

    # Test 3: Template Overrides
    $machine->succeed("grep 'Overridden by test!' /run/current-system/sw/share/nix-mox/templates/web-server/info.txt");
    $machine->fail("grep 'Hello, the administrator is' /run/current-system/sw/share/nix-mox/templates/web-server/info.txt");
  '';
} 