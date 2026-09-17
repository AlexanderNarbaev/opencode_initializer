# ADR-011: Agent Architecture

## Status
Accepted

## Context
Need structured multi-agent workflow for complex development tasks. Different agents have different capabilities and responsibilities.

## Decision
Implement Commander/Planner/Worker/Reviewer hierarchy:
- **Commander** — orchestrator, parallel execution, loop state
- **Planner** — file-level planning, TODO creation
- **Worker** — TDD implementation, follows Commander
- **Reviewer** — async verification, integration testing

## Consequences
- **Positive:** Clear separation of concerns
- **Positive:** Parallel execution of independent tasks
- **Positive:** Quality gates through Reviewer
- **Positive:** Scalable architecture
- **Negative:** Coordination overhead
- **Negative:** Context sharing complexity

## Related
- Task distributor: `src/lib/54-task-distributor.sh`
- Agent orchestrator: `src/lib/66-agent-orchestrator.sh`
- Agent roles docs: `docs/architecture/agent-roles-2026.md`
