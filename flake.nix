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
          };
          typescript = {
            mcpServers = [ "nodejs" "git" "github" "sparc-memory" ];
            testCommand = "npm test";
            lintCommand = "npm run lint || echo 'No lint script'";
            formatCommand = "npm run format || echo 'No format script'";
          };
          python = {
            mcpServers = [ "git" "github" "sparc-memory" ];
            testCommand = "pytest";
            lintCommand = "ruff check .";
            formatCommand = "ruff format .";
          };
          elixir = {
            mcpServers = [ "mix" "git" "github" "sparc-memory" ];
            testCommand = "mix test";
            lintCommand = "mix credo";
            formatCommand = "mix format";
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
            
            # Copy agents and commands
            cp -r ${./.claude/agents}/* .claude/agents/ 2>/dev/null || true
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