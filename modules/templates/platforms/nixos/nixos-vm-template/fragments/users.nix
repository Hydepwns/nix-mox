{ config, pkgs, inputs, ... }:
{
  # WARNING: Change the default password and set your own SSH key!
  # For production, set users.users.example.password = null; and use SSH keys only.
  # To lock the user if no key is set:
  # users.users.example.isLocked = true;

  users.users.example = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "example";
  };
}
