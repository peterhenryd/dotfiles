{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    age
    nmap
    swaks
    tokei
    tree
    uv
    # Editing this repo: formatter and language server for Nix.
    nixfmt
    nil
  ];
}
