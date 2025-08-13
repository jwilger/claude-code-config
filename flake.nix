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
              # First escape newlines in content blocks
              export LANG_DEP_CONTENT=$(echo "${config.languageDependencyContent}" | sed ':a;N;$!ba;s/\n/\\n/g')
              export LANG_TYPE_CONTENT=$(echo "${config.languageTypeSystemContent}" | sed ':a;N;$!ba;s/\n/\\n/g')
              export LANG_QUALITY_CONTENT=$(echo "${config.languageQualityEnforcementContent}" | sed ':a;N;$!ba;s/\n/\\n/g')
              export LANG_TESTING_CONTENT=$(echo "${config.languageTestingContent}" | sed ':a;N;$!ba;s/\n/\\n/g')
              export LANG_DEV_CONTENT=$(echo "${config.languageDevelopmentConventionsContent}" | sed ':a;N;$!ba;s/\n/\\n/g')
              export LANG_GATES_CONTENT=$(echo "${config.languageQualityGatesContent}" | sed ':a;N;$!ba;s/\n/\\n/g')
              export LANG_PROP_CONTENT=$(echo "${config.languagePropertyTestingContent}" | sed ':a;N;$!ba;s/\n/\\n/g')
              export LANG_CRIT_CONTENT=$(echo "${config.languageCriticalRulesContent}" | sed ':a;N;$!ba;s/\n/\\n/g')
              
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
                  -e "s|{{languageDependencyContent}}|$LANG_DEP_CONTENT|g" \
                  -e "s|{{languageTypeSystemContent}}|$LANG_TYPE_CONTENT|g" \
                  -e "s|{{languageQualityEnforcementContent}}|$LANG_QUALITY_CONTENT|g" \
                  -e "s|{{languageTestingContent}}|$LANG_TESTING_CONTENT|g" \
                  -e "s|{{languageDevelopmentConventionsContent}}|$LANG_DEV_CONTENT|g" \
                  -e "s|{{languageQualityGatesContent}}|$LANG_GATES_CONTENT|g" \
                  -e "s|{{languagePropertyTestingContent}}|$LANG_PROP_CONTENT|g" \
                  -e "s|{{languageCriticalRulesContent}}|$LANG_CRIT_CONTENT|g" \
                  CLAUDE.md.template | sed 's/\\n/\n/g' > CLAUDE.base.md

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