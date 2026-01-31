{
  lib,
  pkgs,
  ...
}:
with lib;
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "25.05";

  networking.hostName = "buffoon";

  circus.nixos = {
    base = enabled;
    graphical = enabled;
    boot = enabled;
    doas = enabled;
    network = enabled;

    compositor.hyprland = enabled;
  };

  home-manager.users.bruno =
    { ... }:
    {
      home.stateVersion = "25.05";

      circus.home = {
        base = enabled;
        compositor.hyprland = enabled;
        compositor.hyprsleep = enabled;
        desktop-apps.terminal = enabled;
      };
    };
}
