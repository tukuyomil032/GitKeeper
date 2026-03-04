#!/bin/bash

confirm_and_delete() {
  # Source colors
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

    # Attempt deletion
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
  done <<< "$branches_to_delete"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BOLD}✨ Summary:${NC}"
  echo -e "   ${GREEN}Deleted: $deleted_count${NC}"
  if [ "$failed_count" -gt 0 ]; then
    echo -e "   ${RED}Failed: $failed_count${NC}"
  fi
  echo -e "   ${CYAN}Log: $log_file${NC}"
  echo ""
  
  if [ "$failed_count" -gt 0 ]; then
    echo -e "${YELLOW}💡 Hint: Use --force to delete unmerged branches${NC}"
    echo ""
  fi
}
