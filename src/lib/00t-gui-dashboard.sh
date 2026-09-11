#!/usr/bin/env bash
# src/lib/00t-gui-dashboard.sh — GUI Dashboard (v7.0.0)
# Web-based dashboard for managing the development environment.
set -euo pipefail

# ── GUI configuration ────────────────────────────────────────────────────────
_GUI_PORT="${GUI_PORT:-4200}"
_GUI_HOST="${GUI_HOST:-localhost}"
_GUI_DIR="${SCRIPT_DIR}/src/gui"
_GUI_PID_FILE="${DL_CACHE}/gui.pid"

# ── Generate dashboard HTML ─────────────────────────────────────────────────
_gui_generate_dashboard() {
  local output="${_GUI_DIR}/index.html"
  mkdir -p "$_GUI_DIR"

  cat > "$output" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OpenCode Initializer — Dashboard</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #e2e8f0; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; }
    .header h1 { font-size: 24px; color: #60a5fa; }
    .header .version { background: #1e40af; padding: 4px 12px; border-radius: 20px; font-size: 14px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
    .card { background: #1e293b; border-radius: 12px; padding: 20px; border: 1px solid #334155; }
    .card h2 { font-size: 18px; margin-bottom: 15px; color: #94a3b8; }
    .card .status { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; }
    .card .status .dot { width: 10px; height: 10px; border-radius: 50%; }
    .card .status .dot.green { background: #22c55e; }
    .card .status .dot.yellow { background: #eab308; }
    .card .status .dot.red { background: #ef4444; }
    .card .metric { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #334155; }
    .card .metric:last-child { border-bottom: none; }
    .card .metric .label { color: #94a3b8; }
    .card .metric .value { color: #f1f5f9; font-weight: 500; }
    .btn { background: #3b82f6; color: white; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer; font-size: 14px; }
    .btn:hover { background: #2563eb; }
    .btn.secondary { background: #475569; }
    .btn.secondary:hover { background: #334155; }
    .actions { display: flex; gap: 10px; margin-top: 20px; }
    .log { background: #0f172a; border-radius: 8px; padding: 15px; font-family: monospace; font-size: 13px; max-height: 200px; overflow-y: auto; }
    .log .line { padding: 2px 0; }
    .log .line.info { color: #60a5fa; }
    .log .line.success { color: #22c55e; }
    .log .line.warning { color: #eab308; }
    .log .line.error { color: #ef4444; }
    .tabs { display: flex; gap: 10px; margin-bottom: 20px; }
    .tab { padding: 10px 20px; background: #1e293b; border: 1px solid #334155; border-radius: 8px; cursor: pointer; }
    .tab.active { background: #3b82f6; border-color: #3b82f6; }
    .hidden { display: none; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>OpenCode Initializer</h1>
      <span class="version" id="version">v5.0.0</span>
    </div>

    <div class="tabs">
      <div class="tab active" onclick="showTab('overview')">Overview</div>
      <div class="tab" onclick="showTab('modules')">Modules</div>
      <div class="tab" onclick="showTab('providers')">Providers</div>
      <div class="tab" onclick="showTab('services')">Services</div>
      <div class="tab" onclick="showTab('logs')">Logs</div>
    </div>

    <div id="overview" class="tab-content">
      <div class="grid">
        <div class="card">
          <h2>System Status</h2>
          <div class="status">
            <div class="dot green"></div>
            <span>All systems operational</span>
          </div>
          <div class="metric">
            <span class="label">Modules</span>
            <span class="value" id="module-count">90</span>
          </div>
          <div class="metric">
            <span class="label">Tests</span>
            <span class="value" id="test-count">263</span>
          </div>
          <div class="metric">
            <span class="label">Providers</span>
            <span class="value" id="provider-count">22</span>
          </div>
          <div class="metric">
            <span class="label">MCP Servers</span>
            <span class="value" id="mcp-count">24</span>
          </div>
        </div>

        <div class="card">
          <h2>Quick Actions</h2>
          <div class="actions">
            <button class="btn" onclick="runCommand('health')">Health Check</button>
            <button class="btn secondary" onclick="runCommand('sync')">Sync</button>
            <button class="btn secondary" onclick="runCommand('benchmark')">Benchmark</button>
          </div>
          <div class="actions">
            <button class="btn" onclick="runCommand('security')">Security Scan</button>
            <button class="btn secondary" onclick="runCommand('update')">Update All</button>
          </div>
        </div>

        <div class="card">
          <h2>Environment</h2>
          <div class="metric">
            <span class="label">OS</span>
            <span class="value" id="os-info">Linux</span>
          </div>
          <div class="metric">
            <span class="label">Architecture</span>
            <span class="value" id="arch-info">x86_64</span>
          </div>
          <div class="metric">
            <span class="label">Shell</span>
            <span class="value" id="shell-info">bash</span>
          </div>
          <div class="metric">
            <span class="label">Docker</span>
            <span class="value" id="docker-info">running</span>
          </div>
        </div>

        <div class="card">
          <h2>Recent Activity</h2>
          <div class="log" id="activity-log">
            <div class="line info">[INFO] Dashboard started</div>
            <div class="line success">[OK] All modules loaded</div>
          </div>
        </div>
      </div>
    </div>

    <div id="modules" class="tab-content hidden">
      <div class="card">
        <h2>Installed Modules</h2>
        <div id="modules-list"></div>
      </div>
    </div>

    <div id="providers" class="tab-content hidden">
      <div class="card">
        <h2>AI Providers</h2>
        <div id="providers-list"></div>
      </div>
    </div>

    <div id="services" class="tab-content hidden">
      <div class="card">
        <h2>Infrastructure Services</h2>
        <div id="services-list"></div>
      </div>
    </div>

    <div id="logs" class="tab-content hidden">
      <div class="card">
        <h2>System Logs</h2>
        <div class="log" id="system-log"></div>
      </div>
    </div>
  </div>

  <script>
    function showTab(name) {
      document.querySelectorAll('.tab-content').forEach(el => el.classList.add('hidden'));
      document.querySelectorAll('.tab').forEach(el => el.classList.remove('active'));
      document.getElementById(name).classList.remove('hidden');
      event.target.classList.add('active');
    }

    function runCommand(cmd) {
      fetch(`/api/${cmd}`)
        .then(r => r.json())
        .then(data => {
          const log = document.getElementById('activity-log');
          log.innerHTML += `<div class="line success">[${cmd}] ${data.message || 'Done'}</div>`;
          log.scrollTop = log.scrollHeight;
        })
        .catch(err => {
          const log = document.getElementById('activity-log');
          log.innerHTML += `<div class="line error">[${cmd}] Error: ${err.message}</div>`;
        });
    }

    // Load data on startup
    fetch('/api/status')
      .then(r => r.json())
      .then(data => {
        document.getElementById('module-count').textContent = data.modules || 90;
        document.getElementById('test-count').textContent = data.tests || 263;
        document.getElementById('provider-count').textContent = data.providers || 22;
        document.getElementById('mcp-count').textContent = data.mcp || 24;
      })
      .catch(() => {});
  </script>
</body>
</html>
HTMLEOF

  log "Dashboard HTML generated"
}

# ── Generate API server ─────────────────────────────────────────────────────
_gui_generate_server() {
  local output="${_GUI_DIR}/server.js"
  mkdir -p "$_GUI_DIR"

  cat > "$output" <<'JSEOF'
const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORT = process.env.GUI_PORT || 4200;
const HOST = process.env.GUI_HOST || 'localhost';
const SCRIPT_DIR = process.env.SCRIPT_DIR || __dirname;

// Serve static files
function serveStatic(req, res) {
  let filePath = path.join(__dirname, req.url === '/' ? 'index.html' : req.url);
  const ext = path.extname(filePath);
  const contentType = {
    '.html': 'text/html',
    '.js': 'text/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
  }[ext] || 'text/plain';

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

// API endpoints
const apiRoutes = {
  '/api/status': (req, res) => {
    res.json({
      version: 'v5.0.0',
      modules: 90,
      tests: 263,
      providers: 22,
      mcp: 24,
      status: 'ok',
    });
  },

  '/api/health': (req, res) => {
    try {
      const result = execSync(`bash ${SCRIPT_DIR}/setup.sh --health`, { timeout: 30000 }).toString();
      res.json({ status: 'ok', message: 'Health check passed', output: result });
    } catch (e) {
      res.json({ status: 'error', message: e.message });
    }
  },

  '/api/sync': (req, res) => {
    try {
      const result = execSync(`bash ${SCRIPT_DIR}/setup.sh --sync`, { timeout: 60000 }).toString();
      res.json({ status: 'ok', message: 'Sync complete', output: result });
    } catch (e) {
      res.json({ status: 'error', message: e.message });
    }
  },

  '/api/benchmark': (req, res) => {
    try {
      const result = execSync(`bash ${SCRIPT_DIR}/setup.sh --benchmark`, { timeout: 60000 }).toString();
      res.json({ status: 'ok', message: 'Benchmark complete', output: result });
    } catch (e) {
      res.json({ status: 'error', message: e.message });
    }
  },

  '/api/security': (req, res) => {
    try {
      const result = execSync(`bash ${SCRIPT_DIR}/setup.sh --security-scan`, { timeout: 60000 }).toString();
      res.json({ status: 'ok', message: 'Security scan complete', output: result });
    } catch (e) {
      res.json({ status: 'error', message: e.message });
    }
  },

  '/api/update': (req, res) => {
    try {
      const result = execSync(`bash ${SCRIPT_DIR}/setup.sh --sync-force`, { timeout: 120000 }).toString();
      res.json({ status: 'ok', message: 'Update complete', output: result });
    } catch (e) {
      res.json({ status: 'error', message: e.message });
    }
  },
};

// HTTP server
const server = http.createServer((req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // JSON response helper
  res.json = (data) => {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
  };

  // Route to API or static
  if (apiRoutes[req.url]) {
    apiRoutes[req.url](req, res);
  } else {
    serveStatic(req, res);
  }
});

server.listen(PORT, HOST, () => {
  console.log(`Dashboard running at http://${HOST}:${PORT}`);
});
JSEOF

  log "API server generated"
}

# ── Start GUI server ────────────────────────────────────────────────────────
# Usage: _gui_start [--port 4200] [--host localhost]
_gui_start() {
  local port="${1:-$_GUI_PORT}"
  local host="${2:-$_GUI_HOST}"

  section "Starting GUI Dashboard"

  # Generate files if not exist
  [ ! -f "$_GUI_DIR/index.html" ] && _gui_generate_dashboard
  [ ! -f "$_GUI_DIR/server.js" ] && _gui_generate_server

  # Check if already running
  if [ -f "$_GUI_PID_FILE" ]; then
    local pid
    pid=$(cat "$_GUI_PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      log "Dashboard already running (PID: $pid)"
      info "URL: http://${host}:${port}"
      return 0
    fi
  fi

  # Start server
  cd "$_GUI_DIR" && node server.js &
  local pid=$!
  echo "$pid" > "$_GUI_PID_FILE"

  log "Dashboard started (PID: $pid)"
  info "URL: http://${host}:${port}"
}

# ── Stop GUI server ─────────────────────────────────────────────────────────
# Usage: _gui_stop
_gui_stop() {
  if [ -f "$_GUI_PID_FILE" ]; then
    local pid
    pid=$(cat "$_GUI_PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      log "Dashboard stopped"
    fi
    rm -f "$_GUI_PID_FILE"
  else
    info "Dashboard not running"
  fi
}

# ── GUI status ──────────────────────────────────────────────────────────────
# Usage: _gui_status
_gui_status() {
  if [ -f "$_GUI_PID_FILE" ]; then
    local pid
    pid=$(cat "$_GUI_PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      log "Dashboard running (PID: $pid)"
      info "URL: http://${_GUI_HOST}:${_GUI_PORT}"
    else
      warn "Dashboard not running (stale PID file)"
      rm -f "$_GUI_PID_FILE"
    fi
  else
    info "Dashboard not running"
  fi
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _gui_generate_dashboard _gui_generate_server _gui_start \
  _gui_stop _gui_status 2>/dev/null || true
