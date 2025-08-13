# Lightweight Claude Code configuration library
{ pkgs, system }:

let
  # Import language configuration from config module (breaks circular dependency)
  configModule = import ./config.nix { inherit pkgs system; };
  languageConfig = configModule.languageConfig;
  
  # Note: We no longer import mcp/core modules here to break circular dependencies
  # Instead, we inline their import in the shell scripts below

  # Derived pure functions for accessing configuration
  languagePatterns = builtins.mapAttrs (name: config: config.patterns) languageConfig;
  defaultTooling = builtins.mapAttrs (name: config: config.tooling) languageConfig;

  # FUNCTIONAL CORE: Pure language detection logic
  # Given a list of detected patterns, determine languages (no I/O)
  detectLanguagesPure = detectedPatterns: 
    let
      checkLanguage = name: config:
        let
          hasPattern = pattern: builtins.elem pattern detectedPatterns;
          hasAnyPattern = builtins.any hasPattern config.patterns;
        in
        if hasAnyPattern then name else null;
      
      candidates = builtins.attrNames languageConfig;
      detected = builtins.filter (x: x != null) 
        (builtins.map (name: checkLanguage name languageConfig.${name}) candidates);
    in
    detected;

  # FUNCTIONAL CORE: MCP server listing for a language
  getMcpServersForLanguage = language:
    if builtins.hasAttr language languageConfig 
    then languageConfig.${language}.mcpServers
    else [];

  # FUNCTIONAL CORE: Generate MCP server descriptions
  formatMcpServerInfo = language:
    let
      servers = getMcpServersForLanguage language;
      serverDescriptions = {
        cargo = "cargo (Rust build/test/lint)";
        mix = "mix (Elixir build/test)";
        nodejs = "nodejs (Node.js runtime)";
        git = "git (Version control)";
        github = "github (PR/issue management)";
        sparc-memory = "sparc-memory (SPARC workflow memory)";
      };
      formatServer = server: "  - ${serverDescriptions.${server} or "unknown-server (${server})"}";
    in
    builtins.map formatServer servers;

in
{
  # Expose functional core for use by other modules
  inherit languageConfig;

  # IMPERATIVE SHELL: Language detection script with I/O
  detectLanguage = pkgs.writeShellScriptBin "detect-language" ''
    # I/O function: Check if files/patterns exist in filesystem
    detect_files() {
      local patterns=("$@")
      for pattern in "''${patterns[@]}"; do
        if [[ "$pattern" == *"*"* ]]; then
          if ls $pattern 2>/dev/null | grep -q .; then
            echo "$pattern"
            return 0
          fi
        else
          if [[ -f "$pattern" ]]; then
            echo "$pattern"
            return 0
          fi
        fi
      done
      return 1
    }

    # Collect all detected patterns from filesystem
    detected_patterns=()
    ${builtins.concatStringsSep "\n" (
      builtins.map (lang:
        let patterns = languageConfig.${lang}.patterns;
        in builtins.concatStringsSep "\n" (
          builtins.map (pattern: ''
            if detect_files "${pattern}" >/dev/null 2>&1; then
              detected_patterns+=("${pattern}")
            fi
          '') patterns
        )
      ) (builtins.attrNames languageConfig)
    )}

    # Use functional core to determine languages
    # This is a simple case-based implementation of the Nix logic
    detected_languages=()
    ${builtins.concatStringsSep "\n" (
      builtins.map (lang:
        let 
          patterns = languageConfig.${lang}.patterns;
          checkPatterns = builtins.map (p: ''[[ " ''${detected_patterns[*]} " =~ " ${p} " ]]'') patterns;
        in
        "if ${builtins.concatStringsSep " || " checkPatterns}; then detected_languages+=(\"${lang}\"); fi"
      ) (builtins.attrNames languageConfig)
    )}
    
    # Handle results
    if [[ ''${#detected_languages[@]} -eq 0 ]]; then
      echo "❌ No supported languages detected"
      echo "Supported: ${builtins.concatStringsSep ", " (builtins.attrNames languageConfig)}"
      exit 1
    elif [[ ''${#detected_languages[@]} -eq 1 ]]; then
      lang="''${detected_languages[0]}"
      echo "✅ Detected language: $lang"
      echo ""
      echo "🧠 MCP servers for $lang:"
      ${builtins.concatStringsSep "\n" (
        builtins.map (lang:
          let servers = formatMcpServerInfo lang;
          in ''
            if [[ "$lang" == "${lang}" ]]; then
              ${builtins.concatStringsSep "\n      " (builtins.map (s: "echo \"${s}\"") servers)}
            fi''
        ) (builtins.attrNames languageConfig)
      )}
      echo ""
      echo "🚀 Run 'claude-config setup $lang' to configure"
    else
      echo "⚠️  Multiple languages detected: ''${detected_languages[*]}"
      echo "Choose one with: claude-config setup <language>"
    fi
  '';

  # IMPERATIVE SHELL: Configuration setup script with I/O
  setupConfig = pkgs.writeShellScriptBin "setup-config" ''
    if [[ $# -eq 0 ]]; then
      echo "Usage: setup-config <language> [project-name]"
      echo "Languages: ${builtins.concatStringsSep ", " (builtins.attrNames languageConfig)}"
      exit 1
    fi
    
    language="$1"
    project_name="''${2:-$(basename $(pwd))}"
    
    # Validate language using functional core
    supported_languages="${builtins.concatStringsSep "|" (builtins.attrNames languageConfig)}"
    if [[ ! "$language" =~ ^($supported_languages)$ ]]; then
      echo "❌ Unsupported language: $language"
      echo "Supported: ${builtins.concatStringsSep ", " (builtins.attrNames languageConfig)}"
      exit 1
    fi
    
    mkdir -p .claude/{agents,commands,hooks,templates}
    
    # Generate CLAUDE.md based on language (inline import to break circular dependency)
    ${(import ./core.nix { inherit pkgs system; }).generateClaudeConfig}/bin/generate-claude-config "$language" "$project_name"
    
    # Generate MCP configuration (inline import to break circular dependency)
    ${(import ./mcp.nix { inherit pkgs system; }).generateMcpSettings}/bin/generate-mcp-settings "$language"
    
    # Copy agent definitions
    cp -r ${../..}/.claude/agents/* .claude/agents/
    
    # Copy command definitions  
    cp -r ${../..}/.claude/commands/* .claude/commands/
    
    # Generate language-specific hooks (inline import to break circular dependency)
    ${(import ./core.nix { inherit pkgs system; }).generateHooks}/bin/generate-hooks "$language"
    
    echo "✅ Claude Code configuration setup complete!"
    echo ""
    echo "📁 Generated files:"
    echo "  .claude/CLAUDE.md           # Main configuration"
    echo "  .claude/settings.json       # MCP server settings"
    echo "  .claude/agents/            # SPARC workflow agents"
    echo "  .claude/commands/          # Custom commands"
    echo "  .claude/hooks/             # Git hooks"
    echo ""
    echo "🔧 Next steps:"
    echo "  1. Review .claude/CLAUDE.md"
    echo "  2. Install git hooks: git config core.hooksPath .claude/hooks"
    echo "  3. Open with Claude Code"
  '';

  # FUNCTIONAL CORE: Utility functions (pure, no I/O)
  utils = rec {
    # Check if a language is supported
    isLanguageSupported = language: builtins.hasAttr language languageConfig;
    
    # Get available languages
    availableLanguages = builtins.attrNames languageConfig;
    
    # Get complete language configuration
    getLanguageConfig = language: 
      if builtins.hasAttr language languageConfig 
      then languageConfig.${language}
      else throw "Unsupported language: ${language}";
    
    # Get default tooling for a language
    getDefaultTooling = language: (getLanguageConfig language).tooling;
    
    # Get MCP servers for a language
    getMcpServers = language: (getLanguageConfig language).mcpServers;
    
    # Get file patterns for a language
    getPatterns = language: (getLanguageConfig language).patterns;
  };
}