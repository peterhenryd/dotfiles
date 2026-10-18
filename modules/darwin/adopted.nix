# What `dotfinder adopt` added to the config. It writes
# dotfinder/adopted.json; this reads it into the same options the
# hand-written modules use, and the two are merged.
{ config, lib, ... }:
let
  file = ../../dotfinder/adopted.json;
  adopted = if builtins.pathExists file then builtins.fromJSON (builtins.readFile file) else { };
  app = name: lib.escapeShellArg "/Applications/${name}";
  uvTools = adopted.uvTools or [ ];
in
{
  homebrew.casks = adopted.casks or [ ];
  homebrew.brews = adopted.brews or [ ];
  # adopted.json's App Store apps (masApps) stay out of homebrew.masApps:
  # once Homebrew's Brewfile lists any App Store app, its cleanup
  # uninstalls every App Store app it doesn't list. `dotfinder audit` names
  # them instead when they're missing.
  system.defaults.CustomUserPreferences = adopted.defaults or { };

  # Cask apps kept under a name of your own. After Homebrew installs one
  # under its cask's name, the switch renames it; one already renamed, or
  # with something in the way, is left alone.
  system.activationScripts.postActivation.text = lib.concatStrings (
    lib.mapAttrsToList (cask: r: ''
      if [ -e ${app r.from} ] && [ ! -e ${app r.to} ]; then
        echo "renaming ${r.from} to ${r.to} (cask ${cask})" >&2
        mv ${app r.from} ${app r.to}
      fi
    '') (adopted.renames or { })
  );

  # Python command-line tools installed with uv, for tools nixpkgs lacks or
  # lags behind on. Each switch installs the listed ones that are missing;
  # `dotfinder upgrade` upgrades them. Entries take what `uv tool install`
  # takes, extras and versions included ("mlx-lm[train]>=0.20"). Tools taken
  # off the list stay installed until `uv tool uninstall`.
  #
  # They're installed with Python 3.12. Left to choose, uv downloads the
  # newest Python, which packages with compiled parts may not have wheels for
  # yet (mlx-lm's sentencepiece had none for 3.15); uv then builds them from
  # source, which needs cmake and fails during a switch.
  home-manager.users.${config.system.primaryUser} =
    { lib, pkgs, ... }:
    {
      home.activation.uvTools = lib.mkIf (uvTools != [ ]) (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          uvInstalled=" $(${pkgs.uv}/bin/uv tool list 2>/dev/null | while read -r name _; do
            case "$name" in -* | "") ;; *) printf '%s ' "$name" ;; esac
          done)"
          for spec in ${lib.escapeShellArgs uvTools}; do
            name="''${spec%%[][=<>~!@; ]*}"
            case "$uvInstalled" in
              *" $name "*) ;;
              *) run ${pkgs.uv}/bin/uv tool install --python 3.12 "$spec" || echo "uv couldn't install $spec" >&2 ;;
            esac
          done
        ''
      );
    };
}
