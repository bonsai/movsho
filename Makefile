# Screenshot Auto Mover - Makefile

.PHONY: help install build test lint clean package install-local dev setup ci install-test

# Default target
help:
	@echo "Screenshot Auto Mover - Available commands:"
	@echo ""
	@echo "  setup          - Install dependencies and compile"
	@echo "  build          - Compile TypeScript code"
	@echo "  watch          - Watch for changes and compile automatically"
	@echo "  test           - Run tests"
	@echo "  lint           - Run ESLint"
	@echo "  clean          - Clean build artifacts"
	@echo "  package        - Package the extension as .vsix"
	@echo "  install-local  - Install the extension locally in VS Code"
	@echo "  install-test   - Test extension installation"
	@echo "  ci             - Run full CI pipeline (lint, test, build, package)"
	@echo "  dev            - Start development mode (watch + install)"
	@echo "  all            - Clean, build, test, package, and install"

setup:
	npm install
	npm run compile

build:
	npm run compile

watch:
	npm run watch

test:
	npm run test

lint:
	npm run lint

clean:
	npm run clean

package: build
	npm run package

install-local: package
	npm run install-local

install-test: install-local
	@echo "🧪 Testing extension installation..."
	@if code --list-extensions | grep -q "screenshot-auto-mover"; then \
		echo "✅ Extension successfully installed and detected"; \
	else \
		echo "❌ Extension installation verification failed"; \
		echo "Installed extensions:"; \
		code --list-extensions; \
		exit 1; \
	fi

ci: lint test build package
	@echo "✅ CI pipeline completed successfully!"

dev: setup
	npm run watch &
	@echo "Development mode started. Press Ctrl+C to stop."

all: clean setup lint test package install-test
	@echo "✅ Full build, test and installation completed!"

# Quick development workflow
quick: build package install-local
	@echo "🚀 Quick build and install completed!"
