# The one machine this repo describes. Nothing here is secret: hostname and
# username only. Keys, SSH hosts, WireGuard and git identity live in the
# encrypted vault and are restored outside Nix.
{ ... }:
{
  networking.localHostName = "Peters-MacBook-Pro";

  system.primaryUser = "peter";
  users.users.peter.home = "/Users/peter";

  home-manager.users.peter = {
    imports = [ ../home ];
    home.stateVersion = "26.11";
  };

  nix-homebrew.user = "peter";

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Set once at install time; do not bump it to "upgrade". See
  # `darwin-rebuild changelog` before changing.
  system.stateVersion = 7;
}
