# AeroSpace config and its cheat sheet, generated from one list of bindings so
# the two can't drift apart. Hyper = Caps Lock held = ⌃⌥⌘ (see karabiner.nix).
#
# The app comes from the Homebrew cask (stable path and signature, so the
# Accessibility grant survives updates); this module writes the config only.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  toml = pkgs.formats.toml { };
  aerospaceBin = "/opt/homebrew/bin/aerospace";
  cheatsheetPath = "${config.xdg.dataHome}/aerospace/AeroSpace keys.txt";

  hyper = "ctrl-alt-cmd";
  hyperShift = "ctrl-alt-shift-cmd";

  bind = mods: key: cmd: desc: { inherit mods key cmd desc; };

  workspaces = map toString (lib.range 1 9);

  main = [
    {
      title = "Focus and move";
      binds = [
        (bind hyper "h" "focus left" "Focus the window to the left")
        (bind hyper "j" "focus down" "Focus the window below")
        (bind hyper "k" "focus up" "Focus the window above")
        (bind hyper "l" "focus right" "Focus the window to the right")
        (bind hyperShift "h" "move left" "Move the window left")
        (bind hyperShift "j" "move down" "Move the window down")
        (bind hyperShift "k" "move up" "Move the window up")
        (bind hyperShift "l" "move right" "Move the window right")
      ];
    }
    {
      title = "Workspaces";
      binds = [
        (bind hyper "1-9" null "Go to workspace 1-9")
        (bind hyperShift "1-9" null "Send the window to workspace 1-9")
        (bind hyper "tab" "workspace-back-and-forth" "Previous workspace")
        (bind hyperShift "tab" "move-workspace-to-monitor --wrap-around next" "Workspace to next monitor")
      ];
    }
    {
      title = "Layout (applies to the focused window's group)";
      binds = [
        (bind hyper "t" "layout tiles accordion"
          "Tiles (side by side) / accordion (stacked, edges of the others visible)"
        )
        (bind hyper "r" "layout horizontal vertical" "Rotate: left-to-right / top-to-bottom")
        (bind hyper "arrows" null "Join with the neighbor in that direction, making a group")
        (bind hyper "f" "layout floating tiling" "Float / tile the window")
        (bind hyperShift "f" "fullscreen" "Fullscreen within AeroSpace")
        (bind hyper "minus" "resize smart -50" "Shrink the window")
        (bind hyper "equal" "resize smart +50" "Grow the window")
        (bind hyper "b" "balance-sizes" "Equalize sizes")
      ];
    }
    {
      title = "Other";
      binds = [
        (bind hyper "enter" "exec-and-forget open -na Ghostty" "New Ghostty window")
        (bind hyper "slash" "exec-and-forget /usr/bin/open -a TextEdit '${cheatsheetPath}'"
          "This cheat sheet, in TextEdit (⌘W closes it)"
        )
        (bind hyper "semicolon" "mode service" "Service mode (below)")
      ];
    }
  ];

  service = [
    {
      title = "Service mode (after Hyper + ;)";
      binds = [
        (bind "" "esc" [ "reload-config" "mode main" ] "Reload config, back to normal")
        (bind "" "r" [ "flatten-workspace-tree" "mode main" ] "Reset the workspace layout")
        (bind "" "backspace" [ "close-all-windows-but-current" "mode main" ] "Close all other windows")
      ];
    }
  ];

  # Grouped rows expand into one binding per key: "1-9" per workspace,
  # "arrows" per direction.
  directions = [
    "left"
    "down"
    "up"
    "right"
  ];
  expand =
    b:
    if b.key == "1-9" then
      map (
        n:
        b
        // {
          key = n;
          cmd = if b.mods == hyper then "workspace ${n}" else "move-node-to-workspace ${n}";
        }
      ) workspaces
    else if b.key == "arrows" then
      map (
        d:
        b
        // {
          key = d;
          cmd = "join-with ${d}";
        }
      ) directions
    else
      [ b ];

  toBindings =
    sections:
    lib.listToAttrs (
      map (b: {
        name = if b.mods == "" then b.key else "${b.mods}-${b.key}";
        value = b.cmd;
      }) (lib.concatMap expand (lib.concatMap (s: s.binds) sections))
    );

  # Cheat sheet -------------------------------------------------------------
  modLabel = {
    "${hyper}" = "Hyper";
    "${hyperShift}" = "Hyper Shift";
    "" = "";
  };
  keyLabel = {
    tab = "Tab";
    enter = "Return";
    slash = "/";
    semicolon = ";";
    minus = "-";
    equal = "=";
    esc = "Esc";
    backspace = "Delete";
    arrows = "Arrow keys";
  };
  showKey = k: keyLabel.${k} or (lib.toUpper k);
  row =
    b:
    let
      combo = lib.concatStringsSep " " (
        lib.filter (s: s != "") [
          modLabel.${b.mods}
          (showKey b.key)
        ]
      );
    in
    "  ${padRight 18 combo}${b.desc}";
  padRight = w: s: s + lib.concatStrings (lib.genList (_: " ") (w - lib.stringLength s));
  section = s: lib.concatStringsSep "\n" ([ s.title ] ++ map row s.binds);

  cheatsheet = ''
    AeroSpace   Hyper = hold Caps Lock (tap it for Escape)

    ${lib.concatMapStringsSep "\n\n" section (main ++ service)}

    Trackpad (SwipeAeroSpace): four-finger swipe left/right changes workspace;
    hold Shift to carry the window along; swipe up for the overview.
  '';

  settings = {
    config-version = 2;
    # Started by modules/darwin/login-items.nix instead; false also removes
    # the login item AeroSpace registered for itself earlier.
    start-at-login = false;

    # Visible edges of stacked windows in an accordion, in points.
    accordion-padding = 40;
    default-root-container-layout = "tiles";
    default-root-container-orientation = "auto";

    # Workspaces that exist even when empty, so swiping has a fixed ring.
    persistent-workspaces = [
      "1"
      "2"
      "3"
      "4"
      "5"
    ];

    on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

    gaps = {
      inner.horizontal = 8;
      inner.vertical = 8;
      outer.left = 8;
      outer.right = 8;
      outer.top = 8;
      outer.bottom = 8;
    };

    on-window-detected = [
      {
        "if" = "test %{app-bundle-id} = com.apple.systempreferences";
        run = "layout floating";
      }
      {
        "if" = "test %{app-bundle-id} = org.pqrs.Karabiner-Elements.Settings";
        run = "layout floating";
      }
      {
        "if" = "test %{app-bundle-id} = club.mediosz.SwipeAeroSpace";
        run = "layout floating";
      }
    ];

    mode.main.binding = toBindings main;
    mode.service.binding = toBindings service;
  };
in
{
  xdg.configFile."aerospace/aerospace.toml" = {
    source = toml.generate "aerospace.toml" settings;
    onChange = ''
      if ${aerospaceBin} list-modes --current >/dev/null 2>&1; then
        run ${aerospaceBin} reload-config
      fi
    '';
  };

  # A real, read-only file instead of a link into the Nix store: TextEdit
  # titles the window with its name and opens it locked.
  home.activation.aerospaceCheatsheet = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.coreutils}/bin/install -D -m 444 \
      ${pkgs.writeText "aerospace-keys.txt" cheatsheet} ${lib.escapeShellArg cheatsheetPath}
  '';

  # ⌃⌥⌘8 is macOS's "Invert colors" shortcut, which would swallow Hyper+8.
  # 21 is its ID in the symbolic hotkeys table; -dict-add changes only it.
  home.activation.freeHyper8 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
      -dict-add 21 '<dict><key>enabled</key><false/></dict>'
  '';
}
