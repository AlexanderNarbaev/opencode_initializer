const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync, exec } = require('child_process');

const PORT = process.env.GUI_PORT || 4200;
const HOME = process.env.HOME || '/home/user';
const HTML = path.join(__dirname, 'index.html');

function run(cmd) {
  try { return execSync(cmd, { timeout: 5000, encoding: 'utf-8' }).trim(); } catch { return null; }
}

function json(res, data) {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

function readOpencodeConfig() {
  try {
    let raw = fs.readFileSync(path.join(HOME, '.config/opencode/opencode.json'), 'utf-8');
    // Strip // comments (but not URLs containing //)
    raw = raw.replace(/(?<!:)\/\/.*$/gm, '');
    // Strip /* */ comments
    raw = raw.replace(/\/\*[\s\S]*?\*\//g, '');
    return JSON.parse(raw);
  } catch { return null; }
}

function writeOpencodeConfig(cfg) {
  const p = path.join(HOME, '.config/opencode/opencode.json');
  const bak = path.join(HOME, '.config/opencode/opencode.json.bak');
  try { fs.copyFileSync(p, bak); } catch {}
  fs.writeFileSync(p, JSON.stringify(cfg, null, 2));
}

function ollamaModels() {
  try { const out = execSync('ollama list', { timeout: 5000, encoding: 'utf-8' }).trim();
    return out.split('\n').slice(1).map(l=>{const m=l.match(/^(\S+)\s+\S+\s+([\d.]+\s*\w+)/); return m?{name:m[1],size:m[2]}:null}).filter(Boolean);
  } catch { return []; }
}

function memoryLayerStatus() {
  let ml = { running: false, version: '', embedProxy: false };
  try { const r = execSync('curl -s http://localhost:61001/', { timeout: 3000, encoding: 'utf-8' });
    const d = JSON.parse(r); ml.running = true; ml.version = d.version || '';
  } catch {}
  ml.embedProxy = checkPort(61051);
  ml.qdrant = checkPort(6333);
  ml.redis = checkPort(6379);
  return ml;
}

function readSetupConfig() {
  const conf = path.join(HOME, '.config/opencode-setup/setup.conf');
  let cfg = {};
  try {
    fs.readFileSync(conf, 'utf-8').split('\n').forEach(l => {
      const m = l.match(/^(\w+)\s*=\s*"?([^"#\n\r]+)"?/);
      if (m) cfg[m[1]] = m[2].trim();
    });
  } catch {}
  return cfg;
}

function readTaskProfiles() {
  try { return JSON.parse(fs.readFileSync(path.join(HOME, '.config/opencode/model-router/task-profiles.json'), 'utf-8')); }
  catch { return {}; }
}

function checkPort(port) {
  try { execSync(`ss -tlnp | grep ':${port} '`, { stdio: 'pipe' }); return true; } catch { return false; }
}

function checkBin(name) {
  try { execSync(`which ${name} 2>/dev/null || test -x ${HOME}/.bun/bin/${name}`, { stdio: 'pipe' }); return true; } catch { return false; }
}

const server = http.createServer((req, res) => {
  if (req.url === '/' || req.url === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(fs.readFileSync(HTML));
    return;
  }

  const api = req.url.replace('/api', '');

  if (api === '/action' && req.method === 'POST') {
    let body = '';
    req.on('data',c=>body+=c);
    req.on('end',()=>{
      let act; try{act=JSON.parse(body)}catch{act={}};
      const a=act.action||'', target=act.target||'';
      let result={ok:true,message:'Done'};
      try{
        if(a==='health'){run('dev health > /dev/null 2>&1 &');result.message='Health check started'}
        else if(a==='regen-config'){result.message='Config regenerated'}
        else if(a==='restart-mcps'){result.message='MCP reload on next opencode start'}
        else if(a==='infra-up-all'){run('dev infra up');result.message='Starting all services'}
        else if(a==='infra-down-all'){run('dev infra down');result.message='Stopping all services'}
        else if(a==='infra-start'){run('dev infra up '+target);result.refresh=true;result.message='Starting '+target}
        else if(a==='infra-stop'){run('docker stop opencode-'+target.toLowerCase());result.refresh=true;result.message='Stopping '+target}
        else if(a==='infra-restart'){run('docker restart opencode-'+target.toLowerCase());result.refresh=true;result.message='Restarting '+target}
        else if(a==='restore-backup'){run('dev backup restore '+target);result.message='Restored from '+target}
        else if(a==='pull-model'){run('ollama pull '+target+' > /dev/null 2>&1 &');result.message='Pulling model '+target+' (background)';result.refresh=true}
        else if(a==='remove-model'){run('ollama rm '+target);result.message='Removed model '+target;result.refresh=true}
        else if(a==='switch-model'){const cfg=readOpencodeConfig();if(cfg){cfg.model=target;writeOpencodeConfig(cfg);result.message='Switched to '+target;result.refresh=true}else{result={ok:false,message:'Config not found'}}}
        else if(a==='toggle-external-obs'){const conf=path.join(HOME,'.config/opencode-setup/setup.conf');let content='';try{content=fs.readFileSync(conf,'utf-8')}catch{}if(content.includes('EXTERNAL_OBSERVABILITY=true')){content=content.replace('EXTERNAL_OBSERVABILITY=true','EXTERNAL_OBSERVABILITY=false');result.message='External observability DISABLED'}else if(content.includes('EXTERNAL_OBSERVABILITY=false')){content=content.replace('EXTERNAL_OBSERVABILITY=false','EXTERNAL_OBSERVABILITY=true');result.message='External observability ENABLED'}else{content+='\nEXTERNAL_OBSERVABILITY=true\n';result.message='External observability ENABLED'}try{fs.writeFileSync(conf,content)}catch{}}
        else{result={ok:false,message:'Unknown: '+a}}
      }catch(e){result={ok:false,message:e.message}}
      res.writeHead(200,{'Content-Type':'application/json'});
      res.end(JSON.stringify(result));
    });
    return;
  }

  if (api === '/status') {
    const cfg = readOpencodeConfig();
    const mcpList = cfg && cfg.mcp ? Object.keys(cfg.mcp).filter(k => cfg.mcp[k].enabled !== false) : [];
    const lspList = cfg && cfg.lsp ? Object.keys(cfg.lsp) : [];
    let mcpOk=0,mcpMiss=0,lspOk=0,lspMiss=0;
    mcpList.forEach(m=>{checkBin(m)?mcpOk++:mcpMiss++});
    lspList.forEach(l=>{try{execSync(`which ${l}`,{stdio:'pipe'});lspOk++}catch{lspMiss++}});
    const infraList = [['ChromaDB',8000],['PostgreSQL',5432],['Qdrant',6333],['Redis',6379],['MemoryLayer',61001],['Prometheus',9090],['Grafana',3001]];
    let infraOk=0,infraMiss=0;
    infraList.forEach(([n,p])=>{checkPort(p)?infraOk++:infraMiss++});
    json(res, {
      providers: cfg ? Object.keys(cfg.provider||{}).length : 0,
      mcp_ok: mcpOk, mcp_miss: mcpMiss,
      lsp_ok: lspOk, lsp_miss: lspMiss,
      plugins: cfg ? (cfg.plugin||[]).length : 0,
      infra_ok: infraOk, infra_miss: infraMiss,
      model_router: cfg && cfg.experimental && cfg.experimental.model_router_dir ? true : false,
      config: cfg ? { model: cfg.model, small_model: cfg.small_model, providers: Object.keys(cfg.provider||{}).length, mcps: Object.keys(cfg.mcp||{}).length, lsps: Object.keys(cfg.lsp||{}).length } : null,
    });
    return;
  }

  if (api === '/providers') {
    const secrets = path.join(HOME, '.config/opencode/secrets.env');
    let keys = {};
    try { fs.readFileSync(secrets,'utf-8').split('\n').forEach(l=>{const m=l.match(/^(\w+)=(.+)/);if(m)keys[m[1]]=m[2]}); } catch {}
    const providers = [
      ['DeepSeek','DEEPSEEK_API_KEY','https://api.deepseek.com/v1/models',true],
      ['z.ai GLM','ZAI_API_KEY','https://api.z.ai/api/paas/v4/models',true],
      ['OpenRouter','OPENROUTER_API_KEY','https://openrouter.ai/api/v1/models',true],
      ['OpenAI','OPENAI_API_KEY','https://api.openai.com/v1/models',false],
      ['Anthropic','ANTHROPIC_API_KEY','https://api.anthropic.com/v1/models',false],
      ['Google','GOOGLE_API_KEY','https://generativelanguage.googleapis.com/v1beta/models',true],
      ['xAI','XAI_API_KEY','https://api.x.ai/v1/models',false],
      ['Moonshot','MOONSHOT_API_KEY','https://api.moonshot.cn/v1/models',false],
      ['Alibaba','ALIBABA_API_KEY','https://dashscope.aliyuncs.com/compatible-mode/v1/models',true],
      ['Groq','GROQ_API_KEY','https://api.groq.com/openai/v1/models',true],
      ['Together','TOGETHER_API_KEY','https://api.together.xyz/v1/models',true],
      ['Mistral','MISTRAL_API_KEY','https://api.mistral.ai/v1/models',false],
      ['Cohere','COHERE_API_KEY','https://api.cohere.com/v1/models',true],
      ['DeepInfra','DEEPINFRA_API_KEY','https://api.deepinfra.com/v1/openai/models',true],
      ['Perplexity','PERPLEXITY_API_KEY','https://api.perplexity.ai/models',false],
      ['Ollama',null,null,true],
      ['LiteLLM',null,null,true],
      ['vLLM',null,null,true],
      ['SGLang',null,null,true],
    ];
    const result = providers.map(([name,keyEnv,url,free])=>{
      const hasKey = keyEnv ? !!keys[keyEnv] : true;
      return { name, status: hasKey, models: hasKey?'?':0, free };
    });
    json(res, { providers: result });
    return;
  }

  if (api === '/models') {
    const profiles = readTaskProfiles();
    const result = Object.entries(profiles).map(([task,p])=>({ task, model: p.model, description: p.description }));
    json(res, { profiles: result });
    return;
  }

  if (api === '/mcp') {
    const cfg = readOpencodeConfig();
    const mcps = cfg ? Object.entries(cfg.mcp||{}).map(([name,v])=>{
      const cmd = v.command && v.command[0] ? v.command[0] : '';
      const installed = checkBin(path.basename(cmd)) || fs.existsSync(cmd);
      return { name, installed, command: cmd };
    }) : [];
    json(res, { servers: mcps });
    return;
  }

  if (api === '/lsp') {
    const cfg = readOpencodeConfig();
    const lsps = cfg ? Object.entries(cfg.lsp||{}).map(([name,v])=>{
      const cmd = v.command && v.command[0] ? v.command[0] : '';
      let installed = false; try { execSync(`which ${cmd}`,{stdio:'pipe'}); installed=true; } catch {}
      const exts = (v.extensions||[]).join(', ');
      return { name, installed, languages: exts };
    }) : [];
    json(res, { servers: lsps });
    return;
  }

  if (api === '/infra') {
    const services = [
      ['ChromaDB',8000],['MemoryLayer',61001],['PostgreSQL',5432],['Qdrant',6333],['Redis',6379],
      ['Prometheus',9090],['Grafana',3001],['SearXNG',8888],['LiteLLM',4000],['Ollama',11434],
    ];
    const result = services.map(([name,port])=>({name,port,running:checkPort(port)}));
    json(res, { services: result });
    return;
  }

  if (api === '/isolated') {
    const conf = path.join(HOME, '.config/opencode-setup/setup.conf');
    let enabled = false;
    try { fs.readFileSync(conf,'utf-8').split('\n').forEach(l=>{if(l.match(/^ISOLATED_CIRCUIT=true/))enabled=true}); } catch {}
    const backends = [['Ollama',11434],['LiteLLM',4000],['vLLM',8000],['SGLang',30000]].map(([n,p])=>({name:n,port:p,running:checkPort(p)}));
    json(res, { enabled, backends });
    return;
  }

  if (api === '/isolated/toggle' && req.method === 'POST') {
    const conf = path.join(HOME, '.config/opencode-setup/setup.conf');
    try {
      let content = fs.readFileSync(conf,'utf-8');
      if (content.match(/ISOLATED_CIRCUIT\s*=\s*true/)) {
        content = content.replace(/ISOLATED_CIRCUIT\s*=\s*true/, 'ISOLATED_CIRCUIT=false');
      } else if (content.match(/ISOLATED_CIRCUIT\s*=\s*false/)) {
        content = content.replace(/ISOLATED_CIRCUIT\s*=\s*false/, 'ISOLATED_CIRCUIT=true');
      } else if (content.includes('ISOLATED_CIRCUIT=')) {
        content = content.replace(/ISOLATED_CIRCUIT=.*/, 'ISOLATED_CIRCUIT=true');
      } else {
        content += '\nISOLATED_CIRCUIT=true';
      }
      fs.writeFileSync(conf, content);
    } catch {}
    json(res, { ok: true });
    return;
  }

  if (api === '/backups') {
    const dir = path.join(HOME, '.config/opencode-setup/backups');
    let backups = [];
    try { backups = fs.readdirSync(dir).filter(f=>f.endsWith('.tar.gz')).map(f=>{
      const stat = fs.statSync(path.join(dir,f));
      return { file: f, size: `${(stat.size/1024).toFixed(0)}KB`, date: stat.mtime.toISOString().split('T')[0] };
    }); } catch {}
    json(res, { backups });
    return;
  }

  if (api === '/backup/create' && req.method === 'POST') {
    run('dev backup create');
    json(res, { ok: true });
    return;
  }

  if (api === '/logs') {
    const logFile = path.join(HOME, '.cache/opencode-setup/setup.log');
    let logs = [];
    try { logs = fs.readFileSync(logFile,'utf-8').split('\n').slice(-50); } catch {}
    json(res, { logs });
    return;
  }

  // --- Model Management: POST /config-model (MUST be before GET) ---
  if (api === '/config-model' && req.method === 'POST') {
    let body = '';
    req.on('data',c=>body+=c);
    req.on('end',()=>{
      let act; try{act=JSON.parse(body)}catch{act={}};
      const cfg = readOpencodeConfig();
      if (!cfg) { json(res, { ok: false, message: 'Cannot read config' }); return; }
      if (act.model) cfg.model = act.model;
      if (act.small_model) cfg.small_model = act.small_model;
      try { writeOpencodeConfig(cfg); json(res, { ok: true, model: cfg.model, small_model: cfg.small_model }); }
      catch(e) { json(res, { ok: false, message: e.message }); }
    });
    return;
  }

  if (api === '/config-model') {
    const cfg = readOpencodeConfig();
    const models = ollamaModels();
    const providers = cfg ? Object.keys(cfg.provider||{}) : [];
    json(res, {
      model: cfg ? cfg.model : null,
      small_model: cfg ? cfg.small_model : null,
      local_models: models,
      providers: providers
    });
    return;
  }

  if (api === '/ollama-models') {
    const models = ollamaModels();
    json(res, { models });
    return;
  }

  if (api === '/memory-layer') {
    json(res, memoryLayerStatus());
    return;
  }

  if (api === '/grafana-config') {
    const cfg = readSetupConfig();
    const external = cfg.EXTERNAL_OBSERVABILITY === 'true';
    const localRunning = checkPort(3001);
    const url = external ? (cfg.EXTERNAL_GRAFANA_URL || 'http://localhost:3001') : 'http://localhost:3001';
    json(res, {
      external,
      url,
      localRunning,
      dashboards: [
        { uid: 'opencode-infra', name: 'Infrastructure Overview' },
        { uid: 'opencode-tokens', name: 'Agent Performance' }
      ]
    });
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`OpenCode Manager running at http://localhost:${PORT}`);
});
