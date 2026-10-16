# GUI apps come from Homebrew casks: they keep the vendor's signature, which
# macOS 27's permission checks and TCC grants (Accessibility etc.) depend on.
# Standalone CLI tools come from nixpkgs (see home/packages.nix). C/C++
# libraries stay in Homebrew, where CMake and pkg-config already find them.
{ config, inputs, ... }:
let
  # Matches the brew-src tag in flake.nix.
  brewVersion = "7.0.9";
in
{
  nix-homebrew = {
    enable = true;
    package = inputs.brew-src // {
      name = "brew-${brewVersion}";
      version = brewVersion;
    };
    # Takes over the existing /opt/homebrew: deletes Homebrew's own git
    # checkout and keeps everything installed (Cellar, Caskroom).
    autoMigrate = true;
    # Taps are flake inputs, so `flake.lock` pins them; `brew tap` is disabled.
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "nikitabobko/homebrew-tap" = inputs.homebrew-aerospace;
    };
    # Third-party taps need explicit trust; trust only the one cask used.
    trust.casks = [ "nikitabobko/tap/aerospace" ];
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;

    onActivation = {
      # Anything installed with brew but not declared here is uninstalled on
      # the next switch. App data in ~/Library is kept (that would be "zap").
      cleanup = "uninstall";
      # A switch installs what's missing but leaves installed versions alone;
      # upgrades happen only through an explicit `brew upgrade`. This keeps
      # paid major versions (Parallels 26 → 27) from arriving unasked.
      upgrade = false;
      autoUpdate = false;
    };
    global.autoUpdate = false;

    casks = [
      # New with this config
      "nikitabobko/tap/aerospace"
      "karabiner-elements"

      # Already installed with brew before this config
      "adobe-creative-cloud"
      "antigravity-cli"
      "bettertouchtool"
      "claude-code"
      "ghostty"
      "jetbrains-toolbox"
      "macs-fan-control"
      "parallels"
      "postgres-app"
    ];

    # Formulae you installed yourself (dependencies are kept automatically).
    # age, gh, neovim, nmap, swaks, tokei, tree and uv moved to nixpkgs.
    brews = [
      "boost"
      "cbc"
      "cmake"
      "docbook"
      "docbook-xsl"
      "ensmallen"
      "libimobiledevice"
      "mlpack"
      "mlx-c"
      "pkgconf"
    ];

    # Apps installed by hand. A cask can't install over an existing copy, so to
    # bring one under Homebrew: quit it, move the .app to the Trash (its data
    # in ~/Library stays), uncomment it, and switch.
    #
    #   "keepassxc"          # pending the vault decision
    #   "anki"
    #   "bruno"
    #   "discord"
    #   "microsoft-word"
    #   "openemu"
    #   "pcsx2"
    #   "protonvpn"
    #   "spotify"
    #
    # No cask exists for AdGuard Mini or GroupMe. Xcode, WireGuard and the
    # Creator Studio apps come from the App Store.
  };
}
