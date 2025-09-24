{ config, lib, pkgs, ... }:

with lib;

{
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes,header";
    };
  };

  programs.zsh.sessionVariables = {
    MANPAGER = "sh -c 'col -b | bat -l man -p'";
    MANROFFOPT = "-c";
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  programs.zsh.shellAliases = {
    l = "eza -F";
    ls = "eza --icons";
    ll = "eza --long --all";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--border"
      "--reverse"
      "--inline-info"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--max-columns-preview"
      "--colors=line:style:bold"
    ];
  };

  programs.fd = {
    enable = true;
    hidden = true;
    ignores = [
      ".git/"
      "*.bak"
    ];
  };

  # programs.git = {
  #   enable = true;
  #   userName = "Bruno";
  #   userEmail = "castebruno@gmail.com";
  #
  #   extraConfig = {
  #     init.defaultBranch = "main";
  #     push.default = "current";
  #     pull.rebase = true;
  #     core.editor = "nvim";
  #     merge.conflictstyle = "diff3";
  #     diff.colorMoved = "zebra";
  #   };
  #
  #   delta = {
  #     enable = true;
  #     options = {
  #       navigate = true;
  #       light = false;
  #       side-by-side = true;
  #     };
  #   };
  # };

  # Additional shell packages
  home.packages = with pkgs; [
    btop
    htop

    ncdu

    unzip
    zip
    p7zip
    unrar

    jq
  ];
}
