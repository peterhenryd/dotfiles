{ ... }:
{
  # Touch ID for sudo, written to /etc/pam.d/sudo_local, which macOS updates
  # leave alone. `reattach` makes it work inside tmux too.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  networking.applicationFirewall = {
    enable = true;
    # Don't answer pings or probes to closed ports.
    enableStealthMode = true;
    # Apple and validly signed apps may accept connections without a prompt.
    allowSigned = true;
    allowSignedApp = true;
  };

  system.defaults.loginwindow.GuestEnabled = false;
}
