{ config, lib, pkgs, ... }:

with lib;

{
  programs.home-manager.enable = true;

  users.bruno = {
    home = {
      username = bruno;
      homeDirectory = "/home/bruno";
    };
  };

  # Nix Flakes often needs Git
  programs.git.enable = true;
};

