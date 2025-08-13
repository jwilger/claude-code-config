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
            languageName = "Rust";
            configFile = "Cargo.toml";
            toolchain = "stable with clippy, rustfmt, rust-analyzer";
            devTools = "cargo-nextest, cargo-watch, cargo-expand, cargo-edit";
            projectArchitectureDescription = "Caxton is a **multi-agent orchestration server** that provides WebAssembly-based agent isolation, FIPA-compliant messaging, and comprehensive observability. It runs as a standalone server process (like PostgreSQL or Redis) rather than a library.";
            domainPhilosophy = "type-driven development";
            typeSystemFeatures = "Phantom types for agent state transitions (`Agent<Unloaded>` → `Agent<Loaded>` → `Agent<Running>`)";
            typeLibrary = "nutype crate";
            qualityFlags = "\\`RUSTFLAGS=\\\\\\\"-D warnings\\\\\\\"\\`";
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

        # Build Claude configuration in nix store for each language
        buildClaudeConfig = language:
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
          in pkgs.stdenv.mkDerivation {
            name = "claude-config-${language}";
            src = ./templates;
            
            buildPhase = ''
              # Create .claude directory structure
              mkdir -p .claude/{agents,commands,hooks}
              
              # Copy templates
              cp -r claude-templates/commands/* .claude/commands/
              cp -r claude-templates/hooks/* .claude/hooks/
              cp -r claude-templates/agents/* .claude/agents/
              
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
                  -e "s|{{projectArchitectureDescription}}|${config.projectArchitectureDescription}|g" \
                  -e "s/{{domainPhilosophy}}/${config.domainPhilosophy}/g" \
                  -e "s|{{typeSystemFeatures}}|${config.typeSystemFeatures}|g" \
                  -e "s/{{typeLibrary}}/${config.typeLibrary}/g" \
                  -e "s/{{buildSystem}}/${config.buildSystem}/g" \
                  -e "s/{{packageManager}}/${config.packageManager}/g" \
                  -e "s/{{languageName}}/${config.languageName}/g" \
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
                  CLAUDE.md.template > CLAUDE.base.md

              # Create language-specific MCP settings
              cat > .claude/settings.json << 'EOF'
${mcpServersJson}
EOF
            '';
            
            installPhase = ''
              mkdir -p $out
              cp CLAUDE.base.md $out/
              cp -r .claude $out/
            '';
          };
          
        # Setup function that handles include system
        setupClaudeConfig = language:
          let
            baseConfig = buildClaudeConfig language;
          in pkgs.writeShellScript "setup-claude-${language}" ''
            echo "Setting up Claude Code configuration for ${language}..."
            
            # Copy .claude directory from nix store (always update to latest)
            rm -rf .claude
            cp -r ${baseConfig}/.claude ./
            chmod -R u+w .claude
            
            # Handle CLAUDE.md with include system
            if [ -f "CLAUDE.local.md" ]; then
              # Replace include marker with local content
              sed '/<!-- CLAUDE.local.md -->/r CLAUDE.local.md' ${baseConfig}/CLAUDE.base.md | \
                sed '/<!-- CLAUDE.local.md -->/d' > CLAUDE.md
              echo "✅ Generated CLAUDE.md with local customizations"
            else
              # Just remove the include marker
              sed '/<!-- CLAUDE.local.md -->/d' ${baseConfig}/CLAUDE.base.md > CLAUDE.md
              echo "✅ Generated CLAUDE.md (create CLAUDE.local.md for customizations)"
            fi
            
            echo "📁 Claude Code configuration ready:"
            echo "  CLAUDE.md (generated, do not edit directly)"
            echo "  CLAUDE.local.md (create this for project-specific content)"
            echo "  .claude/ (${builtins.toString (builtins.length (languageConfigs.${language}).mcpServers)} MCP servers, SPARC workflow)"
          '';
        
      in {
        # Development shells that add Claude Code to existing projects
        devShells = {
          rust = pkgs.mkShell {
            buildInputs = with pkgs; [ git gh nodejs python3 ];
            shellHook = ''
              echo "🦀 Rust project with Claude Code"
              ${setupClaudeConfig "rust"}
            '';
          };

          typescript = pkgs.mkShell {
            buildInputs = with pkgs; [ git gh nodejs python3 ];
            shellHook = ''
              echo "⚡ TypeScript project with Claude Code"
              ${setupClaudeConfig "typescript"}
            '';
          };
        };

        # Library function for other flakes to use
        lib.addClaudeCode = language: existingShellHook: existingShellHook + ''
          # Add Claude Code configuration (always sync with latest from flake)
          ${setupClaudeConfig language}
        '';
      }
    ) // {
      templates.claude = {
        path = ./templates/claude;
        description = "Add Claude Code configuration to existing projects";
      };
    };
}