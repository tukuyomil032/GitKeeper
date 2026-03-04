#!/bin/bash

# Generate GitHub PR URL for a branch
# Usage: github.sh <branch-name>

branch=${1:-}

if [ -z "$branch" ]; then
  exit 1
fi

remote_url=$(git config --get remote.origin.url 2>/dev/null)

if [ -z "$remote_url" ]; then
  exit 1
fi

# Extract owner/repo from various GitHub URL formats
# https://github.com/owner/repo.git
# git@github.com:owner/repo.git
repo=$(echo "$remote_url" | sed -E 's|.*github.com[:\/]([^\/]*\/[^\.]*).*|\1|')

if [ -z "$repo" ] || [ "$repo" = "$remote_url" ]; then
  exit 1
fi

echo "https://github.com/$repo/pulls?q=is:pr+head:$branch"
