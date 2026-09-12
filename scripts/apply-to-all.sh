#!/usr/bin/env bash
# apply-to-all.sh — Apply common configurations to all projects
set -euo pipefail

PROJECTS_DIR="/home/alexandr-narbaev/Projects"
OPI_DIR="$PROJECTS_DIR/opencode_initializer"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; }

# ── Apply renovate.json ─────────────────────────────────────────────────────
apply_renovate() {
  local project_dir="$1"
  local project_name=$(basename "$project_dir")

  if [ -f "$project_dir/renovate.json" ]; then
    warn "$project_name: renovate.json already exists"
    return 0
  fi

  cp "$OPI_DIR/renovate.json" "$project_dir/renovate.json"
  log "$project_name: renovate.json applied"
}

# ── Apply mise.toml ──────────────────────────────────────────────────────────
apply_mise() {
  local project_dir="$1"
  local project_name=$(basename "$project_dir")

  if [ -f "$project_dir/mise.toml" ]; then
    warn "$project_name: mise.toml already exists"
    return 0
  fi

  # Detect project type and create appropriate mise.toml
  if [ -f "$project_dir/package.json" ]; then
    cat > "$project_dir/mise.toml" << 'EOF'
[tools]
node = "24"

[tasks.dev]
description = "Run development server"
run = "npm run dev"

[tasks.test]
description = "Run tests"
run = "npm test"

[tasks.build]
description = "Build project"
run = "npm run build"

[tasks.lint]
description = "Run linter"
run = "npm run lint"
EOF
    log "$project_name: mise.toml applied (Node.js)"
  elif [ -f "$project_dir/pyproject.toml" ]; then
    cat > "$project_dir/mise.toml" << 'EOF'
[tools]
python = "3.14"

[tasks.dev]
description = "Run development server"
run = "python -m uvicorn main:app --reload"

[tasks.test]
description = "Run tests"
run = "pytest"

[tasks.lint]
description = "Run linter"
run = "ruff check ."

[tasks.fmt]
description = "Format code"
run = "ruff format ."
EOF
    log "$project_name: mise.toml applied (Python)"
  elif [ -f "$project_dir/Cargo.toml" ]; then
    cat > "$project_dir/mise.toml" << 'EOF'
[tools]
rust = "stable"

[tasks.dev]
description = "Run development"
run = "cargo run"

[tasks.test]
description = "Run tests"
run = "cargo test"

[tasks.build]
description = "Build project"
run = "cargo build --release"

[tasks.lint]
description = "Run linter"
run = "cargo clippy"
EOF
    log "$project_name: mise.toml applied (Rust)"
  elif [ -f "$project_dir/go.mod" ]; then
    cat > "$project_dir/mise.toml" << 'EOF'
[tools]
go = "1.26"

[tasks.dev]
description = "Run development"
run = "go run ."

[tasks.test]
description = "Run tests"
run = "go test ./..."

[tasks.build]
description = "Build project"
run = "go build ."

[tasks.lint]
description = "Run linter"
run = "golangci-lint run"
EOF
    log "$project_name: mise.toml applied (Go)"
  else
    # Generic mise.toml
    cat > "$project_dir/mise.toml" << 'EOF'
[tasks.test]
description = "Run tests"
run = "echo 'Add test command'"

[tasks.lint]
description = "Run linter"
run = "echo 'Add lint command'"
EOF
    log "$project_name: mise.toml applied (generic)"
  fi
}

# ── Apply .editorconfig ─────────────────────────────────────────────────────
apply_editorconfig() {
  local project_dir="$1"
  local project_name=$(basename "$project_dir")

  if [ -f "$project_dir/.editorconfig" ]; then
    warn "$project_name: .editorconfig already exists"
    return 0
  fi

  cat > "$project_dir/.editorconfig" << 'EOF'
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false

[*.py]
indent_size = 4

[*.go]
indent_style = tab

[Makefile]
indent_style = tab
EOF
  log "$project_name: .editorconfig applied"
}

# ── Apply .gitignore additions ───────────────────────────────────────────────
apply_gitignore() {
  local project_dir="$1"
  local project_name=$(basename "$project_dir")

  if [ ! -f "$project_dir/.gitignore" ]; then
    cat > "$project_dir/.gitignore" << 'EOF'
# Dependencies
node_modules/
__pycache__/
.venv/
venv/
target/
dist/
build/

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Environment
.env
.env.local
.env.*.local

# Cache
.cache/
*.cache
EOF
    log "$project_name: .gitignore created"
  else
    warn "$project_name: .gitignore already exists"
  fi
}

# ── Apply GitHub workflows ───────────────────────────────────────────────────
apply_github_workflows() {
  local project_dir="$1"
  local project_name=$(basename "$project_dir")

  if [ ! -d "$project_dir/.github/workflows" ]; then
    mkdir -p "$project_dir/.github/workflows"
  fi

  # Shellcheck workflow for bash projects
  if ls "$project_dir"/*.sh "$project_dir"/src/**/*.sh 2>/dev/null | head -1 > /dev/null 2>&1; then
    if [ ! -f "$project_dir/.github/workflows/shellcheck.yml" ]; then
      cat > "$project_dir/.github/workflows/shellcheck.yml" << 'EOF'
name: ShellCheck

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ShellCheck
        run: sudo apt-get install -y shellcheck
      - name: Run ShellCheck
        run: find . -name "*.sh" -exec shellcheck {} +
EOF
      log "$project_name: shellcheck.yml applied"
    fi
  fi

  # Test workflow
  if [ ! -f "$project_dir/.github/workflows/test.yml" ]; then
    if [ -f "$project_dir/package.json" ]; then
      cat > "$project_dir/.github/workflows/test.yml" << 'EOF'
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [20, 22, 24]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm ci
      - run: npm test
EOF
      log "$project_name: test.yml applied (Node.js)"
    elif [ -f "$project_dir/pyproject.toml" ]; then
      cat > "$project_dir/.github/workflows/test.yml" << 'EOF'
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.12", "3.13", "3.14"]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - run: pip install -e ".[dev]" || pip install -e .
      - run: pytest || python -m pytest
EOF
      log "$project_name: test.yml applied (Python)"
    fi
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
echo "=== Applying configurations to all projects ==="
echo ""

for dir in "$PROJECTS_DIR"/*/; do
  if [ -d "$dir/.git" ]; then
    project_name=$(basename "$dir")
    echo "--- $project_name ---"

    apply_renovate "$dir"
    apply_mise "$dir"
    apply_editorconfig "$dir"
    apply_gitignore "$dir"
    apply_github_workflows "$dir"

    echo ""
  fi
done

echo "=== Done ==="
