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
        
        # Language-specific configurations
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
            watchCommand = "cargo watch -x test";
            expandCommand = "cargo expand";
            editCommand = "cargo edit";
            addCommand = "cargo add";
            removeCommand = "cargo remove";
            mcpTools = [ "mcp__cargo__cargo_test" "mcp__cargo__cargo_check" "mcp__cargo__cargo_clippy" ];
            testFramework = "nextest";
            buildSystem = "Cargo";
            packageManager = "cargo";
            configFile = "Cargo.toml";
            toolchain = "stable with clippy, rustfmt, rust-analyzer";
            devTools = "cargo-nextest, cargo-watch, cargo-expand, cargo-edit";
            architecture = "multi-agent orchestration server";
            domainPhilosophy = "type-driven development";
            typeSystemFeatures = "Phantom types for agent state transitions (Agent<Unloaded> → Agent<Loaded> → Agent<Running>)";
            typeLibrary = "nutype crate";
            qualityFlags = "RUSTFLAGS=\\\"-D warnings\\\"";
            lintSuppressAttribute = "#[allow(clippy::...)]";
            globalLintSuppressAttribute = "#![allow(clippy::...)]";
            testMcpCommand = "mcp__cargo__cargo_test";
            lintMcpCommand = "mcp__cargo__cargo_clippy";
            formatCheckMcpCommand = "mcp__cargo__cargo_fmt_check";
          };
          
          typescript = {
            mcpServers = [ "nodejs" "git" "github" "sparc-memory" ];
            testRunner = "npm test";
            testCommandFallback = "npm test";
            testBacktraceEnv = "NODE_OPTIONS";
            buildCommand = "npm run build";
            buildRelease = "npm run build";
            checkCommand = "npm run typecheck";
            lintCommand = "npm run lint";
            formatCommand = "npm run format";
            watchCommand = "npm run test:watch";
            expandCommand = "npm run analyze";
            editCommand = "npm install";
            addCommand = "npm install";
            removeCommand = "npm uninstall";
            mcpTools = [ "mcp__nodejs__run_script" ];
            testFramework = "Jest/Vitest";
            buildSystem = "npm";
            packageManager = "npm";
            configFile = "package.json";
            toolchain = "Node.js with TypeScript";
            devTools = "Jest, ESLint, Prettier, TypeScript";
            architecture = "web application";
            domainPhilosophy = "type-driven development";
            typeSystemFeatures = "TypeScript branded types and discriminated unions";
            typeLibrary = "TypeScript";
            qualityFlags = "--strict";
            lintSuppressAttribute = "// eslint-disable";
            globalLintSuppressAttribute = "/* eslint-disable */";
            testMcpCommand = "mcp__nodejs__run_script";
            lintMcpCommand = "mcp__nodejs__run_script";
            formatCheckMcpCommand = "mcp__nodejs__run_script";
          };
        };

        # Setup script for each language
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
            
            # Copy templates and generate language-specific content
            cp -r ${./templates/claude-templates/commands}/* .claude/commands/ 2>/dev/null || true
            cp -r ${./templates/claude-templates/hooks}/* .claude/hooks/ 2>/dev/null || true
            cp -r ${./templates/claude-templates/agents}/* .claude/agents/ 2>/dev/null || true
            
            # Generate CLAUDE.md from template with substitutions
            sed -e "s/{{testRunner}}/${config.testRunner}/g" \
                -e "s/{{testCommandFallback}}/${config.testCommandFallback}/g" \
                -e "s/{{testBacktraceEnv}}/${config.testBacktraceEnv}/g" \
                -e "s/{{buildCommand}}/${config.buildCommand}/g" \
                -e "s|{{buildRelease}}|${config.buildRelease}|g" \
                -e "s/{{checkCommand}}/${config.checkCommand}/g" \
                -e "s/{{lintCommand}}/${config.lintCommand}/g" \
                -e "s/{{formatCommand}}/${config.formatCommand}/g" \
                -e "s|{{watchCommand}}|${config.watchCommand}|g" \
                -e "s/{{expandCommand}}/${config.expandCommand}/g" \
                -e "s/{{editCommand}}/${config.editCommand}/g" \
                -e "s/{{addCommand}}/${config.addCommand}/g" \
                -e "s/{{removeCommand}}/${config.removeCommand}/g" \
                -e "s/{{architecture}}/${config.architecture}/g" \
                -e "s/{{domainPhilosophy}}/${config.domainPhilosophy}/g" \
                -e "s|{{typeSystemFeatures}}|${config.typeSystemFeatures}|g" \
                -e "s/{{typeLibrary}}/${config.typeLibrary}/g" \
                -e "s/{{buildSystem}}/${config.buildSystem}/g" \
                -e "s/{{packageManager}}/${config.packageManager}/g" \
                -e "s/{{configFile}}/${config.configFile}/g" \
                -e "s|{{toolchain}}|${config.toolchain}|g" \
                -e "s|{{devTools}}|${config.devTools}|g" \
                -e "s/{{testFramework}}/${config.testFramework}/g" \
                -e "s|{{qualityFlags}}|${config.qualityFlags}|g" \
                -e "s|{{lintSuppressAttribute}}|${config.lintSuppressAttribute}|g" \
                -e "s|{{globalLintSuppressAttribute}}|${config.globalLintSuppressAttribute}|g" \
                -e "s/{{testMcpCommand}}/${config.testMcpCommand}/g" \
                -e "s/{{lintMcpCommand}}/${config.lintMcpCommand}/g" \
                -e "s/{{formatCheckMcpCommand}}/${config.formatCheckMcpCommand}/g" \
                ${./templates/CLAUDE.md.template} > CLAUDE.md

            # Create language-specific MCP settings
            cat > .claude/settings.json << 'EOF'
${mcpServersJson}EOF
            
            echo "✅ Claude Code configuration complete with ${language}-specific setup!"
            echo "📁 Created:"
            echo "  CLAUDE.md (${language}-specific)"
            echo "  .claude/settings.json (${builtins.toString (builtins.length config.mcpServers)} MCP servers)"
            echo "  .claude/agents/ (SPARC workflow)"
            echo "  .claude/commands/ (custom commands)"
            echo "  .claude/hooks/ (quality enforcement)"
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