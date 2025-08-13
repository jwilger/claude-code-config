# MCP (Model Context Protocol) configuration module
{ pkgs, system }:

let
  # Import language configuration from config module (breaks circular dependency)
  configModule = import ./config.nix { inherit pkgs system; };
  languageConfig = configModule.languageConfig;

  # FUNCTIONAL CORE: MCP server definitions (pure data)
  mcpServerDefinitions = {
    sparc-memory = {
      command = "npx";
      args = ["-y" "@anthropic-ai/mcp-sparc-memory"];
      env = {
        SPARC_MEMORY_FILE = ".claude/sparc-memory.jsonl";
      };
    };
    cargo = {
      command = "npx";
      args = ["-y" "@anthropic-ai/mcp-cargo"];
    };
    mix = {
      command = "npx";
      args = ["-y" "@anthropic-ai/mcp-elixir"];
    };
    nodejs = {
      command = "npx";
      args = ["-y" "@anthropic-ai/mcp-nodejs"];
    };
    git = {
      command = "npx";
      args = ["-y" "@anthropic-ai/mcp-git"];
    };
    github = {
      command = "npx";
      args = ["-y" "@anthropic-ai/mcp-github"];
      env = {
        GITHUB_TOKEN = "\${GITHUB_TOKEN}";
      };
    };
  };

  # FUNCTIONAL CORE: Common hook configuration (pure data)
  commonHooks = {
    PostToolUse = [{
      hooks = [{
        command = "\${CLAUDE_PROJECT_DIR}/.claude/hooks/format_and_test.sh";
        timeout = 180;
        type = "command";
      }];
      matcher = "Edit|Write";
    }];
    PreToolUse = [
      {
        hooks = [{
          command = "python3 \${CLAUDE_PROJECT_DIR}/.claude/hooks/check_branch_status.py";
          timeout = 30;
          type = "command";
        }];
        matcher = "Edit|Write|MultiEdit|Bash";
      }
      {
        hooks = [{
          command = "python3 \${CLAUDE_PROJECT_DIR}/.claude/hooks/prevent_no_verify.py";
          timeout = 10;
          type = "command";
        }];
        matcher = "Bash";
      }
    ];
  };

  # FUNCTIONAL CORE: Generate MCP servers for a language (pure function)
  generateMcpServersForLanguage = language:
    let
      languageMcpServers = languageConfig.${language}.mcpServers or [];
      serverConfig = server: 
        let serverDef = mcpServerDefinitions.${server};
        in {
          "${server}" = serverDef;
        };
    in
    builtins.foldl' (acc: server: acc // (serverConfig server)) {} languageMcpServers;

  # FUNCTIONAL CORE: Generate complete settings.json content (pure function)
  generateSettingsJson = language:
    let
      mcpServers = generateMcpServersForLanguage language;
      settings = {
        mcpServers = mcpServers;
        hooks = commonHooks;
      };
    in
    builtins.toJSON settings;

in
{
  # IMPERATIVE SHELL: Generate MCP settings with I/O
  generateMcpSettings = pkgs.writeShellScriptBin "generate-mcp-settings" ''
    language="$1"
    
    # Validate language
    supported_languages="${builtins.concatStringsSep "|" (builtins.attrNames languageConfig)}"
    if [[ ! "$language" =~ ^($supported_languages)$ ]]; then
      echo "❌ Unsupported language: $language"
      echo "Supported: ${builtins.concatStringsSep ", " (builtins.attrNames languageConfig)}"
      exit 1
    fi
    
    # Generate settings.json using functional core
    # This will be overwritten by the language-specific content below
    
    # Replace the language-specific content for each supported language
    ${builtins.concatStringsSep "\n" (
      builtins.map (lang: ''
        if [[ "$language" == "${lang}" ]]; then
          cat > .claude/settings.json << 'EOF'
${generateSettingsJson lang}EOF
        fi
      '') (builtins.attrNames languageConfig)
    )}
    
    echo "Generated MCP server configuration for $language"
  '';
}
