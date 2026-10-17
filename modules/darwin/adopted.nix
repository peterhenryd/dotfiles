# What `dotfinder adopt` added to the config. It writes
# dotfinder/adopted.json; this reads it into the same options the
# hand-written modules use, and the two are merged.
{ lib, ... }:
let
  file = ../../dotfinder/adopted.json;
  adopted = if builtins.pathExists file then builtins.fromJSON (builtins.readFile file) else { };
in
{
  homebrew.casks = adopted.casks or [ ];
  # `mas` installs the App Store apps.
  homebrew.brews = adopted.brews or [ ] ++ lib.optional ((adopted.masApps or { }) != { }) "mas";
  homebrew.masApps = adopted.masApps or { };
  system.defaults.CustomUserPreferences = adopted.defaults or { };
}
