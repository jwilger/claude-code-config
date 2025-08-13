#!/usr/bin/env python3
"""
Prevent --no-verify usage with git commit commands.
This enforces team quality policies by preventing bypass of pre-commit hooks.
"""

import sys
import os

def main():
    """Check if command contains git commit with --no-verify and prevent it."""
    
    # Check if command contains git commit with --no-verify
    if len(sys.argv) > 1:
        command = " ".join(sys.argv[1:])
        if "git" in command and "commit" in command and "--no-verify" in command:
            print("❌ ERROR: --no-verify is forbidden by team policy")
            print("")
            print("All commits must pass pre-commit hooks for quality enforcement.")
            print("This ensures consistent code quality and prevents technical debt.")
            print("")
            print("If you have a genuine emergency that requires bypassing:")
            print("  1. Create a GitHub issue explaining the situation")
            print("  2. Get explicit team approval in issue comments")
            print("  3. Use the system git directly: /usr/bin/git")
            print("  4. Create a follow-up story to address the underlying issue")
            print("")
            print("See CLAUDE.md section 'Code Quality Enforcement' for details.")
            print("Consider these alternatives:")
            print("  - Fix the failing hooks instead of bypassing them")
            print("  - Stage only the files that pass quality checks")
            print("  - Create a smaller, focused commit that passes hooks")
            print("")
            sys.exit(1)
    
    # Also check environment variables for git commands (from shells/scripts)
    git_command = os.environ.get('GIT_COMMAND', '')
    if git_command and "commit" in git_command and "--no-verify" in git_command:
        print("❌ ERROR: --no-verify detected in environment")
        print("Team policy prevents bypassing pre-commit hooks.")
        sys.exit(1)

if __name__ == "__main__":
    main()