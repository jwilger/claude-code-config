# CLAUDE.md

This file provides guidance to Claude Code when working with this rust project.

## SPARC Workflow Integration

This project uses the SPARC workflow with GitHub pull requests and memory storage.

## Language: rust

### Testing
\`\`\`bash
cargo nextest run || cargo test
\`\`\`

### Linting  
\`\`\`bash
cargo clippy -- -D warnings
\`\`\`

### Formatting
\`\`\`bash
cargo fmt
\`\`\`

## Quality Standards

- Follow TDD principles with Red→Green→Refactor cycles
- Maintain comprehensive test coverage
- Use type-driven development where applicable
- Store knowledge in MCP memory after each SPARC phase
