#!/usr/bin/env bash
set -euo pipefail

# Uninstall script for GitKeeper. Removes installed binary and completions
# placed by install.sh. Prompts before removing unless --yes is provided.

REPO_NAME="GitKeeper"
BINARY_NAME="gitkeeper"

usage() {
  cat <<EOF
Usage: uninstall.sh [--bin-dir DIR] [--prefix DIR] [--yes]

Options:
  --bin-dir DIR   Directory where the binary was installed (optional)
  --prefix DIR    Prefix where share files were placed (optional)
  --yes           Don't prompt, just remove
  --help          Show this message
EOF
}

BIN_DIR=""
PREFIX=""
ASSUME_YES=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --bin-dir) BIN_DIR="$2"; shift 2;;
    --prefix) PREFIX="$2"; shift 2;;
    --yes) ASSUME_YES=1; shift 1;;
    --help) usage; exit 0;;
    -*) echo "Unknown option: $1" >&2; usage; exit 2;;
    *) break;;
  esac
done

possible_bins=(/usr/local/bin "$HOME/.local/bin" "$HOME/bin")
possible_prefixes=(/usr/local/share "$HOME/.local/share")

targets=()

if [ -n "$BIN_DIR" ]; then
  possible_bins=("$BIN_DIR")
fi
if [ -n "$PREFIX" ]; then
  possible_prefixes=("$PREFIX")
fi

for d in "${possible_bins[@]}"; do
  if [ -f "$d/$BINARY_NAME" ]; then
    targets+=("$d/$BINARY_NAME")
  fi
done

for p in "${possible_prefixes[@]}"; do
  if [ -f "$p/$BINARY_NAME/completions/_gitkeeper" ]; then
    targets+=("$p/$BINARY_NAME/completions/_gitkeeper")
  fi
done

if [ ${#targets[@]} -eq 0 ]; then
  echo "No installed files for $BINARY_NAME found in common locations."
  exit 0
fi

echo "The following files will be removed:"
for t in "${targets[@]}"; do
  echo "  $t"
done

if [ $ASSUME_YES -ne 1 ]; then
  read -r -p "Proceed? [y/N] " answer
  case "$answer" in
    [Yy]*) ;;
    *) echo "Aborted."; exit 1;;
  esac
fi

for t in "${targets[@]}"; do
  if [ -w "$t" ] || [ -w "$(dirname "$t")" ]; then
    rm -f "$t"
  else
    sudo rm -f "$t"
  fi
done

# Try to remove empty directories left behind
for p in "${possible_prefixes[@]}"; do
  dir="$p/$BINARY_NAME/completions"
  if [ -d "$dir" ]; then
    if [ -z "$(ls -A "$dir")" ]; then
      if [ -w "$dir" ]; then
        rmdir "$dir" || true
      else
        sudo rmdir "$dir" || true
      fi
    fi
  fi
  parent="$p/$BINARY_NAME"
  if [ -d "$parent" ]; then
    if [ -z "$(ls -A "$parent")" ]; then
      if [ -w "$parent" ]; then
        rmdir "$parent" || true
      else
        sudo rmdir "$parent" || true
      fi
    fi
  fi
done

echo "Uninstallation complete."
