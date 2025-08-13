# SPARC workflow module
{ pkgs, system }:

{
  # Get packages needed for SPARC workflow
  getPackages = with pkgs; [
    gh  # GitHub CLI for PR management
  ];

  # Shell hook for SPARC workflow
  getShellHook = ''
    echo "🔄 SPARC Workflow enabled"
    echo "   - Study → Plan → Architect → Review → Code"
    echo "   - Mandatory memory storage for all phases"
    echo "   - GitHub PR integration with draft status"
    echo ""
    
    # Check MCP memory server configuration
    if [ -f ".claude/sparc-memory.jsonl" ]; then
      echo "🧠 MCP Memory Server configured"
      echo "   - Memory file: .claude/sparc-memory.jsonl"
    else
      echo "⚠️  MCP Memory Server not yet configured"
      echo "   - Run 'claude mcp' to set up memory storage"
    fi
    echo ""
    
    echo "📋 SPARC commands:"
    echo "  /sparc                  # Full story workflow with PR integration"
    echo "  /sparc/pr               # Create draft PR for completed story"
    echo "  /sparc/review           # Respond to PR feedback"
    echo "  /sparc/status           # Check branch/PR/story status"
    echo ""
    
    echo "🤖 Available agents:"
    echo "  researcher              # Gather information and create research briefs"
    echo "  planner                 # Create implementation plans following TDD"
    echo "  red-implementer         # Write failing tests that capture intent"
    echo "  green-implementer       # Implement minimal code to make tests pass"
    echo "  refactor-implementer    # Improve code structure preserving behavior"
    echo "  type-architect          # Design domain types and type-state machines"
    echo "  test-hardener           # Strengthen tests and propose type improvements"
    echo "  expert                  # Review code for correctness and best practices"
    echo "  pr-manager              # Handle GitHub PR operations"
    echo ""
  '';

  # Generate SPARC-specific configuration
  generateSparcConfig = {
    enableMemoryStorage ? true,
    enableTddEnforcement ? true,
    enablePrIntegration ? true,
    branchNamingPattern ? "story-{id}-{slug}",
    ...
  }: {
    inherit enableMemoryStorage enableTddEnforcement enablePrIntegration branchNamingPattern;
    
    # TDD phase files
    tddPhases = [
      ".claude/tdd.red"
      ".claude/tdd.green" 
      ".claude/tdd.refactor"
    ];
    
    # SPARC phase tracking
    sparcPhases = [
      ".claude/sparc.research"
      ".claude/sparc.plan"
      ".claude/sparc.architect"
      ".claude/sparc.review"
      ".claude/sparc.code"
    ];
    
    # Required MCP servers
    mcpServers = [
      "sparc-memory"
      "cargo"  # Language-specific
      "git"
      "github"
    ];
  };
}