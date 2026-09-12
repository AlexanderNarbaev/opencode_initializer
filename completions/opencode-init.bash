#!/usr/bin/env bash
# completions/opencode-init.bash — Bash completion for opencode_initializer
# Source: . ~/.local/share/bash-completion/completions/opencode-init.bash

_opencode_init_completions() {
  local cur prev commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  commands="--full --health --dry-run --version --help --config --skip --parallel --no-parallel --force --sync --sync-force --auto-sync --security-scan --install-hooks --benchmark --multi-agent --copilot --claude --cursor --vscode --mirrors --env-create --env-switch --env-list --env-show --template-list --template-new --apm --apm-install --apm-update --apm-info --cloud-upload --cloud-download --cloud-status --gui-start --gui-stop --gui-status --discover-plugins --plugin-health --workflow --list-workflows --print-config"

  # Complete flags
  if [[ ${cur} == -* ]]; then
    COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
    return 0
  fi

  # Complete --config file
  if [[ ${prev} == --config ]]; then
    COMPREPLY=( $(compgen -f -X '!*.toml' -- ${cur}) )
    return 0
  fi

  # Complete --skip modules
  if [[ ${prev} == --skip ]]; then
    local modules="devbox gui caching chromadb providers infrastructure cockpit isolated services observability model-router wal best-practices upstream-sync lynis auditd deepseek-harness sandcastle opencode-desktop"
    COMPREPLY=( $(compgen -W "${modules}" -- ${cur}) )
    return 0
  fi

  # Complete --mirrors regions
  if [[ ${prev} == --mirrors ]]; then
    COMPREPLY=( $(compgen -W "ru cn global" -- ${cur}) )
    return 0
  fi

  # Complete --workflow names
  if [[ ${prev} == --workflow ]]; then
    COMPREPLY=( $(compgen -W "setup update security optimize deploy" -- ${cur}) )
    return 0
  fi

  # Complete --env-switch environments
  if [[ ${prev} == --env-switch ]]; then
    COMPREPLY=( $(compgen -W "default work personal" -- ${cur}) )
    return 0
  fi

  # Complete --template-new templates
  if [[ ${prev} == --template-new ]]; then
    local templates="nextjs react vue angular svelte express fastify django fastapi flask spring-boot quarkus go-cli rust-cli docker k8s terraform"
    COMPREPLY=( $(compgen -W "${templates}" -- ${cur}) )
    return 0
  fi
}

complete -F _opencode_init_completions opencode-init
complete -F _opencode_init_completions ./setup.sh
complete -F _opencode_init_completions bash\ setup.sh
