{
  description = "Peter's macOS configuration: nix-darwin + home-manager + declarative Homebrew";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Installs Homebrew itself and pins its taps, so `flake.lock` also pins
    # which cask versions a rebuild installs.
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.brew-src.follows = "brew-src";
    };
    # Homebrew's own source. Formulae in a newer homebrew-core can use syntax
    # an older Homebrew can't parse, so this tracks a recent release rather
    # than nix-homebrew's pin. The version is repeated in
    # modules/darwin/homebrew.nix.
    brew-src = {
      url = "github:Homebrew/brew/7.0.9";
      flake = false;
    };
    homebrew-core = {
      url = "github:Homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:Homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-aerospace = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };

    # Built locally with Xcode by `nix run .#swipeaerospace` (see apps/).
    swipeaerospace = {
      url = "github:MediosZ/SwipeAeroSpace";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      # Reusable pieces, for anyone who wants parts of this without the host.
      darwinModules.default = ./modules/darwin;
      homeModules.default = ./home;

      darwinConfigurations."Peters-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          self.darwinModules.default
          ./hosts/peters-macbook-pro.nix
        ];
      };

      apps.aarch64-darwin.swipeaerospace = {
        type = "app";
        program = nixpkgs.lib.getExe (
          nixpkgs.legacyPackages.aarch64-darwin.callPackage ./apps/swipeaerospace.nix {
            src = inputs.swipeaerospace;
          }
        );
      };

      # `nix flake check` refuses the tree if it contains key material.
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          no-keys = pkgs.runCommand "dotfiles-no-keys" { nativeBuildInputs = [ pkgs.gnugrep ]; } ''
            cd ${self}
            bash ${./scripts/check-no-keys.sh} --tree .
            touch $out
          '';
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
