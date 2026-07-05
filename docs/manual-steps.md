# Manual Steps — blocked by config zone

## 1. mkdocs.yml — add Comparison to navigation

Insert between "Team Setup" and "Changelog":
```yaml
  - Comparison: comparison.md
```

## 2. mkdocs.yml — add agent-system to Architecture nav

Change `- Architecture: architecture/index.md` to:
```yaml
  - Architecture:
      - Overview: architecture/index.md
      - Agent System: architecture/agent-system.md
```

## 3. Verify site builds

```bash
mkdocs build --strict
```
