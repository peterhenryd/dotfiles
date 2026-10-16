{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./packages.nix
    ./zsh.nix
    ./git.nix
    ./ghostty.nix
    ./neovim.nix
    ./aerospace.nix
    ./karabiner.nix
    ./swipeaerospace.nix
  ];

  options.dotfiles.path = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.config/dotfiles";
    description = ''
      Where this repo is checked out. Configs that apps write back to
      (Neovim's lazy-lock.json, Karabiner's settings UI) are linked to this
      working copy instead of the read-only Nix store, so their edits show up
      in `git status`.
    '';
  };

  config = {
    # XDG base directories (~/.config, ~/.local/share, ~/.local/state, ~/.cache)
    # for everything that supports them.
    xdg.enable = true;

    home.activation = {
      screenshotsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "$HOME/Pictures/Screenshots"
      '';
      # Point the repo at its pre-commit hook, which blocks key material.
      dotfilesHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -d "${config.dotfiles.path}/.git" ]; then
          run chmod +x "${config.dotfiles.path}/.githooks/pre-commit"
          run ${lib.getExe pkgs.git} -C "${config.dotfiles.path}" config core.hooksPath .githooks
        fi
      '';
    };
  };
}
