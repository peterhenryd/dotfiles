{ config, ... }:
{
  programs.zsh = {
    enable = true;
    # Keeps .zshrc and friends in ~/.config/zsh; ~/.zshenv is the one file left
    # in ~ (it points zsh there).
    dotDir = "${config.xdg.configHome}/zsh";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 100000;
      save = 100000;
      share = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
    };
    shellAliases = {
      # Clears the screen and the scrollback behind it. `clear` alone leaves
      # the scrollback in some terminals (Terminal.app among them); \e[3J
      # asks the terminal to drop it.
      c = "clear && printf '\\e[3J'";
    };
  };

  # Terminal sessions start without the "Last login" line.
  home.file.".hushlogin".text = "";

  programs.fzf.enable = true; # ⌃R history search, ⌃T file picker
  programs.zoxide = {
    enable = true;
    # zoxide takes over `cd`: `cd <path>` works as before, `cd <part of a
    # path>` jumps to the best match among visited folders, `cdi` picks
    # one with fzf.
    options = [
      "--cmd"
      "cd"
    ];
  };
  programs.eza.enable = true; # ls replacement; adds ls/ll/la aliases
  programs.bat.enable = true;
  # `btm`: process and resource monitor.
  programs.bottom.enable = true;
  programs.tealdeer = {
    enable = true; # `tldr <command>`: short usage examples
    # Pages download on first use and refresh when a month old, instead of
    # through a weekly launch agent.
    enableAutoUpdates = false;
    settings.updates.auto_update = true;
  };
  programs.direnv = {
    enable = true;
    # Cached `use flake` for per-project dev shells.
    nix-direnv.enable = true;
  };
}
