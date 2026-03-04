#!/usr/bin/env bash
set -euo pipefail

# Simple installer wrapper kept at repository root for CI and user convenience.
# On macOS this delegates to scripts/install-macos.sh. For other OSes it prints
# a short message pointing to the README.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(uname -s)" = "Darwin" ]; then
  if [ -x "$HERE/scripts/install-macos.sh" ]; then
    exec "$HERE/scripts/install-macos.sh" "$@"
  fi
  echo "macOS installer not found: $HERE/scripts/install-macos.sh" >&2
  exit 1
fi

echo "This installer script currently supports macOS only."
echo "See README.md for manual installation instructions or use scripts/install-macos.sh if appropriate."
exit 64
