#!/bin/bash

# Resolve config.json path (handles both direct execution and symlink)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Fallback if not found in expected location
if [ ! -f "$CONFIG_FILE" ]; then
  CONFIG_FILE="$HOME/.config/gitkeeper/config.json"
fi

load_config() {
  # macOS compatible array assignment (no mapfile)
  PROTECTED=()
  while IFS= read -r line; do
    [ -n "$line" ] && PROTECTED+=("$line")
  done < <(jq -r '.protected[]' "$CONFIG_FILE" 2>/dev/null)
  
  DAYS=$(jq -r '.days' "$CONFIG_FILE" 2>/dev/null)
  export DAYS
  CHECK_MERGED=$(jq -r '.checkMerged' "$CONFIG_FILE" 2>/dev/null)
  export CHECK_MERGED
  CHECK_STALE=$(jq -r '.checkStale' "$CONFIG_FILE" 2>/dev/null)
  export CHECK_STALE
  CHECK_GONE=$(jq -r '.checkUpstreamGone' "$CONFIG_FILE" 2>/dev/null)
  export CHECK_GONE
  DEFAULT_BRANCH=$(jq -r '.defaultBranch' "$CONFIG_FILE" 2>/dev/null)
  export DEFAULT_BRANCH
}

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --since|-s)
        DAYS="$2"; export DAYS; shift ;;
      --protect|-p)
        PROTECTED+=("$2"); shift ;;
      --no-merged|-M)
        CHECK_MERGED=false; export CHECK_MERGED ;;
      --no-stale|-S)
        CHECK_STALE=false; export CHECK_STALE ;;
      --no-gone|-G)
        CHECK_GONE=false; export CHECK_GONE ;;
      --dry-run|-n)
        DRY_RUN=true; export DRY_RUN ;;
      --force|-f)
        FORCE=true; export FORCE ;;
      --help|-h)
        show_help; exit 0 ;;
          --configure|-C)
            # Interactive edit config and exit
            interactive_edit_config
            exit 0
            ;;
      *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
    shift
  done
}

show_help() {
  cat << 'EOF'
gitkeeper - Safe Git branch cleanup tool

USAGE:
  gitkeeper [OPTIONS]

OPTIONS:
  --directory, -d DIR     Scan for repositories in specified directory
  --since, -s DAYS        Override stale threshold (default: 30)
  --protect, -p BRANCH    Add protected branch
  --no-merged, -M         Disable merged branch check
  --no-stale, -S          Disable stale (>30d) branch check
  --no-gone, -G           Disable upstream gone branch check
  --dry-run, -n           Show what would be deleted without deleting
  --force, -f             Force delete unmerged branches (use with caution)
  --help, -h              Show this help message

EXAMPLES:
  gitkeeper                           # Interactive cleanup
  gitkeeper --dry-run                 # Preview branches to delete
  gitkeeper --directory ~/projects    # Scan and select repository
  gitkeeper --since 45                # Use 45 days threshold
  gitkeeper --protect staging         # Add staging as protected
  gitkeeper --force                   # Force delete unmerged branches

CONFIG:
  Edit config.json to change defaults (protected branches, days, checks)

EOF
}


interactive_edit_config() {
  echo "Interactive config editor"
  echo "Config file: $CONFIG_FILE"
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found, creating new one at $CONFIG_FILE"
    mkdir -p "$(dirname "$CONFIG_FILE")" || true
    cat > "$CONFIG_FILE" <<'JSON'
{
  "protected": ["main","master","develop"],
  "days": 30,
  "checkMerged": true,
  "checkStale": true,
  "checkUpstreamGone": true,
  "defaultBranch": "main"
}
JSON
  fi

  # Load current values
  cur_protected=$(jq -r '.protected | join(" ")' "$CONFIG_FILE" 2>/dev/null || echo "main master develop")
  cur_days=$(jq -r '.days' "$CONFIG_FILE" 2>/dev/null || echo 30)
  cur_checkMerged=$(jq -r '.checkMerged' "$CONFIG_FILE" 2>/dev/null || echo true)
  cur_checkStale=$(jq -r '.checkStale' "$CONFIG_FILE" 2>/dev/null || echo true)
  cur_checkUpstreamGone=$(jq -r '.checkUpstreamGone' "$CONFIG_FILE" 2>/dev/null || echo true)
  cur_defaultBranch=$(jq -r '.defaultBranch' "$CONFIG_FILE" 2>/dev/null || echo main)

  read -rp "Protected branches (space-separated) [${cur_protected}]: " new_protected
  new_protected=${new_protected:-$cur_protected}
  read -rp "Stale threshold days [${cur_days}]: " new_days
  new_days=${new_days:-$cur_days}
  read -rp "Check merged branches? (true/false) [${cur_checkMerged}]: " new_checkMerged
  new_checkMerged=${new_checkMerged:-$cur_checkMerged}
  read -rp "Check stale branches? (true/false) [${cur_checkStale}]: " new_checkStale
  new_checkStale=${new_checkStale:-$cur_checkStale}
  read -rp "Check upstream gone? (true/false) [${cur_checkUpstreamGone}]: " new_checkUpstreamGone
  new_checkUpstreamGone=${new_checkUpstreamGone:-$cur_checkUpstreamGone}
  read -rp "Default branch [${cur_defaultBranch}]: " new_defaultBranch
  new_defaultBranch=${new_defaultBranch:-$cur_defaultBranch}

  # Build JSON
  protected_array=$(printf '%s\n' "$new_protected" | jq -R . | jq -s .)
  tmpfile=$(mktemp)
  cat > "$tmpfile" <<EOF
{
  "protected": $protected_array,
  "days": $(printf '%s' "$new_days"),
  "checkMerged": $(printf '%s' "$new_checkMerged"),
  "checkStale": $(printf '%s' "$new_checkStale"),
  "checkUpstreamGone": $(printf '%s' "$new_checkUpstreamGone"),
  "defaultBranch": "$(printf '%s' "$new_defaultBranch")"
}
EOF

  # Validate with jq
  if jq . "$tmpfile" >/dev/null 2>&1; then
    mv "$tmpfile" "$CONFIG_FILE"
    echo "Config updated: $CONFIG_FILE"
  else
    echo "Failed to write config (invalid JSON). Aborting."
    rm -f "$tmpfile"
    return 1
  fi
}
