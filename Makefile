.PHONY: install uninstall setup-alias lint test help clean release

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)gitkeeper - Safe Git branch cleanup tool$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@echo "  install       Install gitkeeper globally (macOS)"
	@echo "  uninstall     Remove gitkeeper installation"
	@echo "  setup-alias   Add gk alias to shell profile"
	@echo "  lint          Run ShellCheck on all scripts"
	@echo "  test          Run basic tests"
	@echo "  clean         Remove build artifacts"
	@echo "  release       Create a release (requires VERSION)"
	@echo "  help          Show this help message"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make install"
	@echo "  make setup-alias"
	@echo "  make lint"
	@echo "  make release VERSION=1.0.0"

install:
	@echo "$(BLUE)Installing gitkeeper (macOS)...$(NC)"
	@chmod +x bin/gitkeeper lib/*.sh scripts/*.sh
	@bash scripts/install-macos.sh
	@echo "$(GREEN)✓ Installation complete$(NC)"

uninstall:
	@echo "$(BLUE)Uninstalling gitkeeper...$(NC)"
	@rm -f /usr/local/bin/gitkeeper
	@rm -f /usr/local/bin/gitkeeper-github-pr
	@rm -f /usr/local/bin/gk
	@rm -f ~/.zsh/completions/_gitkeeper
	@echo "$(GREEN)✓ Uninstallation complete$(NC)"
	@echo "⚠️  Config remains at ~/.config/gitkeeper/config.json"
	@echo "   Delete manually if desired: rm -rf ~/.config/gitkeeper"

setup-alias:
	@echo "$(BLUE)Setting up gk alias...$(NC)"
	@chmod +x scripts/setup-alias.sh
	@bash scripts/setup-alias.sh zsh
	@echo "$(GREEN)✓ Setup complete$(NC)"

lint:
	@echo "$(BLUE)Running ShellCheck...$(NC)"
	@which shellcheck > /dev/null || (echo "$(YELLOW)ShellCheck not found. Install with: brew install shellcheck$(NC)" && exit 1)
	@shellcheck bin/gitkeeper lib/*.sh scripts/*.sh
	@jq . templates/config.json > /dev/null
	@echo "$(GREEN)✓ All scripts passed linting$(NC)"

test: lint
	@echo "$(BLUE)Running basic tests...$(NC)"
	@chmod +x bin/gitkeeper lib/*.sh scripts/*.sh
	@bin/gitkeeper --help > /dev/null
	@echo "$(GREEN)✓ Help command works$(NC)"

clean:
	@echo "$(BLUE)Cleaning up...$(NC)"
	@rm -rf dist/ *.tar.gz *.zip
	@echo "$(GREEN)✓ Clean complete$(NC)"

release: lint
	@echo "$(BLUE)Creating release v$(VERSION)...$(NC)"
	@if [ -z "$(VERSION)" ]; then echo "$(YELLOW)Error: VERSION not specified$(NC)" && exit 1; fi
	@git tag -a v$(VERSION) -m "Release v$(VERSION)"
	@git push origin v$(VERSION)
	@echo "$(GREEN)✓ Release v$(VERSION) created$(NC)"

.DEFAULT_GOAL := help
