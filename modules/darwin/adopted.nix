# What `dotfinder adopt` added to the config. It writes
# dotfinder/adopted.json; this reads it into the same options the
# hand-written modules use, and the two are merged.
{ ... }:
let
  file = ../../dotfinder/adopted.json;
  adopted = if builtins.pathExists file then builtins.fromJSON (builtins.readFile file) else { };
in
{
  homebrew.casks = adopted.casks or [ ];
  homebrew.brews = adopted.brews or [ ];
  system.defaults.CustomUserPreferences = adopted.defaults or { };
}
