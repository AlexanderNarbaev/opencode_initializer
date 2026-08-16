# Руководство по DeepSeek Harness

> [EN](deepseek-harness-guide.md) | [RU](deepseek-harness-guide.ru.md)

## Обзор

[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) — открытый agent-харнесс от DeepSeek: *«всё — плагин»*, построен на фреймворке [Cordis](https://github.com/deepseek-ai/deepseek-harness). Предоставляет плагинную архитектуру и Web UI для оркестрации AI-агентов.

Устанавливается модулем `49-deepseek-harness.sh`.

!!! note "Developer preview"
    DeepSeek Harness находится в developer preview — возможны изменения, ломающие совместимость. Лицензия MIT.

## Предварительные требования

- **Node.js 24** (устанавливается модулем `06-node.sh`)

Модуль пропускает установку, если Node.js отсутствует или `dsh` уже есть в `PATH`.

## Установка

```bash
npm install -g @deepseek-ai/dsh@latest
```

## Конфигурация

Профиль плагинов по умолчанию записывается в `~/.config/deepseek-harness/cordis.yml`:

```yaml
# DeepSeek Harness — профиль плагинов по умолчанию (управляется opencode_initializer)
# dsh — «всё — плагин» (Cordis). Подключайте дополнительные плагины здесь.
```

Расширяйте его дополнительными плагинами согласно [каталогу конфигурации](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/config-catalog.md).

## Web UI

Web UI доступен по адресу `http://127.0.0.1:3080` по умолчанию. Порт переопределяется через `DSH_WEB_PORT`.

```bash
npx @deepseek-ai/dsh web
# или запустите пользовательский systemd-сервис
systemctl --user start deepseek-harness.service
```

## Проверка работоспособности

```bash
dsh --version                          # установленная версия
curl -fsS http://127.0.0.1:3080        # Web UI запущен?
```

## Пропуск

Установите `SKIP_DEEPSEEK_HARNESS=true`, чтобы пропустить этот модуль при установке.
