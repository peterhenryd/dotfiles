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
  nvim/                    plain Lua, linked into ~/.config/nvim
  karabiner/               linked into ~/.config/karabiner
  dotfinder.nix            dotfinder and its config, including the vault's file list
dotfinder/                 written by `dotfinder adopt`: adopted items, ignore rules
apps/swipeaerospace.nix    `nix run .#swipeaerospace`
scripts/check-no-keys.sh   used by the pre-commit hook and `nix flake check`
```

The repo is checked out at `~/.config/dotfiles`. Neovim's and Karabiner's
configs link to that working copy, so changes they write show up in
`git status`.

## Daily use

- `dotfinder rebuild`: apply the config. It warns about Homebrew
  packages the switch would uninstall, switches, then records a baseline.
- `dotfinder drift`: what changed on the Mac since the last rebuild.
- `dotfinder audit`: everything on the Mac the config doesn't capture.
- `dotfinder adopt`: go through those changes one by one, adding each to the
  config or ignoring it. Commit `dotfinder/` afterwards.
- `dotfinder vault backup`: save the private files listed in
  `home/dotfinder.nix` into the vault.
- `nix flake update` then `dotfinder rebuild`: update everything, including
  cask versions.
- Hyper + /: AeroSpace cheat sheet, in TextEdit (Hyper = hold Caps Lock).
- New GUI app: add its cask to `modules/darwin/homebrew.nix`. Anything
  installed with `brew` but not listed there is removed on the next rebuild.
- App that should start at login: add it to `modules/darwin/login-items.nix`
  and leave the app's own "Launch at login" switch off.

## Bootstrap on a fresh Mac

1. Install Xcode from the App Store (SwipeAeroSpace builds with it) and sign
   into iCloud.
2. Install Nix:
   `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon`
3. Clone: `git clone https://github.com/peterhenryd/dotfiles ~/.config/dotfiles`
4. First switch:
   `sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/dotfiles`
   If it stops on unrecognized files in /etc, rename each one it lists to
   `<name>.before-nix-darwin` and run it again.
5. Log out and back in.
6. Open AeroSpace and Karabiner-Elements once and grant what they ask for.
   Open Syntax Highlight once so macOS finds its Quick Look extension. Its
   settings live where this config doesn't reach, so set them in the app:
   View → Show advanced settings, then under General keep the RTF rendering
   engine, turn off "Show about info", and pick color schemes that look dark.
   RTF previews don't follow dark mode
   (github.com/sbarex/SourceCodeSyntaxHighlight/issues/309); HTML previews
   do, but open at a fixed size instead of fitting the file.
7. `nix run ~/.config/dotfiles#swipeaerospace`, then allow it under
   Accessibility.
8. Let iCloud Drive download `~/Documents/Recovery/Vault.kdbx`, then restore
   the private files: `dotfinder vault restore`.
9. `dotfinder baseline`.
