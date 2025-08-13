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
            testCommand = "cargo nextest run || cargo test";
            lintCommand = "cargo clippy -- -D warnings";
            formatCommand = "cargo fmt";
            mcpTools = [ "mcp__cargo__cargo_test" "mcp__cargo__cargo_check" "mcp__cargo__cargo_clippy" ];
            testFramework = "Rust's built-in test framework";
            buildSystem = "Cargo";
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

            # Copy commands and hooks (these are language-agnostic)  
            cp -r ${./.claude/commands}/* .claude/commands/ 2>/dev/null || true
            cp -r ${./.claude/hooks}/* .claude/hooks/ 2>/dev/null || true
            
            # Create language-specific CLAUDE.md in project root
            cat > CLAUDE.md << 'EOF'
# CLAUDE.md

This file provides guidance to Claude Code when working with this ${language} project.

## SPARC Workflow Integration

This project uses the SPARC workflow with GitHub pull requests and memory storage.

## Language: ${language}

### Testing
\`\`\`bash
${config.testCommand}
\`\`\`

### Linting  
\`\`\`bash
${config.lintCommand}
\`\`\`

### Formatting
\`\`\`bash
${config.formatCommand}
\`\`\`

## Quality Standards

- Follow TDD principles with Red→Green→Refactor cycles
- Maintain comprehensive test coverage
- Use type-driven development where applicable
- Store knowledge in MCP memory after each SPARC phase
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