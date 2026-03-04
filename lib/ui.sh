#!/bin/bash

# Select branches for deletion using fzf or simple menu
select_branches() {
  if ! command -v fzf &> /dev/null; then
    # Fallback to simple selection if fzf is not available
    simple_select
    return
  fi

  # Display header to stderr for fzf mode
  echo -e "${BOLD}🗑️  Branches to delete:${NC}" >&2
  i=1
  for entry in "${CANDIDATES[@]}"; do
    branch=$(echo "$entry" | cut -d'|' -f1 | sed 's/^ *//;s/ *$//')
    reason=$(echo "$entry" | cut -d'|' -f2)
    printf "  [%d] %s (%s)\n" "$i" "$branch" "$reason" >&2
    ((i++))
  done
  echo "" >&2

  # For dry-run mode, output all candidates without interaction
  if [ "$DRY_RUN" = true ]; then
    printf "%s\n" "${CANDIDATES[@]}" | cut -d"|" -f1 | sed 's/^ *//;s/ *$//'
    return
  fi

  printf "%s\n" "${CANDIDATES[@]}" | fzf -m --preview "
    branch=\$(echo {} | cut -d'|' -f1 | sed 's/^ *//;s/ *$//')
    echo \"🌿 Branch: \$branch\"
    echo \"\"
    echo \"---- Last commit ----\"
    git log -1 --oneline \"\$branch\"
    echo \"\"
    echo \"---- Diff Stats ----\"
    git diff $DEFAULT_BRANCH..\$branch --stat 2>/dev/null || echo \"No diff info available\"
    echo \"\"
    echo \"---- PR ----\"
    $BASE_DIR/lib/github.sh \"\$branch\" 2>/dev/null || echo \"No GitHub repo detected\"
  " | cut -d"|" -f1 | sed 's/^ *//;s/ *$//'
}

# Select repository from multiple repos
# Usage: select_repo REPOS_ARRAY_NAME
select_repo() {
  local repos_var="$1"
  local -a repos=()
  
  # Get the array via eval (bash 3.2 compatible)
  eval "repos=(\"\${${repos_var}[@]}\")"
  
  if [ ${#repos[@]} -eq 0 ]; then
    echo ""
    return 1
  fi
  
  if [ ${#repos[@]} -eq 1 ]; then
    echo "${repos[0]}"
    return 0
  fi
  
  # Multiple repos found, show selection UI
  if ! command -v fzf &> /dev/null; then
    # Fallback to simple selection
    simple_select_repo repos_var
    return $?
  fi
  
  printf "%s\n" "${repos[@]}" | fzf --preview "
    repo=\$(echo {})
    echo \"📍 Repository: \$repo\"
    echo \"\"
    if [ -d \"\$repo/.git\" ]; then
      cd \"\$repo\"
      echo \"Branches: \$(git branch --list | wc -l)\"
      echo \"Remotes: \$(git remote | wc -l)\"
      echo \"HEAD: \$(git rev-parse --abbrev-ref HEAD)\"
      echo \"\"
      echo \"Recent commits:\"
      git log -2 --oneline
    fi
  "
}

# Simple menu for branch selection (fallback)
simple_select() {
  # Source colors
  source "$BASE_DIR/lib/colors.sh" 2>/dev/null || true
  
  echo ""
  echo -e "${BOLD}�️  Branches to delete:${NC}" >&2
  i=1
  for entry in "${CANDIDATES[@]}"; do
    branch=$(echo "$entry" | cut -d'|' -f1 | sed 's/^ *//;s/ *$//')
    reason=$(echo "$entry" | cut -d'|' -f2)
    printf "  [%d] %s (%s)\n" "$i" "$branch" "$reason" >&2
    ((i++))
  done
  echo "" >&2
  
  # Skip reading if in dry-run mode
  if [ "$DRY_RUN" = true ]; then
    # For dry-run, output all candidates to stdout
    for entry in "${CANDIDATES[@]}"; do
      echo "$entry" | cut -d"|" -f1 | sed 's/^ *//;s/ *$//'
    done
    return
  fi
  
  read -rp "Enter branch numbers to delete (space-separated, or 'all'): " selection >&2
  
  if [ "$selection" = "all" ]; then
    # Output all selected branches, one per line to stdout
    for entry in "${CANDIDATES[@]}"; do
      echo "$entry" | cut -d"|" -f1 | sed 's/^ *//;s/ *$//'
    done
  else
    for num in $selection; do
      if [ "$num" -gt 0 ] && [ "$num" -le ${#CANDIDATES[@]} ]; then
        echo "${CANDIDATES[$((num-1))]}" | cut -d"|" -f1 | sed 's/^ *//;s/ *$//'
      fi
    done
  fi
}

# Simple menu for repository selection (fallback)
simple_select_repo() {
  local repos_var="$1"
  local -a repos=()
  
  # Get the array via eval (bash 3.2 compatible)
  eval "repos=(\"\${${repos_var}[@]}\")"
  
  echo ""
  echo "📁 Available repositories:"
  local i=1
  for repo in "${repos[@]}"; do
    printf "  [%d] %s\n" "$i" "$repo"
    ((i++))
  done
  echo ""
  read -rp "Select repository number: " repo_num
  
  if [ "$repo_num" -gt 0 ] && [ "$repo_num" -le ${#repos[@]} ]; then
    echo "${repos[$((repo_num-1))]}"
    return 0
  else
    echo ""
    return 1
  fi
}
display_summary() {
  # Source colors
  source "$BASE_DIR/lib/colors.sh" 2>/dev/null || true
  
  echo ""
  echo -e "${BOLD}✨ Cleanup Summary:${NC}"
  echo "  Total branches to review: ${#CANDIDATES[@]}"
  
  local merged=0
  local stale=0
  local gone=0
  
  for entry in "${CANDIDATES[@]}"; do
    [[ "$entry" == *"merged"* ]] && ((merged++))
    [[ "$entry" == *"stale"* ]] && ((stale++))
    [[ "$entry" == *"gone"* ]] && ((gone++))
  done
  
  [ "$merged" -gt 0 ] && echo -e "  ${GREEN}📌 Merged: $merged${NC}"
  [ "$stale" -gt 0 ] && echo -e "  ${YELLOW}⏰ Stale (>${DAYS}d): $stale${NC}"
  [ "$gone" -gt 0 ] && echo -e "  ${RED}❌ Upstream gone: $gone${NC}"
  echo ""
}