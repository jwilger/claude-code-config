# Claude Config

Add Claude Code SPARC workflow to your existing Nix projects.

## Overview

This flake provides Claude Code integration for existing projects without imposing development toolchains. Simply add it to your project's development shell.

## What It Provides

- **.claude/ Directory**: Complete SPARC workflow setup with agents, commands, and hooks  
- **MCP Server Configuration**: Language-appropriate Model Context Protocol servers
- **SPARC Workflow Integration**: Story-driven development with pull request management
- **Quality Enforcement**: Git hooks for automated checks (when project tooling exists)

## Usage

### Add to Existing Project

In your project's `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-config.url = "github:your-username/claude-config";
  };

  outputs = { self, nixpkgs, claude-config }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        # Your existing development tools
        buildInputs = with pkgs; [ rustc cargo clippy rustfmt ];
        
        # Add Claude Code to your existing shell hook
        shellHook = claude-config.lib.${system}.addClaudeCode "rust" ''
          echo "🦀 Rust project ready!"
          # Your existing setup commands
        '';
      };
    };
}
```

### Use Provided Language Shells

For quick setup, use the pre-configured shells:

```bash
# Rust project
nix develop github:your-username/claude-config#rust

# TypeScript project  
nix develop github:your-username/claude-config#typescript

# Python project
nix develop github:your-username/claude-config#python  

# Elixir project
nix develop github:your-username/claude-config#elixir
```

These shells automatically set up Claude Code configuration on first run.

### Template for New Projects

```bash
# Start new project with Claude Code integration
nix flake init --template github:your-username/claude-config#claude
```

## What Gets Created

When you use this flake, it creates:

```
.claude/
├── CLAUDE.md           # Main Claude Code configuration
├── settings.json       # MCP server configuration
├── agents/            # SPARC workflow agents
├── commands/          # Custom slash commands
└── hooks/            # Git quality enforcement hooks
```

## Language Support

- **Rust**: cargo, git, github, sparc-memory MCP servers
- **TypeScript/JavaScript**: nodejs, git, github, sparc-memory MCP servers
- **Python**: git, github, sparc-memory MCP servers  
- **Elixir**: mix, git, github, sparc-memory MCP servers

## SPARC Workflow

This configuration includes:

- **8 Specialized Agents**: researcher, planner, red-implementer, green-implementer, refactor-implementer, type-architect, expert, pr-manager
- **Custom Commands**: `/sparc` for full workflow orchestration
- **Memory Storage**: Automatic knowledge capture and retrieval
- **Quality Gates**: Git hooks for automated testing and formatting
- **PR Integration**: Draft PR creation with comprehensive descriptions

## Requirements

- Nix with flakes enabled
- Git (for repositories)
- GitHub CLI (for PR management) 
- Node.js and Python3 (for MCP servers)

## Examples

### Rust Project with Existing Tools

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-config.url = "github:your-username/claude-config";
  };

  outputs = { self, nixpkgs, claude-config }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # Your existing Rust toolchain
          rustc cargo clippy rustfmt
          # Your existing tools
          just bacon
        ];
        
        shellHook = claude-config.lib.${system}.addClaudeCode "rust" ''
          echo "🦀 Welcome to your Rust project!"
          echo "Run 'just watch' to start development"
        '';
      };
    };
}
```

### TypeScript Project

```nix
shellHook = claude-config.lib.${system}.addClaudeCode "typescript" ''
  echo "⚡ TypeScript project with Claude Code"
  npm install
'';
```

This approach lets you keep your existing development setup while adding powerful Claude Code SPARC workflow integration.