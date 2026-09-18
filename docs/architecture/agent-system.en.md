# Agent System Architecture

## Overview

The OpenCode Initializer uses a multi-agent architecture with specialized roles for different tasks.

## Agent Roles

### Commander (Orchestrator)
- Coordinates all agent activities
- Manages parallel execution
- Maintains loop state
- Delegates tasks to specialists

### Planner
- File-level planning
- TODO creation
- Task decomposition
- Dependency analysis

### Worker
- TDD implementation
- Follows Commander instructions
- Code generation
- Test writing

### Reviewer
- Async verification
- Integration testing
- Quality assurance
- Code review

## Communication Protocol

Agents communicate through:
1. **File-based IPC** — `.opencode/state/` directory
2. **WAL checkpoints** — Write-ahead log for state persistence
3. **Task delegation** — Structured task objects
4. **Result aggregation** — Collecting and synthesizing results

## Security Model

Each agent operates with:
- **Isolated execution** — Docker containers or MicroVMs
- **Minimal permissions** — Least privilege principle
- **Audit logging** — All actions recorded
- **Secret management** — Short-lived credentials

## Related Documentation

- [Agent Roles 2026](agent-roles-2026.md) — Detailed role definitions
- [Security Model](security-model-2026.md) — Security architecture
- [AIPDLC Integration](aipdlc-integration-guide.md) — Development lifecycle