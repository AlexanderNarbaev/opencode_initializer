# ADR-008: Container Infrastructure

## Status
Accepted

## Context
Company specialists (developers, analysts, designers) need reproducible environments for opencode_initializer. Manual setup is error-prone and time-consuming.

## Decision
Use Docker containers for enterprise deployment with:
- Multi-stage Dockerfile for smaller images
- docker-compose.yml with 5 profiles (default, infra, monitoring, mcp, lsp, full)
- Non-root user for security
- Health checks for reliability
- Volume mounts for configuration updates

## Consequences
- **Positive:** One-command deployment for all roles
- **Positive:** Security isolation between services
- **Positive:** Easy configuration updates via volume mounts
- **Positive:** Reproducible environments across teams
- **Negative:** Docker dependency required
- **Negative:** Container overhead for simple use cases

## Related
- Dockerfile: `Dockerfile`
- docker-compose.yml: `docker-compose.yml`
- Container scripts: `scripts/container-*.sh`
- Container docs: `docs/container/README.md`
