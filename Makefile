# Titan Browser Makefile

.PHONY: help install clean test build run format lint analyze deps security

# Default target
help:
	@echo "Titan Browser Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  install    - Install dependencies"
	@echo "  clean      - Clean build artifacts"
	@echo "  test       - Run all tests"
	@echo "  build      - Build for current platform"
	@echo "  run        - Run in development mode"
	@echo "  format     - Format code"
	@echo "  lint       - Run linter"
	@echo "  analyze    - Analyze code"
	@echo "  deps       - Check dependencies"
	@echo "  security   - Run security checks"

# Install dependencies
install:
	@echo "Installing Flutter dependencies..."
	flutter pub get
	@echo "Building Rust engine..."
	cd rust_engine && cargo build --release
	@echo "Generating code..."
	flutter packages pub run build_runner build --delete-conflicting-outputs

# Clean build artifacts
clean:
	@echo "Cleaning Flutter build..."
	flutter clean
	@echo "Cleaning Rust build..."
	cd rust_engine && cargo clean
	@echo "Removing generated files..."
	find . -name "*.g.dart" -delete
	find . -name "*.mocks.dart" -delete

# Run tests
test:
	@echo "Running unit tests..."
	flutter test --coverage
	@echo "Running integration tests..."
	flutter test integration_test/
	@echo "Running Rust tests..."
	cd rust_engine && cargo test

# Build for current platform
build:
	@echo "Building for current platform..."
	@if [ "$(shell uname)" = "Linux" ]; then \
		flutter build linux --release; \
	elif [ "$(shell uname)" = "Darwin" ]; then \
		flutter build macos --release; \
	elif [ "$(OS)" = "Windows_NT" ]; then \
		flutter build windows --release; \
	else \
		echo "Unsupported platform"; \
		exit 1; \
	fi

# Run in development mode
run:
	@echo "Running Titan Browser in development mode..."
	flutter run -d desktop

# Format code
format:
	@echo "Formatting Dart code..."
	dart format .
	@echo "Formatting Rust code..."
	cd rust_engine && cargo fmt

# Run linter
lint:
	@echo "Running Dart linter..."
	flutter analyze
	@echo "Running Rust linter..."
	cd rust_engine && cargo clippy -- -D warnings

# Analyze code
analyze:
	@echo "Analyzing Dart code..."
	flutter analyze --fatal-infos
	@echo "Analyzing Rust code..."
	cd rust_engine && cargo audit

# Check dependencies
deps:
	@echo "Checking Flutter dependencies..."
	flutter pub deps
	@echo "Checking Rust dependencies..."
	cd rust_engine && cargo tree

# Security checks
security:
	@echo "Running security checks..."
	@echo "Checking for known vulnerabilities..."
	cd rust_engine && cargo audit
	@echo "Checking for secrets in code..."
	@if command -v gitleaks >/dev/null 2>&1; then \
		gitleaks detect --source . --verbose; \
	else \
		echo "gitleaks not installed, skipping secret detection"; \
	fi

# Development setup
dev-setup: install
	@echo "Setting up development environment..."
	@echo "Installing pre-commit hooks..."
	@if [ -d ".git" ]; then \
		echo "#!/bin/sh" > .git/hooks/pre-commit; \
		echo "make format lint" >> .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
	fi

# Release build
release: clean install test build
	@echo "Creating release build..."
	@echo "Build completed successfully!"

# Docker build
docker-build:
	@echo "Building Docker image..."
	docker build -t titan-browser .

# Performance profiling
profile:
	@echo "Running performance profile..."
	flutter run --profile --trace-startup

# Generate documentation
docs:
	@echo "Generating documentation..."
	dart doc .
	cd rust_engine && cargo doc --no-deps

# Benchmark tests
benchmark:
	@echo "Running benchmark tests..."
	cd rust_engine && cargo bench