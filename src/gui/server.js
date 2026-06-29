#!/usr/bin/env node
'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORT = process.env.GUI_PORT || 4200;
const HOST = process.env.GUI_HOST || '127.0.0.1';
const INFRA_FILE = path.join(process.env.HOME, '.config', 'opencode', 'infra.yml');
const PLUGINS_FILE = path.join(process.env.HOME, '.config', 'opencode', 'plugins.json');
const SESSIONS_DIR = path.join(process.env.HOME, '.config', 'opencode', 'sessions');
const CACHE_TTL = 5000;

let cache = { status: null, infra: null, plugins: null };
let lastFetch = 0;

function jsonResponse(res, code, data) {
  res.writeHead(code, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Cache-Control': 'no-cache'
  });
  res.end(JSON.stringify(data));
}

function htmlResponse(res, code, html) {
  res.writeHead(code, {
    'Content-Type': 'text/html; charset=utf-8',
    'Cache-Control': 'no-cache'
  });
  res.end(html);
}

function safeExec(command) {
  try {
    return execSync(command, { timeout: 10000, encoding: 'utf8' }).trim();
  } catch {
    return null;
  }
}

function getDockerStatus() {
  const containers = {};
  const raw = safeExec('docker ps -a --format "{{.Names}}\t{{.State}}\t{{.Image}}" 2>/dev/null') || '';
  raw.split('\n').filter(Boolean).forEach(line => {
    const parts = line.split('\t');
    if (parts.length >= 3) {
      containers[parts[0]] = { running: parts[1] === 'running', state: parts[1], image: parts[2] };
    }
  });
  return containers;
}

function getSystemdServices() {
  const services = {};
  const names = ['open-webui', 'opencode-gui', 'chromadb', 'ollama'];
  const raw = safeExec('systemctl --user list-units --type=service --no-pager --no-legend 2>/dev/null') || '';
  names.forEach(name => {
    const re = new RegExp(name + '\\S*', 'i');
    const matched = raw.split('\n').filter(Boolean).find(line => re.test(line.split(/\s+/)[0] || ''));
    if (matched) {
      const [unit] = matched.trim().split(/\s+/);
      const active = matched.includes(' active ');
      services[unit] = { running: active, state: active ? 'active' : 'inactive' };
    } else {
      services[name] = { running: false, state: 'not found' };
    }
  });
  return services;
}

function getCockpitVersion() {
  try {
    const pkg = require(path.join(process.env.HOME, 'opencode_initializer', 'package.json'));
    return pkg.version || 'unknown';
  } catch {
    return safeExec('git -C ~/opencode_initializer describe --tags --always 2>/dev/null') || 'v1.1.0';
  }
}

function getInfraServices() {
  if (!fs.existsSync(INFRA_FILE)) return { error: 'infra.yml not found', services: [] };
  const raw = safeExec('docker compose -f "' + INFRA_FILE + '" ps --format json 2>/dev/null');
  if (!raw) return { services: [] };
  return { services: raw.split('\n').filter(Boolean).map(line => {
    try { return JSON.parse(line); } catch { return { raw: line }; }
  })};
}

function getPlugins() {
  if (!fs.existsSync(PLUGINS_FILE)) return { error: 'plugins.json not found', plugins: {} };
  try {
    return { plugins: JSON.parse(fs.readFileSync(PLUGINS_FILE, 'utf8')) };
  } catch (e) {
    return { error: e.message, plugins: {} };
  }
}

function getSessions() {
  if (!fs.existsSync(SESSIONS_DIR)) return { sessions: [] };
  try {
    const entries = fs.readdirSync(SESSIONS_DIR, { withFileTypes: true });
    const now = Date.now();
    return {
      sessions: entries
        .filter(e => e.isDirectory())
        .map(e => {
          const stat = fs.statSync(path.join(SESSIONS_DIR, e.name));
          const ageMs = now - stat.mtimeMs;
          const ageDays = Math.floor(ageMs / 86400000);
          const ageHours = Math.floor((ageMs % 86400000) / 3600000);
          const age = ageDays > 0 ? ageDays + 'd ' + ageHours + 'h' : ageHours + 'h';
          return { name: e.name, mtime: stat.mtime.toISOString(), age };
        })
        .sort((a, b) => new Date(b.mtime) - new Date(a.mtime))
    };
  } catch (e) {
    return { error: e.message, sessions: [] };
  }
}

function getGPUInfo() {
  const result = { nvidia: null, ollama: null, error: null };
  result.nvidia = safeExec('nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu,temperature.gpu --format=csv,noheader 2>/dev/null');
  result.ollama = safeExec('ollama list 2>/dev/null');
  if (!result.nvidia && !result.ollama) result.error = 'No GPU tools available (nvidia-smi/ollama)';
  return result;
}

function getMetrics() {
  return {
    memory: safeExec('free -h 2>/dev/null'),
    disk: safeExec('df -h / /home 2>/dev/null'),
    uptime: safeExec('uptime 2>/dev/null'),
    load: safeExec('cat /proc/loadavg 2>/dev/null'),
    timestamp: new Date().toISOString()
  };
}

function handleStatus(req, res) {
  if (Date.now() - lastFetch < CACHE_TTL && cache.status) {
    return jsonResponse(res, 200, cache.status);
  }
  const data = {
    docker: getDockerStatus(),
    systemd: getSystemdServices(),
    version: getCockpitVersion(),
    timestamp: new Date().toISOString()
  };
  cache.status = data;
  cache.infra = getInfraServices();
  cache.plugins = getPlugins();
  lastFetch = Date.now();
  jsonResponse(res, 200, data);
}

function handleInfra(req, res) {
  const data = getInfraServices();
  jsonResponse(res, 200, data);
}

function handlePlugins(req, res) {
  const data = getPlugins();
  jsonResponse(res, 200, data);
}

function handleSessions(req, res) {
  const data = getSessions();
  jsonResponse(res, 200, data);
}

function handleGPU(req, res) {
  const data = getGPUInfo();
  jsonResponse(res, 200, data);
}

function handleMetrics(req, res) {
  const data = getMetrics();
  jsonResponse(res, 200, data);
}

function handleInfraAction(req, res, service, action) {
  if (!fs.existsSync(INFRA_FILE)) {
    return jsonResponse(res, 404, { error: 'infra.yml not found' });
  }
  if (!['start', 'stop', 'restart'].includes(action)) {
    return jsonResponse(res, 400, { error: 'Invalid action: ' + action + '. Use start|stop|restart' });
  }
  try {
    const output = execSync('docker compose -f "' + INFRA_FILE + '" ' + action + ' ' + service + ' 2>&1', {
      timeout: 30000, encoding: 'utf8'
    }).trim();
    lastFetch = 0;
    jsonResponse(res, 200, { service, action, result: 'ok', output });
  } catch (e) {
    jsonResponse(res, 500, { service, action, result: 'error', output: e.stderr || e.message });
  }
}

function handleCORS(req, res) {
  res.writeHead(204, {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
  });
  res.end();
}

function serveIndex(req, res) {
  const indexPath = path.join(__dirname, 'index.html');
  try {
    htmlResponse(res, 200, fs.readFileSync(indexPath, 'utf8'));
  } catch {
    htmlResponse(res, 200, '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>OpenCode GUI</title></head><body><h1>OpenCode Management</h1></body></html>');
  }
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://' + (req.headers.host || 'localhost'));
  const method = req.method.toUpperCase();
  if (method === 'OPTIONS') return handleCORS(req, res);
  if (url.pathname === '/api/status' && method === 'GET') return handleStatus(req, res);
  if (url.pathname === '/api/infra' && method === 'GET') return handleInfra(req, res);
  if (url.pathname === '/api/plugins' && method === 'GET') return handlePlugins(req, res);
  if (url.pathname === '/api/sessions' && method === 'GET') return handleSessions(req, res);
  if (url.pathname === '/api/gpu' && method === 'GET') return handleGPU(req, res);
  if (url.pathname === '/api/metrics' && method === 'GET') return handleMetrics(req, res);
  if (method === 'POST') {
    const match = url.pathname.match(/^\/api\/infra\/([^/]+)\/(start|stop|restart)$/);
    if (match) return handleInfraAction(req, res, match[1], match[2]);
  }
  if (method === 'GET' && !url.pathname.startsWith('/api/')) return serveIndex(req, res);
  jsonResponse(res, 404, { error: 'Not found' });
});

server.listen(PORT, HOST, () => {
  process.stderr.write('GUI server listening on http://' + HOST + ':' + PORT + '\n');
});

process.on('SIGTERM', () => server.close(() => process.exit(0)));
process.on('SIGINT', () => server.close(() => process.exit(0)));
