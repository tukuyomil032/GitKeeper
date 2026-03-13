#!/bin/bash
# shellcheck source=colors.sh

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
  done <<< "$branches_to_delete"

  if [ "$DRY_RUN" = true ]; then
    echo ""
    if [ "${DELETE_REMOTE:-false}" = true ]; then
      echo -e "${YELLOW}🏜️  Dry run mode — showing remote branches that would also be deleted:${NC}"
      while IFS= read -r branch; do
        [ -z "$branch" ] && continue
        upstream=$(git for-each-ref --format='%(upstream:short)' "refs/heads/$branch" 2>/dev/null)
        if [ -n "$upstream" ]; then
          remote_name="${upstream%%/*}"
          remote_branch="${upstream#*/}"
        else
          remote_name=$(git remote | head -n1 2>/dev/null)
          remote_branch="$branch"
        fi
        if [ -z "$remote_name" ]; then
          echo -e "   ${YELLOW}⚠ No remote for: $branch${NC}"
        else
          echo -e "   Would delete remote: $remote_name/$remote_branch"
        fi
      done <<< "$branches_to_delete"
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
      fi
    else
      if git branch -d "$branch" 2>/dev/null; then
        echo -e "${GREEN}✓ Deleted: $branch${NC}"
        ((deleted_count++))
      else
        echo -e "${RED}✗ Failed to delete (use --force to override): $branch${NC}"
        ((failed_count++))
      fi
    fi

    # Attempt remote deletion if requested
    if [ "${DELETE_REMOTE:-false}" = true ]; then
      # Determine remote name and remote branch name
      upstream=$(git for-each-ref --format='%(upstream:short)' "refs/heads/$branch" 2>/dev/null)
      if [ -n "$upstream" ]; then
        remote_name="${upstream%%/*}"
        remote_branch="${upstream#*/}"
      else
        remote_name=$(git remote | head -n1 2>/dev/null)
        remote_branch="$branch"
      fi

      if [ -z "$remote_name" ]; then
        echo -e "${YELLOW}⚠ No remote found for: $branch — skipping remote deletion${NC}"
        echo "REMOTE SKIP (no remote): $branch" >> "$log_file"
        ((remote_failed_count++))
      else
        if remote_err=$(git push "$remote_name" --delete "$remote_branch" 2>&1); then
          echo -e "${GREEN}✓ Deleted remote: $remote_name/$remote_branch${NC}"
          echo "REMOTE DELETED: $remote_name/$remote_branch" >> "$log_file"
          ((remote_deleted_count++))
        else
          echo -e "${RED}✗ Failed to delete remote: $remote_name/$remote_branch${NC}"
          echo "REMOTE FAILED: $remote_name/$remote_branch | $remote_err" >> "$log_file"
          ((remote_failed_count++))
        fi
      fi
    fi
  done <<< "$branches_to_delete"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BOLD}✨ Summary:${NC}"
  echo -e "   ${GREEN}Deleted (local): $deleted_count${NC}"
  if [ "$failed_count" -gt 0 ]; then
    echo -e "   ${RED}Failed (local): $failed_count${NC}"
  fi
  if [ "${DELETE_REMOTE:-false}" = true ]; then
    echo -e "   ${GREEN}Deleted (remote): $remote_deleted_count${NC}"
    if [ "$remote_failed_count" -gt 0 ]; then
      echo -e "   ${RED}Failed (remote): $remote_failed_count${NC}"
    fi
  fi
  echo -e "   ${CYAN}Log: $log_file${NC}"
  echo ""
  
  if [ "$failed_count" -gt 0 ]; then
    echo -e "${YELLOW}💡 Hint: Use --force to delete unmerged branches${NC}"
    echo ""
  fi
}
