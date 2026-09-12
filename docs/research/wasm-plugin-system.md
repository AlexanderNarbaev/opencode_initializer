# OpenCode Initializer — WebAssembly Plugin System

## Overview

This document describes a WebAssembly (WASM) based plugin system for
opencode_initializer, enabling portable, sandboxed, and secure plugins.

## Why WebAssembly?

| Feature | Native Plugins | WASM Plugins |
|---------|---------------|--------------|
| Portability | Platform-specific | Universal |
| Security | Full access | Sandboxed |
| Performance | Fast | Near-native |
| Language | Specific | Any (Rust, Go, C, etc.) |
| Isolation | Weak | Strong |
| Hot-reload | Difficult | Easy |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              WASM Plugin System                         │
├─────────────────────────────────────────────────────────┤
│  Host Runtime (Rust)                                    │
│  ├── Plugin loader                                      │
│  ├── WASM executor (wasmtime/wasmer)                    │
│  ├── Capability system                                  │
│  ├── Resource limiter                                   │
│  └── Event bus                                          │
├─────────────────────────────────────────────────────────┤
│  Plugin SDK                                             │
│  ├── Rust SDK                                           │
│  ├── Go SDK                                             │
│  ├── JavaScript SDK                                     │
│  └── Python SDK                                         │
├─────────────────────────────────────────────────────────┤
│  Plugins (WASM modules)                                 │
│  ├── Language plugins                                   │
│  ├── Tool plugins                                       │
│  ├── Service plugins                                    │
│  └── Workflow plugins                                   │
└─────────────────────────────────────────────────────────┘
```

## Plugin Interface

### WASM Exports

```wat
(module
  ;; Plugin metadata
  (func (export "name") (result i32))
  (func (export "version") (result i32))
  (func (export "description") (result i32))

  ;; Lifecycle
  (func (export "init") (param i32) (result i32))
  (func (export "cleanup") (result i32))

  ;; Commands
  (func (export "execute") (param i32 i32) (result i32))

  ;; Memory
  (memory (export "memory") 1)
)
```

### Host Functions (provided to plugins)

```rust
// Available to plugins via WASM imports
extern "C" {
    fn log(level: i32, message: *const u8, len: usize);
    fn read_file(path: *const u8, path_len: usize) -> i32;
    fn write_file(path: *const u8, path_len: usize, data: *const u8, data_len: usize) -> i32;
    fn execute_command(cmd: *const u8, cmd_len: usize) -> i32;
    fn http_request(url: *const u8, url_len: usize) -> i32;
    fn get_config(key: *const u8, key_len: usize) -> i32;
    fn set_config(key: *const u8, key_len: usize, value: *const u8, value_len: usize) -> i32;
}
```

## Plugin Manifest

```toml
[plugin]
name = "my-plugin"
version = "1.0.0"
description = "A sample plugin"
author = "Developer"
license = "MIT"

[capabilities]
filesystem = ["read", "write"]
network = ["fetch"]
shell = ["execute"]
config = ["read", "write"]

[limits]
memory = "16MB"
timeout = "30s"
cpu = "1s"

[dependencies]
other-plugin = "^1.0.0"
```

## Plugin SDK (Rust)

```rust
use opencode_plugin_sdk::*;

#[plugin_main]
fn main() -> Result<(), Error> {
    // Register command
    register_command("greet", |args| {
        let name = args.get("name").unwrap_or("World");
        Ok(format!("Hello, {}!", name))
    })?;

    // Register hook
    register_hook("pre-install", |ctx| {
        log::info!("Pre-install hook triggered");
        Ok(())
    })?;

    Ok(())
}
```

## Plugin SDK (Go)

```go
package main

import (
    "fmt"
    opencode "github.com/AlexanderNarbaev/opencode-plugin-sdk-go"
)

func main() {
    opencode.RegisterCommand("greet", func(args map[string]interface{}) (interface{}, error) {
        name, ok := args["name"].(string)
        if !ok {
            name = "World"
        }
        return fmt.Sprintf("Hello, %s!", name), nil
    })

    opencode.RegisterHook("pre-install", func(ctx *opencode.Context) error {
        opencode.Log(opencode.Info, "Pre-install hook triggered")
        return nil
    })
}
```

## Security Model

### Capabilities

| Capability | Description | Risk |
|------------|-------------|------|
| `filesystem.read` | Read files | Low |
| `filesystem.write` | Write files | Medium |
| `network.fetch` | HTTP requests | Medium |
| `shell.execute` | Run commands | High |
| `config.read` | Read config | Low |
| `config.write` | Write config | Medium |
| `docker.manage` | Docker ops | High |

### Resource Limits

| Resource | Default | Maximum |
|----------|---------|---------|
| Memory | 16MB | 256MB |
| CPU time | 1s | 30s |
| File size | 1MB | 100MB |
| Network | 1MB | 10MB |

## Plugin Types

### Language Plugins
```rust
// Add support for a new language
register_language("zig", LanguageConfig {
    version_cmd: "zig version",
    install_cmd: "snap install zig",
    test_cmd: "zig build test",
    lint_cmd: "zig fmt --check",
});
```

### Tool Plugins
```rust
// Add support for a new tool
register_tool("k9s", ToolConfig {
    install_cmd: "brew install k9s",
    health_cmd: "k9s version",
    config_path: "~/.config/k9s",
});
```

### Service Plugins
```rust
// Add support for a new service
register_service("clickhouse", ServiceConfig {
    docker_image: "clickhouse/clickhouse-server",
    ports: vec![8123, 9000],
    health_cmd: "clickhouse-client --query 'SELECT 1'",
});
```

### Workflow Plugins
```rust
// Add a new workflow
register_workflow("deploy-k8s", |ctx| {
    // Build image
    ctx.execute("docker build -t myapp .")?;

    // Push to registry
    ctx.execute("docker push myapp")?;

    // Deploy to K8s
    ctx.execute("kubectl apply -f k8s/")?;

    Ok(())
});
```

## Implementation Plan

### Phase 1: Core Runtime
- [ ] WASM runtime integration (wasmtime)
- [ ] Plugin loader
- [ ] Basic capability system
- [ ] Memory limits

### Phase 2: SDK
- [ ] Rust SDK
- [ ] Go SDK
- [ ] JavaScript SDK
- [ ] Plugin template

### Phase 3: Plugin Registry
- [ ] Plugin manifest format
- [ ] Registry server
- [ ] Plugin discovery
- [ ] Version management

### Phase 4: Security
- [ ] Capability enforcement
- [ ] Resource limits
- [ ] Sandboxing
- [ ] Audit logging

## Benefits

1. **Portability** — Plugins work on any platform
2. **Security** — Sandboxed execution
3. **Performance** — Near-native speed
4. **Ecosystem** — Any language can create plugins
5. **Hot-reload** — Update plugins without restart
6. **Isolation** — Plugins can't crash the host

## Future Enhancements

1. **Plugin marketplace** — Browse and install plugins
2. **Plugin signing** — Verify plugin authenticity
3. **Plugin analytics** — Track plugin usage
4. **Plugin monetization** — Premium plugins
