#!/bin/bash

set -euo pipefail

# gitkeeper installer for macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
COMPLETION_DIR="${COMPLETION_DIR:-$HOME/.zsh/completions}"
CONFIG_SOURCE="$SCRIPT_DIR/templates/config.json"
CONFIG_DEST="${CONFIG_DEST:-$HOME/.config/gitkeeper/config.json}"

# Color codes
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  GREEN='' RED='' YELLOW='' CYAN='' BOLD='' NC=''
fi

echo -e "${BOLD}📦 gitkeeper Installer (macOS)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for required tools
echo -e "${CYAN}✓${NC} Checking dependencies..."
for cmd in jq git; do
  if ! command -v "$cmd" &> /dev/null; then
    echo -e "${RED}❌${NC} $cmd is required but not installed"
    if [ "$cmd" = "jq" ]; then
      echo "   Install with: brew install jq"
    fi
    exit 1
  fi
done

if ! command -v fzf &> /dev/null; then
  echo -e "${YELLOW}⚠️${NC} fzf is recommended for interactive UI"
  echo "   Install with: brew install fzf"
fi

echo -e "${GREEN}✓${NC} Dependencies OK"
echo ""

# Make scripts executable
echo -e "${CYAN}✓${NC} Setting permissions..."
chmod +x "$SCRIPT_DIR/bin/gitkeeper"
chmod +x "$SCRIPT_DIR/lib"/*.sh
echo ""

# Create install directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
  echo -e "${YELLOW}⚠️${NC} $INSTALL_DIR does not exist"
  echo "   Creating with sudo..."
  sudo mkdir -p "$INSTALL_DIR"
fi

# Install main script
echo -e "${CYAN}📝${NC} Installing gitkeeper to $INSTALL_DIR..."

# Check if we need sudo
if [ -w "$INSTALL_DIR" ]; then
  ln -sf "$SCRIPT_DIR/bin/gitkeeper" "$INSTALL_DIR/gitkeeper"
  ln -sf "$SCRIPT_DIR/lib/github.sh" "$INSTALL_DIR/gitkeeper-github-pr"
  ln -sf "$INSTALL_DIR/gitkeeper" "$INSTALL_DIR/gk"
else
  sudo ln -sf "$SCRIPT_DIR/bin/gitkeeper" "$INSTALL_DIR/gitkeeper"
  sudo ln -sf "$SCRIPT_DIR/lib/github.sh" "$INSTALL_DIR/gitkeeper-github-pr"
  sudo ln -sf "$INSTALL_DIR/gitkeeper" "$INSTALL_DIR/gk"
fi

echo -e "${GREEN}✓${NC} gitkeeper installed to $INSTALL_DIR/gitkeeper"
echo -e "${GREEN}✓${NC} gk alias installed to $INSTALL_DIR/gk"
echo ""

# Install zsh completion
if [ -d "$COMPLETION_DIR" ] || mkdir -p "$COMPLETION_DIR" 2>/dev/null; then
  cp "$SCRIPT_DIR/completions/_gitkeeper" "$COMPLETION_DIR/_gitkeeper"
  echo -e "${GREEN}✓${NC} zsh completion installed to $COMPLETION_DIR/_gitkeeper"
  echo ""
  echo -e "${CYAN}💡${NC} To enable completions, add this to your ~/.zshrc:"
  echo "   fpath=(~/.zsh/completions \$fpath)"
  echo "   autoload -Uz compinit && compinit"
  echo ""
else
  echo -e "${YELLOW}⚠️${NC} Could not create $COMPLETION_DIR"
  echo "   Manual installation: cp completions/_gitkeeper ~/.zsh/completions/"
  echo ""
fi

# Setup config
echo -e "${CYAN}⚙️${NC} Setting up configuration..."
if [ ! -d "$(dirname "$CONFIG_DEST")" ]; then
  mkdir -p "$(dirname "$CONFIG_DEST")"
fi

if [ -f "$CONFIG_DEST" ]; then
  echo -e "${YELLOW}⚠️${NC} Config already exists at $CONFIG_DEST"
  read -rp "   Overwrite? (y/N): " overwrite
  if [ "$overwrite" = "y" ]; then
    cp "$CONFIG_SOURCE" "$CONFIG_DEST"
    echo -e "${GREEN}✓${NC} Config updated"
  fi
else
  cp "$CONFIG_SOURCE" "$CONFIG_DEST"
  echo -e "${GREEN}✓${NC} Config installed to $CONFIG_DEST"
fi
echo ""

# Verify installation
echo -e "${BOLD}✅ Verifying installation...${NC}"
if command -v gitkeeper &> /dev/null; then
  echo -e "${GREEN}✓${NC} gitkeeper is available in PATH"
  gitkeeper --help | head -3
  echo ""
else
  echo -e "${RED}❌${NC} Installation verification failed"
  echo "   Make sure $INSTALL_DIR is in your PATH"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✨ gitkeeper installed successfully!${NC}"
echo ""
echo -e "${BOLD}🚀 Getting started:${NC}"
echo "   gitkeeper          # Run interactive cleanup"
echo "   gk                 # Quick alias"
echo "   gitkeeper --help   # Show help"
echo "   gitkeeper --dry-run # Preview changes"
echo ""
echo -e "${BOLD}📖 Configuration:${NC}"
echo "   Edit: $CONFIG_DEST"
echo ""
echo -e "${BOLD}📊 Documentation:${NC}"
echo "   README:   https://github.com/tukuyomil322/gitkeeper#readme"
echo ""
