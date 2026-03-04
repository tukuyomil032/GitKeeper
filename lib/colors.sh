#!/bin/bash

# Color codes for output
# Only enable if terminal supports colors

# Detect if output supports colors
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  # Terminal output
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m'  # No Color
else
  # No colors for piped output or when NO_COLOR is set
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  CYAN=''
  BOLD=''
  NC=''
fi

# Utility functions for colored output
log_success() {
  echo -e "${GREEN}✓${NC} $*"
}

log_error() {
  echo -e "${RED}❌${NC} $*" >&2
}

log_warning() {
  echo -e "${YELLOW}⚠️${NC} $*"
}

log_info() {
  echo -e "${CYAN}ℹ${NC} $*"
}

log_header() {
  echo -e "\n${BOLD}$*${NC}"
}

# Export for use in sourced scripts
export RED GREEN YELLOW BLUE CYAN BOLD NC
