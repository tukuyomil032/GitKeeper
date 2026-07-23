.PHONY: lint test help clean

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)gitkeeper - Safe Git branch cleanup tool$(NC)"
	@echo ""
	@echo "$(GREEN)Install:$(NC)"
	@echo "  brew install tukuyomil032/tap/gitkeeper"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@echo "  lint          Run ShellCheck on all scripts"
	@echo "  test          Run basic tests"
	@echo "  clean         Remove build artifacts"
	@echo "  help          Show this help message"

lint:
	@echo "$(BLUE)Running ShellCheck...$(NC)"
	@which shellcheck > /dev/null || (echo "$(YELLOW)ShellCheck not found. Install with: brew install shellcheck$(NC)" && exit 1)
	@shellcheck bin/gitkeeper lib/*.sh
	@jq . templates/config.json > /dev/null
	@echo "$(GREEN)✓ All scripts passed linting$(NC)"

test: lint
	@echo "$(BLUE)Running basic tests...$(NC)"
	@chmod +x bin/gitkeeper lib/*.sh
	@bin/gitkeeper --help > /dev/null
	@echo "$(GREEN)✓ Help command works$(NC)"

clean:
	@echo "$(BLUE)Cleaning up...$(NC)"
	@rm -rf dist/ *.tar.gz *.zip
	@echo "$(GREEN)✓ Clean complete$(NC)"

.DEFAULT_GOAL := help
