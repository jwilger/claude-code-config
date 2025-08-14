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
            # Basic commands
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
            testMcpCommand = "mcp__cargo__cargo_test";
            lintMcpCommand = "mcp__cargo__cargo_clippy";
            formatCheckMcpCommand = "mcp__cargo__cargo_fmt_check";
            
            # Content blocks
            languageDependencyContent = ''
- Rust toolchain: stable with clippy, rustfmt, rust-analyzer
- Development tools: cargo-nextest, cargo-watch, cargo-expand, cargo-edit
- Optional: just for task automation'';
            
            languageTypeSystemContent = ''
**Rust Implementation:**
- All new domain types use `nutype` with `sanitize(...)` and `validate(...)`
- Derive at least: `Clone, Debug, Eq, PartialEq, Display`; add `Serialize, Deserialize` where needed
- Prefer `Result<T, DomainError>` over panics. Panics only for truly unreachable states

**Example:**
```rust
#[nutype(
  sanitize(trim),
  validate(len(min = 1, max = 64)),
  derive(Clone, Debug, Eq, PartialEq, Display)
)]
pub struct AgentName(String);
```'';

            languageQualityEnforcementContent = ''
**Rust-Specific Enforcement:**
- **NEVER** use `#![allow(clippy::...)]` or `#[allow(clippy::...)]` without explicit team approval
- `RUSTFLAGS="-D warnings"` treats all clippy warnings as build failures
- Code quality test (`test_no_clippy_allow_attributes`) enforces zero-tolerance
- Pre-commit hooks prevent allow attribute commits via pattern detection'';

            languageTestingContent = ''
**Rust Testing:**
- Use `mcp__cargo__cargo_test` for all tests; treat clippy warnings as errors
- Prefer `cargo nextest run` over `cargo test` for better performance
- Use `RUST_BACKTRACE=1` for detailed error traces'';

            languageDevelopmentConventionsContent = ''
**Rust-Specific Conventions:**
- **Error Handling**: Use comprehensive `Result<T, DomainError>` types
- **Tracing**: Instrument async functions with `#[instrument]`
- **State Machines**: Use phantom types for compile-time state validation
- **Testing**: Write property-based tests for validation logic using proptest'';

            languageQualityGatesContent = ''
**Rust Quality Gates:**
- All clippy warnings MUST be fixed, not suppressed with allow attributes
- Code quality test (`test_no_clippy_allow_attributes`) enforces zero-tolerance'';

            languagePropertyTestingContent = ''
**Rust Property Testing:**
Use proptest for invariants of domain types and parsers.

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;
    
    proptest! {
        #[test]
        fn agent_name_roundtrip(s in "\\\\PC{1,64}") {
            let name = AgentName::new(s).unwrap();
            assert_eq!(name.as_str(), s.trim());
        }
    }
}
```'';

            languageCriticalRulesContent = ''
**Rust-Specific:**
- NEVER add clippy allow attributes (`#[allow(clippy::...)]` or `#![allow(clippy::...)]`) without explicit team approval'';
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
                  -e "s/{{buildSystem}}/${config.buildSystem}/g" \
                  -e "s/{{packageManager}}/${config.packageManager}/g" \
                  -e "s/{{languageName}}/${config.languageName}/g" \
                  -e "s/{{configFile}}/${config.configFile}/g" \
                  -e "s/{{testFramework}}/${config.testFramework}/g" \
                  -e "s/{{testMcpCommand}}/${config.testMcpCommand}/g" \
                  -e "s/{{lintMcpCommand}}/${config.lintMcpCommand}/g" \
                  -e "s/{{formatCheckMcpCommand}}/${config.formatCheckMcpCommand}/g" \
                  CLAUDE.md.template > CLAUDE.md
              
              # Create temporary files for each content block to avoid shell escaping issues
              cat > lang_dep_content << 'EOF'
${config.languageDependencyContent}
EOF
              cat > lang_type_content << 'EOF'  
${config.languageTypeSystemContent}
EOF
              cat > lang_quality_content << 'EOF'
${config.languageQualityEnforcementContent}
EOF
              cat > lang_testing_content << 'EOF'
${config.languageTestingContent}
EOF
              cat > lang_dev_content << 'EOF'
${config.languageDevelopmentConventionsContent}
EOF
              cat > lang_gates_content << 'EOF'
${config.languageQualityGatesContent}
EOF
              cat > lang_prop_content << 'EOF'
${config.languagePropertyTestingContent}
EOF
              cat > lang_crit_content << 'EOF'
${config.languageCriticalRulesContent}
EOF
              
              # Replace template variables with file contents
              sed -i \
                -e "/{{languageDependencyContent}}/r lang_dep_content" \
                -e "/{{languageDependencyContent}}/d" \
                -e "/{{languageTypeSystemContent}}/r lang_type_content" \
                -e "/{{languageTypeSystemContent}}/d" \
                -e "/{{languageQualityEnforcementContent}}/r lang_quality_content" \
                -e "/{{languageQualityEnforcementContent}}/d" \
                -e "/{{languageTestingContent}}/r lang_testing_content" \
                -e "/{{languageTestingContent}}/d" \
                -e "/{{languageDevelopmentConventionsContent}}/r lang_dev_content" \
                -e "/{{languageDevelopmentConventionsContent}}/d" \
                -e "/{{languageQualityGatesContent}}/r lang_gates_content" \
                -e "/{{languageQualityGatesContent}}/d" \
                -e "/{{languagePropertyTestingContent}}/r lang_prop_content" \
                -e "/{{languagePropertyTestingContent}}/d" \
                -e "/{{languageCriticalRulesContent}}/r lang_crit_content" \
                -e "/{{languageCriticalRulesContent}}/d" \
                CLAUDE.md

              # Create language-specific MCP settings
              cat > .claude/settings.json << 'EOF'
${mcpServersJson}
EOF
            '';
            
            installPhase = ''
              mkdir -p $out
              cp CLAUDE.md $out/
              cp -r .claude $out/
            '';
          };
          
        # Simple setup that creates symlinks
        setupClaudeConfig = language:
          let
            baseConfig = buildClaudeConfig language;
          in pkgs.writeShellScript "setup-claude-${language}" ''
            echo "Setting up Claude Code configuration for ${language}..."
            
            # Create individual symlinks to allow project-specific additions
            ln -sf ${baseConfig}/CLAUDE.md ./CLAUDE.md
            
            # Create .claude directory structure with selective symlinking
            mkdir -p .claude
            ln -sf ${baseConfig}/.claude/settings.json .claude/settings.json
            ln -sf ${baseConfig}/.claude/agents .claude/agents
            ln -sf ${baseConfig}/.claude/commands .claude/commands
            ln -sf ${baseConfig}/.claude/hooks .claude/hooks
            
            echo "✅ Claude Code configuration symlinked!"
            echo "📁 Configuration structure:"
            echo "  CLAUDE.md -> nix store (language-specific, updates with flake)"
            echo "  CLAUDE.local.md (create this for project-specific content - loaded via @CLAUDE.local.md)"
            echo "  .claude/agents/ -> nix store (SPARC workflow)"
            echo "  .claude/commands/ -> nix store (custom commands)"
            echo "  .claude/hooks/ -> nix store (quality enforcement)"
            echo "  .claude/settings.json -> nix store (${builtins.toString (builtins.length (languageConfigs.${language}).mcpServers)} MCP servers)"
            echo ""
            echo "You can add project-specific files directly to .claude/ - they won't be overwritten."
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