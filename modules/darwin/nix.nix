# Upstream Nix, managed by nix-darwin (nix.enable stays at its default, true).
{ ... }:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    # Flakes only; no legacy channels or NIX_PATH.
    channel.enable = false;

    # Deduplicates the store on a schedule. (The inline `auto-optimise-store`
    # setting has a history of corrupting the store on macOS.)
    optimise.automatic = true;

    gc = {
      automatic = true;
      # Sundays at 03:00.
      interval = {
        Weekday = 0;
        Hour = 3;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
  };
}
