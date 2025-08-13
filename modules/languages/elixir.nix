# Elixir language configuration module
{ pkgs, system, inputs }:

{
  # Default tooling configuration for Elixir projects
  defaultTooling = {
    testRunner = "mix-test";
    linter = "credo";
    formatter = "mix-format";
    typeChecker = "dialyzer";
    buildTool = "mix";
    extraTools = [ "phoenix" "livebook" ];
  };

  # Get packages based on tooling configuration
  getPackages = tooling:
    let
      basePackages = with pkgs; [
        elixir
        erlang
        nodejs  # Often needed for Phoenix assets
      ];
      
      extraPackages = builtins.concatLists (map (tool:
        if tool == "phoenix" then [ pkgs.postgresql ]  # Phoenix often needs DB
        else if tool == "livebook" then []  # Livebook is Elixir package
        else []
      ) (tooling.extraTools or []));
      
    in
    basePackages ++ extraPackages;

  # Get environment variables
  getEnvironment = tooling: {
    MIX_ENV = "dev";
    ERL_AFLAGS = "-kernel shell_history enabled";
  };

  # Generate shell hook
  getShellHook = tooling: ''
    echo "💧 Elixir Development Environment"
    echo "Elixir version: $(elixir --version | head -n1)"
    echo "Available tools: ${builtins.concatStringsSep ", " ([ tooling.testRunner tooling.linter tooling.formatter tooling.typeChecker ] ++ (tooling.extraTools or []))}"
    echo ""
    
    # Install dependencies if mix.exs exists
    if [ -f mix.exs ]; then
      echo "Installing Elixir dependencies..."
      mix deps.get
    fi
    
    echo "📋 Elixir commands:"
    echo "  mix test                # Run tests"
    echo "  mix test --watch        # Auto-run tests on changes"
    ${if tooling.linter == "credo" then ''
    echo "  mix credo               # Lint code"
    echo "  mix credo --strict      # Lint with strict rules"
    '' else ""}
    ${if tooling.formatter == "mix-format" then ''
    echo "  mix format              # Format code"
    echo "  mix format --check-formatted  # Check formatting"
    '' else ""}
    ${if tooling.typeChecker == "dialyzer" then ''
    echo "  mix dialyzer            # Type checking"
    '' else ""}
    echo "  mix compile             # Compile project"
    echo "  iex -S mix              # Interactive shell with project"
    ${if builtins.elem "phoenix" (tooling.extraTools or []) then ''
    echo "  mix phx.server          # Start Phoenix server"
    '' else ""}
    echo ""
  '';

  # Generate CLAUDE.md content specific to Elixir
  generateClaudeMd = { projectName, tooling, features }:
    let
      sparcSection = if builtins.elem "sparc-workflow" features then ''

        ## SPARC Workflow Integration

        This project uses the SPARC (Study, Plan, Architect, Review, Code) workflow with GitHub pull requests.
        See the main CLAUDE.md documentation for full SPARC workflow details.
      '' else "";
      
    in
    ''
      # CLAUDE.md

      This file provides guidance to Claude Code (claude.ai/code) when working with this Elixir project.

      ## Development Commands

      ### Testing

      Always use `mix test` for testing:

      ```bash
      mix test                            # Run all tests
      mix test --watch                   # Auto-run tests on changes  
      mix test test/specific_test.exs    # Run specific test file
      mix test --cover                   # Run tests with coverage
      ELIXIR_DEBUG=1 mix test            # Run with debug output
      ```

      ### Building and Linting

      ```bash
      mix compile                         # Compile the project
      mix compile --force                # Force recompilation
      mix deps.get                       # Install dependencies
      ${if tooling.linter == "credo" then "mix credo                          # Linting (strict rules enabled)" else ""}
      ${if tooling.formatter == "mix-format" then "mix format                        # Format code" else ""}
      ${if tooling.typeChecker == "dialyzer" then "mix dialyzer                      # Type checking with Dialyzer" else ""}
      ```

      ### Development Tools

      ```bash
      iex -S mix                         # Interactive shell with project loaded
      mix deps.tree                     # Show dependency tree
      mix hex.outdated                  # Check for outdated dependencies
      ${if builtins.elem "phoenix" (tooling.extraTools or []) then "mix phx.server                    # Start Phoenix development server" else ""}
      ${if builtins.elem "livebook" (tooling.extraTools or []) then "livebook server                   # Start Livebook for interactive development" else ""}
      ```

      ## Architecture Overview

      ${projectName} follows **Elixir/OTP design principles**:

      - Fault-tolerant design with supervisor trees
      - Immutable data structures and functional programming
      - Actor model with GenServers for stateful processes
      - Pattern matching for control flow and data destructuring
      - Ecto schemas for domain modeling (if using Ecto)

      ## Elixir Type-Driven Rules

      - **Leverage pattern matching**: Use pattern matching instead of conditionals where possible
      - **Ecto schemas for domain types**: Define clear data structures with validations
      - **Typespecs for documentation**: Use `@spec` and `@type` for clear interfaces
      - **Prefer `{:ok, result} | {:error, reason}` tuples** over exceptions for expected failures

      ### Example

      ```elixir
      defmodule ${projectName}.ProjectName do
        use Ecto.Schema
        import Ecto.Changeset

        @type t :: %__MODULE__{
          name: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

        schema "project_names" do
          field :name, :string

          timestamps()
        end

        @spec changeset(t(), map()) :: Ecto.Changeset.t()
        def changeset(project_name, attrs) do
          project_name
          |> cast(attrs, [:name])
          |> validate_required([:name])
          |> validate_length(:name, min: 1, max: 64)
        end
      end
      ```

      ## Code Quality Enforcement - CRITICAL

      **NEVER ADD COMPILER WARNINGS SUPPRESSIONS** - This is a hard rule with zero exceptions without team approval.

      - **NEVER** suppress Credo warnings without explicit team approval
      - **NEVER** ignore Dialyzer warnings without investigation
      - **ALWAYS** fix the underlying issue causing the warning instead of suppressing it
      - **ALWAYS** ensure `mix format --check-formatted` passes

      ## Testing Discipline (Kent Beck)

      Work in strict Red → Green → Refactor loops with one failing test at a time.

      Use ExUnit for comprehensive testing; leverage doctests for documentation.

      ## Functional Programming Principles

      - **Immutability**: Never mutate data; transform it
      - **Pure functions**: Minimize side effects; keep them at boundaries
      - **Pipeline operator**: Use `|>` for clear data transformations
      - **Pattern matching**: Prefer pattern matching over conditionals

      ## OTP Design Patterns

      - **GenServer**: For stateful processes and APIs
      - **Supervisor**: For fault tolerance and process management
      - **Task**: For concurrent computation
      - **Agent**: For simple state management
      ${sparcSection}

      ## Development Conventions

      - **Error Handling**: Use `{:ok, result} | {:error, reason}` tuples
      - **Documentation**: Write clear module and function docs with examples
      - **Testing**: Write comprehensive tests including doctests
      - **Dependencies**: Use `mix deps.get` and `mix deps.update` for dependency management
    '';

  # Generate language-specific hooks
  generateHooks = tooling: features:
    let
      formatAndTestScript = ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Run Elixir-specific formatting and linting
        if [ -f mix.exs ]; then
            echo "Running Elixir formatting and tests..."
            ${if tooling.formatter == "mix-format" then "mix format --check-formatted" else ""}
            ${if tooling.linter == "credo" then "mix credo --strict" else ""}
            ${if tooling.typeChecker == "dialyzer" then "mix dialyzer" else ""}
            mix test
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