#!/usr/bin/env bash
set -euo pipefail

# Lightweight installer that supports being run from the repo or as a
# curl | sh one-liner. It installs the `gitkeeper` executable into a
# writable `bin` directory (defaults to /usr/local/bin) and copies
# the `completions/_gitkeeper` file into a share directory, printing
# instructions for enabling shell completion.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_OWNER="tukuyomil032"
REPO_NAME="GitKeeper"
REPO_REF="main"
BINARY_NAME="gitkeeper"
SOURCE_BIN="$HERE/bin/$BINARY_NAME"
SOURCE_COMPLETION="$HERE/completions/_gitkeeper"

usage() {
  cat <<EOF
Usage: install.sh [--bin-dir DIR] [--prefix DIR]

Options:
  --bin-dir DIR   Install binary to DIR (default: /usr/local/bin or ~/.local/bin)
  --prefix DIR    Install share files under DIR (default: /usr/local/share)
  --help          Show this message
EOF
}

BIN_DIR=""
PREFIX=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --bin-dir) BIN_DIR="$2"; shift 2;;
    --prefix) PREFIX="$2"; shift 2;;
    --help) usage; exit 0;;
    -*) echo "Unknown option: $1" >&2; usage; exit 2;;
    *) break;;
  esac
done

# Helper: choose sane defaults for bin dir.
choose_bin_dir() {
  if [ -n "$BIN_DIR" ]; then
    echo "$BIN_DIR"
    return
  fi
  if [ -w "/usr/local/bin" ]; then
    echo "/usr/local/bin"
    return
  fi
  if [ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin" 2>/dev/null; then
    echo "$HOME/.local/bin"
    return
  fi
  echo "$HOME/bin"
}

choose_prefix() {
  if [ -n "$PREFIX" ]; then
    echo "$PREFIX"
    return
  fi
  if [ -w "/usr/local/share" ]; then
    echo "/usr/local/share"
    return
  fi
  echo "$HOME/.local/share"
}

install_from_path() {
  local bin_src="$1"
  local bin_dst_dir="$2"
  local prefix_dir="$3"

  mkdir -p "$bin_dst_dir"
  if [ ! -f "$bin_src" ]; then
    echo "Binary not found at $bin_src" >&2
    return 1
  fi
  echo "Installing $BINARY_NAME to $bin_dst_dir"
  if [ -w "$bin_dst_dir" ]; then
    cp "$bin_src" "$bin_dst_dir/$BINARY_NAME"
  else
    sudo cp "$bin_src" "$bin_dst_dir/$BINARY_NAME"
  fi
  if [ -w "$bin_dst_dir" ]; then
    chmod +x "$bin_dst_dir/$BINARY_NAME"
  else
    sudo chmod +x "$bin_dst_dir/$BINARY_NAME"
  fi

  # completions
  if [ -f "$SOURCE_COMPLETION" ]; then
    local completions_dest="$prefix_dir/$BINARY_NAME/completions"
    echo "Installing completions to $completions_dest"
    if [ -w "$(dirname "$completions_dest")" ]; then
      mkdir -p "$completions_dest"
      cp "$SOURCE_COMPLETION" "$completions_dest/_gitkeeper"
    else
      sudo mkdir -p "$completions_dest"
      sudo cp "$SOURCE_COMPLETION" "$completions_dest/_gitkeeper"
    fi
  fi

  echo "Installation complete."
  echo "Run '$bin_dst_dir/$BINARY_NAME --help' to verify."
}

install_from_archive() {
  local bin_dst_dir="$1"
  local prefix_dir="$2"
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT

  echo "Downloading archive from GitHub..."
  tarball_url="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$REPO_REF.tar.gz"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$tarball_url" | tar -xzf - -C "$tmpdir"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$tarball_url" | tar -xzf - -C "$tmpdir"
  else
    echo "curl or wget is required to download the archive." >&2
    return 1
  fi

  local extracted_dir="$tmpdir/$REPO_NAME-$REPO_REF"
  local shipped_bin="$extracted_dir/bin/$BINARY_NAME"
  local shipped_completion="$extracted_dir/completions/_gitkeeper"

  if [ ! -f "$shipped_bin" ]; then
    echo "Downloaded archive does not contain $shipped_bin" >&2
    return 1
  fi

  echo "Installing from downloaded archive..."
  install_from_path "$shipped_bin" "$bin_dst_dir" "$prefix_dir"
}

main() {
  BIN_DIR_CHOSEN="$(choose_bin_dir)"
  PREFIX_CHOSEN="$(choose_prefix)"

  # If we have a local bin, install from repo. Otherwise assume curl pipe and
  # download the archive from GitHub.
  if [ -f "$SOURCE_BIN" ]; then
    install_from_path "$SOURCE_BIN" "$BIN_DIR_CHOSEN" "$PREFIX_CHOSEN"
  else
    install_from_archive "$BIN_DIR_CHOSEN" "$PREFIX_CHOSEN"
  fi

  echo
  echo "To enable shell completion (example for bash):"
  echo "  mkdir -p \"~/.local/share/bash-completion/completions\" && cp \"$PREFIX_CHOSEN/$BINARY_NAME/completions/_gitkeeper\" ~/.local/share/bash-completion/completions/"
  echo "For zsh, source the file or add it to your fpath."
}

main "$@"

