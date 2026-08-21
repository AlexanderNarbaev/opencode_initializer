# Устранение неполадок

## Общие проблемы

### 1. setup.sh падает с ошибкой "LOG_FILE: unbound variable"

**Причина:** Переменная `LOG_FILE` не определена.

**Решение:** Обновите до последней версии:
```bash
git pull origin main
bash setup.sh --reinit
```

### 2. `dev` команды не работают в zsh

**Причина:** Файл `dev.sh` не имеет права на исполнение.

**Решение:**
```bash
chmod +x dev.sh
```

### 3. OpenCode Desktop не запускается

**Причина:** Нет прав sudo для установки .deb пакета.

**Решение:** Используйте user-space установку:
```bash
bash setup.sh --reinit
# Автоматически установит в ~/.local/share/opencode-desktop/
```

### 4. Build/Plan режимы не видны

**Причина:** Плагин `opencode-orchestrator` переопределяет агентов.

**Решение:** Удалите оркестратор из plugin array:
```bash
# Откройте ~/.config/opencode/opencode.json
# Удалите "opencode-orchestrator" из массива plugin
```

### 5. dsh (DeepSeek Harness) не работает

**Причина:** Node.js не установлен или dsh не в PATH.

**Решение:**
```bash
# Проверьте Node.js
node --version

# Переустановите dsh
npm install -g @deepseek-ai/dsh@latest

# Проверьте
dsh --version
```

### 6. MCP серверы не запускаются

**Причина:** Бинарники не установлены или не в PATH.

**Решение:**
```bash
# Проверьте установку
which c7-mcp-server codegraph playwright-mcp

# Переустановите если нужно
npm install -g @anthropic-ai/mcp-server-filesystem
npm install -g @anthropic-ai/mcp-server-github
```

### 7. LSP серверы не работают

**Причина:** Бинарники не установлены.

**Решение:**
```bash
# Установите LSP серверы
npm install -g typescript-language-server
npm install -g pyright
go install golang.org/x/tools/gopls@latest
cargo install rust-analyzer
```

### 8. har команды не работают

**Причина:** har не в PATH или не исполняемый.

**Решение:**
```bash
# Проверьте
which har
har version

# Если не найден
chmod +x scripts/har
ln -sf $(pwd)/scripts/har ~/.local/bin/har
```

### 9. GRACE семантика не работает

**Причина:** Python не установлен или модуль не найден.

**Решение:**
```bash
# Проверьте Python
python3 --version

# Проверьте модуль
bash -n src/lib/56-grace-semantics.sh

# Запустите тест
bash tests/unit/test_grace_semantics.sh
```

### 10. Контекст переполняется

**Причина:** Слишком много MCP/LSP серверов загружено.

**Решение:** Используйте контекстный селектор:
```bash
# Проверьте контекстный селектор
bash -n src/lib/52-context-selector.sh

# Настройте в opencode.json
# Используйте har context для проверки
har context
```

## Отладка

### Проверка статуса системы

```bash
# Полный статус
har status

# Диагностика
har doctor

# Проверка агентов
har agents

# Проверка плагинов
har plugins

# Проверка MCP
har mcp

# Проверка LSP
har lsp
```

### Проверка логов

```bash
# Лог setup.sh
cat ~/.cache/opencode-setup/setup-*.log | tail -50

# Лог har
cat ~/.cache/har/har.log | tail -50

# Лог OpenCode
cat ~/.cache/opencode/*.log | tail -50
```

### Проверка конфигурации

```bash
# Проверка opencode.json
cat ~/.config/opencode/opencode.json | python3 -m json.tool

# Проверка bundle.json
cat ~/.config/opencode/bundle.json | python3 -m json.tool

# Проверка setup.conf
cat ~/.config/opencode-setup/setup.conf
```

### Проверка тестов

```bash
# Все тесты
bash tests/run_tests.sh

# Конкретный тест
bash tests/unit/test_dryrun_dns.sh
bash tests/unit/test_hooks.sh
bash tests/unit/test_project.sh
```

## Производительность

### Медленная установка

**Причина:** Медленная сеть или зеркала.

**Решение:**
```bash
# Используйте российские зеркала
export USE_RUSSIAN_MIRRORS=true
bash setup.sh --reinit
```

### Медленные тесты

**Причина:** Некоторые тесты делают сетевые запросы.

**Решение:**
```bash
# Запускайте тесты с таймаутом
timeout 30 bash tests/unit/test_version_check.sh
```

### Высокое потребление памяти

**Причина:** Слишком много MCP серверов.

**Решение:**
```bash
# Отключите неиспользуемые MCP в opencode.json
# Используйте контекстный селектор
har context
```

## Безопасность

### PII утечки

**Причина:** PII guard не настроен.

**Решение:**
```bash
# Проверьте PII guard
bash -n src/lib/45-pii-guard.sh

# Настройте в opencode.json
# Используйте har grace hallucination для проверки
har grace hallucination <context> <output>
```

### Небезопасные команды

**Причина:** Vibeguard не настроен.

**Решение:**
```bash
# Проверьте vibeguard
npm list -g opencode-vibeguard

# Настройте в opencode.json
```

## Получение помощи

### Команды har

```bash
har help          # Общая помощь
har grace help    # Помощь по GRACE
har status        # Статус системы
har doctor        # Диагностика
```

### Документация

- [README](../README.md) — основная документация
- [README.ru](../README.ru.md) — русская документация
- [Architecture](architecture.md) — архитектура
- [Modules](modules.md) — модули
- [Configuration](configuration.md) — конфигурация

### GitHub Issues

https://github.com/AlexanderNarbaev/opencode_initializer/issues
