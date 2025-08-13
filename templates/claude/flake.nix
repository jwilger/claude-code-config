{
  description = "Claude Code configuration for existing project";

  inputs = {
    claude-config.url = "github:your-org/claude-config";
    nixpkgs.follows = "claude-config/nixpkgs";
    flake-utils.follows = "claude-config/flake-utils";
  };

  outputs = { self, claude-config, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # Development shell with Claude Code configured
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            gh
            nodejs
            python3
          ];
          
          shellHook = ''
            echo "⚡ Claude Code Configuration Active"
            echo ""
            echo "🔍 Detect language: nix run github:your-org/claude-config -- detect"
            echo "⚙️  Setup configuration: nix run github:your-org/claude-config -- setup <language>"
            echo ""
            
            if [ ! -d ".claude" ]; then
              echo "💡 Run setup to configure Claude Code for this project"
            else
              echo "✅ Claude Code configured - open with Claude Desktop"
            fi
          '';
        };
      }
    );
}