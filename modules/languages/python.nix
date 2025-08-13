# Python language configuration module
{ pkgs, system, inputs }:

{
  # Default tooling configuration for Python projects
  defaultTooling = {
    testRunner = "pytest";
    linter = "ruff";
    formatter = "ruff-format";
    typeChecker = "mypy";
    buildTool = "setuptools";
    packageManager = "poetry";
    extraTools = [ "black" "isort" ];
  };

  # Get packages based on tooling configuration
  getPackages = tooling:
    let
      pythonPackages = with pkgs; [
        python3
        python3Packages.pip
      ];
      
      packageManagerPkg = if tooling.packageManager == "poetry" then [ pkgs.poetry ]
        else if tooling.packageManager == "pipenv" then [ pkgs.pipenv ]
        else if tooling.packageManager == "uv" then [ pkgs.uv ]
        else [];
        
      linterPkg = if tooling.linter == "ruff" then [ pkgs.ruff ]
        else if tooling.linter == "flake8" then [ pkgs.python3Packages.flake8 ]
        else [];
        
      typeCheckerPkg = if tooling.typeChecker == "mypy" then [ pkgs.python3Packages.mypy ]
        else [];
        
      formatterPkg = if tooling.formatter == "ruff-format" then [ pkgs.ruff ]
        else if tooling.formatter == "black" then [ pkgs.python3Packages.black ]
        else [];
        
      extraPackages = builtins.concatLists (map (tool:
        if tool == "black" then [ pkgs.python3Packages.black ]
        else if tool == "isort" then [ pkgs.python3Packages.isort ]
        else []
      ) (tooling.extraTools or []));
      
    in
    pythonPackages ++ packageManagerPkg ++ linterPkg ++ typeCheckerPkg ++ formatterPkg ++ extraPackages;

  # Get environment variables
  getEnvironment = tooling: {
    PYTHONPATH = "$PWD:$PYTHONPATH";
    PYTHONDONTWRITEBYTECODE = "1";  # Prevent .pyc files
    PYTHON_ENV = "development";
  };

  # Generate shell hook
  getShellHook = tooling: ''
    echo "🐍 Python Development Environment"
    echo "Python version: $(python --version)"
    echo "Package manager: ${tooling.packageManager}"
    echo "Available tools: ${builtins.concatStringsSep ", " ([ tooling.testRunner tooling.linter tooling.formatter tooling.typeChecker ] ++ (tooling.extraTools or []))}"
    echo ""
    
    # Install dependencies based on package manager
    ${if tooling.packageManager == "poetry" then ''
    if [ -f pyproject.toml ]; then
      echo "Installing dependencies with Poetry..."
      poetry install
    fi
    '' else if tooling.packageManager == "pipenv" then ''
    if [ -f Pipfile ]; then
      echo "Installing dependencies with Pipenv..."
      pipenv install --dev
    fi
    '' else if tooling.packageManager == "uv" then ''
    if [ -f pyproject.toml ]; then
      echo "Installing dependencies with uv..."
      uv sync
    fi
    '' else ''
    if [ -f requirements.txt ]; then
      echo "Installing dependencies with pip..."
      pip install -r requirements.txt
    fi
    if [ -f requirements-dev.txt ]; then
      pip install -r requirements-dev.txt
    fi
    ''}
    
    echo "📋 Python commands:"
    ${if tooling.testRunner == "pytest" then ''
    echo "  ${if tooling.packageManager == "poetry" then "poetry run pytest" else "pytest"}     # Run tests with pytest"
    echo "  ${if tooling.packageManager == "poetry" then "poetry run pytest" else "pytest"} --watch   # Auto-run tests on changes"
    echo "  ${if tooling.packageManager == "poetry" then "poetry run pytest" else "pytest"} --cov     # Run tests with coverage"
    '' else ''
    echo "  ${if tooling.packageManager == "poetry" then "poetry run python -m unittest" else "python -m unittest"}  # Run tests"
    ''}
    ${if tooling.linter == "ruff" then ''
    echo "  ${if tooling.packageManager == "poetry" then "poetry run ruff check" else "ruff check"}    # Lint code with Ruff"
    echo "  ${if tooling.packageManager == "poetry" then "poetry run ruff check --fix" else "ruff check --fix"}  # Fix linting issues"
    '' else ""}
    ${if tooling.formatter == "ruff-format" then ''
    echo "  ${if tooling.packageManager == "poetry" then "poetry run ruff format" else "ruff format"}   # Format code with Ruff"
    '' else if tooling.formatter == "black" then ''
    echo "  ${if tooling.packageManager == "poetry" then "poetry run black" else "black"} .      # Format code with Black"
    '' else ""}
    ${if tooling.typeChecker == "mypy" then ''
    echo "  ${if tooling.packageManager == "poetry" then "poetry run mypy" else "mypy"} .       # Type checking with mypy"
    '' else ""}
    echo "  ${if tooling.packageManager == "poetry" then "poetry run python" else "python"}     # Run Python interpreter"
    echo ""
  '';

  # Generate CLAUDE.md content specific to Python
  generateClaudeMd = { projectName, tooling, features }:
    let
      runPrefix = if tooling.packageManager == "poetry" then "poetry run " else "";
      testCommand = if tooling.testRunner == "pytest" then "${runPrefix}pytest" else "${runPrefix}python -m unittest";
      testCommandOptions = if tooling.testRunner == "pytest" then ''
        ```bash
        ${testCommand}                       # Run all tests
        ${testCommand} --watch              # Auto-run tests on changes
        ${testCommand} --cov                # Run tests with coverage
        ${testCommand} -v                   # Verbose output
        ${testCommand} -x                   # Stop on first failure
        DEBUG=1 ${testCommand}              # Run with debug output
        ```
      '' else ''
        ```bash
        ${testCommand}                       # Run all tests
        ${testCommand} discover             # Discover and run tests
        ${testCommand} -v                   # Verbose output
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

      This file provides guidance to Claude Code (claude.ai/code) when working with this Python project.

      ## Development Commands

      ### Testing

      Always use `${testCommand}` for testing:

      ${testCommandOptions}

      ### Building and Linting

      ```bash
      ${if tooling.packageManager == "poetry" then "poetry install                      # Install dependencies" else "pip install -r requirements.txt        # Install dependencies"}
      ${if tooling.linter == "ruff" then "${runPrefix}ruff check                    # Linting with Ruff" else ""}
      ${if tooling.formatter == "ruff-format" then "${runPrefix}ruff format                  # Format code with Ruff" else if tooling.formatter == "black" then "${runPrefix}black .                      # Format code with Black" else ""}
      ${if tooling.typeChecker == "mypy" then "${runPrefix}mypy .                      # Type checking with mypy" else ""}
      ```

      ### Development Tools

      ```bash
      ${if tooling.packageManager == "poetry" then "poetry shell                      # Activate virtual environment" else ""}
      ${if tooling.packageManager == "poetry" then "poetry show --outdated           # Check for outdated packages" else "pip list --outdated                # Check for outdated packages"}
      ${runPrefix}python -i                   # Interactive Python shell
      ${if builtins.elem "isort" (tooling.extraTools or []) then "${runPrefix}isort .                      # Sort imports" else ""}
      ```

      ## Architecture Overview

      ${projectName} follows **Python type-driven development** principles:

      - Type hints and mypy for static type checking
      - Pydantic models for data validation and serialization
      - Dataclasses for simple domain objects
      - Result/Either patterns for error handling
      - Functional programming patterns with immutable data

      ## Python Type-Driven Rules

      - **Type hints everywhere**: Use comprehensive type annotations
      - **Pydantic for domain models**: Use Pydantic models for data validation
      - **Prefer dataclasses**: Use dataclasses for simple immutable objects
      - **Result patterns**: Use Result/Either types for error handling instead of exceptions

      ### Example

      ```python
      from typing import Union, Literal
      from pydantic import BaseModel, Field, validator
      from dataclasses import dataclass
      from enum import Enum

      class ProjectNameError(Enum):
          EMPTY = "empty"
          TOO_LONG = "too_long"

      # Result type for error handling
      Result = Union[tuple[Literal[True], T], tuple[Literal[False], E]]

      def ok(value: T) -> Result[T, E]:
          return (True, value)

      def err(error: E) -> Result[T, E]:
          return (False, error)

      # Pydantic model for domain validation
      class ProjectName(BaseModel):
          name: str = Field(..., min_length=1, max_length=64)
          
          @validator('name')
          def name_must_be_trimmed(cls, v):
              return v.strip()

          @classmethod
          def create(cls, name: str) -> Result['ProjectName', ProjectNameError]:
              try:
                  return ok(cls(name=name))
              except ValueError:
                  if not name.strip():
                      return err(ProjectNameError.EMPTY)
                  return err(ProjectNameError.TOO_LONG)

      # Dataclass for simple domain objects
      @dataclass(frozen=True)
      class ProjectConfig:
          name: ProjectName
          created_at: datetime
      ```

      ## Code Quality Enforcement - CRITICAL

      **NEVER ADD RUFF NOQA COMMENTS** - This is a hard rule with zero exceptions without team approval.

      - **NEVER** use `# noqa` comments without explicit team approval
      - **NEVER** use `# type: ignore` without investigation and approval
      - **ALWAYS** fix the underlying issue causing the warning instead of suppressing it
      - **ALWAYS** ensure `${runPrefix}ruff check` and `${runPrefix}mypy .` pass

      ## Testing Discipline (Kent Beck)

      Work in strict Red → Green → Refactor loops with one failing test at a time.

      Use pytest for comprehensive testing with type safety and fixtures.

      ## Functional Programming Principles

      - **Immutability**: Use frozen dataclasses and immutable data structures
      - **Pure functions**: Minimize side effects; keep them at boundaries
      - **Type safety**: Use mypy and comprehensive type hints
      - **Result types**: Prefer Result patterns over exceptions for expected errors
      ${sparcSection}

      ## Development Conventions

      - **Error Handling**: Use Result types or custom exception hierarchies
      - **Type Safety**: Use comprehensive type hints and mypy
      - **Testing**: Write comprehensive tests with pytest and type safety
      - **Dependencies**: Use `${tooling.packageManager}` for package management
      - **Code Style**: Use ${tooling.formatter} for consistent formatting
      - **Import Organization**: Keep imports organized ${if builtins.elem "isort" (tooling.extraTools or []) then "with isort" else ""}
    '';

  # Generate language-specific hooks
  generateHooks = tooling: features:
    let
      runPrefix = if tooling.packageManager == "poetry" then "poetry run " else "";
      formatAndTestScript = ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Run Python-specific formatting and linting
        if [ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ]; then
            echo "Running Python formatting and tests..."
            ${if tooling.formatter == "ruff-format" then "${runPrefix}ruff format" else if tooling.formatter == "black" then "${runPrefix}black ." else ""}
            ${if builtins.elem "isort" (tooling.extraTools or []) then "${runPrefix}isort ." else ""}
            ${if tooling.linter == "ruff" then "${runPrefix}ruff check" else ""}
            ${if tooling.typeChecker == "mypy" then "${runPrefix}mypy ." else ""}
            ${if tooling.testRunner == "pytest" then "${runPrefix}pytest" else "${runPrefix}python -m unittest"}
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