{ config, pkgs, ... }:
{
  # `uv tool install` puts its commands here.
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    age
    nmap
    swaks
    tokei
    tree
    dust
    uv
    # Editing this repo: formatter and language server for Nix.
    nixfmt
    nil
  ];
}
