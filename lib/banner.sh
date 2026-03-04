#!/usr/bin/env bash
# shellcheck source=colors.sh

# ASCII banner and pretty UI helpers for interactive mode
# Usage: source "$BASE_DIR/lib/banner.sh" && show_banner

show_banner() {
  # Colors come from lib/colors.sh (assumed sourced)
  local cyan=${CYAN:-}
  local yellow=${YELLOW:-}
  local green=${GREEN:-}
  
  local underline=${UNDERLINE:-}
  local reset=${NC:-}

  # Small label line
  printf "%s%sGitKeeper%s\n" "$cyan" "$underline" "$reset"
  # ASCII art provided by user (exact copy)
  cat <<'ART'
   ______  _____  _________   ___  ____   ________  ________  _______  ________  _______     
  .' ___  ||_   _||  _   _  | |_  ||_  _| |_   __  ||_   __  ||_   __ \|_   __  ||_   __ \    
 / .'   \_|  | |  |_/ | | \_|   | |_/ /     | |_ \_|  | |_ \_|  | |__) | | |_ \_|  | |__) |   
 | |   ____  | |      | |       |  __'.     |  _| _   |  _| _   |  ___/  |  _| _   |  __ /    
 \ `.___]  |_| |_    _| |_     _| |  \ \_  _| |__/ | _| |__/ | _| |_    _| |__/ | _| |  \ \_  
  `._____.'|_____|  |_____|   |____||____||________||________||_____|  |________||____| |___| 
                                                                                              
ART

  # Subtitle
  printf "%s  %sModern Git branch cleanup — safe, fast, and friendly%s\n\n" "$green" "$yellow" "$reset"
}

pretty_header() {
  local title="$1"
  local mag="${MAGENTA:-${CYAN:-}}"
  local underline_local="${UNDERLINE:-}"
  local reset_local="${NC:-}"
  echo -e "${mag}${underline_local}${title}${reset_local}"
}

export -f show_banner pretty_header 2>/dev/null || true
