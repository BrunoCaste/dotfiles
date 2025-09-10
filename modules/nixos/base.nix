{ config, lib, pkgs, inputs, ... }:

with lib;

{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org/"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  time.timeZone = "America/Cordoba";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" "es_AR.UTF-8/UTF-8" ];
    extraLocaleSettings = {
      LC_IDENTIFICATION = "es_AR.UTF-8";
      LC_MEASUREMENT = "es_AR.UTF-8";
      LC_MONETARY = "es_AR.UTF-8";
      LC_NAME = "es_AR.UTF-8";
      LC_NUMERIC = "es_AR.UTF-8";
      LC_PAPER = "es_AR.UTF-8";
      LC_TIME = "es_AR.UTF-8";
    };
  };

  users.users.bruno = {
    isNormalUser = true;
    description = "Bruno (the Ringmaster)";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
  ];

  programs.zsh.enable = true;

  hardware.enableAllFirmware = true;
}

