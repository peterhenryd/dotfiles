#!/usr/bin/env bash
# Fails if key material appears in this repo: SSH public or private keys,
# age keys, PEM/PGP private keys, WireGuard keys, GitHub tokens.
#
#   check-no-keys.sh --tree DIR   scan every file under DIR (used by `nix flake check`)
#   check-no-keys.sh --staged     scan the staged version of each staged file (pre-commit)
set -euo pipefail

patterns=(
  # SSH public keys and certificates
  '(ssh-(ed25519|rsa|dss)|ecdsa-sha2-nistp[0-9]+|sk-(ssh-ed25519|ecdsa-sha2-nistp256)@openssh\.com)( |-cert-v01@openssh\.com )AAAA'
  # PEM / OpenSSH / PGP private keys
  '-----BEGIN ([A-Z]+ )*PRIVATE KEY( BLOCK)?-----'
  # age identities and recipients
  'AGE-SECRET-KEY-1[0-9A-Z]+'
  'age1[02-9ac-hj-np-z]{58}'
  # WireGuard config lines
  '(PrivateKey|PublicKey|PresharedKey)[[:space:]]*='
  # GitHub tokens
  '(gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{50,})'
)
# A bare 32-byte base64 value (WireGuard key format), excluding Nix hashes.
wg_bare='(^|[^A-Za-z0-9+/=-])[A-Za-z0-9+/]{42}[AEIMQUYcgkosw048]=($|[^A-Za-z0-9+/=])'

found=0

scan() { # $1 = label; content on stdin
  local label=$1 content
  content=$(cat)
  for p in "${patterns[@]}"; do
    if grep -nE -e "$p" <<<"$content" >/dev/null; then
      echo "key material in $label (pattern: $p)" >&2
      found=1
    fi
  done
  if grep -nE -e "$wg_bare" <<<"$content" | grep -vE 'sha(256|512)-' >/dev/null; then
    echo "possible WireGuard key in $label" >&2
    found=1
  fi
}

case "${1:-}" in
  --tree)
    root=${2:?usage: --tree DIR}
    while IFS= read -r -d '' f; do
      case "$f" in */flake.lock | */.git/*) continue ;; esac
      scan "$f" <"$f"
    done < <(find "$root" -type f -print0)
    ;;
  --staged)
    while IFS= read -r -d '' f; do
      [ "$f" = flake.lock ] && continue
      scan "$f" < <(git show ":$f")
    done < <(git diff --cached --name-only --diff-filter=ACMR -z)
    ;;
  *)
    echo "usage: $0 --tree DIR | --staged" >&2
    exit 2
    ;;
esac

if [ "$found" -ne 0 ]; then
  echo "Refusing: keys belong in the vault, not in this repo." >&2
  exit 1
fi
