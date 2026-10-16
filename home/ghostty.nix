{ ... }:
{
  programs.ghostty = {
    enable = true;
    # The app itself comes from the Homebrew cask; this only writes
    # ~/.config/ghostty/config.
    package = null;
    settings = {
      # Matches the Neovim colorscheme, which expects a translucent background.
      theme = "Catppuccin Mocha";
      background-opacity = 0.9;
      background-blur = 20;

      # Left Option is Meta (⌥b/⌥f in zsh, Alt maps in Neovim); right Option
      # still types special characters.
      macos-option-as-alt = "left";

      window-padding-x = 8;
      window-padding-y = 6;
      window-save-state = "always";
      mouse-hide-while-typing = true;
      copy-on-select = "clipboard";
      # ssh-terminfo installs Ghostty's terminfo on hosts you ssh into.
      shell-integration-features = "sudo,title,ssh-terminfo";

      # ⌃` drops down a terminal from any app. Global keybinds need
      # Accessibility permission for Ghostty.
      keybind = [ "global:ctrl+grave_accent=toggle_quick_terminal" ];
    };
  };
}
