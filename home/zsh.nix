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
      rebuild = "sudo darwin-rebuild switch --flake ${config.dotfiles.path}";
    };
  };

  programs.fzf.enable = true; # ⌃R history search, ⌃T file picker
  programs.zoxide.enable = true; # `z <part of a path>`
  programs.eza.enable = true; # ls replacement; adds ls/ll/la aliases
  programs.bat.enable = true;
  programs.direnv = {
    enable = true;
    # Cached `use flake` for per-project dev shells.
    nix-direnv.enable = true;
  };
}
