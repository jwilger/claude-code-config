---
description: Orchestrate SPARC for the next unfinished story in @PLANNING.md (or the specified one) using strict TDD + type-driven design.
argument-hint: [optional-instructions or explicit story]
model: claude-opus-4-1-20250805
allowed-tools: Task
---
<!-- cSpell:ignore nextest clippy proptest nutype thiserror wasmtime newtypes nocapture -->

# SPARC Orchestration (Multi-Language)

Execute the complete SPARC workflow directly, using specialized agents for each phase.

## Context

- User input: **$ARGUMENTS**
- Planning file: PLANNING.md
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`

## Pre-Workflow Setup

**CRITICAL FIRST STEP**: Before delegating to any agents, the SPARC coordinator MUST:

1. **Detect Project Language**: Examine project files to determine language (Cargo.toml → Rust, package.json → Node.js/TypeScript, pyproject.toml → Python, mix.exs → Elixir)
2. **Set Language-Specific Working Directory**: Configure appropriate MCP servers based on detected language
3. **Verify Setup**: Ensure language-specific tools are available for all subsequent operations

This ensures all agents have proper access to language-specific commands (test, lint, build, etc.) without MCP working directory errors.

## SPARC Coordinator Role

**CRITICAL: The SPARC coordinator (you) is STRICTLY an orchestrator. You MUST NOT:**

- Write or read any code directly
- Perform any research or web searches
- Create or modify any plans
- Run any commands or tests
- Make any implementation decisions
- Analyze code or requirements

**Your ONLY job is to:**

1. **Delegate ALL work** to specialized subagents using the Task tool
2. **Relay information** between subagents and present results to the user
3. **Route information requests** between agents as needed
4. **Track workflow state** and enforce correct SPARC phase ordering
5. **Interface with human** for approvals and decisions
6. **ENFORCE MEMORY STORAGE** - Verify each agent stored knowledge before proceeding

## SPARC Workflow

Execute each phase using specialized agents:

### A) STORY SELECTION

Use Task tool with `planner` agent:

1. Read PLANNING.md to identify available stories
2. If $ARGUMENTS specifies a story, select it; otherwise pick next unfinished (`- [ ]`)
3. Return chosen story text and ID for coordinator to present to user

### A.5) BRANCH SETUP

Use Task tool with `pr-manager` agent:

- Create feature branch: `story-{zero-padded-id}-{kebab-case-slug}`
- Switch to feature branch
- Record story/branch mapping in `.claude/branch.info`

### B) RESEARCH

Use Task tool with `researcher` agent:

- Research external dependencies and language-specific tools
- Gather authoritative sources and documentation
- Return "Research Brief" with assumptions, key facts, and open questions

### C) PLAN

Use Task tool with `planner` agent:

- Plan Kent Beck Red→Green→Refactor loop (one failing test)
- List new/updated domain types (language-appropriate patterns) and function signatures
- Specify pure functions vs shell boundaries and error handling patterns
- Define acceptance checks and rollback plan

### D) APPROVAL GATE

**Coordinator responsibilities:**

- Present plan from planner agent to user for approval
- Collect user approval/feedback
- If approved, delegate to `pr-manager` agent to write `.claude/plan.approved` with plan content
- Block further progress until approved

### E) IMPLEMENT (TDD Cycle)

**RED Phase** - Use Task tool with `red-implementer` agent:
- Write exactly ONE failing test that captures the next behavior
- Use language-appropriate failure mechanisms to force clear failure
- Verify test fails for the right reason
- Create `.claude/tdd.red` state file
- Store test patterns in MCP memory

**GREEN Phase** - Use Task tool with `green-implementer` agent:
- Implement minimal code to make the failing test pass
- Use simplest possible solution (fake it 'til you make it)
- Verify test passes and no existing tests break
- Create `.claude/tdd.green` state file
- Store minimal implementation patterns in MCP memory

**REFACTOR Phase** - Use Task tool with `refactor-implementer` agent:
- Remove duplication and improve code structure
- Extract pure functions (functional core / imperative shell)
- Keep all tests green throughout refactoring
- Use language-specific quality tools (linting, formatting)
- Store refactoring patterns in MCP memory
- **COMMIT**: Create descriptive commit with Claude Code attribution

**TYPE PASS**: Use Task tool with `type-architect` to improve type safety with language-appropriate domain types

### F) TEST-HARDENING

Use Task tool with `test-hardener` agent:

- For each test added/changed, propose type/API changes that make failures impossible at compile time
- If safe, implement type changes with small diffs
- Update call sites and re-run language-specific quality tools

### G) EXPERT CHECK (Optional)

Use Task tool with `expert` agent:

- Request brief review on type-state soundness and error pipeline
- Get validation of implementation approach

### H) PR CREATION

Use Task tool with `pr-manager` agent:

- Create draft PR with comprehensive description
- Link story acceptance criteria and implementation summary
- Update `.claude/branch.info` with PR number
- Never mark PR ready-for-review (human only)

### I) PR REVIEW LOOP (if feedback exists)

Use Task tool with `pr-manager` agent:

- Monitor for PR comments via GitHub MCP server tools
- Respond with Claude Code attribution
- Address requested changes using TDD discipline
- Create follow-up commits as needed

### J) COMPLETION

Use Task tool with `pr-manager` agent:

- Remove `.claude/plan.approved` file
- Generate summary of files changed and commits made
- Ensure PR remains in draft status for human review and merge

## Language-Specific Adaptations

### Rust
- Use `cargo nextest run` or `cargo test` for testing
- Use `cargo clippy -- -D warnings` for strict linting
- Focus on nutype domain types and Result error handling
- Emphasize memory safety and borrowing patterns

### TypeScript/Node.js
- Use Jest, Vitest, or project test framework
- Use ESLint and Prettier for code quality
- Focus on branded types and functional patterns
- Emphasize type safety and async/await patterns

### Python
- Use pytest for testing
- Use ruff for linting and formatting
- Focus on Pydantic models and type hints
- Emphasize clean architecture and dependency injection

### Elixir
- Use `mix test` for testing
- Use Credo for code analysis
- Focus on GenServer patterns and supervision trees
- Emphasize fault tolerance and message passing

## Memory Storage Verification

**MANDATORY FINAL STEP**: Verify all agents stored their knowledge:
1. Check that research findings were stored
2. Confirm planning decisions were captured
3. Verify RED, GREEN, and REFACTOR implementation patterns were saved
4. Ensure type improvements were documented
5. Confirm test hardening insights were stored
6. Verify expert analysis was preserved
7. Ensure PR workflow patterns were captured

**If any agent failed to store knowledge, request immediate remediation before marking story complete.**

## Information Request Routing Protocol

### Information Request Processing

During SPARC workflow execution, agents may include "Information Requests" sections in their responses. The coordinator MUST handle these by:

1. **Parse Information Requests**: Look for sections labeled "## Information Requests" or "### Information Requests" in agent responses
2. **Route to Target Agent**: Use Task tool to delegate each request to the appropriate agent
3. **Track Requests**: Maintain request tracking to prevent infinite loops and cycles
4. **Relay Responses**: Collect responses and provide them back to the requesting agent

### Request Format Recognition

Agents will format information requests as:

```markdown
## Information Requests

### Request 1: [Brief Description]
- **Target Agent**: [agent-name]
- **Request**: [specific information needed]
- **Context**: [why this information is needed]

### Request 2: [Brief Description]
- **Target Agent**: [agent-name]
- **Request**: [specific information needed]
- **Context**: [why this information is needed]
```

### Routing Logic

**Agent Specializations:**

- `researcher` → External docs, APIs, dependencies, best practices
- `planner` → Architecture decisions, implementation strategies, TDD plans
- `red-implementer` → Test writing, behavior capture, failure specification
- `green-implementer` → Minimal implementations, test satisfaction, simple solutions
- `refactor-implementer` → Code improvement, FCIS architecture, duplication removal
- `type-architect` → Domain types, type safety, API design
- `test-hardener` → Test coverage, invariants, property-based tests
- `expert` → Code review, soundness validation, optimization
- `pr-manager` → Git operations, branch status, PR management

### Multi-Agent Coordination Principles

- Coordinator is pure information router, never content creator
- Each agent maintains their specialized domain expertise
- Information flows through coordinator but is never modified
- Request chains enable collaborative problem-solving between agents
- Human escalation ensures complex coordination doesn't block progress

## Critical Rules

- Follow Kent Beck TDD discipline strictly: Red→Green→Refactor
- Use language-appropriate testing and quality tools
- Treat quality warnings as errors when possible
- **NEVER** add allow/ignore attributes without explicit team approval
- All new domain types must use language-appropriate type safety patterns
- Maintain functional core / imperative shell boundaries
- Use language-appropriate error handling patterns
- All commits include Claude Code attribution
- **MANDATORY MEMORY STORAGE**: Every agent MUST store knowledge after significant actions

## Memory Storage Enforcement

**CRITICAL**: After each agent completes a phase, you MUST verify they stored knowledge:

- **Researcher**: Must store research findings, sources, and patterns
- **Planner**: Must store planning decisions, strategies, and rationale
- **Red-Implementer**: Must store test patterns, behavior capture techniques, and failure strategies
- **Green-Implementer**: Must store minimal implementation patterns, solution strategies, and test satisfaction approaches
- **Refactor-Implementer**: Must store refactoring patterns, FCIS improvements, and code quality enhancements
- **Type-Architect**: Must store domain type designs, validation patterns, and decisions
- **Test-Hardener**: Must store test improvements and type strengthening patterns
- **Expert**: Must store architectural insights, quality patterns, and reviews
- **PR-Manager**: Must store workflow patterns, PR strategies, and outcomes

If an agent fails to store knowledge, **immediately request they do so before continuing**.

## Language Detection and Tool Configuration

**Language Detection Logic:**
```
if exists("Cargo.toml") → Rust
elif exists("package.json") → Node.js/TypeScript
elif exists("pyproject.toml") or exists("requirements.txt") → Python
elif exists("mix.exs") → Elixir
else → Ask user to specify language
```

**Configure appropriate MCP servers based on detected language for all subsequent agent operations.**