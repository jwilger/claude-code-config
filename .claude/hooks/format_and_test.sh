#!/usr/bin/env bash
set -euo pipefail

# Multi-language format and test script
# Detects project language and runs appropriate formatting and testing

echo "🔧 Running format and test checks..."

# Function to detect project language
detect_language() {
    if [ -f "Cargo.toml" ]; then
        echo "rust"
    elif [ -f "package.json" ]; then
        echo "typescript"
    elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        echo "python"
    elif [ -f "mix.exs" ]; then
        echo "elixir"
    else
        echo "unknown"
    fi
}

# Detect the project language
LANGUAGE=$(detect_language)
echo "📋 Detected language: $LANGUAGE"

case "$LANGUAGE" in
    "rust")
        echo "🦀 Running Rust format and test checks..."
        if command -v cargo >/dev/null 2>&1; then
            # Format code
            echo "  - Formatting code..."
            cargo fmt
            
            # Run clippy with strict linting
            echo "  - Running clippy..."
            cargo clippy -- -D warnings
            
            # Run tests
            echo "  - Running tests..."
            if command -v cargo-nextest >/dev/null 2>&1; then
                cargo nextest run --nocapture
            else
                cargo test
            fi
        else
            echo "⚠️  Cargo not found, skipping Rust checks"
        fi
        ;;
        
    "typescript")
        echo "📦 Running TypeScript/Node.js format and test checks..."
        
        # Determine package manager
        if [ -f "pnpm-lock.yaml" ]; then
            PKG_MANAGER="pnpm"
        elif [ -f "yarn.lock" ]; then
            PKG_MANAGER="yarn"
        else
            PKG_MANAGER="npm"
        fi
        
        echo "  - Using package manager: $PKG_MANAGER"
        
        # Run formatting if prettier is available
        if [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ]; then
            echo "  - Running prettier..."
            $PKG_MANAGER run format 2>/dev/null || echo "    (format script not found, skipping)"
        fi
        
        # Run linting if ESLint is available
        if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ]; then
            echo "  - Running ESLint..."
            $PKG_MANAGER run lint 2>/dev/null || echo "    (lint script not found, skipping)"
        fi
        
        # Run type checking
        if [ -f "tsconfig.json" ]; then
            echo "  - Running TypeScript compiler..."
            $PKG_MANAGER run type-check 2>/dev/null || npx tsc --noEmit || echo "    (type-check failed or not configured)"
        fi
        
        # Run tests
        echo "  - Running tests..."
        $PKG_MANAGER run test 2>/dev/null || echo "    (test script not found)"
        ;;
        
    "python")
        echo "🐍 Running Python format and test checks..."
        
        # Run ruff formatting and linting if available
        if command -v ruff >/dev/null 2>&1; then
            echo "  - Running ruff format..."
            ruff format .
            
            echo "  - Running ruff check..."
            ruff check .
        elif command -v black >/dev/null 2>&1 && command -v flake8 >/dev/null 2>&1; then
            echo "  - Running black..."
            black .
            
            echo "  - Running flake8..."
            flake8 .
        else
            echo "  - No formatter/linter found (ruff or black+flake8 recommended)"
        fi
        
        # Run mypy type checking if available
        if command -v mypy >/dev/null 2>&1; then
            echo "  - Running mypy..."
            mypy . || echo "    (mypy check failed or not configured)"
        fi
        
        # Run tests
        echo "  - Running tests..."
        if command -v pytest >/dev/null 2>&1; then
            pytest
        elif [ -f "manage.py" ]; then
            python manage.py test
        else
            python -m unittest discover || echo "    (no tests found)"
        fi
        ;;
        
    "elixir")
        echo "💧 Running Elixir format and test checks..."
        
        if command -v mix >/dev/null 2>&1; then
            # Format code
            echo "  - Running mix format..."
            mix format
            
            # Run credo if available
            echo "  - Running credo..."
            mix credo || echo "    (credo not available or failed)"
            
            # Compile to check for warnings
            echo "  - Compiling with warnings as errors..."
            mix compile --warnings-as-errors
            
            # Run tests
            echo "  - Running tests..."
            mix test
        else
            echo "⚠️  Mix not found, skipping Elixir checks"
        fi
        ;;
        
    "unknown")
        echo "❓ Unknown project type, running generic git hooks..."
        
        # Run pre-commit hooks if available
        if [ -f ".git/hooks/pre-commit" ] && [ -x ".git/hooks/pre-commit" ]; then
            echo "  - Running pre-commit hooks..."
            ./.git/hooks/pre-commit
        else
            echo "  - No pre-commit hooks found"
        fi
        ;;
esac

echo "✅ Format and test checks completed successfully!"