{ lib, ... }:

with lib;

{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "25.05";
  home-manager.users.bruno.home.stateVersion = "25.05";

  circus.nixos = {
    base = enabled;
    boot = enabled;
  };
}
