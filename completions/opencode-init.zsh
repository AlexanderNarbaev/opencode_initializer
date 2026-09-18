#compdef opencode-init
# completions/opencode-init.zsh — Zsh completion for opencode_initializer
# Source: fpath=(/path/to/completions $fpath); autoload -Uz compinit; compinit

_opencode_init() {
  local -a commands
  commands=(
    'install:Install components'
    'remove:Remove components'
    'update:Update components'
    'health:Run health checks'
    'list:List components'
    'config:Manage configuration'
    'self-update:Update opencode_initializer'
    'version-check:Check versions'
    'autoupdate:Enable auto-update'
    'backup:Manage backups'
    'state:Show state'
    'doctor:Run diagnostics'
    'infra:Manage infrastructure'
    'observability:Manage observability'
    'gui:Launch web GUI'
    'metrics:Show metrics'
    'plugins:Manage plugins'
    'isolated:Manage isolated circuit'
    'models:Manage models'
    'sandbox:Manage sandbox'
    'ci:Run CI mode'
    'docs:Manage documentation'
  )

  _describe 'command' commands
}

_opencode_init "$@"
