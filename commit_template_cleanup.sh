#!/bin/bash

echo "🧹 REFACTOR: Creating commit for template architecture cleanup"
echo ""

# Step 1: Reset the heavyweight template files from staging
echo "📤 Unstaging heavyweight templates..."
git reset HEAD templates/rust/ 2>/dev/null || true
git reset HEAD templates/typescript/ 2>/dev/null || true
git reset HEAD templates/python/ 2>/dev/null || true
git reset HEAD templates/elixir/ 2>/dev/null || true

# Step 2: Remove heavyweight template directories (they may still exist)
echo "🗑️  Removing heavyweight template directories..."
rm -rf templates/rust/
rm -rf templates/typescript/
rm -rf templates/python/  
rm -rf templates/elixir/

# Step 3: Stage the deletion of these files
echo "📝 Staging template removals..."
git add -A templates/

# Step 4: Create the commit with proper attribution
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
echo "✅ REFACTOR COMPLETE: Architectural inconsistency eliminated"
echo "   - Single template approach maintained"
echo "   - No toolchain imposition"  
echo "   - Pure configuration focus restored"