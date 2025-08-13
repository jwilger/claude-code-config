# TypeScript/Node.js language configuration module
{ pkgs, system, inputs }:

{
  # Default tooling configuration for TypeScript projects
  defaultTooling = {
    testRunner = "vitest";
    linter = "eslint";
    formatter = "prettier";
    typeChecker = "tsc";
    buildTool = "tsc";
    packageManager = "pnpm";
    extraTools = [ "tsx" "nodemon" ];
  };

  # Get packages based on tooling configuration
  getPackages = tooling:
    let
      nodePackages = with pkgs; [
        nodejs
        typescript
      ];
      
      packageManagerPkg = if tooling.packageManager == "pnpm" then [ pkgs.nodePackages.pnpm ]
        else if tooling.packageManager == "yarn" then [ pkgs.yarn ]
        else [ pkgs.nodejs ]; # npm comes with nodejs
        
      linterPkg = if tooling.linter == "eslint" then [ pkgs.nodePackages.eslint ]
        else [];
        
      formatterPkg = if tooling.formatter == "prettier" then [ pkgs.nodePackages.prettier ]
        else [];
        
      extraPackages = builtins.concatLists (map (tool:
        if tool == "nodemon" then [ pkgs.nodePackages.nodemon ]
        else if tool == "ts-node" then [ pkgs.nodePackages.ts-node ]
        else []
      ) (tooling.extraTools or []));
      
    in
    nodePackages ++ packageManagerPkg ++ linterPkg ++ formatterPkg ++ extraPackages;

  # Get environment variables
  getEnvironment = tooling: {
    NODE_ENV = "development";
    # Enable TypeScript strict mode by default
    TS_NODE_COMPILER_OPTIONS = ''{"strict": true}'';
  };

  # Generate shell hook
  getShellHook = tooling: ''
    echo "📘 TypeScript Development Environment"
    echo "Node.js version: $(node --version)"
    echo "TypeScript version: $(tsc --version)"
    echo "Package manager: ${tooling.packageManager}"
    echo "Available tools: ${builtins.concatStringsSep ", " ([ tooling.testRunner tooling.linter tooling.formatter tooling.typeChecker ] ++ (tooling.extraTools or []))}"
    echo ""
    
    # Install dependencies if package.json exists
    if [ -f package.json ]; then
      echo "Installing dependencies with ${tooling.packageManager}..."
      ${if tooling.packageManager == "pnpm" then "pnpm install"
        else if tooling.packageManager == "yarn" then "yarn install"
        else "npm install"}
    fi
    
    echo "📋 TypeScript commands:"
    ${if tooling.testRunner == "vitest" then ''
    echo "  ${tooling.packageManager} test        # Run tests with Vitest"
    echo "  ${tooling.packageManager} test --watch # Auto-run tests on changes"
    '' else if tooling.testRunner == "jest" then ''
    echo "  ${tooling.packageManager} test        # Run tests with Jest"
    echo "  ${tooling.packageManager} test --watch # Auto-run tests on changes"
    '' else ''
    echo "  ${tooling.packageManager} test        # Run tests"
    ''}
    ${if tooling.linter == "eslint" then ''
    echo "  ${tooling.packageManager} lint        # Lint code with ESLint"
    echo "  ${tooling.packageManager} lint --fix  # Fix linting issues"
    '' else ""}
    ${if tooling.formatter == "prettier" then ''
    echo "  ${tooling.packageManager} format      # Format code with Prettier"
    echo "  ${tooling.packageManager} format:check # Check formatting"
    '' else ""}
    ${if tooling.typeChecker == "tsc" then ''
    echo "  ${tooling.packageManager} type-check  # Type checking with tsc"
    '' else ""}
    echo "  ${tooling.packageManager} build       # Build project"
    echo "  ${tooling.packageManager} dev         # Start development server"
    ${if builtins.elem "tsx" (tooling.extraTools or []) then ''
    echo "  tsx src/index.ts       # Run TypeScript directly"
    '' else ""}
    echo ""
  '';

  # Generate CLAUDE.md content specific to TypeScript
  generateClaudeMd = { projectName, tooling, features }:
    let
      testCommand = if tooling.testRunner == "vitest" then "${tooling.packageManager} test" 
                   else if tooling.testRunner == "jest" then "${tooling.packageManager} test"
                   else "${tooling.packageManager} test";
      testCommandOptions = if tooling.testRunner == "vitest" then ''
        ```bash
        ${tooling.packageManager} test                    # Run all tests
        ${tooling.packageManager} test --watch           # Auto-run tests on changes
        ${tooling.packageManager} test --coverage        # Run tests with coverage
        ${tooling.packageManager} test --ui              # Run tests with UI
        DEBUG=1 ${tooling.packageManager} test           # Run with debug output
        ```
      '' else if tooling.testRunner == "jest" then ''
        ```bash
        ${tooling.packageManager} test                    # Run all tests
        ${tooling.packageManager} test --watch           # Auto-run tests on changes
        ${tooling.packageManager} test --coverage        # Run tests with coverage
        ${tooling.packageManager} test --watchAll        # Watch all files
        DEBUG=1 ${tooling.packageManager} test           # Run with debug output
        ```
      '' else ''
        ```bash
        ${tooling.packageManager} test                    # Run all tests
        ${tooling.packageManager} test --watch           # Auto-run tests on changes
        ```
      '';
      
      sparcSection = if builtins.elem "sparc-workflow" features then ''

        ## SPARC Workflow Integration

        This project uses the SPARC (Study, Plan, Architect, Review, Code) workflow with GitHub pull requests.
        See the main CLAUDE.md documentation for full SPARC workflow details.
      '' else "";
      
    in
    ''
      # CLAUDE.md

      This file provides guidance to Claude Code (claude.ai/code) when working with this TypeScript project.

      ## Development Commands

      ### Testing

      Always use `${testCommand}` for testing:

      ${testCommandOptions}

      ### Building and Linting

      ```bash
      ${tooling.packageManager} build                     # Build the project
      ${tooling.packageManager} dev                       # Development server
      ${tooling.packageManager} type-check               # TypeScript type checking
      ${if tooling.linter == "eslint" then "${tooling.packageManager} lint                       # Linting with ESLint" else ""}
      ${if tooling.formatter == "prettier" then "${tooling.packageManager} format                     # Format code with Prettier" else ""}
      ```

      ### Development Tools

      ```bash
      ${tooling.packageManager} install                  # Install dependencies
      ${tooling.packageManager} outdated                # Check for outdated packages
      ${if builtins.elem "tsx" (tooling.extraTools or []) then "tsx src/index.ts                    # Run TypeScript directly" else ""}
      ${if builtins.elem "nodemon" (tooling.extraTools or []) then "nodemon --exec tsx src/index.ts      # Auto-restart on changes" else ""}
      ```

      ## Architecture Overview

      ${projectName} follows **TypeScript type-driven development** principles:

      - Strict TypeScript configuration for compile-time safety
      - Branded types for domain modeling
      - Functional programming patterns with immutable data
      - Result/Either types for error handling
      - Comprehensive type definitions with utility types

      ## TypeScript Type-Driven Rules

      - **Strict TypeScript config**: Enable all strict mode options
      - **Branded types for domain modeling**: Use branded types instead of primitives
      - **Prefer `Result<T, E>` types** over throwing exceptions for expected errors
      - **Immutable data structures**: Use readonly types and immutable patterns

      ### Example

      ```typescript
      // Branded type for domain modeling
      declare const ProjectNameBrand: unique symbol;
      type ProjectName = string & { readonly [ProjectNameBrand]: typeof ProjectNameBrand };

      // Smart constructor with validation
      function createProjectName(value: string): Result<ProjectName, ValidationError> {
        const trimmed = value.trim();
        if (trimmed.length === 0) {
          return err(new ValidationError("Project name cannot be empty"));
        }
        if (trimmed.length > 64) {
          return err(new ValidationError("Project name cannot exceed 64 characters"));
        }
        return ok(trimmed as ProjectName);
      }

      // Result type for error handling
      type Result<T, E> = 
        | { readonly success: true; readonly data: T }
        | { readonly success: false; readonly error: E };

      const ok = <T>(data: T): Result<T, never> => ({ success: true, data });
      const err = <E>(error: E): Result<never, E> => ({ success: false, error });
      ```

      ## Code Quality Enforcement - CRITICAL

      **NEVER ADD ESLINT DISABLE COMMENTS** - This is a hard rule with zero exceptions without team approval.

      - **NEVER** use `// eslint-disable` comments without explicit team approval
      - **NEVER** bypass TypeScript strict checks with `any` or `@ts-ignore`
      - **ALWAYS** fix the underlying issue causing the warning instead of suppressing it
      - **ALWAYS** ensure `${tooling.packageManager} lint` and `${tooling.packageManager} type-check` pass

      ## Testing Discipline (Kent Beck)

      Work in strict Red → Green → Refactor loops with one failing test at a time.

      Use ${tooling.testRunner} for comprehensive testing with type safety.

      ## Functional Programming Principles

      - **Immutability**: Use readonly types and avoid mutation
      - **Pure functions**: Minimize side effects; keep them at boundaries
      - **Function composition**: Use pipe operators and function composition
      - **Result types**: Prefer Result/Either types over exceptions
      ${sparcSection}

      ## Development Conventions

      - **Error Handling**: Use Result types with comprehensive error information
      - **Type Safety**: Enable strict TypeScript configuration
      - **Testing**: Write comprehensive tests with type safety
      - **Dependencies**: Use `${tooling.packageManager}` for package management
      - **Code Style**: Use ${tooling.formatter} for consistent formatting
    '';

  # Generate language-specific hooks
  generateHooks = tooling: features:
    let
      formatAndTestScript = ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Run TypeScript-specific formatting and linting
        if [ -f package.json ]; then
            echo "Running TypeScript formatting and tests..."
            ${if tooling.formatter == "prettier" then "${tooling.packageManager} run format:check" else ""}
            ${if tooling.linter == "eslint" then "${tooling.packageManager} run lint" else ""}
            ${if tooling.typeChecker == "tsc" then "${tooling.packageManager} run type-check" else ""}
            ${tooling.packageManager} test
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
            # Check TDD phase indicators
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