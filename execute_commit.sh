#!/bin/bash

# Execute the template cleanup commit
echo "Executing template cleanup commit..."

# Make the script executable and run it
chmod +x /workspaces/claude-config/commit_template_cleanup.sh
/workspaces/claude-config/commit_template_cleanup.sh

echo "Commit complete!"