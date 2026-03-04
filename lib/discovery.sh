#!/bin/bash

# Repository discovery and scanning utilities

# Find all git repositories in a directory tree
# Usage: find_repos [START_DIR]
find_repos() {
  local search_dir="${1:-.}"
  local max_depth="${2:-5}"
  
  # Find all .git directories up to max_depth
  find "$search_dir" -maxdepth "$max_depth" -type d -name ".git" 2>/dev/null | \
    while read -r gitdir; do
      dirname "$gitdir"
    done | sort
}

# Count git repositories in a directory
# Usage: count_repos [START_DIR]
count_repos() {
  local search_dir="${1:-.}"
  find_repos "$search_dir" | wc -l
}

# Get current or parent git repository
# Usage: get_current_repo
get_current_repo() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git rev-parse --show-toplevel
  else
    echo ""
  fi
}

# Check if directory contains a git repository
# Usage: is_git_repo [DIR]
is_git_repo() {
  local dir="${1:-.}"
  [ -d "$dir/.git" ] || (cd "$dir" && git rev-parse --git-dir > /dev/null 2>&1)
}

# Get repository info
# Usage: get_repo_info [REPO_DIR]
get_repo_info() {
  local repo="$1"
  
  if [ ! -d "$repo/.git" ] && ! (cd "$repo" && git rev-parse --git-dir > /dev/null 2>&1); then
    return 1
  fi
  
  cd "$repo" || return 1
  
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  
  local branch_count
  branch_count=$(git branch --list | wc -l)
  
  local remote_count
  remote_count=$(git remote | wc -l)
  
  echo "$repo | branch:$branch_count | remote:$remote_count | HEAD:$current_branch"
}

# Parse scan directory from options or use current
# Usage: get_scan_directory
get_scan_directory() {
  # If --scan-dir is specified, use it
  if [ -n "$SCAN_DIR" ]; then
    echo "$SCAN_DIR"
    return 0
  fi
  
  # Try current directory first
  local current_repo
  current_repo=$(get_current_repo)
  
  if [ -n "$current_repo" ]; then
    # We're in a repo, but still check if we should scan multiple
    echo "."
  else
    # We're not in a repo, scan current directory and parents
    echo "."
  fi
}
