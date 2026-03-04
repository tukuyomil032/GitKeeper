#!/usr/bin/env bash
set -euo pipefail

# Ensure script runs under bash (re-exec under bash if invoked from another shell)
if [ -z "${BASH_VERSION-}" ]; then
  if command -v bash >/dev/null 2>&1; then
    exec bash "$0" "$@"
  else
    echo "bash is required to run this script." >&2
    exit 1
  fi
fi

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

# Also detect any gitkeeper found in PATH (covers cases where installed elsewhere)
if command -v "$BINARY_NAME" >/dev/null 2>&1; then
  path_bin=$(command -v "$BINARY_NAME")
  # avoid duplicates
  skip=0
  for t in "${targets[@]:-}"; do
    [ "$t" = "$path_bin" ] && skip=1 && break
  done
  if [ $skip -eq 0 ]; then
    targets+=("$path_bin")
    # if this binary is in a bin dir, also consider its parent lib location
    bin_dir_of_path="$(cd "$(dirname "$path_bin")" && pwd)"
    possible_bins+=("$bin_dir_of_path")
  fi
fi

for p in "${possible_prefixes[@]}"; do
  if [ -f "$p/$BINARY_NAME/completions/_gitkeeper" ]; then
    targets+=("$p/$BINARY_NAME/completions/_gitkeeper")
  fi
done

# Also consider lib files located next to the bin parent (e.g. /usr/local/lib or ~/.local/lib)
lib_files=(colors.sh ui.sh analyze.sh banner.sh config.sh delete.sh discovery.sh github.sh)
for d in "${possible_bins[@]}"; do
  # compute lib parent: bin_dir/.. -> lib_parent/lib
  lib_parent="$(cd "$(dirname "$d")/.." 2>/dev/null && pwd || true)"
  if [ -n "$lib_parent" ]; then
    lib_dir="$lib_parent/lib"
    for lf in "${lib_files[@]}"; do
      if [ -f "$lib_dir/$lf" ]; then
        targets+=("$lib_dir/$lf")
      fi
    done
  fi
done

if [ ${#targets[@]:-0} -eq 0 ]; then
  echo "No installed files for $BINARY_NAME found in common locations."
  exit 0
fi

echo "The following files will be removed:"
for t in "${targets[@]:-}"; do
  echo "  $t"
done

if [ $ASSUME_YES -ne 1 ]; then
  read -r -p "Proceed? [y/N] " answer
  case "$answer" in
    [Yy]*) ;;
    *) echo "Aborted."; exit 1;;
  esac
fi

for t in "${targets[@]:-}"; do
  [ -z "$t" ] && continue
  if [ -w "$t" ] || [ -w "$(dirname "$t")" ]; then
    rm -f "$t"
  else
    sudo rm -f "$t"
  fi
done

# Attempt to remove lib and completion directories if left empty
for d in "${possible_bins[@]}"; do
  lib_parent="$(cd "$(dirname "$d")/.." 2>/dev/null && pwd || true)"
  [ -z "$lib_parent" ] && continue
  lib_dir="$lib_parent/lib"
  if [ -d "$lib_dir" ]; then
    if [ -z "$(ls -A "$lib_dir")" ]; then
      if [ -w "$lib_dir" ]; then rmdir "$lib_dir" || true; else sudo rmdir "$lib_dir" || true; fi
    fi
  fi
done

for p in "${possible_prefixes[@]}"; do
  comp_dir="$p/$BINARY_NAME/completions"
  if [ -d "$comp_dir" ]; then
    if [ -z "$(ls -A "$comp_dir")" ]; then
      if [ -w "$comp_dir" ]; then rmdir "$comp_dir" || true; else sudo rmdir "$comp_dir" || true; fi
    fi
  fi
  parent="$p/$BINARY_NAME"
  if [ -d "$parent" ]; then
    if [ -z "$(ls -A "$parent")" ]; then
      if [ -w "$parent" ]; then rmdir "$parent" || true; else sudo rmdir "$parent" || true; fi
    fi
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
