#!/bin/bash

set -e

echo "🧹 REFACTOR: Creating final commit for template architecture cleanup"
echo ""

# Ensure we're in the right directory
cd /workspaces/claude-config

# Remove heavyweight template directories if they exist
echo "🗑️  Removing heavyweight template directories..."
rm -rf templates/rust/ templates/typescript/ templates/python/ templates/elixir/

# Stage all changes to templates directory
echo "📝 Staging changes..."
git add -A templates/

# Check what we're committing
echo ""
echo "📊 Changes to be committed:"
git diff --cached --stat | grep templates/ || echo "No template changes in staging area"

# Create the commit
echo ""
echo "💾 Creating commit..."
git commit -m "refactor: eliminate heavyweight template scaffolds

Remove project scaffold templates that contradict lightweight configuration approach:
- templates/rust/ (full Rust project setup)
- templates/typescript/ (full Node.js project setup)  
- templates/python/ (full Python project setup)
- templates/elixir/ (full Elixir project setup)

These templates:
- Used non-existent mkDevShell API
- Created full development environments
- Contradicted the tool's lightweight configuration focus
- Imposed specific toolchain choices on users

Kept aligned template:
- templates/claude/ (lightweight configuration only)

This maintains architectural consistency with the detect/setup CLI approach
that focuses purely on Claude Code configuration rather than project scaffolding.

Co-authored-by: Claude Code <claude@anthropic.com>"

echo ""
echo "✅ REFACTOR COMPLETE: Template architecture cleanup committed"
echo "   - Heavyweight scaffolds eliminated"
echo "   - Architectural consistency restored"  
echo "   - Single lightweight template approach maintained"