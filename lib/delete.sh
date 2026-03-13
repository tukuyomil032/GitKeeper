#!/bin/bash
# shellcheck source=colors.sh

# _remote_ref_for_branch BRANCH
# Outputs "remote remote-branch" (space-separated) for the given local branch.
# Uses the configured upstream when available; falls back to origin/<branch>
# or the first available remote.
_remote_ref_for_branch() {
  local branch="$1"
  local upstream remote remote_branch
  upstream=$(git for-each-ref --format='%(upstream:short)' "refs/heads/$branch" 2>/dev/null)
  if [ -n "$upstream" ]; then
    remote="${upstream%%/*}"
    remote_branch="${upstream#*/}"
  else
    if git remote 2>/dev/null | grep -q "^origin$"; then
      remote="origin"
    else
      remote=$(git remote 2>/dev/null | head -1)
    fi
    remote_branch="$branch"
  fi
  [ -n "$remote" ] && printf '%s %s' "$remote" "$remote_branch"
}

confirm_and_delete() {
  # Source colors
    # shellcheck disable=SC1091
    # shellcheck source=colors.sh
    source "$BASE_DIR/lib/colors.sh" 2>/dev/null || true
  
  local branches_to_delete="$1"

  echo ""
  echo -e "${BOLD}🗑️  Branches to delete:${NC}"
  while IFS= read -r branch; do
    [ -z "$branch" ] && continue
    echo "   • $branch"
    if [ "${DELETE_REMOTE:-false}" = true ]; then
      local _r _rb _ref
      _ref=$(_remote_ref_for_branch "$branch")
      if [ -n "$_ref" ]; then
        read -r _r _rb <<< "$_ref"
        echo "     ↳ remote: ${_r}/${_rb}"
      fi
    fi
  done <<< "$branches_to_delete"

  if [ "$DRY_RUN" = true ]; then
    if [ "${DELETE_REMOTE:-false}" = true ]; then
      echo ""
      echo -e "${YELLOW}  (remote branches shown above would also be deleted)${NC}"
    fi
    echo ""
    echo -e "${YELLOW}🏜️  Dry run mode - no branches were deleted${NC}"
    exit 0
  fi

  echo ""
  read -rp "Delete these branches? (y/N): " confirm
  
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    log_info "Aborted."
    exit 0
  fi

  # Create backup directory if it doesn't exist
  mkdir -p .git/gitkeeper-backup

  # Create timestamped log file
  timestamp=$(date +"%Y%m%d-%H%M%S")
  log_file=".git/gitkeeper-backup/$timestamp.log"

  echo -e "${CYAN}📝${NC} Backing up branch info to $log_file..."
  echo "=== Deleted $(date) ===" > "$log_file"
  echo "" >> "$log_file"

  deleted_count=0
  failed_count=0
  remote_deleted_count=0
  remote_failed_count=0

  while IFS= read -r branch; do
    [ -z "$branch" ] && continue
    
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    # Don't delete the current branch
    if [ "$branch" = "$current_branch" ]; then
      log_warning "Skipping current branch: $branch"
      continue
    fi

    # Capture remote info before local deletion (ref will be gone after)
    local_remote=""
    local_remote_branch=""
    if [ "${DELETE_REMOTE:-false}" = true ]; then
      local _ref
      _ref=$(_remote_ref_for_branch "$branch")
      if [ -n "$_ref" ]; then
        read -r local_remote local_remote_branch <<< "$_ref"
      fi
    fi

    # Get commit hash before deletion
    hash=$(git rev-parse "$branch" 2>/dev/null)
    last_date=$(git log -1 --format="%ai" "$branch" 2>/dev/null)

    if [ -n "$hash" ]; then
      echo "$branch | $hash | $last_date" >> "$log_file"
    fi

    # Attempt local deletion
    if [ "$FORCE" = true ]; then
      if git branch -D "$branch" 2>/dev/null; then
        echo -e "${GREEN}✓ Deleted: $branch${NC}"
        ((deleted_count++))
      else
        echo -e "${RED}✗ Failed to force delete: $branch${NC}"
        ((failed_count++))
        continue
      fi
    else
      if git branch -d "$branch" 2>/dev/null; then
        echo -e "${GREEN}✓ Deleted: $branch${NC}"
        ((deleted_count++))
      else
        echo -e "${RED}✗ Failed to delete (use --force to override): $branch${NC}"
        ((failed_count++))
        continue
      fi
    fi

    # Attempt remote deletion if requested and a remote was found
    if [ "${DELETE_REMOTE:-false}" = true ] && [ -n "$local_remote" ]; then
      echo -e "${CYAN}  → Deleting remote branch: ${local_remote}/${local_remote_branch}${NC}"
      if git push "$local_remote" --delete "$local_remote_branch" 2>/dev/null; then
        echo -e "${GREEN}  ✓ Remote deleted: ${local_remote}/${local_remote_branch}${NC}"
        echo "  remote: $local_remote/$local_remote_branch" >> "$log_file"
        ((remote_deleted_count++))
      else
        echo -e "${RED}  ✗ Failed to delete remote: ${local_remote}/${local_remote_branch}${NC}"
        ((remote_failed_count++))
      fi
    fi
  done <<< "$branches_to_delete"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BOLD}✨ Summary:${NC}"
  echo -e "   ${GREEN}Deleted (local): $deleted_count${NC}"
  if [ "${DELETE_REMOTE:-false}" = true ]; then
    echo -e "   ${GREEN}Deleted (remote): $remote_deleted_count${NC}"
    if [ "$remote_failed_count" -gt 0 ]; then
      echo -e "   ${RED}Failed (remote): $remote_failed_count${NC}"
    fi
  fi
  if [ "$failed_count" -gt 0 ]; then
    echo -e "   ${RED}Failed (local): $failed_count${NC}"
  fi
  echo -e "   ${CYAN}Log: $log_file${NC}"
  echo ""
  
  if [ "$failed_count" -gt 0 ]; then
    echo -e "${YELLOW}💡 Hint: Use --force to delete unmerged branches${NC}"
    echo ""
  fi
}
