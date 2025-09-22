{ lib, pkgs, ... }:

with lib;

{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "25.05";

  networking.hostName = "joker";

  circus.nixos = {
    base = enabled;
    boot = enabled;
    doas = enabled;
    network = enabled;
    keyboard = enabled;

    hyprland = enabled;
    sddm = enabled;

    fonts = enabled;
  };

  home-manager.users.bruno = { ... }: {
    home.stateVersion = "25.05";

    circus.home = {
      base = enabled;
      hyprland = enabled;
      hyprsleep = enabled;
      alacritty = enabled;
    };

    home.packages = with pkgs; [
      brave
    ];
  };

#  hardware.graphics = {
#    enable = true;
#    enable32Bit = true;
#    extraPackages = with pkgs; [
#      mesa
#      amdvlk
#    ];
#    extraPackages32 = with pkgs; [
#      driversi686Linux.amdvlk
#    ];
#  };
}
