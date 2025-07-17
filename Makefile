# Screenshot Auto Mover - Makefile

.PHONY: help install build test lint clean package install-local dev setup

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

dev: setup
	npm run watch &
	@echo "Development mode started. Press Ctrl+C to stop."

all: clean setup lint test package install-local
	@echo "✅ Full build and installation completed!"

# Quick development workflow
quick: build package install-local
	@echo "🚀 Quick build and install completed!"
