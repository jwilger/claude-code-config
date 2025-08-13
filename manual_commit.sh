#!/bin/bash

echo "🧹 REFACTOR: Manual commit for template cleanup"
echo ""

# Remove any existing heavyweight template directories
rm -rf templates/rust/ templates/typescript/ templates/python/ templates/elixir/ 2>/dev/null || true

# Check git status
echo "Current git status:"
git status --porcelain | head -20

echo ""
echo "🔄 Processing template files..."

# Stage all changes in templates directory (additions and deletions)
git add -A templates/

echo ""
echo "Changes staged:"
git status --porcelain | grep templates/ || echo "No template changes to show"

echo ""
echo "📝 Creating commit with proper message..."