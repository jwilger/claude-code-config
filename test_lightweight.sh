#!/usr/bin/env bash
set -euo pipefail

echo "Testing lightweight claude-config implementation..."

# Test 1: Check flake structure is valid
echo "✓ Testing flake syntax..."
nix flake show --no-eval-cache 2>/dev/null || {
  echo "❌ Flake syntax error"
  exit 1
}

# Test 2: Check CLI tool exists
echo "✓ Testing CLI tool availability..."
nix eval '.#packages.x86_64-linux.default.name' 2>/dev/null || {
  echo "❌ CLI tool not found"
  exit 1  
}

# Test 3: Check language detection script exists
echo "✓ Testing language detection..."
nix eval '.#lib.x86_64-linux.detectLanguage.name' 2>/dev/null || {
  echo "❌ Language detection script not found"
  exit 1
}

# Test 4: Check setup script exists
echo "✓ Testing setup script..."
nix eval '.#lib.x86_64-linux.setupConfig.name' 2>/dev/null || {
  echo "❌ Setup script not found"
  exit 1
}

# Test 5: Check template exists
echo "✓ Testing template..."
nix flake show 2>/dev/null | grep -q "claude" || {
  echo "❌ Template not found"
  exit 1
}

echo "✅ All tests passed! Lightweight implementation is working."
echo ""
echo "Usage:"
echo "  nix run . -- detect     # Detect project language"
echo "  nix run . -- setup rust # Setup Claude configuration"