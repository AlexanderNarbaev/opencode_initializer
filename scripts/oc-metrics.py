#!/usr/bin/env python3
"""
OpenCode Metrics Exporter — Prometheus /metrics endpoint on port 9464.

Exposes real-time observability data from:
  - Sessions (count, status, project distribution)
  - WAL (agent journal entries, domain breakdown, S1/S2 ratio)
  - Docker containers (status, uptime)
  - Ollama models (count, total size)
  - OpenCode config (active model, providers, MCPs, agents, plugins)
  - Setup progress (completed steps, run count)
  - Model router (task profiles, active model)
  - System (CPU, RAM, disk via psutil)

Usage: python3 oc-metrics.py [--port 9464]
"""

import os
import sys
import json
import time
import glob
import subprocess
import http.server
from pathlib import Path
from datetime import datetime, timezone
from collections import Counter

HOME = Path.home()
CONFIG_DIR = HOME / ".config" / "opencode"
SETUP_DIR = HOME / ".config" / "opencode-setup"
CACHE_DIR = HOME / ".cache" / "opencode"
SETUP_CACHE = HOME / ".cache" / "opencode-setup"
PORT = int(os.environ.get("METRICS_EXPORTER_PORT", os.environ.get("METRICS_PORT", "9464")))

# ── Helpers ──────────────────────────────────────────────────────────────

def safe_read_json(path, default=None):
    """Read JSON file, strip comments, return dict or default."""
    try:
        raw = Path(path).read_text(encoding="utf-8")
        # strip // and /* */ comments
        raw = "\n".join(
            line.split("//")[0] if "//" in line and '"' not in line else line
            for line in raw.split("\n")
        )
        return json.loads(raw)
    except Exception:
        return default if default is not None else {}

def safe_read_lines(path, tail=0):
    try:
        lines = Path(path).read_text().strip().split("\n")
        return lines[-tail:] if tail else lines
    except Exception:
        return []

def run(cmd, timeout=5):
    try:
        return subprocess.check_output(cmd, timeout=timeout, text=True).strip()
    except Exception:
        return ""

def prom_metric(name, value, labels=None, help_text=""):
    """Format a Prometheus metric line."""
    out = f"# HELP {name} {help_text}\n# TYPE {name} gauge\n"
    label_str = ""
    if labels:
        label_str = "{" + ",".join(f'{k}="{v}"' for k, v in labels.items()) + "}"
    out += f"{name}{label_str} {value}\n"
    return out

# ── Collectors ──────────────────────────────────────────────────────────

def collect_sessions():
    """Count sessions by status, project, and memory entries."""
    metrics = []
    sessions_dir = CONFIG_DIR / "sessions"
    if not sessions_dir.is_dir():
        metrics.append(prom_metric("opencode_sessions_total", 0, {}, "Total session directories"))
        return metrics

    sessions = list(sessions_dir.iterdir())
    total = 0
    active = 0
    idle = 0
    completed = 0
    projects = Counter()

    for s in sessions:
        if not s.is_dir():
            continue
        total += 1
        # detect status
        status = "unknown"
        status_path = s / "status.json"
        state_path = s / "state.json"
        if status_path.exists():
            data = safe_read_json(status_path)
            status = data.get("status", "unknown")
        elif state_path.exists():
            data = safe_read_json(state_path)
            if data.get("active"):
                status = "active"
        else:
            # fallback: check mtime
            mtime = s.stat().st_mtime
            age_hours = (time.time() - mtime) / 3600
            status = "active" if age_hours < 1 else ("idle" if age_hours < 24 else "completed")

        if status == "active":
            active += 1
        elif status == "idle":
            idle += 1
        elif status == "completed":
            completed += 1

        # detect project
        if state_path.exists():
            data = safe_read_json(state_path)
            project = data.get("project", "") or data.get("title", "") or data.get("cwd", "")
            if project:
                projects[Path(project).name if "/" in project else project] += 1

    metrics.append(prom_metric("opencode_sessions_total", total, {}, "Total sessions"))
    metrics.append(prom_metric("opencode_sessions_active", active, {}, "Active sessions"))
    metrics.append(prom_metric("opencode_sessions_idle", idle, {}, "Idle sessions"))
    metrics.append(prom_metric("opencode_sessions_completed", completed, {}, "Completed sessions"))
    for proj, count in projects.items():
        metrics.append(prom_metric("opencode_sessions_by_project", count, {"project": proj}, "Sessions per project"))
    return metrics


def collect_wal():
    """WAL entry count, domain distribution, S1/S2 ratio, average confidence."""
    metrics = []
    wal_path = CACHE_DIR / "wal.jsonl"
    if not wal_path.exists():
        metrics.append(prom_metric("opencode_wal_entries_total", 0, {}, "Total WAL entries"))
        return metrics

    entries = []
    for line in safe_read_lines(wal_path):
        try:
            entries.append(json.loads(line.strip()))
        except Exception:
            continue

    total = len(entries)
    metrics.append(prom_metric("opencode_wal_entries_total", total, {}, "Total WAL entries"))

    domains = Counter(e.get("domain", "unknown") for e in entries)
    for domain, count in domains.items():
        metrics.append(prom_metric("opencode_wal_entries_by_domain", count, {"domain": domain}, "WAL entries by domain"))

    s1 = sum(1 for e in entries if e.get("mode") == "S1")
    s2 = total - s1
    metrics.append(prom_metric("opencode_wal_s1_ratio", s1 / max(total, 1), {}, "WAL S1 ratio"))
    metrics.append(prom_metric("opencode_wal_s2_ratio", s2 / max(total, 1), {}, "WAL S2 ratio"))

    avg_conf = sum(e.get("confidence", 0) for e in entries) / max(total, 1)
    metrics.append(prom_metric("opencode_wal_avg_confidence", avg_conf, {}, "WAL average confidence"))

    return metrics


def collect_containers():
    """Docker container status (1 = running, 0 = stopped/absent)."""
    metrics = []
    infra_yml = CONFIG_DIR / "infra.yml"
    known = []
    if infra_yml.exists():
        text = infra_yml.read_text()
        for line in text.split("\n"):
            line = line.strip()
            if line.startswith("container_name:"):
                name = line.split(":", 1)[1].strip()
                if name not in known:
                    known.append(name)

    if not known:
        out = run(["docker", "ps", "--format", "{{.Names}}"])
        known = out.split("\n") if out else []

    # Check each known container
    running_list = run(["docker", "ps", "--format", "{{.Names}}"]).split("\n")
    running_set = set(running_list)

    for name in sorted(set(known)):
        is_running = 1 if name in running_set else 0
        metrics.append(prom_metric("opencode_container_up", is_running, {"container": name}, "Container running status (1=up, 0=down)"))

    # Also check open-webui (not in infra.yml but relevant)
    if "open-webui" in running_set:
        metrics.append(prom_metric("opencode_container_up", 1, {"container": "open-webui"}, "Container running status"))

    metrics.append(prom_metric("opencode_containers_total", len(running_set), {}, "Total running containers"))
    return metrics


def collect_ollama():
    """Ollama model count and total size."""
    metrics = []
    out = run(["ollama", "list"])
    if not out:
        metrics.append(prom_metric("opencode_ollama_models_total", 0, {}, "Ollama models count"))
        metrics.append(prom_metric("opencode_ollama_size_bytes", 0, {}, "Ollama total model size bytes"))
        return metrics

    lines = out.strip().split("\n")[1:]  # skip header
    model_count = 0
    total_bytes = 0
    for line in lines:
        parts = line.strip().split()
        if len(parts) >= 3:
            model_count += 1
            size_str = parts[-2] if len(parts) >= 4 else parts[-1]
            try:
                if "GB" in size_str:
                    total_bytes += float(size_str.replace("GB", "")) * 1e9
                elif "MB" in size_str:
                    total_bytes += float(size_str.replace("MB", "")) * 1e6
                elif "KB" in size_str:
                    total_bytes += float(size_str.replace("KB", "")) * 1e3
            except ValueError:
                pass

    metrics.append(prom_metric("opencode_ollama_models_total", model_count, {}, "Ollama models count"))
    metrics.append(prom_metric("opencode_ollama_size_bytes", int(total_bytes), {}, "Ollama total model size bytes"))
    return metrics


def collect_config():
    """Active model, providers, MCPs, agents, plugins from opencode.json."""
    metrics = []
    cfg = safe_read_json(CONFIG_DIR / "opencode.json")
    if not cfg:
        return metrics

    # Active model
    model = cfg.get("model", "unknown")
    metrics.append(prom_metric("opencode_config_info", 1, {"model": str(model), "small_model": str(cfg.get("small_model", "")), "agent": str(cfg.get("default_agent", ""))}, "OpenCode active configuration"))

    providers = len(cfg.get("provider", {}))
    mcps = len(cfg.get("mcp", {}))
    lsps = len(cfg.get("lsp", {}))
    agents = len(cfg.get("agents", {}))
    plugins = len(cfg.get("plugins", []))

    metrics.append(prom_metric("opencode_providers_total", providers, {}, "Configured AI providers"))
    metrics.append(prom_metric("opencode_mcp_servers_total", mcps, {}, "MCP servers configured"))
    metrics.append(prom_metric("opencode_lsp_servers_total", lsps, {}, "LSP servers configured"))
    metrics.append(prom_metric("opencode_agents_total", agents, {}, "Agent definitions"))
    metrics.append(prom_metric("opencode_plugins_total", plugins, {}, "Registered plugins"))

    # Experimental features
    exp = cfg.get("experimental", {})
    for key in ["openTelemetry", "token_counter", "performance_stats", "context_tracker"]:
        val = 1 if exp.get(key) else 0
        metrics.append(prom_metric(f"opencode_experimental_{key}", val, {}, f"Experimental feature {key}"))

    return metrics


def collect_setup():
    """Setup progress: completed steps, run count, log size."""
    metrics = []
    progress_file = SETUP_CACHE / "progress"
    if progress_file.exists():
        lines = safe_read_lines(progress_file)
        steps = sum(1 for l in lines if l.strip() and not l.strip().startswith("#"))
        metrics.append(prom_metric("opencode_setup_steps_completed", steps, {}, "Completed setup steps"))
    else:
        metrics.append(prom_metric("opencode_setup_steps_completed", 0, {}, "Completed setup steps"))

    # Setup log runs
    log_pattern = str(SETUP_CACHE / "setup-*.log")
    log_files = glob.glob(log_pattern)
    metrics.append(prom_metric("opencode_setup_runs_total", len(log_files), {}, "Total setup runs"))

    # Total log lines
    total_lines = sum(len(safe_read_lines(f)) for f in log_files)
    metrics.append(prom_metric("opencode_setup_log_lines_total", total_lines, {}, "Total setup log lines"))

    return metrics


def collect_router():
    """Task profiles count, active model recommendations."""
    metrics = []
    profiles_path = CONFIG_DIR / "model-router" / "task-profiles.json"
    if profiles_path.exists():
        profiles = safe_read_json(profiles_path)
        if isinstance(profiles, dict):
            metrics.append(prom_metric("opencode_task_profiles_total", len(profiles), {}, "Task profiles for model routing"))
            for task, p in profiles.items():
                metrics.append(prom_metric("opencode_task_profile_info", 1, {"task": task, "model": str(p.get("model", "unknown"))}, "Task profile mapping"))
    else:
        metrics.append(prom_metric("opencode_task_profiles_total", 0, {}, "Task profiles for model routing"))
    return metrics


def collect_system():
    """System metrics via psutil if available."""
    metrics = []
    try:
        import psutil
    except ImportError:
        return metrics

    # CPU
    cpu_pct = psutil.cpu_percent(interval=0.3)
    cpu_count = psutil.cpu_count()
    metrics.append(prom_metric("opencode_system_cpu_percent", cpu_pct, {}, "System CPU usage %"))
    metrics.append(prom_metric("opencode_system_cpu_count", cpu_count, {}, "CPU cores"))

    # RAM
    mem = psutil.virtual_memory()
    metrics.append(prom_metric("opencode_system_memory_bytes", mem.used, {"type": "used"}, "Memory used bytes"))
    metrics.append(prom_metric("opencode_system_memory_bytes", mem.total, {"type": "total"}, "Memory total bytes"))
    metrics.append(prom_metric("opencode_system_memory_percent", mem.percent, {}, "Memory usage %"))

    # Disk
    disk = psutil.disk_usage(str(HOME))
    metrics.append(prom_metric("opencode_system_disk_bytes", disk.used, {"type": "used"}, "Disk used bytes"))
    metrics.append(prom_metric("opencode_system_disk_bytes", disk.total, {"type": "total"}, "Disk total bytes"))
    metrics.append(prom_metric("opencode_system_disk_percent", disk.percent, {}, "Disk usage %"))

    # Uptime
    boot = datetime.fromtimestamp(psutil.boot_time(), tz=timezone.utc)
    uptime_seconds = (datetime.now(tz=timezone.utc) - boot).total_seconds()
    metrics.append(prom_metric("opencode_system_uptime_seconds", int(uptime_seconds), {}, "System uptime seconds"))

    return metrics


# ── HTTP Handler ────────────────────────────────────────────────────────

class MetricsHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/metrics":
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            html = """<html>
<head><title>OpenCode Metrics Exporter</title></head>
<body>
<h1>OpenCode Metrics Exporter</h1>
<p>Prometheus metrics available at <a href="/metrics">/metrics</a></p>
<pre>""" + time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()) + """</pre>
</body></html>"""
            self.wfile.write(html.encode())
            return

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()

        output = []
        try:
            output.extend(collect_sessions())
        except Exception as e:
            output.append(f"# ERROR sessions: {e}\n")
        try:
            output.extend(collect_wal())
        except Exception as e:
            output.append(f"# ERROR wal: {e}\n")
        try:
            output.extend(collect_containers())
        except Exception as e:
            output.append(f"# ERROR containers: {e}\n")
        try:
            output.extend(collect_ollama())
        except Exception as e:
            output.append(f"# ERROR ollama: {e}\n")
        try:
            output.extend(collect_config())
        except Exception as e:
            output.append(f"# ERROR config: {e}\n")
        try:
            output.extend(collect_setup())
        except Exception as e:
            output.append(f"# ERROR setup: {e}\n")
        try:
            output.extend(collect_router())
        except Exception as e:
            output.append(f"# ERROR router: {e}\n")
        try:
            output.extend(collect_system())
        except Exception as e:
            output.append(f"# ERROR system: {e}\n")

        # Health and deployment profile gauges
        output.append(prom_metric("opencode_metrics_up", 1, {}, "Metrics exporter health"))
        profile = os.environ.get("DEPLOYMENT_PROFILE", "personal")
        output.append(prom_metric("opencode_deployment_profile_info", 1, {"profile": profile}, "Deployment profile"))

        self.wfile.write("".join(output).encode())

    def log_message(self, format, *args):
        pass  # suppress logs


def main():
    print(f"OpenCode Metrics Exporter starting on port {PORT}")
    print(f"Endpoint: http://localhost:{PORT}/metrics")
    server = http.server.HTTPServer(("0.0.0.0", PORT), MetricsHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.shutdown()


if __name__ == "__main__":
    main()
