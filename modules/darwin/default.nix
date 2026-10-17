{ inputs, ... }:
{
  imports = [
    ./nix.nix
    ./defaults.nix
    ./security.nix
    ./homebrew.nix
    ./login-items.nix
    ./adopted.nix
  ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    # An existing file in the way of a managed one is renamed to
    # `<name>.pre-hm` instead of aborting the switch.
    backupFileExtension = "pre-hm";
  };
}
