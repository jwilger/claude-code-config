#!/bin/bash

# REFACTOR: Remove heavyweight project scaffold templates
# These contradict the lightweight configuration tool approach and use non-existent mkDevShell API

echo "🧹 REFACTOR: Removing inconsistent heavyweight templates..."
echo ""

echo "📋 Templates to remove (architectural inconsistencies):"
echo "   - templates/rust/      (full project scaffold)"
echo "   - templates/typescript/ (full project scaffold)"  
echo "   - templates/python/    (full project scaffold)"
echo "   - templates/elixir/    (full project scaffold)"
echo ""

echo "🔧 Issues with heavyweight templates:"
echo "   - Use non-existent mkDevShell function"
echo "   - Create full development environments"
echo "   - Contradict lightweight configuration approach"
echo "   - Impose toolchain choices on users"
echo ""

# Remove full project scaffolds
rm -rf templates/rust/
rm -rf templates/typescript/ 
rm -rf templates/python/
rm -rf templates/elixir/

echo "✅ Removed heavyweight templates successfully"
echo ""
echo "✅ Kept aligned template:"
echo "   - templates/claude/ (lightweight configuration only)"
echo ""
echo "🎯 REFACTOR COMPLETE: Tool now focused purely on lightweight configuration"
echo "   - Single template approach"  
echo "   - No toolchain imposition"
echo "   - Configuration-only methodology"
echo "   - Consistent with detect/setup CLI"