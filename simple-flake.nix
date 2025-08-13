{
  description = "Claude Code configuration";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells = {
          rust = pkgs.mkShell {
            buildInputs = with pkgs; [ git gh nodejs python3 ];
            shellHook = ''
              echo "🦀 Rust + Claude Code"
              echo "This would set up Claude configuration..."
            '';
          };
        };
      }
    );
}