# Rust language configuration module
{ pkgs, system, inputs }:

let
  # Import rust overlay for proper toolchain management
  rustPkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ (import inputs.rust-overlay) ];
    config.allowUnfree = true;
  };
in
{
  # Default tooling configuration for Rust projects
  defaultTooling = {
    testRunner = "nextest";
    linter = "clippy";
    formatter = "rustfmt";
    buildTool = "cargo";
    extraTools = [ "cargo-watch" "cargo-expand" "cargo-edit" ];
  };

  # Get packages based on tooling configuration
  getPackages = tooling:
    let
      # Use stable Rust toolchain - users can override via rust-toolchain.toml in their project
      rustToolchain = rustPkgs.rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" "rustfmt" "clippy" "rust-analyzer" ];
      };
        
      basePackages = [
        rustToolchain
        pkgs.pkg-config
        pkgs.openssl
      ];
      
      testPackages = if tooling.testRunner == "nextest" 
        then [ pkgs.cargo-nextest ]
        else [];
        
      extraPackages = map (tool: pkgs.${tool}) (tooling.extraTools or []);
      
    in
    basePackages ++ testPackages ++ extraPackages;

  # Get environment variables
  getEnvironment = tooling: {
    RUST_SRC_PATH = "${rustPkgs.rust-bin.stable.latest.default}/lib/rustlib/src/rust/library";
    RUST_BACKTRACE = "1";
  };

  # Generate shell hook
  getShellHook = tooling: ''
    # Install cargo-mcp if needed
    if ! command -v cargo-mcp &> /dev/null; then
      cargo install --locked cargo-mcp
    fi
    
    echo "🦀 Rust Development Environment"
    echo "Rust version: $(rustc --version)"
    echo "Available tools: ${builtins.concatStringsSep ", " ([ tooling.testRunner tooling.linter tooling.formatter ] ++ (tooling.extraTools or []))}"
    echo ""
    
    echo "📋 Rust commands:"
    ${if tooling.testRunner == "nextest" then ''
    echo "  cargo nextest run        # Run tests with nextest"
    echo "  cargo nextest run --lib  # Unit tests only"
    '' else ''
    echo "  cargo test               # Run tests"
    ''}
    ${if tooling.linter == "clippy" then ''
    echo "  cargo clippy             # Lint code"
    echo "  cargo clippy -- -D warnings  # Lint with warnings as errors"
    '' else ""}
    ${if tooling.formatter == "rustfmt" then ''
    echo "  cargo fmt               # Format code"
    '' else ""}
    echo "  cargo build             # Build project"
    echo "  cargo check             # Fast syntax checking"
    ${if builtins.elem "cargo-watch" (tooling.extraTools or []) then ''
    echo "  cargo watch -x test     # Auto-run tests on changes"
    '' else ""}
    echo ""
  '';

  # Generate CLAUDE.md content specific to Rust
  generateClaudeMd = { projectName, tooling, features }:
    let
      testCommand = if tooling.testRunner == "nextest" then "cargo nextest run" else "cargo test";
      testCommandOptions = if tooling.testRunner == "nextest" then ''
        ```bash
        cargo nextest run                    # Run all tests
        cargo nextest run --lib             # Unit tests only
        cargo nextest run --tests           # Integration tests only
        cargo nextest run --nocapture       # Show test output
        RUST_BACKTRACE=1 cargo nextest run  # With backtrace on failure
        ```
      '' else ''
        ```bash
        cargo test                          # Run all tests
        cargo test --lib                   # Unit tests only
        cargo test --tests                 # Integration tests only
        RUST_BACKTRACE=1 cargo test        # With backtrace on failure
        ```
      '';
      
      sparcSection = if builtins.elem "sparc-workflow" features then ''

        ## SPARC Workflow Integration

        This project uses the SPARC (Study, Plan, Architect, Review, Code) workflow with GitHub pull requests:

        ### Story Development Flow

        1. **Story Selection**: Choose from PLANNING.md
        2. **Branch Creation**: `story-{id}-{slug}` feature branches  
        3. **Standard SPARC**: Research → Plan → Implement → Expert (with mandatory memory storage)
        4. **PR Creation**: Draft PRs with comprehensive descriptions
        5. **Review Loop**: Address feedback with Claude Code attribution
        6. **Human Merge**: Only humans mark PRs ready-for-review

        ### MANDATORY Memory Storage (CRITICAL)

        **Every SPARC phase MUST store knowledge in MCP memory for systematic improvement.**

        ### Commands & Agents

        Primary commands:
        - `/sparc` - Full story workflow with PR integration
        - `/sparc/pr` - Create draft PR for completed story
        - `/sparc/review` - Respond to PR feedback
        - `/sparc/status` - Check branch/PR/story status

        Subagents: researcher, planner, implementer, type-architect, test-hardener, expert, pr-manager.
      '' else "";
      
    in
    ''
      # CLAUDE.md

      This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

      ## Development Commands

      ### Testing

      Always use `${testCommand}` for testing:

      ${testCommandOptions}

      ### Building and Linting

      ```bash
      cargo build                          # Build the project
      cargo build --release              # Release build
      cargo check                         # Fast syntax/type checking
      ${if tooling.linter == "clippy" then "cargo clippy                        # Linting (strict rules enabled)" else ""}
      ${if tooling.formatter == "rustfmt" then "cargo fmt                          # Format code" else ""}
      ```

      ### Development Tools

      ```bash
      ${if builtins.elem "cargo-watch" (tooling.extraTools or []) then "cargo watch -x test                 # Auto-run tests on changes" else ""}
      ${if builtins.elem "cargo-expand" (tooling.extraTools or []) then "cargo expand                       # Macro expansion" else ""}
      ${if builtins.elem "cargo-edit" (tooling.extraTools or []) then "cargo edit                         # Dependency management" else ""}
      ```

      ## Architecture Overview

      ${projectName} follows **type-driven development** principles:

      - Illegal states are unrepresentable through the type system
      - Phantom types for state transitions where applicable
      - Smart constructors with validation
      - Comprehensive error types with domain-specific variants
      - nutype crate for eliminating primitive obsession

      ## Rust Type-Driven Rules

      - **Illegal states are unrepresentable**: prefer domain types over primitives.
      - All new domain types use `nutype` with `sanitize(...)` and `validate(...)`. Derive at least: `Clone, Debug, Eq, PartialEq, Display`; add `Serialize, Deserialize` where needed.
      - Prefer `Result<T, DomainError>` over panics. Panics only for truly unreachable states.

      ### Example

      ```rust
      #[nutype(
        sanitize(trim),
        validate(len(min = 1, max = 64)),
        derive(Clone, Debug, Eq, PartialEq, Display)
      )]
      pub struct ProjectName(String);
      ```

      ## Code Quality Enforcement - CRITICAL

      **NEVER ADD ALLOW ATTRIBUTES** - This is a hard rule with zero exceptions without team approval.

      - **NEVER** use `#![allow(clippy::...)]` or `#[allow(clippy::...)]` without explicit team approval
      - **NEVER** bypass pre-commit hooks or ignore clippy warnings/errors
      - **ALWAYS** fix the underlying issue causing the warning instead of suppressing it
      - Pre-commit hooks MUST pass with `-D warnings` (treat warnings as errors)

      ## Testing Discipline (Kent Beck)

      Work in strict Red → Green → Refactor loops with one failing test at a time.

      Use MCP cargo server for all tests; treat clippy warnings as errors.

      ## Functional Core / Imperative Shell

      Put pure logic in the core (no I/O, no mutation beyond local scope).

      Keep an imperative shell for I/O; inject dependencies via traits.

      Model workflows as Result pipelines (railway style).
      ${sparcSection}

      ## Development Conventions

      - **Error Handling**: Use comprehensive Result types with domain errors
      - **Resource Safety**: Always validate resource limits before allocation
      - **State Machines**: Use phantom types for compile-time state validation
      - **Testing**: Write property-based tests for validation logic
      - **Dependency Management**: Always use package manager CLI tools (`cargo add`, `cargo remove`) to install/update dependencies. Never manually edit Cargo.toml version numbers.
    '';

  # Generate language-specific hooks
  generateHooks = tooling: features:
    let
      formatAndTestScript = ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Run Rust-specific formatting and linting
        if [ -f Cargo.toml ]; then
            echo "Running Rust formatting and tests..."
            ${if tooling.formatter == "rustfmt" then "cargo fmt" else ""}
            ${if tooling.linter == "clippy" then "cargo clippy -- -D warnings" else ""}
            ${if tooling.testRunner == "nextest" then "cargo nextest run --nocapture" else "cargo test"}
        elif [ -f .git/hooks/pre-commit ]; then
            ./.git/hooks/pre-commit
        fi
      '';
      
    in
    {
      "format_and_test.sh" = formatAndTestScript;
      "prevent_no_verify.py" = ''
        #!/usr/bin/env python3
        import sys
        import os

        # Check if command contains git commit with --no-verify
        if len(sys.argv) > 1:
            command = " ".join(sys.argv[1:])
            if "git" in command and "commit" in command and "--no-verify" in command:
                print("❌ ERROR: --no-verify is forbidden by team policy")
                print("")
                print("All commits must pass pre-commit hooks for quality enforcement.")
                print("See CLAUDE.md section 'Code Quality Enforcement' for details.")
                sys.exit(1)
      '';
      "check_branch_status.py" = ''
        #!/usr/bin/env python3
        import subprocess
        import sys
        import os

        def main():
            try:
                # Check if we're in a git repository
                subprocess.run(["git", "rev-parse", "--git-dir"], 
                             check=True, capture_output=True)
                
                # Get current branch
                result = subprocess.run(["git", "branch", "--show-current"], 
                                      capture_output=True, text=True, check=True)
                current_branch = result.stdout.strip()
                
                # Warn if on main branch
                if current_branch == "main":
                    print("⚠️  WARNING: You are on the main branch")
                    print("   Consider creating a feature branch for changes")
                    print("")
                    
            except subprocess.CalledProcessError:
                # Not a git repo or other git error - continue silently
                pass
            except Exception:
                # Any other error - continue silently
                pass

        if __name__ == "__main__":
            main()
      '';
      "prompt_guard.py" = ''
        #!/usr/bin/env python3
        import sys
        import re

        # Basic prompt safety checks
        def main():
            # This is a placeholder for prompt safety validation
            # In a real implementation, this would check for potentially harmful prompts
            pass

        if __name__ == "__main__":
            main()
      '';
    } // (if builtins.elem "sparc-workflow" features then {
      "enforce_plan_mode.py" = ''
        #!/usr/bin/env python3
        import sys
        import os

        def main():
            # Check if .claude/tdd.red exists (indicating we should be in RED phase)
            if os.path.exists(".claude/tdd.red"):
                print("🔴 RED phase active - write failing tests first")
            elif os.path.exists(".claude/tdd.green"):
                print("🟢 GREEN phase active - implement minimal solution")
            elif os.path.exists(".claude/tdd.refactor"):
                print("🔵 REFACTOR phase active - improve without changing behavior")

        if __name__ == "__main__":
            main()
      '';
      "require_red_first.py" = ''
        #!/usr/bin/env python3
        import sys
        import os

        def main():
            # Enforce TDD red-green-refactor cycle
            # This is a placeholder for TDD enforcement logic
            pass

        if __name__ == "__main__":
            main()
      '';
      "verify_pr_state.py" = ''
        #!/usr/bin/env python3
        import subprocess
        import sys

        def main():
            try:
                # Check if there are any PRs for current branch
                result = subprocess.run(["gh", "pr", "status", "--json", "state"], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    print("📋 PR status checked")
            except Exception:
                # gh CLI not available or other error - continue silently
                pass

        if __name__ == "__main__":
            main()
      '';
    } else {});
}