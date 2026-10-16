{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim
    # What the Lua config calls out to: telescope (rg, fd), nvim-treesitter's
    # main branch (tree-sitter CLI; it uses Xcode's clang), and mason, which
    # installs language servers with npm, go and pip.
    tree-sitter
    nodejs
    go
    python3
  ];

  home.sessionVariables.EDITOR = "nvim";
  programs.zsh.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };

  # The config stays plain Lua in home/nvim, linked from the working copy so
  # edits apply without a rebuild and lazy.nvim can update lazy-lock.json.
  # Commit lazy-lock.json: it pins plugin versions.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/home/nvim";
}
