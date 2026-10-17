# macOS defaults. Values are written on every switch; removing a line leaves
# the last written value in place rather than restoring Apple's default.
# Some settings take effect only after logging out and back in.
{ config, ... }:
let
  home = config.system.primaryUserHome;
in
{
  system.defaults = {
    NSGlobalDomain = {
      # Keyboard ------------------------------------------------------------
      # Holding a letter opens the accent popup (ä, é, š); keys without
      # accents repeat as usual.
      ApplePressAndHoldEnabled = true;
      # Key repeat, in 15 ms units: 180 ms before repeating starts (the
      # slider's shortest is 225 ms), then a repeat every 30 ms (the slider's
      # fastest).
      InitialKeyRepeat = 12;
      KeyRepeat = 2;
      # Tab moves focus through every control in dialogs, not just text fields.
      AppleKeyboardUIMode = 3;

      # Text --------------------------------------------------------------
      # Sentences start with a capital letter automatically.
      NSAutomaticCapitalizationEnabled = true;
      # Straight quotes become curly (" → “ ”) and -- becomes an em dash.
      NSAutomaticQuoteSubstitutionEnabled = true;
      NSAutomaticDashSubstitutionEnabled = true;
      # Misspellings are corrected as you type.
      NSAutomaticSpellingCorrectionEnabled = true;
      # Predicted words appear inline as you type; Tab accepts them.
      NSAutomaticInlinePredictionEnabled = true;
      # Two spaces stay two spaces (no automatic period).
      NSAutomaticPeriodSubstitutionEnabled = false;

      # Files and dialogs -----------------------------------------------------
      # File extensions are hidden where the app or file type hides them.
      AppleShowAllExtensions = false;
      # Save and print panels open in their expanded form.
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      # Saving a new document suggests a folder in iCloud Drive (Apple's default).
      NSDocumentSaveNewDocumentsToCloud = true;

      # Windows -----------------------------------------------------------
      # Sheets and window resizes animate almost instantly.
      NSWindowResizeTime = 0.001;
      # ⌃⌘-drag anywhere in a window moves it (recommended by AeroSpace's guide).
      NSWindowShouldDragOnGesture = true;
    };

    dock = {
      # The Dock hides and reappears with no hover delay and a short animation.
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.15;
      # No "recent apps" section.
      show-recents = false;
      # Icons of hidden apps are dimmed.
      showhidden = true;
      # App icons bounce while the app launches.
      launchanim = true;
      # Minimized windows go into their app's icon instead of a separate tile.
      minimize-to-application = true;
      # Spaces stay in a fixed order instead of reordering by recent use.
      mru-spaces = false;
      # Mission Control groups windows by app. AeroSpace parks hidden windows
      # in a screen corner, and grouping keeps Mission Control legible with that.
      expose-group-apps = true;
      # Mission Control and App Exposé have no trackpad gesture; four-finger
      # swipes go to SwipeAeroSpace instead.
      showMissionControlGestureEnabled = false;
      showAppExposeGestureEnabled = false;
    };

    finder = {
      # Finder hides file extensions where macOS normally does.
      AppleShowAllExtensions = false;
      # Path bar and status bar along the bottom of each window.
      ShowPathbar = true;
      ShowStatusBar = true;
      # Window titles show the folder name, not its full path.
      _FXShowPosixPathInTitle = false;
      # Folders sort above files.
      _FXSortFoldersFirst = true;
      # Searches cover the current folder rather than the whole Mac.
      FXDefaultSearchScope = "SCcf";
      # Changing a file's extension happens without a confirmation dialog.
      FXEnableExtensionChangeWarning = false;
      # New windows use list view and open at the home folder.
      FXPreferredViewStyle = "Nlsv";
      NewWindowTarget = "Home";
      # Items in the Trash are deleted after 30 days.
      FXRemoveOldTrashItems = true;
    };

    trackpad = {
      # A click needs a physical press; tapping the trackpad doesn't click.
      Clicking = false;
      # Three-finger drag. It replaces three-finger swipes, which is why
      # SwipeAeroSpace uses four fingers and the native four-finger swipes
      # are off.
      TrackpadThreeFingerDrag = true;
      TrackpadThreeFingerHorizSwipeGesture = 0;
      TrackpadThreeFingerVertSwipeGesture = 0;
      TrackpadFourFingerHorizSwipeGesture = 0;
      TrackpadFourFingerVertSwipeGesture = 0;
    };

    screencapture = {
      # Screenshots are PNGs saved to Screenshots in iCloud Drive; window
      # screenshots keep their shadow.
      location = "${home}/Library/Mobile Documents/com~apple~CloudDocs/Screenshots";
      type = "png";
      disable-shadow = false;
      # Screenshots save immediately, without the floating thumbnail.
      show-thumbnail = false;
    };

    # One Space spans all displays. AeroSpace's guide reports fewer focus and
    # performance bugs with this setting. Takes effect at the next login.
    spaces.spans-displays = true;

    WindowManager = {
      # macOS's own window tiling is off, leaving tiling to AeroSpace.
      EnableTilingByEdgeDrag = false;
      EnableTopTilingByEdgeDrag = false;
      EnableTilingOptionAccelerator = false;
      # Clicking the wallpaper leaves windows where they are.
      EnableStandardClickToShowDesktop = false;
      # Stage Manager is off.
      GloballyEnabled = false;
    };

    # Battery percentage next to the menu bar icon.
    controlcenter.BatteryShowPercentage = true;

    CustomUserPreferences = {
      # No .DS_Store files on network shares or USB drives.
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      # Apple's personalized ads are off.
      "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
      # Syntax Highlight renders Quick Look previews with its HTML engine. Its
      # default RTF engine shows the light color scheme even in dark mode
      # (github.com/sbarex/SourceCodeSyntaxHighlight/issues/309).
      "org.sbarex.SourceCodeSyntaxHighlight".format = "html";
    };
  };
}
