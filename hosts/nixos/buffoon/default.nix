{ lib, ... }:

with lib;

{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.11";
  home-manager.users.bruno.home.stateVersion = "24.05";

  circus.nixos = {
    base = enabled;
    boot = enabled;
  };
}
