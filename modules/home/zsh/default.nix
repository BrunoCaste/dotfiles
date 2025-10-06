{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.circus.home.zsh;
in {
    programs.zsh = {
      enable = true;

      autocd = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      defaultKeymap = "emacs";

      setOptions = [

        "HIST_REDUCE_BLANKS"

        "CD_SILENT"
        "AUTO_PUSHD"
        "PUSHD_IGNORE_DUPS"
        "PUSHD_SILENT"

        "INTERACTIVE_COMMENTS"
        "beep"
        "extendedglob"
        "promptsubst"

        "NO_nomatch"
        "NO_notify"
      ];

      history = {
        append = true;
        size = 10000;
        save = 10000;
        ignoreAllDups = true;
        ignoreSpace = true;
        extended = false;
        share = true;
      };

      siteFunctions = {
        g = ''
          if [[ $# -gt 0 ]]; then
            git $@
          else
            git status --short --branch
          fi
        '';

        md = "mkdir -p $1 && cd $1";

        extract = ''
          if [ -f $1 ] ; then
            case $1 in
              *.tar.bz2)   tar xjf $1     ;;
              *.tar.gz)    tar xzf $1     ;;
              *.bz2)       bunzip2 $1     ;;
              *.rar)       unrar e $1     ;;
              *.gz)        gunzip $1      ;;
              *.tar)       tar xf $1      ;;
              *.tbz2)      tar xjf $1     ;;
              *.tgz)       tar xzf $1     ;;
              *.zip)       unzip $1       ;;
              *.Z)         uncompress $1  ;;
              *.7z)        7z x $1        ;;
              *)     echo "'$1' cannot be extracted via extract()" ;;
            esac
          else
            echo "'$1' is not a valid file"
          fi
        '';
      };

      sessionVariables = {
        WORDCHARS =  "$" + "{WORDCHARS:s:/:}";
      };

      shellAliases = {
        # System management
        rebuild = "doas nixos-rebuild switch --flake ~/troupe";
        update = "nix flake update ~/troupe";

        # File operations
        mkdir = "mkdir -p";
        cp = "cp -i";
        mv = "mv -i";

        # Misc
        "..." = "../..";
        diff = "diff --color=auto";
      };

      initContent = ''
        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
        bindkey "^[[3~" delete-char
        bindkey "^[[3;5~" delete-word

        source ${./prompt.zsh}
      '';

      completionInit = ''
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' menu select

        zstyle ':completion:*' group-name ""
        zstyle ':completion:*:descriptions' format '%B%d%b'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"

        zstyle ':completion:*' list-suffixes
        zstyle ':completion:*' expand prefix suffix

        compdef 'g=git'
      '';
    };
}
