# ADR-007: Cloud Sync with Multiple Backends

## Status
Accepted

## Context
Users need to sync their development environment configuration across machines. Different users prefer different cloud providers.

## Decision
Implement a pluggable cloud sync system with 9 backends:
1. GitHub Gist (private)
2. GitLab Snippet
3. AWS S3 / MinIO
4. Google Cloud Storage
5. Azure Blob Storage
6. Dropbox
7. Google Drive
8. rsync over SSH
9. Syncthing (P2P)

Features: encryption, compression, conflict resolution, sync history.

## Consequences
- **Positive:** Users choose their preferred backend
- **Positive:** Works offline (rsync, Syncthing)
- **Positive:** Encrypted sync for sensitive configs
- **Negative:** Must maintain 9 backend implementations
- **Negative:** OAuth complexity for some backends

## Related
- Module: `src/lib/00s-cloud-sync.sh`
- CLI: `--cloud-upload`, `--cloud-download`, `--cloud-status`
