# Claude Config - Multi-Language Configuration Package

A comprehensive Nix flake that provides Claude Code configuration for multiple programming languages with SPARC workflow integration.

## Features

- **Multi-Language Support**: Rust, TypeScript/Node.js, Python, Elixir
- **SPARC Workflow**: Complete Study-Plan-Architect-Review-Code methodology  
- **Kent Beck TDD**: Strict Red-Green-Refactor discipline with specialized agents
- **Type-Driven Development**: Domain types that make illegal states unrepresentable
- **Quality Enforcement**: Zero-tolerance code quality with comprehensive linting
- **MCP Integration**: Memory storage for continuous learning and improvement
- **GitHub PR Workflow**: Professional draft PR creation with comprehensive documentation

## Quick Start

### Using as a Flake Input

Add to your project's `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-config.url = "github:your-org/claude-config";
  };

  outputs = { self, nixpkgs, claude-config }:
    let
      system = "x86_64-linux";  # or your system
    in {
      devShells.${system}.default = claude-config.lib.${system}.mkDevShell {
        language = "rust";  # or "typescript", "python", "elixir"
        projectName = "my-awesome-project";
        tooling = {
          testRunner = "nextest";
          linter = "clippy";
          formatter = "rustfmt";
        };
        features = [ "sparc-workflow" "memory-storage" "git-safety" ];
      };
    };
}
```

### Using Templates

Create a new project from template:

```bash
nix flake init --template github:your-org/claude-config#rust
# or typescript, python, elixir
```

## Language Support

### Rust
- **Tools**: cargo, clippy, rustfmt, nextest
- **Types**: nutype for domain types, Result for error handling
- **Testing**: Property-based testing with proptest
- **Architecture**: Functional core / Imperative shell

### TypeScript/Node.js  
- **Tools**: npm/pnpm, ESLint, Prettier, TypeScript compiler
- **Types**: Branded types for domain safety
- **Testing**: Jest, Vitest, or project-specific frameworks
- **Architecture**: Functional programming with immutability

### Python
- **Tools**: poetry/pip, ruff, mypy, pytest
- **Types**: Pydantic models, comprehensive type hints
- **Testing**: pytest with property-based testing
- **Architecture**: Clean architecture with dependency injection

### Elixir
- **Tools**: mix, credo, dialyzer, ExUnit
- **Types**: Custom types with pattern matching
- **Testing**: ExUnit with property-based testing
- **Architecture**: OTP patterns with supervision trees

## SPARC Workflow

The SPARC methodology provides systematic development:

1. **Study**: Research domain and technical requirements
2. **Plan**: Create implementation strategy with TDD approach
3. **Architect**: Design types and APIs that prevent errors
4. **Review**: Expert quality assessment and validation
5. **Code**: Kent Beck Red-Green-Refactor implementation

### Available Commands

- `/sparc` - Complete workflow with PR integration
- `/sparc/pr` - Create draft PR for completed story
- `/sparc/review` - Respond to PR feedback
- `/sparc/status` - Check branch/PR/story status

### Specialized Agents

- **researcher** - Gathers authoritative information
- **planner** - Creates TDD implementation plans
- **red-implementer** - Writes failing tests
- **green-implementer** - Implements minimal solutions
- **refactor-implementer** - Improves code structure
- **type-architect** - Designs domain types
- **expert** - Provides quality review
- **pr-manager** - Manages GitHub workflow

## Code Quality Enforcement

### Zero-Tolerance Quality Policy

- **No allow attributes**: Clippy warnings must be fixed, not suppressed
- **Mandatory hooks**: Pre-commit hooks cannot be bypassed
- **Automatic formatting**: Code formatting enforced on every change
- **Comprehensive testing**: All code must have appropriate test coverage

### Language-Specific Quality Tools

| Language | Linter | Formatter | Type Checker |
|----------|--------|-----------|--------------|
| Rust | clippy | rustfmt | Built-in |
| TypeScript | ESLint | Prettier | tsc |
| Python | ruff | ruff format | mypy |
| Elixir | credo | mix format | dialyzer |

## Configuration Options

### mkDevShell Parameters

```nix
claude-config.lib.${system}.mkDevShell {
  language = "rust";              # Required: Language selection
  projectName = "my-project";     # Optional: Project name
  tooling = {                     # Optional: Tool customization
    testRunner = "nextest";
    linter = "clippy";
    formatter = "rustfmt";
    extraTools = [ "cargo-watch" ];
  };
  features = [                    # Optional: Feature selection
    "sparc-workflow"              # Enable SPARC commands and agents
    "memory-storage"              # Enable MCP memory integration
    "git-safety"                  # Enable git safety enforcement
  ];
}
```

### Tooling Defaults

Each language has sensible defaults that can be overridden:

- **Rust**: nextest, clippy, rustfmt, with cargo-watch, cargo-expand
- **TypeScript**: vitest, ESLint, Prettier, with tsc type checking
- **Python**: pytest, ruff, mypy, with poetry package management
- **Elixir**: ExUnit, credo, mix format, with dialyzer

## Memory Storage Integration

The SPARC workflow includes mandatory knowledge storage:

- **Research findings** stored for reuse across projects
- **Planning patterns** captured for similar problem domains
- **Implementation approaches** documented for continuous improvement
- **Quality insights** preserved for team learning

This creates a continuously improving development process where lessons learned are preserved and applied to future work.

## Git and GitHub Integration

### Professional Workflow

- **Feature branches**: Automatic branch creation with story naming
- **Draft PRs**: Comprehensive PR descriptions with Claude Code attribution
- **Review coordination**: Automated response to PR feedback
- **Quality gates**: No commits without passing quality checks

### Safety Features

- **Git wrapper**: Prevents --no-verify usage
- **Branch protection**: Warnings for main branch commits
- **Pre-commit enforcement**: Mandatory quality checks
- **Change validation**: Automatic formatting and testing

## Development

To work on claude-config itself:

```bash
cd /workspaces/claude-config
nix develop
```

### Project Structure

```
claude-config/
├── flake.nix                 # Main flake entry point
├── modules/
│   ├── lib.nix              # Main library interface
│   ├── core.nix             # Shared core functionality
│   ├── sparc.nix            # SPARC workflow integration
│   ├── mcp.nix              # MCP server configuration
│   └── languages/           # Language-specific modules
│       ├── rust.nix
│       ├── typescript.nix
│       ├── python.nix
│       └── elixir.nix
├── templates/               # Project templates
│   ├── rust/
│   ├── typescript/
│   ├── python/
│   └── elixir/
└── .claude/                 # Shared Claude Code configuration
    ├── agents/              # SPARC workflow agents
    ├── commands/            # Available commands
    └── hooks/               # Quality enforcement hooks
```

## Contributing

1. Follow the SPARC workflow for any changes
2. Ensure all quality checks pass
3. Update documentation for new features
4. Test with multiple languages
5. Store implementation patterns in MCP memory

## License

MIT License - see LICENSE file for details.

## Philosophy

This package embodies several key principles:

- **Type Safety**: Use type systems to prevent runtime errors
- **Quality First**: Never compromise on code quality for speed
- **Continuous Learning**: Capture and reuse knowledge systematically
- **Professional Workflow**: Maintain high standards for team collaboration
- **Language Agnostic**: Apply proven patterns across languages

The goal is to provide a consistent, high-quality development experience regardless of programming language, while maintaining the flexibility to adapt to project-specific needs.