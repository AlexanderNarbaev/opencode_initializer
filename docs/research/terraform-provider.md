# OpenCode Initializer — Terraform Provider

## Overview

This document describes a Terraform provider for managing opencode_initializer
environments as infrastructure as code.

## Why Terraform Provider?

| Feature | Manual Setup | Terraform |
|---------|-------------|-----------|
| Declarative | No | Yes |
| Version control | No | Yes |
| Reproducible | Difficult | Easy |
| Multi-cloud | No | Yes |
| State management | No | Yes |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Terraform Provider                          │
├─────────────────────────────────────────────────────────┤
│  Provider (Go)                                          │
│  ├── Resource: opencode_environment                     │
│  ├── Resource: opencode_module                          │
│  ├── Resource: opencode_provider                        │
│  ├── Resource: opencode_service                         │
│  └── Data Source: opencode_config                       │
├─────────────────────────────────────────────────────────┤
│  Backend                                                │
│  ├── Local execution                                    │
│  ├── Remote execution                                   │
│  └── Docker execution                                   │
└─────────────────────────────────────────────────────────┘
```

## Resources

### opencode_environment

```hcl
resource "opencode_environment" "dev" {
  name = "development"
  
  modules = [
    "system",
    "docker",
    "nodejs",
    "python",
    "go"
  ]
  
  providers = {
    deepseek = {
      enabled = true
      api_key = var.deepseek_api_key
    }
    openai = {
      enabled = true
      api_key = var.openai_api_key
    }
  }
  
  services = {
    postgres = {
      enabled = true
      version = "17"
      port = 5432
    }
    redis = {
      enabled = true
      port = 6379
    }
  }
  
  config = {
    parallel = 4
    skip     = ["gui"]
  }
}
```

### opencode_module

```hcl
resource "opencode_module" "nodejs" {
  name    = "nodejs"
  version = "24"
  
  dependencies = ["system"]
  
  config = {
    npm_registry = "https://registry.npmjs.org"
  }
}
```

### opencode_provider

```hcl
resource "opencode_provider" "deepseek" {
  name = "deepseek"
  
  config = {
    api_key = var.deepseek_api_key
    model   = "deepseek-coder"
  }
}
```

### opencode_service

```hcl
resource "opencode_service" "postgres" {
  name    = "postgres"
  version = "17"
  port    = 5432
  
  config = {
    max_connections = 100
    shared_buffers  = "256MB"
  }
}
```

## Data Sources

### opencode_config

```hcl
data "opencode_config" "current" {}

output "version" {
  value = data.opencode_config.current.version
}

output "modules" {
  value = data.opencode_config.current.modules
}
```

## Provider Configuration

```hcl
terraform {
  required_providers {
    opencode = {
      source  = "AlexanderNarbaev/opencode"
      version = "~> 1.0"
    }
  }
}

provider "opencode" {
  # Configuration
  config_file = "~/.config/opencode-init/config.toml"
  parallel    = 4
}
```

## Implementation

### Provider Schema

```go
package provider

import (
    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func Provider() *schema.Provider {
    return &schema.Provider{
        ResourcesMap: map[string]*schema.Resource{
            "opencode_environment": resourceEnvironment(),
            "opencode_module":     resourceModule(),
            "opencode_provider":   resourceProvider(),
            "opencode_service":    resourceService(),
        },
        DataSourcesMap: map[string]*schema.Resource{
            "opencode_config": dataSourceConfig(),
        },
        Schema: map[string]*schema.Schema{
            "config_file": {
                Type:     schema.TypeString,
                Optional: true,
                Default:  "~/.config/opencode-init/config.toml",
            },
            "parallel": {
                Type:     schema.TypeInt,
                Optional: true,
                Default:  4,
            },
        },
    }
}
```

### Resource Implementation

```go
func resourceEnvironment() *schema.Resource {
    return &schema.Resource{
        Create: resourceEnvironmentCreate,
        Read:   resourceEnvironmentRead,
        Update: resourceEnvironmentUpdate,
        Delete: resourceEnvironmentDelete,

        Schema: map[string]*schema.Schema{
            "name": {
                Type:     schema.TypeString,
                Required: true,
            },
            "modules": {
                Type:     schema.TypeList,
                Optional: true,
                Elem: &schema.Schema{
                    Type: schema.TypeString,
                },
            },
            "providers": {
                Type:     schema.TypeMap,
                Optional: true,
                Elem: &schema.Schema{
                    Type: schema.TypeMap,
                },
            },
            "services": {
                Type:     schema.TypeMap,
                Optional: true,
                Elem: &schema.Schema{
                    Type: schema.TypeMap,
                },
            },
        },
    }
}
```

## Usage Examples

### Basic Environment

```hcl
module "dev_environment" {
  source = "./modules/opencode-environment"
  
  name = "development"
  modules = ["system", "docker", "nodejs", "python"]
}
```

### Multi-Environment

```hcl
module "dev" {
  source = "./modules/opencode-environment"
  name   = "development"
  modules = ["system", "docker", "nodejs", "python"]
}

module "staging" {
  source = "./modules/opencode-environment"
  name   = "staging"
  modules = ["system", "docker", "nodejs", "python", "go"]
}

module "production" {
  source = "./modules/opencode-environment"
  name   = "production"
  modules = ["system", "docker", "nodejs", "python", "go", "rust"]
}
```

## Benefits

1. **Declarative** — Define desired state
2. **Reproducible** — Same setup every time
3. **Version controlled** — Track changes in Git
4. **Multi-cloud** — Works anywhere
5. **Collaborative** — Team can share configs

## Implementation Plan

### Phase 1: Basic Provider
- [ ] Provider skeleton
- [ ] Basic resources
- [ ] Local execution
- [ ] Documentation

### Phase 2: Advanced Features
- [ ] Remote execution
- [ ] State management
- [ ] Import existing
- [ ] Data sources

### Phase 3: Production
- [ ] Registry publishing
- [ ] Acceptance tests
- [ ] Documentation
- [ ] Examples

## Future Enhancements

1. **Remote state** — Store state in cloud
2. **Modules** — Reusable modules
3. **Workspaces** — Multiple environments
4. **Sentinel** — Policy as code
