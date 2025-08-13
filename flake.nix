{
  description = "Multi-language Claude Code configuration package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
      in
      {
        # Main library interface for projects to consume
        lib = import ./modules/lib.nix {
          inherit pkgs system;
          inherit (self) inputs;
        };

        # Default development shell for the claude-config project itself
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            nix
            nixpkgs-fmt
          ];

          shellHook = ''
            echo "🔧 Claude Config Development Environment"
            echo "Available commands:"
            echo "  nix flake check      # Validate flake"
            echo "  nixpkgs-fmt .        # Format nix files"
            echo ""
          '';
        };

        # Development shells for different languages (examples)
        devShells = {
          rust-example = self.lib.${system}.mkDevShell {
            language = "rust";
            tooling = {
              testRunner = "nextest";
              linter = "clippy";
              formatter = "rustfmt";
            };
            features = [ "sparc-workflow" "memory-storage" "git-safety" ];
          };

          elixir-example = self.lib.${system}.mkDevShell {
            language = "elixir";
            tooling = {
              testRunner = "mix-test";
              linter = "credo";
              formatter = "mix-format";
              typeChecker = "dialyzer";
            };
            features = [ "sparc-workflow" "memory-storage" ];
          };

          typescript-example = self.lib.${system}.mkDevShell {
            language = "typescript";
            tooling = {
              testRunner = "vitest";
              linter = "eslint";
              formatter = "prettier";
              typeChecker = "tsc";
              packageManager = "pnpm";
            };
            features = [ "sparc-workflow" "memory-storage" ];
          };

          python-example = self.lib.${system}.mkDevShell {
            language = "python";
            tooling = {
              testRunner = "pytest";
              linter = "ruff";
              formatter = "ruff-format";
              typeChecker = "mypy";
              packageManager = "poetry";
            };
            features = [ "sparc-workflow" "memory-storage" ];
          };
        };

        # Package templates for different languages
        packages = {
          templates = pkgs.stdenv.mkDerivation {
            name = "claude-config-templates";
            src = ./templates;
            installPhase = ''
              mkdir -p $out
              cp -r * $out/
            '';
          };
        };
      }
    ) // {
      # Flake templates for easy initialization (system-independent)
      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust project with Claude Code configuration";
        };
        elixir = {
          path = ./templates/elixir;
          description = "Elixir project with Claude Code configuration";
        };
        typescript = {
          path = ./templates/typescript;
          description = "TypeScript project with Claude Code configuration";
        };
        python = {
          path = ./templates/python;
          description = "Python project with Claude Code configuration";
        };
      };
    };
}