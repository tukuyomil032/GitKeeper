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
      --since) DAYS="$2"; export DAYS; shift ;;
      --protect) PROTECTED+=("$2"); shift ;;
      --no-merged) CHECK_MERGED=false; export CHECK_MERGED ;;
      --no-stale) CHECK_STALE=false; export CHECK_STALE ;;
      --no-gone) CHECK_GONE=false; export CHECK_GONE ;;
      --dry-run) DRY_RUN=true; export DRY_RUN ;;
      --force) FORCE=true; export FORCE ;;
      --help|-h) show_help; exit 0 ;;
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
  --scan-dir DIR          Scan for repositories in specified directory
  --since DAYS            Override stale threshold (default: 30)
  --protect BRANCH        Add protected branch
  --no-merged             Disable merged branch check
  --no-stale              Disable stale (>30d) branch check
  --no-gone               Disable upstream gone branch check
  --dry-run               Show what would be deleted without deleting
  --force                 Force delete unmerged branches (use with caution)
  --help, -h              Show this help message

EXAMPLES:
  gitkeeper                           # Interactive cleanup
  gitkeeper --dry-run                 # Preview branches to delete
  gitkeeper --scan-dir ~/projects     # Scan and select repository
  gitkeeper --since 45                # Use 45 days threshold
  gitkeeper --protect staging         # Add staging as protected
  gitkeeper --force                   # Force delete unmerged branches

CONFIG:
  Edit config.json to change defaults (protected branches, days, checks)

EOF
}
