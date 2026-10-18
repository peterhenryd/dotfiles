# Apps that start at login. Each is a launchd agent in ~/Library/LaunchAgents
# that opens the app the way Finder does, so an app that's already running
# isn't started a second time. The apps' own "Launch at login" switches stay
# off; this list replaces them.
#
# Apps are found by bundle ID, so renaming one doesn't break its agent.
#
# Karabiner-Elements isn't listed: it installs its own background services,
# which start at login once allowed in System Settings.
{ lib, ... }:
let
  apps = {
    AeroSpace = "bobko.aerospace";
    SwipeAeroSpace = "club.mediosz.SwipeAeroSpace";
  };
in
{
  launchd.user.agents = lib.mapAttrs' (
    name: bundleId:
    lib.nameValuePair (lib.toLower name) {
      serviceConfig = {
        # -g: the app opens without taking focus.
        ProgramArguments = [
          "/usr/bin/open"
          "-g"
          "-b"
          bundleId
        ];
        RunAtLoad = true;
        # Only in a logged-in desktop session, not over SSH.
        LimitLoadToSessionType = "Aqua";
      };
    }
  ) apps;
}
