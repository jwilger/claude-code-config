# MCP (Model Context Protocol) configuration module
{ pkgs, system }:

let
  # Generate MCP server configurations for different languages
  generateMcpConfig = language: tooling: {
    rust = {
      servers = {
        "sparc-memory" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-sparc-memory" ];
          env = {
            SPARC_MEMORY_FILE = ".claude/sparc-memory.jsonl";
          };
        };
        "cargo" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-cargo" ];
        };
        "git" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-git" ];
        };
        "github" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-github" ];
          env = {
            GITHUB_TOKEN = "$GITHUB_TOKEN";
          };
        };
      };
    };
    
    elixir = {
      servers = {
        "sparc-memory" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-sparc-memory" ];
          env = {
            SPARC_MEMORY_FILE = ".claude/sparc-memory.jsonl";
          };
        };
        "git" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-git" ];
        };
        "github" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-github" ];
          env = {
            GITHUB_TOKEN = "$GITHUB_TOKEN";
          };
        };
        "mix" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-elixir" ];
        };
      };
    };
    
    typescript = {
      servers = {
        "sparc-memory" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-sparc-memory" ];
          env = {
            SPARC_MEMORY_FILE = ".claude/sparc-memory.jsonl";
          };
        };
        "git" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-git" ];
        };
        "github" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-github" ];
          env = {
            GITHUB_TOKEN = "$GITHUB_TOKEN";
          };
        };
        "nodejs" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-nodejs" ];
        };
      };
    };
    
    python = {
      servers = {
        "sparc-memory" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-sparc-memory" ];
          env = {
            SPARC_MEMORY_FILE = ".claude/sparc-memory.jsonl";
          };
        };
        "git" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-git" ];
        };
        "github" = {
          command = "npx";
          args = [ "-y" "@anthropic-ai/mcp-github" ];
          env = {
            GITHUB_TOKEN = "$GITHUB_TOKEN";
          };
        };
      };
    };
  }.${language} or (throw "No MCP configuration for language: ${language}");

in
{
  # Get packages needed for MCP servers
  getPackages = with pkgs; [
    # No additional packages needed - MCP servers are configured via Claude Code
  ];

  # Shell hook for MCP setup
  getShellHook = ''
    echo "🧠 MCP Memory Server configured via Claude Code"
    echo "   - Check status: claude mcp list"
    echo "   - Memory file: .claude/sparc-memory.jsonl"
    echo ""
  '';

  # Expose the generateMcpConfig function
  inherit generateMcpConfig;

  # Generate MCP configuration file content
  generateMcpConfigFile = language: tooling: builtins.toJSON {
    mcpServers = (generateMcpConfig language tooling).servers;
  };
}
