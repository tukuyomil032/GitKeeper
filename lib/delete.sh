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
    if [ "$DELETE_REMOTE" = true ]; then
      echo ""
      echo -e "${BOLD}🌐 Remote branches that would also be deleted:${NC}"
      while IFS= read -r branch; do
        [ -z "$branch" ] && continue
        upstream=$(git for-each-ref --format='%(upstream:short)' "refs/heads/$branch" 2>/dev/null)
        if [ -n "$upstream" ]; then
          echo "   • $upstream"
        else
          fallback_remote=$(git remote 2>/dev/null | head -1)
          if [ -n "$fallback_remote" ]; then
            echo "   • $fallback_remote/$branch (fallback remote)"
          fi
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

    # Resolve upstream remote info before local deletion (refs gone afterward)
    del_remote=""
    del_remote_branch=""
    if [ "$DELETE_REMOTE" = true ]; then
      upstream=$(git for-each-ref --format='%(upstream:short)' "refs/heads/$branch" 2>/dev/null)
      if [ -n "$upstream" ]; then
        del_remote="${upstream%%/*}"
        del_remote_branch="${upstream#*/}"
      else
        del_remote=$(git remote 2>/dev/null | head -1)
        del_remote_branch="$branch"
      fi
    fi

    # Get commit hash before deletion
    hash=$(git rev-parse "$branch" 2>/dev/null)
    last_date=$(git log -1 --format="%ai" "$branch" 2>/dev/null)

    if [ -n "$hash" ]; then
      echo "$branch | $hash | $last_date" >> "$log_file"
    fi

    # Attempt local deletion
    local_success=false
    if [ "$FORCE" = true ]; then
      if git branch -D "$branch" 2>/dev/null; then
        echo -e "${GREEN}✓ Deleted: $branch${NC}"
        ((deleted_count++))
        local_success=true
      else
        echo -e "${RED}✗ Failed to force delete: $branch${NC}"
        ((failed_count++))
      fi
    else
      if git branch -d "$branch" 2>/dev/null; then
        echo -e "${GREEN}✓ Deleted: $branch${NC}"
        ((deleted_count++))
        local_success=true
      else
        echo -e "${RED}✗ Failed to delete (use --force to override): $branch${NC}"
        ((failed_count++))
      fi
    fi

    # Attempt remote deletion if enabled and local deletion succeeded
    if [ "$DELETE_REMOTE" = true ] && [ "$local_success" = true ] && [ -n "$del_remote" ]; then
      echo -e "   ${CYAN}→ Deleting remote branch: $del_remote/$del_remote_branch${NC}"
      echo "$branch | $del_remote/$del_remote_branch | remote" >> "$log_file"
      if git push "$del_remote" --delete "$del_remote_branch" 2>/dev/null; then
        echo -e "   ${GREEN}✓ Remote deleted: $del_remote/$del_remote_branch${NC}"
        ((remote_deleted_count++))
      else
        echo -e "   ${RED}✗ Failed to delete remote: $del_remote/$del_remote_branch${NC}"
        ((remote_failed_count++))
      fi
    fi
  done <<< "$branches_to_delete"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BOLD}✨ Summary:${NC}"
  echo -e "   ${GREEN}Deleted: $deleted_count${NC}"
  if [ "$DELETE_REMOTE" = true ]; then
    echo -e "   ${GREEN}Deleted (remote): $remote_deleted_count${NC}"
  fi
  if [ "$failed_count" -gt 0 ]; then
    echo -e "   ${RED}Failed: $failed_count${NC}"
  fi
  if [ "$DELETE_REMOTE" = true ] && [ "$remote_failed_count" -gt 0 ]; then
    echo -e "   ${RED}Failed (remote): $remote_failed_count${NC}"
  fi
  echo -e "   ${CYAN}Log: $log_file${NC}"
  echo ""
  
  if [ "$failed_count" -gt 0 ]; then
    echo -e "${YELLOW}💡 Hint: Use --force to delete unmerged branches${NC}"
    echo ""
  fi
}
