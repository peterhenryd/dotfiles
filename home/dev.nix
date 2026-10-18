# Development tools: rustup (with Cargo's settings), OpenCode and Claude
# Code's settings. Claude Code itself comes from the claude-code cask.
{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;
in
{
  # The commands `cargo install` adds.
  home.sessionPath = [ "${home}/.cargo/bin" ];

  programs.cargo = {
    enable = true;
    # rustup provides cargo.
    package = null;
    settings.build = {
      # One build folder for every project instead of a target/ in each.
      target-dir = "${home}/.cargo-shared-target";
      # Compiler output is cached across projects and clean builds. Set here
      # rather than as RUSTC_WRAPPER so builds started from an IDE use it too.
      rustc-wrapper = "${pkgs.sccache}/bin/sccache";
    };
  };

  home.packages = with pkgs; [
    # cargo, rustc and the rest. Toolchains live in ~/.rustup; on a new Mac,
    # `rustup default stable` downloads the first one.
    rustup
    # `sccache --show-stats` and friends.
    sccache
    # Builds macOS .app bundles from Rust projects.
    cargo-bundle
    # Task runner for Makefile.toml (`cargo make`, `makers`).
    cargo-make
  ];

  # From nixpkgs, whose package turns off OpenCode's own updater;
  # `nix flake update` updates it.
  programs.opencode = {
    enable = true;
    settings = {
      provider.mlx = {
        npm = "@ai-sdk/openai-compatible";
        name = "MLX local";
        # The port `mlx_lm.server` listens on by default.
        options.baseURL = "http://localhost:8080/v1";
        models."peculiar-ragdoll/Tiel-Coder-35B-A3B-MLX-oQ4e-MTP" = { };
      };
      mcp.context7 = {
        type = "remote";
        url = "https://mcp.context7.com/mcp";
      };
      permission = {
        webfetch = "ask";
        bash = "ask";
        edit = "ask";
      };
    };
  };

  programs.claude-code = {
    enable = true;
    package = null;
    # Claude Code writes to ~/.claude/settings.json itself (/config, /model,
    # plugin installs). Each switch merges these values into that file
    # instead of replacing it; what Claude Code changes stays on this Mac
    # until it's copied here.
    mutableSettings = true;
    settings = builtins.fromJSON (builtins.readFile ./claude/settings.json);
  };
}
