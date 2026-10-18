# Apps that start at login. Each is a launchd agent in ~/Library/LaunchAgents
# that opens the app the way Finder does, so an app that's already running
# isn't started a second time. The apps' own "Launch at login" switches stay
# off; this list replaces them.
#
# Apps are found by bundle ID, so renaming one doesn't break its agent.
#
# Karabiner-Elements isn't listed: it installs its own background services,
# which start at login once allowed in System Settings.
{ lib, pkgs, ... }:
let
  # `args` go to the app when the agent starts it.
  apps = {
    "AeroSpace".id = "bobko.aerospace";
    "SwipeAeroSpace".id = "club.mediosz.SwipeAeroSpace";
    # Macs Fan Control, renamed. `/minimized` is the flag its own "Autostart
    # minimized" setting uses: it starts in the menu bar with no window.
    "Fan Control" = {
      id = "com.crystalidea.macsfancontrol";
      args = [ "/minimized" ];
    };
    "KeePassXC".id = "org.keepassxc.keepassxc";
  };

  # System Settings → General → Login Items lists an agent under the file
  # name of the program it runs. Each agent runs a script named after its app,
  # so the list says "AeroSpace" instead of "open". The scripts are copied
  # out of the Nix store so their paths stay the same across rebuilds.
  dir = "/Library/Application Support/nix-darwin/Login Items";
  path = name: "${dir}/${name}";
  script =
    app:
    pkgs.writeText "login-item" ''
      #!/bin/sh
      # -g: the app opens without taking focus. -j: it opens hidden, so an
      # app that shows a window on launch doesn't show it at login.
      exec /usr/bin/open -g -j -b ${app.id}${
        lib.optionalString (app.args or [ ] != [ ]) " --args ${lib.escapeShellArgs app.args}"
      }
    '';
  label = name: lib.toLower (lib.replaceStrings [ " " ] [ "" ] name);
in
{
  launchd.user.agents = lib.mapAttrs' (
    name: _:
    lib.nameValuePair (label name) {
      serviceConfig = {
        ProgramArguments = [ (path name) ];
        RunAtLoad = true;
        # Only in a logged-in desktop session, not over SSH.
        LimitLoadToSessionType = "Aqua";
      };
    }
  ) apps;

  # Before the agents load, so each finds its script. Scripts of apps taken
  # off the list are removed.
  system.activationScripts.preActivation.text = ''
    mkdir -p ${lib.escapeShellArg dir}
    ${lib.concatStrings (
      lib.mapAttrsToList (name: app: ''
        cmp -s ${script app} ${lib.escapeShellArg (path name)} \
          || install -m 755 ${script app} ${lib.escapeShellArg (path name)}
      '') apps
    )}
    for f in ${lib.escapeShellArg dir}/*; do
      [ -e "$f" ] || continue
      case "''${f##*/}" in
        ${lib.concatStringsSep " | " (map lib.escapeShellArg (lib.attrNames apps))}) ;;
        *) rm -f "$f" ;;
      esac
    done
  '';
}
