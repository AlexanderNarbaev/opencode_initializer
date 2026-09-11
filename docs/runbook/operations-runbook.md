# OpenCode Initializer — Operations Runbook

## Table of Contents
1. [Quick Reference](#quick-reference)
2. [Installation](#installation)
3. [Health Checks](#health-checks)
4. [Troubleshooting](#troubleshooting)
5. [Maintenance](#maintenance)
6. [Emergency Procedures](#emergency-procedures)

---

## Quick Reference

### Essential Commands
```bash
# Full installation
./setup.sh --full

# Health check
./setup.sh --health

# Dry run (check without installing)
./setup.sh --dry-run

# Update everything
./setup.sh --sync

# Security scan
./setup.sh --security-scan

# Performance benchmark
./setup.sh --benchmark

# Start GUI dashboard
./setup.sh --gui-start

# View logs
tail -f ~/.local/state/opencode-init/setup.log
```

### Version Information
```bash
./setup.sh --version
cat package.json | grep version
```

---

## Installation

### First-Time Installation
```bash
# 1. Clone repository
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git
cd opencode_initializer

# 2. Run full installation
./setup.sh --full

# 3. Verify installation
./setup.sh --health
```

### Custom Configuration
```bash
# 1. Copy template
cp src/data/setup.toml.template setup.toml

# 2. Edit configuration
vim setup.toml

# 3. Install with custom config
./setup.sh --full --config=setup.toml
```

### Skip Specific Modules
```bash
# Skip devbox and GUI
./setup.sh --full --skip devbox,gui

# Skip multiple modules
./setup.sh --full --skip devbox,gui,caching,chromadb
```

### Parallel Installation
```bash
# Use 8 parallel jobs
./setup.sh --full --parallel 8

# Disable parallel (sequential)
./setup.sh --full --no-parallel
```

---

## Health Checks

### System Health
```bash
# Full health check
./setup.sh --health

# Check specific components
docker ps                    # Docker services
systemctl --user status opencode  # OpenCode service
```

### Service Health
```bash
# PostgreSQL
pg_isready -h localhost -p 5432

# Redis
redis-cli ping

# Qdrant
curl http://localhost:6333/healthz

# Prometheus
curl http://localhost:9090/-/healthy

# Grafana
curl http://localhost:3000/api/health
```

### Log Locations
```bash
# Main log
~/.local/state/opencode-init/setup.log

# WAL (Write-Ahead Log)
~/.local/state/opencode-init/wal.log

# Docker logs
docker logs postgres
docker logs redis
docker logs qdrant
```

---

## Troubleshooting

### Problem: Installation Fails

**Symptom:** `setup.sh` exits with error

**Solution:**
```bash
# 1. Check logs
tail -50 ~/.local/state/opencode-init/setup.log

# 2. Check WAL for partial state
cat ~/.local/state/opencode-init/wal.log

# 3. Resume from last checkpoint
./setup.sh --full  # Will skip completed steps

# 4. Force reinstall specific module
./setup.sh --full --force
```

### Problem: Docker Services Won't Start

**Symptom:** `docker ps` shows no containers

**Solution:**
```bash
# 1. Check Docker status
sudo systemctl status docker

# 2. Start Docker
sudo systemctl start docker

# 3. Check for port conflicts
sudo lsof -i :5432  # PostgreSQL
sudo lsof -i :6379  # Redis
sudo lsof -i :6333  # Qdrant

# 4. Restart infrastructure
cd ~/.local/share/opencode-init/infra
docker compose down
docker compose up -d
```

### Problem: Port Conflicts

**Symptom:** `Error: Port 5432 already in use`

**Solution:**
```bash
# 1. Find process using port
sudo lsof -i :5432

# 2. Kill process or change port in setup.toml
[ports]
postgres = 5433

# 3. Restart services
./setup.sh --health
```

### Problem: WAL Race Condition

**Symptom:** `Error: WAL write failed`

**Solution:**
```bash
# 1. Check WAL file
cat ~/.local/state/opencode-init/wal.log

# 2. Clear WAL and retry
rm ~/.local/state/opencode-init/wal.log
./setup.sh --full

# 3. If persistent, check disk space
df -h ~/.local/state/
```

### Problem: Module Installation Fails

**Symptom:** Specific module fails during installation

**Solution:**
```bash
# 1. Skip failing module
./setup.sh --full --skip <module-name>

# 2. Check module dependencies
grep "_deps()" src/lib/<module>.sh

# 3. Install dependencies manually
# (module-specific instructions in module file)

# 4. Retry with force
./setup.sh --full --force
```

### Problem: Tests Fail

**Symptom:** `test_*.sh` exits with non-zero

**Solution:**
```bash
# 1. Run specific test
bash tests/unit/test_core.sh

# 2. Check test output
bash tests/unit/test_core.sh 2>&1 | tail -20

# 3. Run all tests
for t in tests/unit/test_*.sh; do
  echo "--- $(basename $t) ---"
  bash "$t" 2>&1 | tail -3
done
```

---

## Maintenance

### Daily Tasks
```bash
# Check for updates
./setup.sh --sync

# Security scan
./setup.sh --security-scan

# Check disk usage
du -sh ~/.local/share/opencode-init/
du -sh ~/.cache/opencode-init/
```

### Weekly Tasks
```bash
# Full benchmark
./setup.sh --benchmark

# Clean old cache
./setup.sh --cache-cleanup

# Update documentation
./setup.sh --sync-force
```

### Monthly Tasks
```bash
# Review security report
cat ~/.local/state/opencode-init/security-report.json

# Check for new plugin versions
./setup.sh --discover-plugins

# Update session checkpoint
./setup.sh --health
```

### Backup Configuration
```bash
# Export configuration
cp setup.toml setup.toml.backup.$(date +%Y%m%d)

# Export to cloud
./setup.sh --cloud-upload

# Import from cloud
./setup.sh --cloud-download
```

---

## Emergency Procedures

### Complete Reset
```bash
# 1. Stop all services
docker compose -f ~/.local/share/opencode-init/infra/docker-compose.yml down

# 2. Remove state
rm -rf ~/.local/state/opencode-init/

# 3. Remove cache
rm -rf ~/.cache/opencode-init/

# 4. Reinstall
./setup.sh --full
```

### Rollback to Previous Version
```bash
# 1. Checkout previous version
git log --oneline -10
git checkout <previous-commit>

# 2. Reinstall
./setup.sh --full

# 3. Return to latest
git checkout main
```

### Fix Corrupted Database
```bash
# 1. Stop PostgreSQL
docker stop postgres

# 2. Backup data
cp -r ~/.local/share/opencode-init/infra/pgdata ~/.local/share/opencode-init/infra/pgdata.backup

# 3. Remove corrupted data
rm -rf ~/.local/share/opencode-init/infra/pgdata

# 4. Restart
docker compose -f ~/.local/share/opencode-init/infra/docker-compose.yml up -d postgres

# 5. Restore from backup if needed
# (pg_restore or manual migration)
```

### Emergency Contacts
- **GitHub Issues:** https://github.com/AlexanderNarbaev/opencode_initializer/issues
- **Documentation:** https://alexandernarbaev.github.io/opencode_initializer/

---

## Appendix

### Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `OPENCODE_INIT_CONFIG` | Config file path | `setup.toml` |
| `OPENCODE_INIT_LOG_LEVEL` | Log level | `info` |
| `OPENCODE_INIT_PARALLEL` | Parallel jobs | `4` |
| `OPENCODE_INIT_MIRRORS` | Mirror region | `global` |

### File Locations
| Path | Description |
|------|-------------|
| `~/.local/state/opencode-init/` | State files |
| `~/.local/share/opencode-init/` | Data files |
| `~/.cache/opencode-init/` | Cache files |
| `~/.config/opencode/` | OpenCode config |

### Port Allocation
| Service | Port | Override |
|---------|------|----------|
| PostgreSQL | 5432 | `PORTS_POSTGRES` |
| Redis | 6379 | `PORTS_REDIS` |
| Qdrant | 6333 | `PORTS_QDRANT` |
| Prometheus | 9090 | `PORTS_PROMETHEUS` |
| Grafana | 3000 | `PORTS_GRAFANA` |
| GUI | 4200 | `GUI_PORT` |
| WebUI | 3080 | `PORTS_WEBUI` |
