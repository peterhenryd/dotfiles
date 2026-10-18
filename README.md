# dotfiles

My macOS setup as one flake: nix-darwin for system settings, home-manager for
user config, and nix-homebrew for GUI apps with pinned taps. A reset Mac goes
back to this state with a clone and one command.

No keys, tokens or private host details live here. A pre-commit hook and
`nix flake check` both refuse key material. Those things live in a KeePassXC
vault, and [dotfinder](https://github.com/peterhenryd/dotfinder) backs them up
and restores them.

## Layout

```
flake.nix                  inputs, the host, apps, checks
hosts/peters-macbook-pro.nix
modules/darwin/            system: defaults, security, Homebrew, Nix
  login-items.nix          apps started at login
  adopted.nix              reads dotfinder/adopted.json
home/                      user: zsh, git, Ghostty, Neovim, AeroSpace, Karabiner
  dev.nix                  Cargo, OpenCode and Claude Code settings; their PATH entries
  claude/settings.json     Claude Code settings, merged into ~/.claude/settings.json
  nvim/                    plain Lua, linked into ~/.config/nvim
  ghostty/                 Ghostty's config file, linked into ~/.config/ghostty
  karabiner/               linked into ~/.config/karabiner
  dotfinder.nix            dotfinder and its config, including the vault's file list
dotfinder/                 written by `dotfinder adopt`: adopted items, ignore rules
apps/swipeaerospace.nix    `nix run .#swipeaerospace`
scripts/check-no-keys.sh   used by the pre-commit hook and `nix flake check`
```

The repo is checked out at `~/.config/dotfiles`. Neovim's, Ghostty's and
Karabiner's configs link to that working copy, so changes to them apply
without a rebuild and show up in `git status`.

## Daily use

- `dotfinder rebuild`: apply the config. It warns about Homebrew
  packages the switch would uninstall, switches, then records a baseline.
- `dotfinder drift`: what changed on the Mac since the last rebuild.
- `dotfinder audit`: everything on the Mac the config doesn't capture.
- `dotfinder adopt`: go through those changes one by one, adding each to the
  config or ignoring it. Private ignores stay out of the repo;
  `dotfinder vault backup` saves them.
- `dotfinder push`: after changing the config, by hand or with `adopt`:
  shows what changed, asks for a commit message, commits and pushes.
- `dotfinder vault backup`: save the private files listed in
  `home/dotfinder.nix` into the vault.
- `dotfinder apps backup`: copy your own things in `~/Applications` (web
  apps, script apps, folders of aliases) to iCloud Drive/Backups/Applications.
- `nix flake update`, `dotfinder rebuild`, then `dotfinder upgrade`: update
  everything. The rebuild picks up new Nix packages and Homebrew's package
  lists but never upgrades an installed app; `dotfinder upgrade` runs
  `brew upgrade`, which does, except for apps that update themselves (such
  as Parallels), which it leaves to their own updaters. Renamed apps get
  their Homebrew names back while it runs. It then runs
  `uv tool upgrade --all`.
- Hyper + /: AeroSpace cheat sheet, in TextEdit (Hyper = hold Caps Lock).
- New GUI app: add its cask to `modules/darwin/homebrew.nix`. Anything
  installed with `brew` but not listed there is removed on the next rebuild.
- Python command-line tool nixpkgs lacks or lags on (mlx-lm): install it
  with `uv tool install`, then add it with `dotfinder adopt --audit`.
  Switches install listed tools that are missing.
- Shell aliases: `programs.zsh.shellAliases` in `home/zsh.nix`. zsh reads
  its config from `~/.config/zsh`, so `~/.zshrc`, `~/.zprofile` and
  `~/.profile` do nothing; when an installer adds a PATH line to one of them
  (`dotfinder audit` shows the file), add the folder to `home.sessionPath`
  instead and delete the file.
- App that should start at login: add it and its bundle ID to
  `modules/darwin/login-items.nix` and leave the app's own "Launch at login"
  switch off.
- Renaming a Homebrew app: rename it in Finder, then record the rename with
  `dotfinder adopt --audit`, so new Macs get the same name.

## Bootstrap on a fresh Mac

1. Install Xcode from the App Store (SwipeAeroSpace builds with it) and sign
   into iCloud.
2. Install Nix:
   `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon`
3. Clone: `git clone https://github.com/peterhenryd/dotfiles ~/.config/dotfiles`
4. In System Settings → Privacy & Security → App Management, turn on
   Terminal (add it with + if it isn't listed). Homebrew needs it to install
   and replace apps; without it, the switch fails partway through the casks.
   The same goes for any other terminal you run `dotfinder rebuild` from.
5. First switch, naming the configuration (`darwin-rebuild` otherwise picks
   one by the Mac's current name, which a fresh install may not match; the
   switch then renames the Mac to Peters-MacBook-Pro):
   `sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/dotfiles#Peters-MacBook-Pro`
   If it stops on unrecognized files in /etc, rename each one it lists to
   `<name>.before-nix-darwin` and run it again.
6. Log out and back in.
7. Open AeroSpace and Karabiner-Elements once and grant what they ask for.
   Open Syntax Highlight once so macOS finds its Quick Look extension. Its
   settings live where this config doesn't reach, so set them in the app:
   View → Show advanced settings, then under General keep the RTF rendering
   engine, turn off "Show about info", and set the color scheme for dark
   appearance to a light scheme: in dark mode, RTF previews show a light
   scheme as dark and a dark one as light
   (github.com/sbarex/SourceCodeSyntaxHighlight/issues/309). HTML previews
   follow dark mode, but open at a fixed size instead of fitting the file.
8. `nix run ~/.config/dotfiles#swipeaerospace`, then allow it under
   Accessibility.
9. Let iCloud Drive download `~/Documents/Recovery/Vault.kdbx`, then restore
   the private files: `dotfinder vault restore`. Restore your own apps to
   `~/Applications`: `dotfinder apps restore`.
10. Download the Rust toolchain: `rustup default stable`.
11. `dotfinder baseline`.
