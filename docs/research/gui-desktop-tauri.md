# OpenCode Initializer — GUI Desktop App (Tauri)

## Overview

This document outlines the design for a native desktop application using
Tauri (Rust-based) for managing the opencode_initializer environment.

## Why Tauri?

| Feature | Electron | Tauri |
|---------|----------|-------|
| Bundle size | ~150MB | ~10MB |
| Memory usage | ~200MB | ~30MB |
| Startup time | Slow | Fast |
| Security | Medium | High |
| Native feel | No | Yes |
| Cross-platform | Yes | Yes |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Tauri App                             │
├─────────────────────────────────────────────────────────┤
│  Frontend (HTML/CSS/JS or React/Vue/Svelte)             │
│  ├── Dashboard view                                     │
│  ├── Modules view                                       │
│  ├── Providers view                                     │
│  ├── Services view                                      │
│  ├── Settings view                                      │
│  └── Terminal view                                      │
├─────────────────────────────────────────────────────────┤
│  Backend (Rust)                                         │
│  ├── Command execution                                  │
│  ├── File system operations                             │
│  ├── Process management                                 │
│  ├── System tray                                        │
│  └── Notifications                                      │
├─────────────────────────────────────────────────────────┤
│  Shell (bash)                                           │
│  ├── setup.sh execution                                 │
│  ├── Module management                                  │
│  └── Service management                                 │
└─────────────────────────────────────────────────────────┘
```

## Features

### 1. Dashboard
- System status overview
- Module installation progress
- Service health indicators
- Quick actions

### 2. Modules
- List all modules
- Install/uninstall modules
- Update modules
- Module dependencies

### 3. Providers
- AI provider status
- API key management
- Model selection
- Provider health

### 4. Services
- Docker service management
- Start/stop/restart
- Logs viewer
- Resource monitoring

### 5. Settings
- Configuration editor
- TOML syntax highlighting
- Environment variables
- Shell configuration

### 6. Terminal
- Integrated terminal
- Command history
- Auto-completion
- Output streaming

## Tech Stack

- **Framework:** Tauri 2.0
- **Frontend:** React + TypeScript + Vite
- **Styling:** Tailwind CSS
- **State:** Zustand
- **Terminal:** xterm.js
- **Charts:** Recharts

## Project Structure

```
opencode-init-gui/
├── src-tauri/
│   ├── src/
│   │   ├── main.rs
│   │   ├── commands/
│   │   ├── system/
│   │   └── tray.rs
│   ├── Cargo.toml
│   └── tauri.conf.json
├── src/
│   ├── App.tsx
│   ├── components/
│   ├── hooks/
│   ├── stores/
│   └── utils/
├── package.json
└── vite.config.ts
```

## Implementation Plan

### Phase 1: Basic App
- [ ] Create Tauri project
- [ ] Implement basic window
- [ ] Add system tray
- [ ] Add notifications

### Phase 2: Dashboard
- [ ] System status display
- [ ] Module list
- [ ] Service status
- [ ] Quick actions

### Phase 3: Management
- [ ] Module installation
- [ ] Service management
- [ ] Configuration editor
- [ ] Terminal integration

### Phase 4: Polish
- [ ] Native menus
- [ ] Keyboard shortcuts
- [ ] Auto-update
- [ ] Error handling

## Code Example

### Rust Backend

```rust
use tauri::Manager;

#[tauri::command]
fn run_setup(args: Vec<String>) -> Result<String, String> {
    let output = std::process::Command::new("bash")
        .arg("setup.sh")
        .args(&args)
        .output()
        .map_err(|e| e.to_string())?;

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

#[tauri::command]
fn get_system_status() -> Result<serde_json::Value, String> {
    // Get system status
    todo!()
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            run_setup,
            get_system_status,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

### React Frontend

```tsx
import { invoke } from '@tauri-apps/api/tauri';
import { useState } from 'react';

function App() {
  const [status, setStatus] = useState(null);

  const runHealth = async () => {
    const result = await invoke('run_setup', { args: ['--health'] });
    console.log(result);
  };

  return (
    <div>
      <h1>OpenCode Initializer</h1>
      <button onClick={runHealth}>Health Check</button>
    </div>
  );
}

export default App;
```

## Future Enhancements

1. **Auto-update** — Automatic app updates
2. **Plugin system** — Install plugins from marketplace
3. **Cloud sync** — Sync settings across devices
4. **Team features** — Shared configurations
5. **AI integration** — AI-powered suggestions
