#!/bin/bash

collect_candidates() {
  CANDIDATES=()

  for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    skip_protected "$branch" && continue

    reason=""

    $CHECK_MERGED && is_merged "$branch" && reason+="merged "
    $CHECK_STALE && is_stale "$branch" && reason+="stale "
    $CHECK_GONE && is_gone "$branch" && reason+="gone "

    if [ -n "$reason" ]; then
      CANDIDATES+=("$branch | $reason")
    fi
  done
}

skip_protected() {
  for p in "${PROTECTED[@]}"; do
    [ "$1" = "$p" ] && return 0
  done
  return 1
}

is_merged() {
  git merge-base --is-ancestor "$1" "$DEFAULT_BRANCH" 2>/dev/null
}

is_stale() {
  last=$(git log -1 --format="%ct" "$1" 2>/dev/null)
  
  if [ -z "$last" ]; then
    return 1
  fi
  
  now=$(date +%s)
  diff=$(( (now - last) / 86400 ))
  [ "$diff" -gt "$DAYS" ]
}

is_gone() {
  git branch -vv | grep -w "$1" | grep gone >/dev/null
}

get_diff_stat() {
  git diff "$DEFAULT_BRANCH".."$1" --stat 2>/dev/null | head -20
}

last_commit_hash() {
  git rev-parse "$1" 2>/dev/null
}

last_commit_date() {
  git log -1 --format="%ai" "$1" 2>/dev/null
}
