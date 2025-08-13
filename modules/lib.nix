# Main library interface for claude-config
{ pkgs, system, inputs }:

let
  # Import language-specific modules
  rustModule = import ./languages/rust.nix { inherit pkgs system inputs; };
  elixirModule = import ./languages/elixir.nix { inherit pkgs system inputs; };
  typescriptModule = import ./languages/typescript.nix { inherit pkgs system inputs; };
  pythonModule = import ./languages/python.nix { inherit pkgs system inputs; };

  # Import core modules
  coreModule = import ./core.nix { inherit pkgs system; };
  sparcModule = import ./sparc.nix { inherit pkgs system; };
  mcpModule = import ./mcp.nix { inherit pkgs system; };

  # Map language names to their modules
  languageModules = {
    rust = rustModule;
    elixir = elixirModule;
    typescript = typescriptModule;
    python = pythonModule;
  };

in
{
  # Main function to create a development shell for a specific language
  mkDevShell = {
    language,
    tooling ? {},
    features ? [],
    projectName ? "project",
    ...
  }:
    let
      languageModule = languageModules.${language} or (throw "Unsupported language: ${language}");
      
      # Merge user tooling preferences with language defaults
      finalTooling = languageModule.defaultTooling // tooling;
      
      # Get language-specific packages
      languagePackages = languageModule.getPackages finalTooling;
      
      # Get core packages
      corePackages = coreModule.getCorePackages;
      
      # Get feature-specific packages and setup
      featurePackages = builtins.concatLists (map (feature: 
        if feature == "sparc-workflow" then sparcModule.getPackages
        else if feature == "memory-storage" then mcpModule.getPackages  
        else if feature == "git-safety" then coreModule.getGitSafetyPackages
        else []
      ) features);
      
      # Generate shell hook
      shellHook = builtins.concatStringsSep "\n" ([
        (coreModule.getBaseShellHook projectName language)
        (languageModule.getShellHook finalTooling)
      ] ++ (map (feature:
        if feature == "sparc-workflow" then sparcModule.getShellHook
        else if feature == "memory-storage" then mcpModule.getShellHook
        else if feature == "git-safety" then coreModule.getGitSafetyShellHook
        else ""
      ) features));
      
    in
    pkgs.mkShell ({
      buildInputs = languagePackages ++ corePackages ++ featurePackages;
      inherit shellHook;
    } // (languageModule.getEnvironment finalTooling));

  # Generate configuration files for a project
  generateConfig = {
    language,
    tooling ? {},
    features ? [],
    projectName ? "project",
    outputDir ? ".claude",
    ...
  }:
    let
      languageModule = languageModules.${language} or (throw "Unsupported language: ${language}");
      finalTooling = languageModule.defaultTooling // tooling;
      
      # Generate CLAUDE.md content
      claudeMdContent = languageModule.generateClaudeMd {
        inherit projectName finalTooling features;
      };
      
      # Generate settings.json content
      settingsContent = builtins.toJSON (coreModule.generateSettings {
        inherit language finalTooling features;
      });
      
      # Generate hooks based on language and features
      hooks = languageModule.generateHooks finalTooling features;
      
    in
    pkgs.stdenv.mkDerivation {
      name = "${projectName}-claude-config";
      unpackPhase = "true";
      
      installPhase = ''
        mkdir -p $out/${outputDir}
        echo '${claudeMdContent}' > $out/${outputDir}/CLAUDE.md
        echo '${settingsContent}' > $out/${outputDir}/settings.json
        
        # Copy hooks
        mkdir -p $out/${outputDir}/hooks
        ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: content: ''
          echo '${content}' > $out/${outputDir}/hooks/${name}
          chmod +x $out/${outputDir}/hooks/${name}
        '') hooks)}
      '';
    };

  # Utility functions
  utils = {
    # Check if a language is supported
    isLanguageSupported = language: builtins.hasAttr language languageModules;
    
    # Get available languages
    availableLanguages = builtins.attrNames languageModules;
    
    # Get default tooling for a language
    getDefaultTooling = language: 
      let
        languageModule = languageModules.${language} or (throw "Unsupported language: ${language}");
      in
      languageModule.defaultTooling;
  };
}