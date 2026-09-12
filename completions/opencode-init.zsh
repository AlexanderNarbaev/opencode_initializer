#compdef opencode-init
# completions/opencode-init.zsh — Zsh completion for opencode_initializer
# Source: fpath=(/path/to/completions $fpath); autoload -Uz compinit; compinit

_opencode_init() {
  local -a commands

  commands=(
    '--full[Run full installation]'
    '--health[Run health check]'
    '--dry-run[Check without installing]'
    '--version[Show version]'
    '--help[Show help]'
    '--config[Config file path]:file:_files -g "*.toml"'
    '--skip[Skip modules]:modules:'
    '--parallel[Parallel jobs]:jobs:'
    '--no-parallel[Disable parallel execution]'
    '--force[Force reinstall]'
    '--sync[Sync updates]'
    '--sync-force[Force sync updates]'
    '--auto-sync[Start auto-sync daemon]'
    '--security-scan[Run security scan]'
    '--install-hooks[Install git hooks]'
    '--benchmark[Run performance benchmark]'
    '--multi-agent[Generate all AI configs]'
    '--copilot[Generate Copilot config]'
    '--claude[Generate Claude config]'
    '--cursor[Generate Cursor config]'
    '--vscode[Generate VS Code config]'
    '--mirrors[Configure mirrors]:region:(ru cn global)'
    '--env-create[Create environment]:name:'
    '--env-switch[Switch environment]:env:(default work personal)'
    '--env-list[List environments]'
    '--env-show[Show environment]:env:'
    '--template-list[List templates]'
    '--template-new[Generate project]:template:(nextjs react vue angular svelte express fastify django fastapi flask spring-boot quarkus go-cli rust-cli docker k8s terraform)'
    '--apm[Generate APM manifest]'
    '--apm-install[Install via APM]'
    '--apm-update[Update via APM]'
    '--apm-info[Show APM info]'
    '--cloud-upload[Upload config to cloud]'
    '--cloud-download[Download config from cloud]'
    '--cloud-status[Show sync status]'
    '--gui-start[Start GUI dashboard]:port:'
    '--gui-stop[Stop GUI dashboard]'
    '--gui-status[Show GUI status]'
    '--discover-plugins[Discover new plugins]'
    '--plugin-health[Check plugin health]'
    '--workflow[Run workflow]:workflow:(setup update security optimize deploy)'
    '--list-workflows[List workflows]'
    '--print-config[Print resolved config]'
  )

  _arguments -s \
    $commands \
    '*::arg:->args'
}

_opencode_init "$@"
