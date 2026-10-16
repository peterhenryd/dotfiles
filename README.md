# dotfiles

My macOS setup as one flake: nix-darwin for system settings, home-manager for
user config, and nix-homebrew for GUI apps with pinned taps. A reset Mac goes
back to this state with a clone and one command.

No keys, tokens or private host details live here. A pre-commit hook and
`nix flake check` both refuse key material. Those things live in an encrypted
vault and are restored separately.

## Layout

```
flake.nix                  inputs, the host, apps, checks
hosts/peters-macbook-pro.nix
modules/darwin/            system: defaults, security, Homebrew, Nix
home/                      user: zsh, git, Ghostty, Neovim, AeroSpace, Karabiner
  nvim/                    plain Lua, linked into ~/.config/nvim
  karabiner/               linked into ~/.config/karabiner
apps/swipeaerospace.nix    `nix run .#swipeaerospace`
scripts/check-no-keys.sh   used by the pre-commit hook and `nix flake check`
```

The repo is checked out at `~/.config/dotfiles`. Neovim's and Karabiner's
configs link to that working copy, so changes they write show up in
`git status`.

## Daily use

- `rebuild`: apply the config (alias for `sudo darwin-rebuild switch --flake ~/.config/dotfiles`)
- `nix flake update` then `rebuild`: update everything, including cask versions
- Hyper + /: AeroSpace cheat sheet (Hyper = hold Caps Lock)
- New GUI app: add its cask to `modules/darwin/homebrew.nix`. Anything
  installed with `brew` but not listed there is removed on the next rebuild.

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
7. `nix run ~/.config/dotfiles#swipeaerospace`, then allow it under
   Accessibility.
8. Restore keys and identity from the vault.
