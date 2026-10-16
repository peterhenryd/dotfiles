# `nix run .#swipeaerospace`: builds SwipeAeroSpace at the commit pinned in
# flake.lock with your Xcode, signs it, and installs it to /Applications.
#
# The Nix build sandbox can't run xcodebuild, so this is an app rather than a
# package. Signing uses a fixed certificate because macOS ties the
# Accessibility grant to the app's signature: an ad-hoc signature changes with
# every build and would need re-granting each time.
#
# The certificate is a self-signed "Local Code Signing" identity in the login
# keychain (it needs no Apple account), with an Apple Development certificate
# as the fallback.
{
  writeShellApplication,
  coreutils,
  src,
}:
writeShellApplication {
  name = "swipeaerospace-install";
  runtimeInputs = [ coreutils ];
  text = ''
    # All code-signing identities, trusted or not: signing only needs the
    # certificate and its private key, not a trust setting.
    identities=$(/usr/bin/security find-identity -p codesigning)
    identity=$(awk '/"Local Code Signing"/ { print $2; exit }' <<<"$identities")
    if [ -z "$identity" ]; then
      identity=$(awk '/"Apple Development: / { print $2; exit }' <<<"$identities")
    fi
    if [ -z "$identity" ]; then
      echo "No signing identity found. Expected a self-signed code signing" >&2
      echo "certificate named \"Local Code Signing\" in the login keychain, or an" >&2
      echo "Apple Development certificate." >&2
      exit 1
    fi

    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    cp -R ${src} "$work/src"
    chmod -R u+w "$work/src"

    /usr/bin/xcodebuild \
      -project "$work/src/SwipeAeroSpace.xcodeproj" \
      -scheme SwipeAeroSpace \
      -configuration Release \
      -destination 'generic/platform=macOS' \
      -derivedDataPath "$work/build" \
      CODE_SIGNING_ALLOWED=NO \
      build

    app="$work/build/Build/Products/Release/SwipeAeroSpace.app"
    # No hardened runtime: it exists for notarized distribution, and its
    # library validation rejects frameworks signed without an Apple Team ID.
    /usr/bin/codesign --force --deep \
      --entitlements "$work/src/SwipeAeroSpace/SwipeAeroSpace.entitlements" \
      --sign "$identity" "$app"

    /usr/bin/osascript -e 'quit app "SwipeAeroSpace"' 2>/dev/null || true
    rm -rf /Applications/SwipeAeroSpace.app
    /usr/bin/ditto "$app" /Applications/SwipeAeroSpace.app
    open /Applications/SwipeAeroSpace.app
    echo "Installed. First run: allow SwipeAeroSpace in System Settings > Privacy & Security > Accessibility."
  '';
}
