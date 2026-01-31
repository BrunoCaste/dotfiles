{ config
, lib
, pkgs
, ...
}:
with lib; {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      fzf
      gnumake
      ripgrep

      gcc
      nodejs
      tree-sitter

      lua-language-server
      nil
    ];

    # plugins = with pkgs.vimPlugins; [
    #   nvim-cmp
    #   cmp-nvim-lsp
    #   cmp-buffer
    #   cmp-path
    #   cmp_luasnip
    #   luasnip
    #   mini-comment
    #   mini-surround
    #   mini-pairs
    #
    #   tokyonight-nvim
    #
    #   which-key-nvim
    #   gitsigns-nvim
    #   telescope-nvim
    #   telescope-fzf-native-nvim
    #   todo-comments-nvim
    #
    #   nvim-lspconfig
    #   lazydev-nvim
    #
    #   lualine-nvim
    #   noice-nvim
    #
    #   (nvim-treesitter.withPlugins (p: with p; [
    #     bibtex
    #     c
    #     cpp
    #     latex
    #     lua
    #     nim
    #     python
    #     regex
    #     rust
    #     vim
    #     vimdoc
    #   ]))
    #   playground # tree-sitter playground
    #   mini-ai
    #   nvim-treesitter-textobjects
    # ];
  };

  # xdg.configFile."nvim/lua".source = config.lib.file.mkOutOfStoreSymlink "/home/bruno/dotfiles/modules/home/neovim/config/lua";
  # xdg.configFile."nvim/init.lua".source = config.lib.file.mkOutOfStoreSymlink "/home/bruno/dotfiles/modules/home/neovim/config/init.lua";
}
