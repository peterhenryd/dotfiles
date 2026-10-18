# Settings for development tools that are installed outside Nix: Cargo
# (through rustup), OpenCode (its own installer, which keeps it updated) and
# Claude Code (the claude-code cask).
{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;
in
{
  home.sessionPath = [
    # rustup's cargo and rustc, and the commands `cargo install` adds.
    "${home}/.cargo/bin"
    "${home}/.opencode/bin"
    # Launchers JetBrains Toolbox makes for its IDEs.
    "${home}/Library/Application Support/JetBrains/Toolbox/scripts"
  ];

  programs.cargo = {
    enable = true;
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
    # `sccache --show-stats` and friends.
    sccache
    # Builds macOS .app bundles from Rust projects.
    cargo-bundle
    # Task runner for Makefile.toml (`cargo make`, `makers`).
    cargo-make
  ];

  programs.opencode = {
    enable = true;
    package = null;
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
