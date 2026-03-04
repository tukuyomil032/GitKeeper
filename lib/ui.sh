#!/bin/bash
# shellcheck source=colors.sh
# The runtime resolves $BASE_DIR dynamically; tell shellcheck where to find
# the local helper so the linter can follow the file when run on this script.

# UI helpers: spinner, selection UIs

# spinner_start [anchor] message
# If an anchor is provided (e.g. emoji), the spinner will be positioned immediately to the right
# of the anchor using saved cursor + relative moves so the rest of the message remains intact.
spinner_start() {
  local anchor=""
  local msg=""
  if [ $# -ge 2 ]; then
    anchor="$1"
    shift
    msg="$*"
  else
    msg="${1:-Processing...}"
  fi

  : "${CYAN:-}" ; : "${NC:-}"

  local sp="|/-\\"
  local init_frame="${sp:0:1}"

  if [ -n "$anchor" ]; then
    # Print: <anchor><space><spinner><space><msg>
    printf "%s " "$anchor" >&2
    printf "%s%s%s " "${CYAN:-}" "$init_frame" "${NC:-}" >&2
    printf "%s" "$msg" >&2
    # Save end cursor
    tput sc 2>/dev/null || true
    # compute move distance from end to spinner (msg_len + 2)
    local msg_len
    msg_len=$(printf "%s" "$msg" | wc -m | tr -d ' ')
    SPINNER_MOVE_LEFT=$((msg_len + 2))
  else
    # No anchor: print msg, a space, then spinner
    printf "%s " "$msg" >&2
    printf "%s%s%s" "${CYAN:-}" "$init_frame" "${NC:-}" >&2
    tput sc 2>/dev/null || true
    SPINNER_MOVE_LEFT=1
  fi

  # Normalize spinner min duration to integer seconds (default 2)
  _sd="${SPINNER_MIN_DURATION:-2}"
  if [[ "$_sd" == *.* ]]; then
    _int=${_sd%%.*}
    _frac=${_sd#*.}
    if [ -z "$_int" ]; then _int=0; fi
    # if there is any fractional part > 0, round up to next integer
    if [ "$_frac" -gt 0 ] 2>/dev/null; then
      SPINNER_MIN_DURATION=$(( _int + 1 ))
    else
      SPINNER_MIN_DURATION=$_int
    fi
  else
    SPINNER_MIN_DURATION=$_sd
  fi
  SPINNER_START=$(date +%s)

  local i=0
  # hide terminal cursor while spinner runs to avoid visible focus/block
  tput civis 2>/dev/null || true
  (
    while true; do
      tput rc 2>/dev/null || true
      if [ "${SPINNER_MOVE_LEFT}" -gt 0 ]; then
        printf "\033[%dD" "${SPINNER_MOVE_LEFT}" >&2
      fi
      frame="${sp:i%4:1}"
      printf "%s%s%s" "${CYAN:-}" "$frame" "${NC:-}" >&2
      i=$((i+1))
      sleep 0.12
    done
  ) &
  SPINNER_PID=$!
  disown
}

spinner_stop() {
  if [ -n "${SPINNER_PID:-}" ]; then
    # Ensure minimum display duration (integer seconds)
    now=$(date +%s)
    elapsed=$((now - SPINNER_START))
    need_sleep=$((SPINNER_MIN_DURATION - elapsed))
    if [ "$need_sleep" -gt 0 ]; then
      sleep "$need_sleep"
    fi
    # Try to terminate spinner process cleanly, wait briefly, then force kill
    kill "$SPINNER_PID" >/dev/null 2>&1 || true
    # Wait up to 0.5s for it to exit
    for _i in 1 2 3 4 5; do
      if ! kill -0 "$SPINNER_PID" >/dev/null 2>&1; then
        break
      fi
      sleep 0.1
    done
    # Force kill if still alive
    kill -9 "$SPINNER_PID" >/dev/null 2>&1 || true
    wait "$SPINNER_PID" 2>/dev/null || true
    unset SPINNER_PID
    # restore terminal cursor visibility and sane tty state
    tput cnorm 2>/dev/null || true
    stty sane 2>/dev/null || true

    # Overwrite spinner position with a checkmark (preserve rest of line)
    tput rc 2>/dev/null || true
    if [ -n "${SPINNER_MOVE_LEFT:-}" ] && [ "${SPINNER_MOVE_LEFT}" -gt 0 ]; then
      printf "\033[%dD" "$SPINNER_MOVE_LEFT" >&2
    fi
    printf "%s%s%s" "${GREEN:-}" "✓" "${NC:-}" >&2
    # Move to end of line and newline
    tput rc 2>/dev/null || true
    printf "\n" >&2
  fi
}

# SIGINT handler support: double-press Ctrl+C within 1s to force exit
LAST_SIGINT=0
on_sigint() {
  now=$(date +%s)
  if [ -n "${LAST_SIGINT:-}" ] && [ $(( now - LAST_SIGINT )) -lt 1 ]; then
    # second Ctrl+C within 1s -> force exit
    spinner_stop || true
    tput cnorm 2>/dev/null || true
    printf '\nAborting.\n' >&2
    exit 130
  else
    # first Ctrl+C: stop spinner and notify
    LAST_SIGINT=$now
    spinner_stop || true
    printf '\nInterrupted. Press Ctrl+C again within 1s to abort.\n' >&2
  fi
}


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
    reason=$(echo "$entry" | cut -d'|' -f2 | sed 's/^ *//;s/ *$//')
    repo_path=$(echo "$entry" | cut -d'|' -f3 | sed 's/^ *//;s/ *$//')
    printf "  [%d] %s (%s) — %s\n" "$i" "$branch" "$reason" "$repo_path" >&2
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
  # shellcheck disable=SC1091
  source "$BASE_DIR/lib/colors.sh" 2>/dev/null || true

  echo ""
  echo -e "${BOLD}�️  Branches to delete:${NC}" >&2
  i=1
  for entry in "${CANDIDATES[@]}"; do
    branch=$(echo "$entry" | cut -d'|' -f1 | sed 's/^ *//;s/ *$//')
    reason=$(echo "$entry" | cut -d'|' -f2 | sed 's/^ *//;s/ *$//')
    repo_path=$(echo "$entry" | cut -d'|' -f3 | sed 's/^ *//;s/ *$//')
    printf "  [%d] %s (%s) — %s\n" "$i" "$branch" "$reason" "$repo_path" >&2
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
  # Prompt and validate input; on invalid tokens re-prompt instead of exiting
  while true; do
    read -rp "Enter branch numbers to delete (space-separated, or 'all'): " selection >&2

    # empty -> treat as none selected
    if [ -z "${selection// /}" ]; then
      echo "Nothing selected." >&2
      return
    fi

    if [ "$selection" = "all" ]; then
      for entry in "${CANDIDATES[@]}"; do
        echo "$entry" | cut -d"|" -f1 | sed 's/^ *//;s/ *$//'
      done
      return
    fi

    # Validate tokens
    invalid=0
    selected_indices=()
    for token in $selection; do
      if [[ "$token" =~ ^[0-9]+$ ]]; then
        if [ "$token" -gt 0 ] && [ "$token" -le ${#CANDIDATES[@]} ]; then
          selected_indices+=("$token")
        else
          echo "Number out of range: $token" >&2
          invalid=1
          break
        fi
      else
        echo "Invalid input: $token (enter numbers or 'all')" >&2
        invalid=1
        break
      fi
    done

    if [ "$invalid" -eq 1 ]; then
      echo "Please try again." >&2
      continue
    fi

    # All tokens valid — output selection and return
    for num in "${selected_indices[@]}"; do
      echo "${CANDIDATES[$((num-1))]}" | cut -d"|" -f1 | sed 's/^ *//;s/ *$//'
    done
    return
  done
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
  # shellcheck disable=SC1091
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
