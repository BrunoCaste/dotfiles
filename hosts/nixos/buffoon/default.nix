{ lib, pkgs, ... }:

with lib;

{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "25.05";

  networking.hostName = "buffoon";

  circus.nixos = {
    base = enabled;
    boot = enabled;
    doas = enabled;
    network = enabled;

    hyprland = enabled;
    sddm = enabled;
  };

  home-manager.users.bruno = { ... }: {
    home.stateVersion = "25.05";

    circus.home = {
      hyprland = enabled;
      alacritty = enabled;
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      amdvlk
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };
}
