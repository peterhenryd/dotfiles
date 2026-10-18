# Ghostty. The app comes from the Homebrew cask; its settings are the plain
# config file in home/ghostty, linked from the working copy like Neovim's.
{ config, ... }:
{
  # For the zsh integration only (prompt marks, the sudo and ssh helpers);
  # with no `settings`, Home Manager writes no config file of its own.
  programs.ghostty = {
    enable = true;
    package = null;
  };

  xdg.configFile."ghostty/config.ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/home/ghostty/config.ghostty";
}
