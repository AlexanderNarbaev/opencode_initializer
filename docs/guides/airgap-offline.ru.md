# Air-Gap и офлайн-установка

v3.0.0 предоставляет полную поддержку air-gap: офлайн-установка, команды `dev bundle` и режим Isolated Circuit.

## Быстрый старт

```bash
# На онлайн-машине — создаём офлайн-бандл
dev bundle create /mnt/usb/opencode-bundle.tar.gz

# На изолированной машине
bash setup.sh --airgap --bundle /mnt/usb/opencode-bundle.tar.gz
```

## Создание офлайн-бандла

```bash
# Создать бандл со всеми зависимостями
dev bundle create /path/to/bundle.tar.gz

# Посмотреть содержимое
dev bundle list /path/to/bundle.tar.gz

# Проверить SHA-256 манифест
dev bundle verify /path/to/bundle.tar.gz
```

Бандл включает:
- Все 49 модулей (`src/lib/*.sh`)
- Оркестратор (`setup.sh`) и CLI (`dev.sh`)
- Бинарники MCP/LSP-серверов (из Bun-кэша)
- Файлы LLM-моделей (с флагом `--include-models`)
- Кэши зависимостей (npm, pip, Go modules)
- SHA-256 манифест на каждый файл

## Установка из бандла

```bash
# Полная офлайн-установка
bash setup.sh --airgap --bundle /path/to/bundle.tar.gz

# С API-ключами (предварительно настроенными, сеть не нужна)
bash setup.sh --airgap --bundle bundle.tar.gz \
  --deepseek-key "sk-..." --github-token "ghp_..."
```

## Isolated Circuit Mode

Air-gapped работа LLM с локальными бэкендами:

```bash
# Включить при установке
bash setup.sh --full --isolated

# Или включить после установки
dev isolated on

# Проверить текущее состояние
dev isolated status
```

Поддерживаемые локальные бэкенды:

| Бэкенд | Порт | Endpoint |
|--------|------|----------|
| Ollama | 11434 | `http://localhost:11434/v1` |
| vLLM | 8000 | `http://localhost:8000/v1` |
| SGLang | 30000 | `http://localhost:30000/v1` |

### Что блокируется

При `ISOLATED_CIRCUIT=true`:

| Gate | Эффект |
|------|--------|
| `version-check.sh` | Пропускается — нет сети для сравнения версий |
| `20-autoupdate.sh` | topgrade + unattended-upgrades отключены |
| `00-core.sh: _set_dns()` | No-op под `DRY_RUN` |
| `dev doctor` | Проверки провайдеров ограничены локальными endpoint'ами |
| `model-policy.json` | Авто-установка `mode: "allowlist"` только с локальными провайдерами |

## Верификация цепочки поставок

Каждый артефакт бандла верифицируется через SHA-256:

```bash
# _download_verify() — используется 46-offline-bundle.sh
_download_verify "https://example.com/tool.sh" "tool.sh" "abc123..."

# Манифест бандла
cat bundle-manifest.sha256
# abc123...  setup.sh
# def456...  src/lib/00-core.sh
# ...
```

## См. также

- [Профили развёртывания](deployment-profiles.md) — 4 типа профилей
- [Security & Compliance](../reference/security-compliance.md) — PII, аудит, SBOM
- [Model Governance](../reference/governance.md) — allowlist/blocklist
