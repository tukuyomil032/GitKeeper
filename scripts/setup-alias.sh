#!/bin/bash

# gitkeeper zsh/bash alias setup helper
# Usage: ./scripts/setup-alias.sh [zsh|bash]

set -euo pipefail

# Colors
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  NC='\033[0m'
else
  GREEN='' YELLOW='' CYAN='' NC=''
fi

SHELL_TYPE="${1:-zsh}"
SHELL_RC=""

case "$SHELL_TYPE" in
  zsh)
    SHELL_RC="$HOME/.zshrc"
    ;;
  bash)
    SHELL_RC="$HOME/.bash_profile"
    if [ ! -f "$SHELL_RC" ]; then
      SHELL_RC="$HOME/.bashrc"
    fi
    ;;
  *)
    echo "Usage: $0 [zsh|bash]"
    exit 1
    ;;
esac

if [ ! -f "$SHELL_RC" ]; then
  echo -e "${YELLOW}⚠️${NC} Shell configuration file not found: $SHELL_RC"
  exit 1
fi

# Check if alias already exists
if grep -q "alias gk=" "$SHELL_RC"; then
  echo -e "${YELLOW}⚠️${NC} 'gk' alias already exists in $SHELL_RC"
  read -rp "Overwrite? (y/N): " overwrite
  if [ "$overwrite" != "y" ]; then
    echo "Aborted."
    exit 0
  fi
  # Remove existing alias
  sed -i.bak "/alias gk=/d" "$SHELL_RC"
  echo -e "${GREEN}✓${NC} Removed previous alias"
fi

# Add alias
{
  echo ""
  echo "# gitkeeper alias"
  echo "alias gk='gitkeeper'"
} >> "$SHELL_RC"

echo -e "${GREEN}✓${NC} Added 'gk' alias to $SHELL_RC"
echo -e "${CYAN}💡${NC} Reload shell to use: source $SHELL_RC"
