#!/usr/bin/env python3
"""
Check git branch status and provide warnings for common issues.
Helps prevent accidental commits to main branch and other workflow issues.
"""

import subprocess
import sys
import os

def main():
    """Check current branch status and provide appropriate warnings."""
    try:
        # Check if we're in a git repository
        subprocess.run(["git", "rev-parse", "--git-dir"], 
                     check=True, capture_output=True)
        
        # Get current branch
        result = subprocess.run(["git", "branch", "--show-current"], 
                              capture_output=True, text=True, check=True)
        current_branch = result.stdout.strip()
        
        # Warn if on main/master branch
        if current_branch in ["main", "master"]:
            print("⚠️  WARNING: You are on the main branch")
            print("   Consider creating a feature branch for changes:")
            print("   git checkout -b story-XXX-descriptive-name")
            print("")
            
        # Check for branch.info file to see if we're in a SPARC workflow
        branch_info_path = ".claude/branch.info"
        if os.path.exists(branch_info_path):
            try:
                import json
                with open(branch_info_path, 'r') as f:
                    branch_info = json.load(f)
                
                expected_branch = branch_info.get('branch')
                current_story = branch_info.get('current_story')
                
                if expected_branch and current_branch != expected_branch:
                    print(f"⚠️  WARNING: Branch mismatch detected")
                    print(f"   Current branch: {current_branch}")
                    print(f"   Expected branch: {expected_branch}")
                    print(f"   Current story: {current_story}")
                    print("   Consider switching to the correct branch:")
                    print(f"   git checkout {expected_branch}")
                    print("")
                elif current_story:
                    print(f"📋 Active story: {current_story}")
                    print(f"   Current branch: {current_branch}")
                    print("")
                    
            except (json.JSONDecodeError, IOError):
                # branch.info exists but is invalid - not critical
                pass
        
        # Check for uncommitted changes
        result = subprocess.run(["git", "status", "--porcelain"], 
                              capture_output=True, text=True, check=True)
        if result.stdout.strip():
            # There are uncommitted changes - just informational
            staged_changes = any(line[0] in 'MADRC' for line in result.stdout.split('\n') if line.strip())
            unstaged_changes = any(line[1] in 'MD' for line in result.stdout.split('\n') if line.strip())
            
            if staged_changes and unstaged_changes:
                print("📝 You have both staged and unstaged changes")
            elif staged_changes:
                print("📝 You have staged changes ready to commit")
            elif unstaged_changes:
                print("📝 You have unstaged changes")
        
        # Check if we're ahead/behind remote
        try:
            # Get remote tracking branch
            remote_result = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", f"{current_branch}@{{upstream}}"],
                capture_output=True, text=True, check=True
            )
            remote_branch = remote_result.stdout.strip()
            
            # Check if we're ahead or behind
            ahead_result = subprocess.run(
                ["git", "rev-list", "--count", f"{remote_branch}..{current_branch}"],
                capture_output=True, text=True, check=True
            )
            behind_result = subprocess.run(
                ["git", "rev-list", "--count", f"{current_branch}..{remote_branch}"],
                capture_output=True, text=True, check=True
            )
            
            ahead_count = int(ahead_result.stdout.strip())
            behind_count = int(behind_result.stdout.strip())
            
            if ahead_count > 0 and behind_count > 0:
                print(f"🔄 Branch is {ahead_count} commits ahead and {behind_count} commits behind {remote_branch}")
                print("   Consider rebasing: git pull --rebase")
            elif ahead_count > 0:
                print(f"⬆️  Branch is {ahead_count} commits ahead of {remote_branch}")
            elif behind_count > 0:
                print(f"⬇️  Branch is {behind_count} commits behind {remote_branch}")
                print("   Consider updating: git pull")
                
        except subprocess.CalledProcessError:
            # No remote tracking branch or other issue - not critical
            pass
            
    except subprocess.CalledProcessError:
        # Not a git repo or git command failed - continue silently
        pass
    except Exception:
        # Any other error - continue silently to not block workflow
        pass

if __name__ == "__main__":
    main()