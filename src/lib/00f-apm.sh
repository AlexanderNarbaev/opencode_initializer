#!/usr/bin/env bash
# src/lib/00f-apm.sh — APM Preparation Module (v3.5.0)
# Generates apm.yml (AI Package Manager) from setup.toml configuration.
# Enables future integration with Microsoft APM ecosystem.
# Sources: src/lib/00-core.sh must be sourced before this file
set -euo pipefail

# ── APM configuration ────────────────────────────────────────────────────────
_APM_YML="${APM_YML:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/apm.yml}"
_APM_SCHEMA_VERSION="1.0.0"
_APM_PACKAGE_NAME="opencode-initializer"
_APM_PACKAGE_VERSION="${SCRIPT_VERSION:-v3.5.0}"

# ── Generate apm.yml from setup.toml ────────────────────────────────────────
# Usage: _apm_generate [setup.toml_path]
# If no path given, uses CONFIG_TOML env var or default location.
_apm_generate() {
  local toml_file="${1:-${CONFIG_TOML:-}}"
  local output="${2:-$_APM_YML}"

  # If no TOML file, generate minimal apm.yml
  if [ -z "$toml_file" ] || [ ! -f "$toml_file" ]; then
    info "No setup.toml found — generating minimal apm.yml"
    _apm_generate_minimal "$output"
    return 0
  fi

  info "Generating apm.yml from $toml_file"

  # Use python3 for TOML parsing and YAML generation
  python3 - "$toml_file" "$output" "$_APM_PACKAGE_NAME" "$_APM_PACKAGE_VERSION" "$_APM_SCHEMA_VERSION" <<'PYEOF'
import sys
import json
from pathlib import Path

try:
    import tomllib
except ImportError:
    # Python 3.10 fallback
    try:
        import tomli as tomllib
    except ImportError:
        print("ERROR: tomllib not available", file=sys.stderr)
        sys.exit(1)

def toml_to_apm(toml_path, output_path, pkg_name, pkg_version, schema_version):
    """Convert setup.toml to apm.yml format."""
    with open(toml_path, 'rb') as f:
        config = tomllib.load(f)

    apm = {
        'schema_version': schema_version,
        'package': {
            'name': pkg_name,
            'version': pkg_version,
            'description': 'Unified AI-powered developer machine bootstrapper',
            'homepage': 'https://github.com/AlexanderNarbaev/opencode_initializer',
            'repository': 'https://github.com/AlexanderNarbaev/opencode_initializer',
            'license': 'MIT',
            'maintainers': [
                {'name': 'Alexander Narbaev', 'email': 'alex@example.com'}
            ],
            'tags': ['ai', 'developer-tools', 'bootstrapper', 'opencode']
        },
        'dependencies': [],
        'features': {},
        'services': {},
        'providers': {},
        'tools': {},
        'configuration': {}
    }

    # Map TOML features to APM features
    features = config.get('features', {})
    for key, value in features.items():
        if isinstance(value, bool):
            apm['features'][key] = {'enabled': value}
        else:
            apm['features'][key] = {'version': str(value)}

    # Map services
    services = config.get('services', {})
    for svc, enabled in services.items():
        if isinstance(enabled, bool):
            apm['services'][svc] = {'enabled': enabled}
        elif isinstance(enabled, dict):
            apm['services'][svc] = enabled

    # Map providers
    providers = config.get('providers', {})
    for provider, enabled in providers.items():
        if isinstance(enabled, bool):
            apm['providers'][provider] = {'enabled': enabled}
        elif isinstance(enabled, dict):
            apm['providers'][provider] = enabled

    # Map tools versions
    tools = config.get('tools', {})
    for tool, version in tools.items():
        apm['tools'][tool] = {'version': str(version)}

    # Map user configuration
    user = config.get('user', {})
    if user:
        apm['configuration']['user'] = user

    # Map meta
    meta = config.get('meta', {})
    if meta:
        apm['configuration']['meta'] = meta

    # Build APM dependencies list from features
    apm_deps = []
    if features.get('docker', True):
        apm_deps.append({'name': 'docker', 'version': '>=24.0', 'optional': False})
    if features.get('nodejs', True):
        node_ver = features.get('nodejs', '24')
        apm_deps.append({'name': 'nodejs', 'version': f'>={node_ver}', 'optional': False})
    if features.get('python', True):
        py_ver = features.get('python', '3.14')
        apm_deps.append({'name': 'python', 'version': f'>={py_ver}', 'optional': False})
    if features.get('go', True):
        go_ver = features.get('go', '1.26')
        apm_deps.append({'name': 'go', 'version': f'>={go_ver}', 'optional': True})
    if features.get('rust', True):
        rust_ver = features.get('rust', '1.97')
        apm_deps.append({'name': 'rust', 'version': f'>={rust_ver}', 'optional': True})

    apm['dependencies'] = apm_deps

    # Write YAML (manual generation for portability)
    lines = []
    lines.append(f"# apm.yml — Auto-generated from setup.toml")
    lines.append(f"# Schema: {schema_version}")
    lines.append(f"# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)")
    lines.append("")
    lines.append(f"schema_version: \"{schema_version}\"")
    lines.append("")
    lines.append("package:")
    lines.append(f"  name: \"{apm['package']['name']}\"")
    lines.append(f"  version: \"{apm['package']['version']}\"")
    lines.append(f"  description: \"{apm['package']['description']}\"")
    lines.append(f"  homepage: \"{apm['package']['homepage']}\"")
    lines.append(f"  repository: \"{apm['package']['repository']}\"")
    lines.append(f"  license: \"{apm['package']['license']}\"")
    lines.append("  maintainers:")
    for m in apm['package']['maintainers']:
        lines.append(f"    - name: \"{m['name']}\"")
        lines.append(f"      email: \"{m['email']}\"")
    lines.append("  tags:")
    for tag in apm['package']['tags']:
        lines.append(f"    - \"{tag}\"")
    lines.append("")
    lines.append("dependencies:")
    for dep in apm['dependencies']:
        lines.append(f"  - name: \"{dep['name']}\"")
        lines.append(f"    version: \"{dep['version']}\"")
        lines.append(f"    optional: {str(dep['optional']).lower()}")
    lines.append("")
    lines.append("features:")
    for feat, conf in apm['features'].items():
        if 'enabled' in conf:
            lines.append(f"  {feat}:")
            lines.append(f"    enabled: {str(conf['enabled']).lower()}")
        elif 'version' in conf:
            lines.append(f"  {feat}:")
            lines.append(f"    version: \"{conf['version']}\"")
    lines.append("")
    lines.append("services:")
    for svc, conf in apm['services'].items():
        if isinstance(conf, dict):
            lines.append(f"  {svc}:")
            for k, v in conf.items():
                if isinstance(v, bool):
                    lines.append(f"    {k}: {str(v).lower()}")
                else:
                    lines.append(f"    {k}: \"{v}\"")
        else:
            lines.append(f"  {svc}: {str(conf).lower()}")
    lines.append("")
    lines.append("providers:")
    for provider, conf in apm['providers'].items():
        if isinstance(conf, dict):
            lines.append(f"  {provider}:")
            for k, v in conf.items():
                if isinstance(v, bool):
                    lines.append(f"    {k}: {str(v).lower()}")
                else:
                    lines.append(f"    {k}: \"{v}\"")
        else:
            lines.append(f"  {provider}: {str(conf).lower()}")
    lines.append("")
    lines.append("tools:")
    for tool, conf in apm['tools'].items():
        lines.append(f"  {tool}:")
        lines.append(f"    version: \"{conf['version']}\"")

    # Write output
    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text('\n'.join(lines) + '\n')
    print(f"Generated: {output_path}")

toml_to_apm(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
PYEOF

  log "apm.yml generated: $output"
}

# ── Generate minimal apm.yml (no TOML input) ────────────────────────────────
_apm_generate_minimal() {
  local output="${1:-$_APM_YML}"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$output" <<EOF
# apm.yml — Minimal configuration (no setup.toml provided)
# Schema: $_APM_SCHEMA_VERSION
# Generated: $now

schema_version: "1.0.0"

package:
  name: "$_APM_PACKAGE_NAME"
  version: "$_APM_PACKAGE_VERSION"
  description: "Unified AI-powered developer machine bootstrapper"
  homepage: "https://github.com/AlexanderNarbaev/opencode_initializer"
  repository: "https://github.com/AlexanderNarbaev/opencode_initializer"
  license: "MIT"
  maintainers:
    - name: "Alexander Narbaev"
      email: "alex@example.com"
  tags:
    - "ai"
    - "developer-tools"
    - "bootstrapper"
    - "opencode"

dependencies:
  - name: "docker"
    version: ">=24.0"
    optional: false
  - name: "nodejs"
    version: ">=24"
    optional: false
  - name: "python"
    version: ">=3.14"
    optional: false
  - name: "go"
    version: ">=1.26"
    optional: true
  - name: "rust"
    version: ">=1.97"
    optional: true

features:
  docker:
    enabled: true
  nodejs:
    version: "24"
  python:
    version: "3.14"
  go:
    version: "1.26"
  rust:
    version: "1.97"

services:
  postgres:
    enabled: true
  qdrant:
    enabled: true
  redis:
    enabled: true
  prometheus:
    enabled: true
  grafana:
    enabled: true

providers:
  deepseek:
    enabled: true
  opencode:
    enabled: true
  minimax:
    enabled: true
  mimo:
    enabled: true

tools:
  nodejs:
    version: "24"
  python:
    version: "3.14"
  go:
    version: "1.26"
  rust:
    version: "1.97"
  java:
    version: "25"
  dotnet:
    version: "10"
EOF

  log "Minimal apm.yml generated: $output"
}

# ── Export to SBOM (Software Bill of Materials) ─────────────────────────────
# Usage: _apm_export_sbom [output_path]
# Generates CycloneDX-compatible SBOM from apm.yml.
_apm_export_sbom() {
  local apm_file="${1:-$_APM_YML}"
  local output="${2:-${DL_CACHE}/sbom.json}"

  if [ ! -f "$apm_file" ]; then
    warn "apm.yml not found — cannot export SBOM"
    return 1
  fi

  python3 - "$apm_file" "$output" <<'PYEOF'
import sys
import json
from datetime import datetime

def apm_to_sbom(apm_path, sbom_path):
    """Convert apm.yml to CycloneDX SBOM format."""
    # Parse YAML manually (no PyYAML dependency)
    with open(apm_path, 'r') as f:
        content = f.read()

    # Extract package info
    name = "opencode-initializer"
    version = "v3.5.0"

    sbom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "serialNumber": f"urn:uuid:{hash(apm_path)}",
        "version": 1,
        "metadata": {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "component": {
                "type": "application",
                "name": name,
                "version": version
            }
        },
        "components": []
    }

    # Add dependencies as components
    # Simple YAML parsing for dependencies section
    in_deps = False
    current_dep = {}
    for line in content.split('\n'):
        line = line.rstrip()
        if line.strip() == 'dependencies:':
            in_deps = True
            continue
        if in_deps:
            if line.startswith('  - name:'):
                if current_dep:
                    sbom['components'].append(current_dep)
                dep_name = line.split(':', 1)[1].strip().strip('"')
                current_dep = {
                    "type": "library",
                    "name": dep_name,
                    "version": "latest"
                }
            elif line.strip().startswith('version:'):
                ver = line.split(':', 1)[1].strip().strip('"')
                current_dep['version'] = ver
            elif line.strip().startswith('optional:'):
                opt = line.split(':', 1)[1].strip().lower()
                current_dep['optional'] = opt == 'true'
            elif not line.startswith('    ') and not line.startswith('  -'):
                if current_dep:
                    sbom['components'].append(current_dep)
                    current_dep = {}
                in_deps = False

    if current_dep:
        sbom['components'].append(current_dep)

    with open(sbom_path, 'w') as f:
        json.dump(sbom, f, indent=2)
    print(f"SBOM exported: {sbom_path}")

apm_to_sbom(sys.argv[1], sys.argv[2])
PYEOF

  log "SBOM exported: $output"
}

# ── APM install command ─────────────────────────────────────────────────────
# Usage: _apm_install
# Generates apm.yml and SBOM, ready for `apm install` integration.
_apm_install() {
  section "APM Preparation"

  # Generate apm.yml
  if [ -n "${CONFIG_TOML:-}" ] && [ -f "$CONFIG_TOML" ]; then
    _apm_generate "$CONFIG_TOML"
  else
    _apm_generate_minimal
  fi

  # Export SBOM
  _apm_export_sbom

  log "APM preparation complete"
  info "  apm.yml: $_APM_YML"
  info "  SBOM: ${DL_CACHE}/sbom.json"
  info "  Future: apm install $_APM_PACKAGE_NAME"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _apm_generate _apm_generate_minimal _apm_export_sbom _apm_install 2>/dev/null || true
