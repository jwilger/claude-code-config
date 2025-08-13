# Core functionality shared across all languages
{ pkgs, system }:

{
  # Base packages needed for all Claude Code projects
  getCorePackages = with pkgs; [
    git
    gh  # GitHub CLI
    nodejs  # Required for Claude Code
    python3  # Required for hooks
  ];

  # Git safety packages and scripts
  getGitSafetyPackages = with pkgs; [
    pre-commit
  ];

  # Base shell hook for all projects
  getBaseShellHook = projectName: language: ''
    echo "🔧 ${projectName} Development Environment (${language})"
    echo "Claude Code configuration active"
    echo ""
    
    # Ensure claude code is available
    if ! command -v claude &> /dev/null; then
      echo "Installing Claude Code..."
      npx @anthropic-ai/claude-code install --force latest
    fi
    
    echo "📋 Common commands:"
  '';

  # Git safety shell hook
  getGitSafetyShellHook = ''
    # Set up git safety wrapper if available
    if [ -f "$PWD/scripts/git" ]; then
      chmod +x "$PWD/scripts/git" 2>/dev/null || true
      export PATH="$PWD/scripts:$PATH"
      echo "🛡️  Git safety wrapper enabled"
      echo "   - git commands now go through quality enforcement"
      echo "   - --no-verify is blocked (use /usr/bin/git for emergencies)"
    fi
    echo ""
  '';

  # Generate base settings.json structure
  generateSettings = { language, tooling, features }:
    let
      # Base hooks that apply to all languages
      baseHooks = {
        PostToolUse = [
          {
            hooks = [
              {
                command = "$CLAUDE_PROJECT_DIR/.claude/hooks/format_and_test.sh";
                timeout = 180;
                type = "command";
              }
            ];
            matcher = "Edit|Write";
          }
        ];
        PreToolUse = [
          {
            hooks = [
              {
                command = "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/check_branch_status.py";
                timeout = 30;
                type = "command";
              }
            ];
            matcher = "Edit|Write|MultiEdit|Bash";
          }
          {
            hooks = [
              {
                command = "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/prevent_no_verify.py";
                timeout = 10;
                type = "command";
              }
            ];
            matcher = "Bash";
          }
        ];
        UserPromptSubmit = [
          {
            hooks = [
              {
                command = "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/prompt_guard.py";
                type = "command";
              }
            ];
          }
        ];
      };
      
      # Add SPARC workflow hooks if enabled
      sparcHooks = if builtins.elem "sparc-workflow" features then {
        PreToolUse = baseHooks.PreToolUse ++ [
          {
            hooks = [
              {
                command = "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/enforce_plan_mode.py";
                timeout = 60;
                type = "command";
              }
            ];
            matcher = "Edit|Write|MultiEdit";
          }
          {
            hooks = [
              {
                command = "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/require_red_first.py";
                timeout = 60;
                type = "command";
              }
            ];
            matcher = "Edit|Write|MultiEdit";
          }
        ];
        UserPromptSubmit = baseHooks.UserPromptSubmit ++ [
          {
            hooks = [
              {
                command = "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/verify_pr_state.py";
                type = "command";
              }
            ];
          }
        ];
      } else {};
      
    in
    {
      hooks = baseHooks // sparcHooks;
    };

  # Generate base git safety wrapper
  generateGitWrapper = ''
    #!/bin/bash
    # Git wrapper that prevents --no-verify usage
    # This provides an additional layer of protection beyond hooks

    # Check if attempting to use --no-verify with commit
    if [[ "$*" == *"commit"* ]] && [[ "$*" == *"--no-verify"* ]]; then
        echo "❌ ERROR: --no-verify is forbidden by team policy"
        echo ""
        echo "All commits must pass pre-commit hooks for quality enforcement."
        echo "If you have a genuine emergency that requires bypassing:"
        echo "  1. Create a GitHub issue explaining the situation"
        echo "  2. Get explicit team approval"
        echo "  3. Use the system git directly: /usr/bin/git"
        echo ""
        echo "See CLAUDE.md section 'Code Quality Enforcement' for details."
        exit 1
    fi

    # If we're already in a Nix shell, use the Nix-provided git directly
    if [ -n "$IN_NIX_SHELL" ]; then
        # Find the nix store git (avoiding our wrapper)
        NIX_GIT=$(which -a git 2>/dev/null | grep -E '^/nix/store' | head -n1)
        if [ -n "$NIX_GIT" ]; then
            exec "$NIX_GIT" "$@"
        fi
    fi

    # Fall back to system git
    exec /usr/bin/git "$@"
  '';
}