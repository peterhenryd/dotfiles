{ ... }:
{
  programs.git = {
    enable = true;

    # Name, email and signing key live outside this repo, in a local file
    # restored from the vault. Git silently skips the include if it's missing.
    includes = [ { path = "~/.config/git/identity"; } ];

    ignores = [
      ".DS_Store"
      "**/.claude/settings.local.json"
    ];

    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
      rerere.enabled = true;
      diff.algorithm = "histogram";
      merge.conflictStyle = "zdiff3";
      commit.verbose = true;
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      help.autocorrect = "prompt";
    };
  };
}
