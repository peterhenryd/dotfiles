# dotfinder: drift detection against this repo, adoption into
# dotfinder/adopted.json, and the KeePassXC vault for private files.
{
  config,
  inputs,
  pkgs,
  ...
}:
{
  home.packages = [ inputs.dotfinder.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  xdg.configFile."dotfinder/config.json".text = builtins.toJSON {
    dotfiles = config.dotfiles.path;
    vault = {
      database = "~/Documents/Recovery/Vault.kdbx";
      # Private files that can't go in this public repo. Paths only; the
      # contents live in the vault.
      files = [
        {
          path = "~/.ssh/config";
          mode = "600";
        }
        {
          path = "~/.ssh/known_hosts";
          mode = "644";
        }
        {
          path = "~/.config/git/identity";
          mode = "644";
        }
        # dotfinder's private ignore rules, kept out of this repo.
        {
          path = "~/.local/share/dotfinder/ignored.json";
          mode = "600";
        }
      ];
    };
  };
}
