# completions/opencode-init.fish — Fish completion for opencode_initializer
# Source: Copy to ~/.config/fish/completions/opencode-init.fish

# Main commands
complete -c opencode-init -l full -d "Run full installation"
complete -c opencode-init -l health -d "Run health check"
complete -c opencode-init -l dry-run -d "Check without installing"
complete -c opencode-init -l version -d "Show version"
complete -c opencode-init -l help -d "Show help"

# Configuration
complete -c opencode-init -l config -d "Config file path" -r -F
complete -c opencode-init -l print-config -d "Print resolved config"
complete -c opencode-init -l skip -d "Skip modules" -x
complete -c opencode-init -l parallel -d "Parallel jobs" -x
complete -c opencode-init -l no-parallel -d "Disable parallel execution"
complete -c opencode-init -l force -d "Force reinstall"

# Sync and updates
complete -c opencode-init -l sync -d "Sync updates"
complete -c opencode-init -l sync-force -d "Force sync updates"
complete -c opencode-init -l auto-sync -d "Start auto-sync daemon"

# Security and benchmark
complete -c opencode-init -l security-scan -d "Run security scan"
complete -c opencode-init -l install-hooks -d "Install git hooks"
complete -c opencode-init -l benchmark -d "Run performance benchmark"

# Multi-agent
complete -c opencode-init -l multi-agent -d "Generate all AI configs"
complete -c opencode-init -l copilot -d "Generate Copilot config"
complete -c opencode-init -l claude -d "Generate Claude config"
complete -c opencode-init -l cursor -d "Generate Cursor config"
complete -c opencode-init -l vscode -d "Generate VS Code config"

# Mirrors
complete -c opencode-init -l mirrors -d "Configure mirrors" -x -a "ru cn global"

# Environments
complete -c opencode-init -l env-create -d "Create environment" -x
complete -c opencode-init -l env-switch -d "Switch environment" -x -a "default work personal"
complete -c opencode-init -l env-list -d "List environments"
complete -c opencode-init -l env-show -d "Show environment" -x

# Templates
complete -c opencode-init -l template-list -d "List templates"
complete -c opencode-init -l template-new -d "Generate project" -x -a "nextjs react vue angular svelte express fastify django fastapi flask spring-boot quarkus go-cli rust-cli docker k8s terraform"

# APM
complete -c opencode-init -l apm -d "Generate APM manifest"
complete -c opencode-init -l apm-install -d "Install via APM"
complete -c opencode-init -l apm-update -d "Update via APM"
complete -c opencode-init -l apm-info -d "Show APM info"

# Cloud sync
complete -c opencode-init -l cloud-upload -d "Upload config to cloud"
complete -c opencode-init -l cloud-download -d "Download config from cloud"
complete -c opencode-init -l cloud-status -d "Show sync status"

# GUI
complete -c opencode-init -l gui-start -d "Start GUI dashboard" -x
complete -c opencode-init -l gui-stop -d "Stop GUI dashboard"
complete -c opencode-init -l gui-status -d "Show GUI status"

# Plugins
complete -c opencode-init -l discover-plugins -d "Discover new plugins"
complete -c opencode-init -l plugin-health -d "Check plugin health"

# Workflows
complete -c opencode-init -l workflow -d "Run workflow" -x -a "setup update security optimize deploy"
complete -c opencode-init -l list-workflows -d "List workflows"
