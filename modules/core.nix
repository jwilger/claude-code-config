# Core configuration generation for Claude Code
{ pkgs, system }:

let
  # Import language configuration from config module (breaks circular dependency)
  configModule = import ./config.nix { inherit pkgs system; };
  languageConfig = configModule.languageConfig;

  # FUNCTIONAL CORE: Common template sections (pure data)
  commonSections = {
    header = projectName: ''
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
'';

    sparcWorkflow = ''
## SPARC Workflow Integration

This project uses the SPARC (Study, Plan, Architect, Review, Code) workflow with GitHub pull requests:

### Story Development Flow

1. **Story Selection**: Choose from PLANNING.md
2. **Branch Creation**: \`story-{id}-{slug}\` feature branches  
3. **Standard SPARC**: Research → Plan → Implement → Expert (with mandatory memory storage)
4. **PR Creation**: Draft PRs with comprehensive descriptions
5. **Review Loop**: Address feedback with Claude Code attribution
6. **Human Merge**: Only humans mark PRs ready-for-review

### MANDATORY Memory Storage (CRITICAL)

**Every SPARC phase MUST store knowledge in MCP memory for systematic improvement.**

### Commands & Agents

Primary commands:
- \`/sparc\` - Full story workflow with PR integration
- \`/sparc/pr\` - Create draft PR for completed story
- \`/sparc/review\` - Respond to PR feedback
- \`/sparc/status\` - Check branch/PR/story status

Subagents: researcher, planner, implementer, type-architect, test-hardener, expert, pr-manager.
'';
  };

  # FUNCTIONAL CORE: Language-specific template sections
  languageSpecificSections = {
    rust = {
      testing = ''
### Testing

Always use \`cargo test\` for testing:

\`\`\`bash
cargo test                          # Run all tests
cargo test --lib                   # Unit tests only
cargo test --tests                 # Integration tests only
RUST_BACKTRACE=1 cargo test        # With backtrace on failure
\`\`\`
'';
      building = ''
### Building and Linting

\`\`\`bash
cargo build                          # Build the project
cargo build --release              # Release build
cargo check                         # Fast syntax/type checking
cargo clippy                        # Linting (strict rules enabled)
cargo fmt                          # Format code
\`\`\`
'';
      architecture = projectName: ''
## Architecture Overview

'''${projectName}''' follows **type-driven development** principles:

- Illegal states are unrepresentable through the type system
- Phantom types for state transitions where applicable
- Smart constructors with validation
- Comprehensive error types with domain-specific variants
- nutype crate for eliminating primitive obsession
'';
      rules = ''
## Rust Type-Driven Rules

- **Illegal states are unrepresentable**: prefer domain types over primitives.
- All new domain types use \`nutype\` with \`sanitize(...)\` and \`validate(...)\`. Derive at least: \`Clone, Debug, Eq, PartialEq, Display\`; add \`Serialize, Deserialize\` where needed.
- Prefer \`Result<T, DomainError>\` over panics. Panics only for truly unreachable states.

### Example

\`\`\`rust
#[nutype(
  sanitize(trim),
  validate(len(min = 1, max = 64)),
  derive(Clone, Debug, Eq, PartialEq, Display)
)]
pub struct ProjectName(String);
\`\`\`

## Code Quality Enforcement - CRITICAL

**NEVER ADD ALLOW ATTRIBUTES** - This is a hard rule with zero exceptions without team approval.

- **NEVER** use \`#![allow(clippy::...)]\` or \`#[allow(clippy::...)]\` without explicit team approval
- **NEVER** bypass pre-commit hooks or ignore clippy warnings/errors
- **ALWAYS** fix the underlying issue causing the warning instead of suppressing it
- Pre-commit hooks MUST pass with \`-D warnings\` (treat warnings as errors)

## Testing Discipline (Kent Beck)

Work in strict Red → Green → Refactor loops with one failing test at a time.

Use MCP cargo server for all tests; treat clippy warnings as errors.

## Functional Core / Imperative Shell

Put pure logic in the core (no I/O, no mutation beyond local scope).

Keep an imperative shell for I/O; inject dependencies via traits.

Model workflows as Result pipelines (railway style).
'';
      conventions = ''
## Development Conventions

- **Error Handling**: Use comprehensive Result types with domain errors
- **Resource Safety**: Always validate resource limits before allocation
- **State Machines**: Use phantom types for compile-time state validation
- **Testing**: Write property-based tests for validation logic
- **Dependency Management**: Always use package manager CLI tools (\`cargo add\`, \`cargo remove\`) to install/update dependencies. Never manually edit Cargo.toml version numbers.
'';
    };

    elixir = {
      testing = ''
### Testing

Always use \`mix test\` for testing:

\`\`\`bash
mix test                           # Run all tests
mix test --stale                   # Run only stale tests
mix test --failed                  # Run only failed tests
mix test test/specific_test.exs    # Run specific test file
\`\`\`
'';
      building = ''
### Building and Linting

\`\`\`bash
mix compile                        # Compile the project
mix compile --warnings-as-errors   # Compile with strict warnings
mix credo                          # Linting with Credo
mix format                         # Format code
mix dialyzer                       # Static analysis
\`\`\`
'';
      architecture = projectName: ''
## Architecture Overview

'''${projectName}''' follows **functional programming** principles with Elixir:

- Immutable data structures
- Pattern matching for control flow
- Actor model with GenServer/GenStateMachine
- Supervision trees for fault tolerance
- Pipeline operators for data transformation
'';
      rules = ''
## Elixir Development Rules

- **Let it crash**: Use supervisor trees instead of defensive programming
- **Pattern match early**: Use function heads and case statements
- **Keep functions small**: Single responsibility principle
- **Use pipes**: Chain operations with |> operator
- **Avoid shared state**: Use message passing between processes
'';
      conventions = ''
## Development Conventions

- **Error Handling**: Use {:ok, result} | {:error, reason} tuples
- **Process Design**: Each GenServer should have a single clear responsibility
- **Testing**: Use ExUnit with property-based testing where appropriate
- **Dependencies**: Use \`mix deps.get\` and manage via mix.exs
'';
    };
    
    typescript = {
      testing = ''
### Testing

Always use \`npm test\` for testing:

\`\`\`bash
npm test                           # Run all tests
npm run test:watch                 # Watch mode
npm run test:coverage              # Coverage report
\`\`\`
'';
      building = ''
### Building and Linting

\`\`\`bash
npm run build                      # Build the project
npm run lint                       # ESLint checking
npm run format                     # Prettier formatting
npm run type-check                 # TypeScript checking
\`\`\`
'';
      architecture = projectName: ''
## Architecture Overview

'''${projectName}''' follows **modern JavaScript/TypeScript** patterns:

- Functional programming with immutable data
- Strong typing with TypeScript
- Async/await for asynchronous operations
- Result types for error handling
- Modular architecture with clear boundaries
'';
      rules = ''
## TypeScript Development Rules

- **Strict types**: Use strict TypeScript settings
- **No any**: Avoid any type, use unknown instead
- **Result types**: Use Result<T, E> pattern for error handling
- **Immutability**: Prefer readonly and const assertions
- **Functional style**: Use map, filter, reduce over loops
'';
      conventions = ''
## Development Conventions

- **Error Handling**: Use Result types or proper Error subclasses
- **Async**: Use async/await with proper error handling
- **Testing**: Use Jest/Vitest with comprehensive test coverage
- **Dependencies**: Use package manager CLI (npm/pnpm/yarn) for dependency management
'';
    };
    
    javascript = {
      testing = ''
### Testing

Always use \`npm test\` for testing:

\`\`\`bash
npm test                           # Run all tests
npm run test:watch                 # Watch mode
npm run test:coverage              # Coverage report
\`\`\`
'';
      building = ''
### Building and Linting

\`\`\`bash
npm run build                      # Build the project
npm run lint                       # ESLint checking
npm run format                     # Prettier formatting
\`\`\`
'';
      architecture = projectName: ''
## Architecture Overview

'''${projectName}''' follows **modern JavaScript** patterns:

- Functional programming with immutable data
- Async/await for asynchronous operations
- Result types for error handling
- Modular architecture with clear boundaries
'';
      rules = ''
## JavaScript Development Rules

- **Strict mode**: Always use strict mode
- **Immutability**: Prefer const and avoid mutations
- **Result types**: Use Result<T, E> pattern for error handling
- **Functional style**: Use map, filter, reduce over loops
'';
      conventions = ''
## Development Conventions

- **Error Handling**: Use Result types or proper Error subclasses
- **Async**: Use async/await with proper error handling
- **Testing**: Use Jest/Vitest with comprehensive test coverage
- **Dependencies**: Use package manager CLI (npm/pnpm/yarn) for dependency management
'';
    };
    
    python = {
      testing = ''
### Testing

Always use \`pytest\` for testing:

\`\`\`bash
pytest                             # Run all tests
pytest -v                          # Verbose output
pytest --cov                       # Coverage report
pytest -k "pattern"                # Run tests matching pattern
\`\`\`
'';
      building = ''
### Building and Linting

\`\`\`bash
ruff check                         # Linting with Ruff
ruff format                        # Formatting with Ruff
mypy .                            # Type checking with MyPy
\`\`\`
'';
      architecture = projectName: ''
## Architecture Overview

'''${projectName}''' follows **modern Python** development patterns:

- Type hints throughout
- Functional programming where appropriate
- Domain-driven design with value objects
- Result types for error handling
- Dependency injection for testability
'';
      rules = ''
## Python Development Rules

- **Type hints**: All functions and classes should have type annotations
- **Immutable data**: Use dataclasses with frozen=True or Pydantic models
- **Error handling**: Use Result types or custom exception hierarchies
- **Testing**: Use pytest with high coverage requirements
- **Code style**: Follow Ruff formatting and linting rules
'';
      conventions = ''
## Development Conventions

- **Error Handling**: Use Result types from returns library or custom implementations
- **Data Classes**: Use Pydantic for data validation and serialization
- **Testing**: Use pytest with fixtures and parametrized tests
- **Dependencies**: Use pip-tools or poetry for dependency management
'';
    };
  };

  # FUNCTIONAL CORE: Generate complete CLAUDE.md content (pure function)
  generateClaudeMdContent = language: projectName:
    let
      langSections = languageSpecificSections.${language};
    in
    (commonSections.header projectName) +
    "\n## Development Commands\n\n" +
    (langSections.testing) +
    (langSections.building) +
    (langSections.architecture projectName) +
    (langSections.rules) +
    (commonSections.sparcWorkflow) +
    (langSections.conventions);

  # FUNCTIONAL CORE: Language-specific hook generation data
  hookScripts = {
    rust = ''
#!/usr/bin/env bash
set -euo pipefail

# Run Rust-specific formatting and linting
if [ -f Cargo.toml ]; then
    echo "Running Rust formatting and tests..."
    cargo fmt
    cargo clippy -- -D warnings
    cargo test
elif [ -f .git/hooks/pre-commit ]; then
    ./.git/hooks/pre-commit
fi
'';
    elixir = ''
#!/usr/bin/env bash
set -euo pipefail

# Run Elixir-specific formatting and testing
if [ -f mix.exs ]; then
    echo "Running Elixir formatting and tests..."
    mix format
    mix credo --strict
    mix test
elif [ -f .git/hooks/pre-commit ]; then
    ./.git/hooks/pre-commit
fi
'';
    typescript = ''
#!/usr/bin/env bash
set -euo pipefail

# Run Node.js-specific formatting and testing
if [ -f package.json ]; then
    echo "Running Node.js formatting and tests..."
    npm run format || true
    npm run lint
    npm test
elif [ -f .git/hooks/pre-commit ]; then
    ./.git/hooks/pre-commit
fi
'';
    javascript = ''
#!/usr/bin/env bash
set -euo pipefail

# Run Node.js-specific formatting and testing
if [ -f package.json ]; then
    echo "Running Node.js formatting and tests..."
    npm run format || true
    npm run lint
    npm test
elif [ -f .git/hooks/pre-commit ]; then
    ./.git/hooks/pre-commit
fi
'';
    python = ''
#!/usr/bin/env bash
set -euo pipefail

# Run Python-specific formatting and testing
if [ -f pyproject.toml ] || [ -f setup.py ]; then
    echo "Running Python formatting and tests..."
    ruff format .
    ruff check .
    pytest
elif [ -f .git/hooks/pre-commit ]; then
    ./.git/hooks/pre-commit
fi
'';
  };

in
{
  # IMPERATIVE SHELL: Generate CLAUDE.md content with I/O
  generateClaudeConfig = pkgs.writeShellScriptBin "generate-claude-config" ''
    language="$1"
    project_name="$2"
    
    # Validate language
    supported_languages="${builtins.concatStringsSep "|" (builtins.attrNames languageConfig)}"
    if [[ ! "$language" =~ ^($supported_languages)$ ]]; then
      echo "❌ Unsupported language: $language"
      echo "Supported: ${builtins.concatStringsSep ", " (builtins.attrNames languageConfig)}"
      exit 1
    fi
    
    # Generate CLAUDE.md using functional core
    ${builtins.concatStringsSep "\n" (
      builtins.map (lang: ''
        if [[ "$language" == "${lang}" ]]; then
          cat > .claude/CLAUDE.md << 'EOF'
${generateClaudeMdContent lang "$project_name"}EOF
        fi
      '') (builtins.attrNames languageConfig)
    )}
    
    echo "Generated .claude/CLAUDE.md for $language project: $project_name"
  '';

  # IMPERATIVE SHELL: Generate git hooks with I/O
  generateHooks = pkgs.writeShellScriptBin "generate-hooks" ''
    language="$1"
    
    # Validate language
    supported_languages="${builtins.concatStringsSep "|" (builtins.attrNames languageConfig)}"
    if [[ ! "$language" =~ ^($supported_languages)$ ]]; then
      echo "❌ Unsupported language: $language"
      echo "Supported: ${builtins.concatStringsSep ", " (builtins.attrNames languageConfig)}"
      exit 1
    fi
    
    # Generate language-specific hook using functional core
    ${builtins.concatStringsSep "\n" (
      builtins.map (lang: ''
        if [[ "$language" == "${lang}" ]]; then
          cat > .claude/hooks/format_and_test.sh << 'EOF'
${hookScripts.${lang}}EOF
        fi
      '') (builtins.attrNames languageConfig)
    )}
    
    chmod +x .claude/hooks/format_and_test.sh
    
    # Common hooks for all languages
    cp ${../..}/.claude/hooks/check_branch_status.py .claude/hooks/
    cp ${../..}/.claude/hooks/prevent_no_verify.py .claude/hooks/
    
    chmod +x .claude/hooks/*.py
    
    echo "Generated language-specific hooks for $language"
  '';
}