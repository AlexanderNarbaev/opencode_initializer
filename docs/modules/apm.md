# APM Preparation Module (00f-apm.sh)

> **Version:** v3.5.0  
> **File:** `src/lib/00f-apm.sh`  
> **Dependencies:** `00-core.sh`

## Overview

APM (AI Package Manager) preparation module. Generates `apm.yml` from `setup.toml` configuration and exports Software Bill of Materials (SBOM).

## Functions

### APM Generation

#### `_apm_generate(setup.toml_path)`
Generates `apm.yml` from `setup.toml` configuration.

```bash
_apm_generate "/path/to/setup.toml"
# Creates: ~/.config/opencode/apm.yml
```

#### `_apm_generate_minimal(output_path)`
Generates minimal `apm.yml` without TOML configuration.

```bash
_apm_generate_minimal "/path/to/apm.yml"
```

### SBOM Export

#### `_apm_export_sbom()`
Exports Software Bill of Materials (SBOM) in JSON format.

```bash
_apm_export_sbom
# Creates: ~/.cache/opencode-setup/sbom.json
```

### Installation

#### `_apm_install()`
Prepares APM for installation. Generates `apm.yml` and SBOM.

```bash
_apm_install
# Output:
# APM Preparation
#   apm.yml: ~/.config/opencode/apm.yml
#   SBOM: ~/.cache/opencode-setup/sbom.json
#   Future: apm install opencode-initializer
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `APM_YML` | APM YAML output path | `~/.config/opencode/apm.yml` |
| `_APM_SCHEMA_VERSION` | Schema version | `1.0.0` |
| `_APM_PACKAGE_NAME` | Package name | `opencode-initializer` |
| `_APM_PACKAGE_VERSION` | Package version | `v3.5.0` |

## Usage

```bash
# Source the module
source src/lib/00-core.sh
source src/lib/00f-apm.sh

# Show help
_apm_help

# Generate APM configuration
_apm_generate "/path/to/setup.toml"

# Or generate minimal configuration
_apm_generate_minimal

# Export SBOM
_apm_export_sbom

# Prepare for installation
_apm_install
```

## APM YAML Structure

```yaml
name: opencode-initializer
version: v3.5.0
schema_version: 1.0.0
description: AI Package Manager configuration
dependencies:
  - name: postgres
    version: "16"
  - name: redis
    version: "7"
  - name: qdrant
    version: "1.7"
```

## SBOM Structure

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.5",
  "version": 1,
  "components": [
    {
      "type": "library",
      "name": "postgres",
      "version": "16"
    }
  ]
}
```

## Integration

APM preparation enables future integration with:
- Microsoft APM ecosystem
- Package managers (npm, pip, cargo)
- Container registries
- Security scanners

## See Also

- [core.md](core.md) - Core infrastructure
- [security.md](security.md) - Security scanning
- [helpers.sh](../helpers.sh) - Helper functions
