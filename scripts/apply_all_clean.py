import json

PROVIDER = {
    "deepseek": {"options": {"timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True}, "fallback": ["opencode", "moonshotai", "minimax", "mimo"]},
    "opencode": {"fallback": ["deepseek", "moonshotai", "minimax", "mimo"]},
    "opencode-go": {"fallback": ["deepseek", "moonshotai", "minimax", "mimo"]},
    "moonshotai": {"options": {"timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True, "baseURL": "https://api.moonshot.ai/v1", "apiKey": "{env:MOONSHOT_API_KEY}"}, "fallback": ["deepseek", "opencode-go"]},
    "minimax": {"options": {"timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True, "baseURL": "https://api.minimax.io/v1", "apiKey": "{env:MINIMAX_API_KEY}"}, "fallback": ["deepseek", "opencode-go"]},
    "mimo": {"options": {"timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True, "apiKey": "{env:MIMO_API_KEY}"}, "fallback": ["deepseek", "opencode-go"]}
}

for p in ['agi','ThePath','opora','opora-landing','rag-system','rag-system-bak','DeepSeek','opencode_initializer']:
    path = f'/home/alexandr-narbaev/Projects/{p}/opencode.json'
    with open(path) as f: cfg=json.load(f)
    cfg['provider'] = PROVIDER
    cfg.setdefault('agent',{}).setdefault('build',{'mode':'primary','model':cfg.get('model','deepseek/deepseek-v4-pro')})
    with open(path,'w') as f:
        json.dump(cfg,f,indent=2,ensure_ascii=False); f.write('\n')
    print(f'OK {p}')
