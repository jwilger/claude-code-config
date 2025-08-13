{
  description = "Claude Code configuration for existing projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Language-specific configurations (inline to avoid module complexity)
        languageConfigs = {
          rust = {
            mcpServers = [ "cargo" "git" "github" "sparc-memory" ];
            testRunner = "cargo nextest run";
            testCommandFallback = "cargo test";
            testBacktraceEnv = "RUST_BACKTRACE";
            buildCommand = "cargo build";
            buildRelease = "cargo build --release";
            checkCommand = "cargo check";
            lintCommand = "cargo clippy";
            formatCommand = "cargo fmt";
            formatCheckCommand = "cargo fmt --check";
            watchCommand = "cargo watch -x test";
            expandCommand = "cargo expand";
            editCommand = "cargo edit";
            addCommand = "cargo add";
            removeCommand = "cargo remove";
            mcpTools = [ "mcp__cargo__cargo_test" "mcp__cargo__cargo_check" "mcp__cargo__cargo_clippy" ];
            testFramework = "nextest";
            buildSystem = "Cargo";
            packageManager = "cargo";
            packageManagerTools = "cargo add, cargo remove";
            configFile = "Cargo.toml";
            toolchain = "stable with clippy, rustfmt, rust-analyzer";
            devTools = "cargo-nextest, cargo-watch, cargo-expand, cargo-edit";
            architecture = "multi-agent orchestration server";
            domainPhilosophy = "type-driven development";
            typeSystemFeatures = "Phantom types for agent state transitions (`Agent<Unloaded>` → `Agent<Loaded>` → `Agent<Running>`)";
            typeLibrary = "nutype crate";
            qualityRules = "NEVER ADD ALLOW ATTRIBUTES - treat warnings as errors";
            qualityFlags = "RUSTFLAGS=\"-D warnings\"";
            lintSuppressAttribute = "#[allow(clippy::...)]";
            globalLintSuppressAttribute = "#![allow(clippy::...)]";
            testMcpCommand = "mcp__cargo__cargo_test";
            lintMcpCommand = "mcp__cargo__cargo_clippy";
            formatCheckMcpCommand = "mcp__cargo__cargo_fmt_check";
          };
          typescript = {
            mcpServers = [ "nodejs" "git" "github" "sparc-memory" ];
            testCommand = "npm test";
            lintCommand = "npm run lint || echo 'No lint script'";
            formatCommand = "npm run format || echo 'No format script'";
            mcpTools = [ "mcp__nodejs__run_script" ];
            testFramework = "Jest/Vitest/npm test scripts";
            buildSystem = "npm/pnpm/yarn";
          };
          python = {
            mcpServers = [ "git" "github" "sparc-memory" ];
            testCommand = "pytest";
            lintCommand = "ruff check .";
            formatCommand = "ruff format .";
            mcpTools = [ ];
            testFramework = "pytest";
            buildSystem = "pip/poetry/uv";
          };
          elixir = {
            mcpServers = [ "mix" "git" "github" "sparc-memory" ];
            testCommand = "mix test";
            lintCommand = "mix credo";
            formatCommand = "mix format";
            mcpTools = [ "mcp__mix__test" ];
            testFramework = "ExUnit";
            buildSystem = "Mix";
          };
        };

        # Setup script with proper language-specific configuration
        setupClaudeConfig = language: 
          let
            config = languageConfigs.${language};
            mcpServersJson = builtins.toJSON {
              mcpServers = builtins.listToAttrs (map (server: {
                name = server;
                value = {
                  command = server;
                  args = [];
                };
              }) config.mcpServers);
            };
          in pkgs.writeShellScript "setup-claude-${language}" ''
            # Only set up if Claude configuration doesn't exist
            if [ -f "CLAUDE.md" ] && [ -d ".claude" ]; then
              echo "✅ Claude Code already configured - skipping setup"
              echo "   Existing CLAUDE.md and .claude/ preserved"
              exit 0
            fi
            
            echo "Setting up Claude Code configuration for ${language}..."
            
            # Create .claude directory structure
            mkdir -p .claude/{agents,commands,hooks}
            
            # Generate language-specific agents
            cat > .claude/agents/expert.md << 'EOF'
---
name: expert
description: Provide expert review and validation of code quality, architecture decisions, and implementation approaches for ${language} projects.
tools: Read, Grep, Glob, ${builtins.concatStringsSep ", " (config.mcpTools ++ ["mcp__git__git_status" "mcp__git__git_diff" "mcp__sparc-memory__create_entities" "mcp__sparc-memory__create_relations" "mcp__sparc-memory__add_observations" "mcp__sparc-memory__search_nodes" "mcp__sparc-memory__open_nodes"])}
---

# Expert Agent - ${language}

You are the expert review specialist for ${language} projects using SPARC workflows.

## Language-Specific Focus

- **Build System**: ${config.buildSystem}  
- **Test Framework**: ${config.testFramework}
- **Quality Commands**: ${config.lintCommand}, ${config.formatCommand}

## Core Responsibilities

### 1. ${language} Code Quality Review
- Correctness verification using ${config.testFramework}
- Performance analysis for ${language} applications  
- ${language}-specific best practices and idioms
- Security review for ${language} applications

### 2. Architecture Review
- Evaluate ${language} project structure and organization
- Review dependency management via ${config.buildSystem}
- Assess maintainability and extensibility

Use \`${config.testCommand}\` to run tests and \`${config.lintCommand}\` for quality checks.
EOF

            # Generate red-implementer agent  
            cat > .claude/agents/red-implementer.md << 'EOF'
---
name: red-implementer
description: Write FAILING tests that capture behavioral intent for ${language} projects.
tools: Read, Edit, MultiEdit, Write, Grep, Glob, ${builtins.concatStringsSep ", " (config.mcpTools ++ ["mcp__git__git_status" "mcp__git__git_diff" "mcp__sparc-memory__create_entities" "mcp__sparc-memory__create_relations" "mcp__sparc-memory__add_observations" "mcp__sparc-memory__search_nodes" "mcp__sparc-memory__open_nodes"])}
---

# Red Implementer - ${language}

Write failing tests for ${language} using ${config.testFramework}.

## ${language} Testing Approach

- **Framework**: ${config.testFramework}
- **Run Command**: \`${config.testCommand}\`
- **Build System**: ${config.buildSystem}

## Failure Verification

Always verify test fails by running: \`${config.testCommand}\`
EOF

            # Generate green-implementer agent
            cat > .claude/agents/green-implementer.md << 'EOF'
---
name: green-implementer  
description: Implement minimal code to make failing tests pass in ${language}.
tools: Read, Edit, MultiEdit, Write, Grep, Glob, ${builtins.concatStringsSep ", " (config.mcpTools ++ ["mcp__git__git_status" "mcp__git__git_diff" "mcp__sparc-memory__create_entities" "mcp__sparc-memory__create_relations" "mcp__sparc-memory__add_observations" "mcp__sparc-memory__search_nodes" "mcp__sparc-memory__open_nodes"])}
---

# Green Implementer - ${language}

Implement minimal ${language} code to make tests pass.

## ${language} Implementation

- **Test Command**: \`${config.testCommand}\`
- **Build System**: ${config.buildSystem}
- **Quality Check**: \`${config.lintCommand}\`

Apply the simplest solution that makes tests pass.
EOF

            # Copy language-agnostic templates and generate language-specific content
            cp -r ${./templates/claude-templates/commands}/* .claude/commands/ 2>/dev/null || true
            cp -r ${./templates/claude-templates/hooks}/* .claude/hooks/ 2>/dev/null || true
            cp -r ${./templates/claude-templates/agents}/* .claude/agents/ 2>/dev/null || true
            
            # Generate CLAUDE.md from template
            cat > CLAUDE.md << 'EOF'
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing

Always use \`${config.testRunner}\` instead of \`${config.testCommandFallback}\`:

\`\`\`bash
${config.testRunner}                    # Run all tests
${config.testRunner} --lib             # Unit tests only
${config.testRunner} --tests           # Integration tests only
${config.testRunner} --nocapture       # Show test output
RUST_BACKTRACE=1 ${config.testRunner}  # With backtrace on failure
\`\`\`

### Building and Linting

\`\`\`bash
${config.buildCommand}                          # Build the project
${config.buildRelease}              # Release build
${config.checkCommand}                         # Fast syntax/type checking
${config.lintCommand}                        # Linting (strict rules enabled)
${config.formatCommand}                          # Format code
\`\`\`

### Development Tools

\`\`\`bash
${config.watchCommand}                 # Auto-run tests on changes
${config.expandCommand}                       # Macro expansion
${config.editCommand}                         # Dependency management
\`\`\`

## Architecture Overview

This is a **${config.architecture}** that provides WebAssembly-based agent isolation, FIPA-compliant messaging, and comprehensive observability. It runs as a standalone server process (like PostgreSQL or Redis) rather than a library.

### Core Components

- **Agent Runtime Environment**: Manages WebAssembly agent lifecycle with sandboxing and resource limits
- **FIPA Message Router**: High-performance async message routing between agents with conversation tracking
- **Security & Sandboxing**: WebAssembly isolation with CPU/memory limits and host function restrictions
- **Observability Layer**: Built-in structured logging, metrics (Prometheus), and distributed tracing (OpenTelemetry)
- **Agent Lifecycle Management**: Deployment strategies including blue-green, canary, and shadow deployments

### Domain Model Philosophy

The codebase follows **${config.domainPhilosophy}** principles:

- Illegal states are unrepresentable through the type system
- ${config.typeSystemFeatures}
- Smart constructors with validation (e.g., \`AgentId\`, \`Percentage\`)
- Comprehensive error types with domain-specific variants
- nutype crate for eliminating primitive obsession

### Key Domain Types

Located in \`src/domain_types.rs\` and \`src/domain/\`:

- **Agent Identity**: \`AgentId\`, \`AgentName\` with validation
- **Resources**: \`CpuFuel\`, \`MemoryBytes\`, \`MaxAgentMemory\` with limits
- **Messaging**: \`MessageId\`, \`ConversationId\`, \`Performative\` for FIPA compliance
- **Deployment**: \`DeploymentId\`, \`DeploymentStrategy\`, \`DeploymentStatus\` for lifecycle management
- **Security**: \`WasmSecurityPolicy\`, \`ResourceLimits\`, \`ValidationRule\` for sandboxing

[... rest of Caxton's comprehensive CLAUDE.md content ...]

## Code Quality Enforcement - CRITICAL

**${config.qualityRules}** - This is a hard rule with zero exceptions without team approval.

- **NEVER** use \`#![allow(clippy::...)]\` or \`#[allow(clippy::...)]\` without explicit team approval
- **NEVER** bypass pre-commit hooks or ignore clippy warnings/errors  
- **ALWAYS** fix the underlying issue causing the warning instead of suppressing it
- Pre-commit hooks MUST pass with \`-D warnings\` (treat warnings as errors)

EOF

            # Create language-specific MCP settings
            cat > .claude/settings.json << 'EOF'
${mcpServersJson}
EOF
            
            echo "✅ Claude Code configuration complete with ${language}-specific setup!"
            echo "📁 Created:"
            echo "  CLAUDE.md (${language}-specific commands)"
            echo "  .claude/settings.json (${builtins.toString (builtins.length config.mcpServers)} MCP servers)"
            echo "  .claude/agents/ (SPARC workflow agents)"
            echo "  .claude/commands/ (custom slash commands)"  
            echo "  .claude/hooks/ (quality enforcement hooks)"
          '';
        
      in {
        # Development shells that add Claude Code to existing projects
        devShells = {
          rust = pkgs.mkShell {
            buildInputs = with pkgs; [ git gh nodejs python3 ];
            shellHook = ''
              echo "🦀 Rust project with Claude Code"
              if [ ! -d ".claude" ]; then
                ${setupClaudeConfig "rust"}
              fi
            '';
          };

          typescript = pkgs.mkShell {
            buildInputs = with pkgs; [ git gh nodejs python3 ];
            shellHook = ''
              echo "⚡ TypeScript project with Claude Code"
              if [ ! -d ".claude" ]; then
                ${setupClaudeConfig "typescript"}
              fi
            '';
          };

          python = pkgs.mkShell {
            buildInputs = with pkgs; [ git gh nodejs python3 ];
            shellHook = ''
              echo "🐍 Python project with Claude Code"
              if [ ! -d ".claude" ]; then
                ${setupClaudeConfig "python"}
              fi
            '';
          };

          elixir = pkgs.mkShell {
            buildInputs = with pkgs; [ git gh nodejs python3 ];
            shellHook = ''
              echo "💜 Elixir project with Claude Code"
              if [ ! -d ".claude" ]; then
                ${setupClaudeConfig "elixir"}
              fi
            '';
          };
        };

        # Library function for other flakes to use
        lib.addClaudeCode = language: existingShellHook: existingShellHook + ''
          # Add Claude Code configuration
          if [ ! -d ".claude" ]; then
            echo "Setting up Claude Code for ${language}..."
            ${setupClaudeConfig language}
          fi
        '';
      }
    ) // {
      templates.claude = {
        path = ./templates/claude;
        description = "Add Claude Code configuration to existing projects";
      };
    };
}