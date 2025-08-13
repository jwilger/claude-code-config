# Language configuration data - shared across all modules
{ pkgs, system }:

{
  # FUNCTIONAL CORE: Language configuration (pure data)
  languageConfig = {
    rust = {
      patterns = [ "Cargo.toml" "rust-toolchain.toml" "Cargo.lock" ];
      mcpServers = [ "cargo" "git" "github" "sparc-memory" ];
      tooling = {
        test = "cargo nextest run";
        lint = "cargo clippy -- -D warnings";
        format = "cargo fmt";
        build = "cargo build";
      };
    };

    typescript = {
      patterns = [ "package.json" "tsconfig.json" "yarn.lock" "pnpm-lock.yaml" ];
      mcpServers = [ "nodejs" "git" "github" "sparc-memory" ];
      tooling = {
        test = "npm test";
        lint = "npm run lint";
        format = "npm run format";
        build = "npm run build";
      };
    };

    python = {
      patterns = [ "pyproject.toml" "setup.py" "requirements.txt" "poetry.lock" ];
      mcpServers = [ "git" "github" "sparc-memory" ];
      tooling = {
        test = "pytest";
        lint = "ruff check";
        format = "ruff format";
        build = "python -m build";
      };
    };

    elixir = {
      patterns = [ "mix.exs" "mix.lock" ];
      mcpServers = [ "mix" "git" "github" "sparc-memory" ];
      tooling = {
        test = "mix test";
        lint = "mix credo";
        format = "mix format";
        build = "mix compile";
      };
    };
  };
}