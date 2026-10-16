# Caps Lock: held = ⌃⌥⌘ ("Hyper", used by every AeroSpace binding),
# tapped = Escape. The rule is in home/karabiner/karabiner.json.
#
# The whole directory is linked from the working copy (Karabiner watches the
# directory, and its settings UI writes back to the file), so UI changes show
# up as a diff in this repo.
{ config, ... }:
{
  xdg.configFile."karabiner".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/home/karabiner";
}
