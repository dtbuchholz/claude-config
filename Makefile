.PHONY: install deps hooks format format-check help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: deps hooks ## Full setup (deps + hooks)

deps: ## Install Node dependencies and CLI tools
	pnpm install
	@command -v gitleaks >/dev/null 2>&1 || { echo "Installing gitleaks..."; brew install gitleaks; }
	@command -v terminal-notifier >/dev/null 2>&1 || { echo "Installing terminal-notifier..."; brew install terminal-notifier; }
	@command -v gh >/dev/null 2>&1 || { echo "Installing gh..."; brew install gh; }
	@command -v qmd >/dev/null 2>&1 || { echo "Installing qmd..."; npm install -g @tobilu/qmd; }

hooks: ## Make all hook scripts executable
	chmod +x hooks/*.sh

format: ## Format all files with Prettier
	pnpm format

format-check: ## Check formatting (CI)
	pnpm format:check
