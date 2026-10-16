# Settings for SwipeAeroSpace (built by `nix run .#swipeaerospace`). Keys in
# this file override what's saved in the app's Settings window. The directory
# name's misspelling is the app's own.
{ pkgs, ... }:
let
  toml = pkgs.formats.toml { };
in
{
  xdg.configFile."swipeareospace/config.toml".source = toml.generate "swipeaerospace.toml" {
    # Four fingers: three-finger drag owns three-finger movement.
    fingers = "Four";
    swipeUpFingers = "Four";
    natural = true;
    wrap = false;
    skip-empty = false;
    multiSwipe = true;
    maxSteps = 5;
    # Swipe up: overview of all workspaces (replaces Mission Control).
    swipeUpOverview = true;
    show-empty-workspaces = false;
  };
}
