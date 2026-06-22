---
layout: default
title: Troubleshooting — Решение проблем
description: Пошаговое руководство по диагностике и исправлению типовых проблем
nav_order: 6
---

[← Главная](index.md) · [FAQ](faq.md) · [Руководство](guide.md) · [Справка](reference.md)

# Troubleshooting — Решение проблем

## Как запустить диагностику

Первый шаг при любой проблеме — диагностика:

```bash
dev health                    # 54+ проверок: CLI, MCP, плагины, конфигурация
dev version-check             # сравнение версий с последними релизами
bash setup.sh --health        # то же самое без CLI dev
```

**Логи**: `~/setup-*.log` — логи установки. `journalctl -u opencode-*` — логи systemd-сервисов (ChromaDB, Ollama, autoupdate). `journalctl -xe` — последние системные ошибки.

---

## Проблемы с сетью / зеркалами

### Симптомы

- `curl: (6) Could not resolve host`
- `npm ERR! network`
- Таймауты при загрузке пакетов
- Медленная установка (>30 минут)

### Диагностика

```bash
cat /etc/resolv.conf                           # DNS-серверы
ping -c 3 8.8.8.8                              # доступность Google DNS
curl -I --connect-timeout 5 https://github.com # доступность GitHub
curl -I --connect-timeout 5 https://registry.npmjs.org  # npm registry
echo $GOPROXY                                   # проверка Go-прокси
```

### Исправления

**DNS недоступен** — скрипт добавляет 8.8.8.8, 1.1.1.1, 77.88.8.8. Проверьте, что они есть в `/etc/resolv.conf`. Если файл перезаписан systemd-resolved — добавьте в `/etc/systemd/resolved.conf`:
```ini
[Resolve]
DNS=8.8.8.8 1.1.1.1 77.88.8.8
```
Затем `sudo systemctl restart systemd-resolved`.

**GitHub недоступен (РФ)** — скрипт использует зеркала `ghproxy.net` и `mirror.ghproxy.com`. Проверьте: `git clone --depth 1 https://ghproxy.net/https://github.com/test/repo /tmp/test`. Если блокировка — VPN или прокси.

**npm registry недоступен** — скрипт использует `https://registry.npmmirror.com` как fallback. Вручную: `npm config set registry https://registry.npmmirror.com`. После установки верните обратно: `npm config delete registry`.

**Медленная загрузка пакетов** — все `curl`-запросы идут через `_curl()` (5 повторов с экспоненциальной задержкой) и кешируются на 24 часа в `~/.cache/opencode-setup/`. Повторный запуск использует кеш.

### Проверка исправления

```bash
curl -fsSL --connect-timeout 10 https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh > /dev/null && echo "OK"
```

---

## Проблемы с правами доступа

### Симптомы

- `Permission denied`
- `sudo: a password is required`
- `chsh: PAM: Authentication failure`
- `usermod: user does not exist`

### Диагностика

```bash
whoami                            # текущий пользователь
groups                            # группы пользователя
sudo -v                           # проверка sudo-доступа
ls -la ~/secrets.env              # права на секреты
ls -la ~/.zshrc                   # права на shell-rc
```

### Исправления

**Нет sudo-доступа** — добавьте пользователя в sudo: `su - root -c "usermod -aG sudo $USER"`. Перелогиньтесь. На WSL2 sudo обычно настроен по умолчанию.

**chsh не меняет shell** — WSL2 не использует `chsh`. Настройте shell в `/etc/wsl.conf`:
```ini
[boot]
systemd=true

[user]
default=$USER
```
Для обычного Linux: `sudo chsh -s $(which zsh) $USER`. Если ошибка PAM — используйте `sudo usermod -s $(which zsh) $USER`.

**secrets.env доступен другим пользователям** — `chmod 600 ~/secrets.env`. Проверьте: `ls -la ~/secrets.env` должно показывать `-rw-------`.

### Проверка исправления

```bash
sudo -n true && echo "sudo OK"
echo $SHELL | grep zsh && echo "Shell is ZSH"
stat -c "%a %n" ~/secrets.env | grep "^600" && echo "Permissions OK"
```

---

## Проблемы с пакетами

### Симптомы

- `npm ERR! EACCES: permission denied`
- `cargo: command not found` или `error: linker 'cc' not found`
- `pip: error: externally-managed-environment`
- `uv: command not found`

### Диагностика

```bash
npm config get prefix                     # npm-префикс
which node && node --version
which cargo && cargo --version
which python3.14 && python3.14 --version
which uv && uv --version
echo $PATH | tr ':' '\n' | head -20       # переменная PATH
```

### Исправления

**npm EACCES** — скрипт настраивает npm-префикс `~/.npm-global`, чтобы избежать прав root. Проверьте: `npm config get prefix` должно показывать `~/.npm-global`. Если нет — `npm config set prefix ~/.npm-global` и добавьте в `.zshrc`: `export PATH="$HOME/.npm-global/bin:$PATH"`.

**cargo build fails (linker not found)** — установите build-essential: `sudo apt install build-essential pkg-config libssl-dev -y`. Для кросс-компиляции: `rustup target add wasm32-unknown-unknown x86_64-unknown-linux-musl`.

**pip conflicts** — скрипт использует `uv` и `pipx` для изоляции. Никогда не ставьте пакеты через `sudo pip install`. Используйте: `uv pip install <pkg>` или `pipx install <pkg>`.

**Python 3.14 не найден** — скрипт устанавливает через PPA `deadsnakes`. Если PPA недоступен — установите вручную: `sudo add-apt-repository ppa:deadsnakes/ppa -y && sudo apt update && sudo apt install python3.14 python3.14-venv -y`.

### Проверка исправления

```bash
npm install -g cowsay 2>/dev/null && cowsay "OK" && npm uninstall -g cowsay
cargo new /tmp/test-cargo && cd /tmp/test-cargo && cargo build && rm -rf /tmp/test-cargo
python3.14 -c "print('OK')"
```

---

## Проблемы с ZSH

### Симптомы

- Плагины не грузятся (fzf-tab не работает, автодополнение отсутствует)
- Тема P10k не применяется (стандартный prompt)
- `compinit: insecure directories` warnings
- `zsh compinit: insecure files` при каждом запуске

### Диагностика

```bash
zsh --version                          # должно быть ≥ 5.8
echo $ZSH                              # путь к Oh My Zsh
echo $ZSH_THEME                        # тема (должно быть "powerlevel10k/powerlevel10k")
echo $plugins                          # список плагинов
ls ~/.oh-my-zsh/custom/plugins/        # кастомные плагины
compaudit                              # проблемы с правами compinit
```

### Исправления

**Плагины не грузятся** — проверьте `~/.zshrc`: строка `plugins=(...)` не должна быть закомментирована. После правки запустите `exec zsh`. Если плагины всё ещё не работают — `bash setup.sh --fix-zshrc` перегенерирует `.zshrc` со стандартным набором.

**Тема P10k не применяется** — в `~/.zshrc` должно быть `ZSH_THEME="powerlevel10k/powerlevel10k"`. Если P10k не установлен: `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k`. После этого `exec zsh` и пройдите конфигурацию `p10k configure`.

**compinit insecure directories** — проблема с правами на директории Oh My Zsh. Исправление:
```bash
compaudit | xargs chmod g-w,o-w
```
Или проще: `bash setup.sh --fix-zshrc` — скрипт применит нужные права автоматически.

**ZSH не является shell по умолчанию** — `echo $SHELL` показывает `/bin/bash`. Исправление: `which zsh | sudo tee -a /etc/shells && sudo chsh -s $(which zsh) $USER`. В WSL2 это не нужно, shell задаётся в терминале.

### Проверка исправления

```bash
zsh -c "echo plugins loaded: \$plugins" | grep fzf-tab && echo "OK"
p10k &>/dev/null && echo "P10k theme active"
compaudit 2>&1 | grep -q "no issues" && echo "compinit OK"
```

---

## Проблемы с MCP-серверами

### Симптомы

- MCP-сервер не стартует в OpenCode
- `Error: connect ECONNREFUSED`
- `Error: port already in use`
- `command not found: <mcp-server>`

### Диагностика

```bash
dev health | grep -A1 "MCP Servers"   # быстрая проверка всех MCP
which c7-mcp-server                     # путь к серверу (должен быть в ~/.bun/bin/)
ls ~/.bun/bin/                          # все bun-бинарники
npm list -g --depth=0 2>/dev/null       # глобальные npm-пакеты MCP
ps aux | grep mcp                       # запущенные MCP-процессы
```

### Исправления

**MCP не найден (command not found)** — проверьте `which <сервер>`. Если нет — `npm install -g <пакет>` или `bash setup.sh --reinit` (только MCP/LSP секция). Убедитесь, что `~/.bun/bin` есть в PATH: `echo $PATH | grep ".bun/bin"`.

**Connection refused (порт занят)** — найдите процесс: `lsof -i :PORT` или `ss -tlnp | grep PORT`. Убейте: `kill -9 PID`. Для remote MCP измените порт в `opencode.json` → `"url": "http://localhost:3002/sse"`.

**Ошибка npx / npm pack** — скрипт использует локальный кеш `.tgz` файлов в `~/.cache/opencode-setup/mcp-cache/`. Очистите кеш: `rm -rf ~/.cache/opencode-setup/mcp-cache/`. Затем `bash setup.sh --reinit`.

**ChromaDB не стартует (systemd)** — проверьте сервис: `systemctl status chromadb`. Если failed — `journalctl -u chromadb -n 50` для логов. Перезапуск: `sudo systemctl restart chromadb`. Порт по умолчанию: 8000.

### Проверка исправления

```bash
c7-mcp-server --version 2>/dev/null && echo "context7 OK"
curl -s http://localhost:8000/api/v1/heartbeat 2>/dev/null && echo "ChromaDB OK"
timeout 2 playwright-mcp --version 2>/dev/null && echo "playwright OK"
```

---

## Проблемы с OpenCode

### Симптомы

- `Error: Cannot parse opencode.json`
- `Error: Model not found` или `Provider not configured`
- `Error: Provider returned 401 / 403`
- OpenCode стартует, но не отвечает на запросы

### Диагностика

```bash
opencode --version                                    # версия OpenCode
python3 -m json.tool ~/opencode.json > /dev/null      # валидность JSON
grep '"model"' ~/opencode.json                        # текущая модель
grep -A5 '"provider"' ~/opencode.json                 # настроенные провайдеры
cat ~/secrets.env                                     # проверка ключей
bash setup.sh --health | grep -i "provider\|model"    # health-проверка
```

### Исправления

**opencode.json не читается** — JSON невалиден. Причина: комментарии `//` в неправильном месте или запятые после последнего элемента. Исправление: `bash setup.sh --fix-config` — полная перегенерация конфига.

**Модель не найдена (Provider not configured)** — проверьте, что в `opencode.json` секция `"provider"` содержит нужного провайдера. Если DeepSeek — нужен ключ в `~/secrets.env`: `DEEPSEEK_API_KEY=sk-...`. После добавления ключа: `bash setup.sh --fix-config`.

**401 / 403 ошибка провайдера** — ключ недействителен или просрочен. Проверьте баланс на платформе провайдера. Для DeepSeek: [platform.deepseek.com](https://platform.deepseek.com/) → Billing. Попробуйте ключ напрямую:
```bash
curl -s https://api.deepseek.com/models -H "Authorization: Bearer sk-YOUR_KEY"
```

**OpenCode не отвечает** — проверьте процессы: `ps aux | grep opencode`. Перезапустите: `pkill opencode && opencode`. Проверьте журнал: `journalctl -u opencode --no-pager -n 50` (если работает как systemd-сервис).

### Проверка исправления

```bash
bash setup.sh --fix-config && echo "config regenerated"
```
В самом OpenCode: отправьте `/model` чтобы увидеть текущую модель, `/providers` — список провайдеров.

---

## Проблемы с Docker

### Симптомы

- `docker: permission denied`
- `docker: Cannot connect to the Docker daemon`
- `docker: Error response from daemon: iptables failed`
- Контейнеры не видят сеть в WSL2

### Диагностика

```bash
docker --version                          # установлен ли Docker
docker ps                                 # работает ли демон
systemctl status docker                   # статус systemd-сервиса
groups | grep docker                      # пользователь в группе docker
sudo docker run --rm hello-world          # тестовый контейнер
```

### Исправления

**Permission denied** — пользователь не в группе `docker`. Исправление: `sudo usermod -aG docker $USER`, затем `newgrp docker` или перелогиньтесь.

**Daemon not running** — `sudo systemctl start docker` и `sudo systemctl enable docker`. Если systemd не работает (старые контейнеры WSL2) — `sudo dockerd &` для ручного запуска.

**WSL2 integration** — Docker Desktop в Windows должен иметь галочку напротив вашего дистрибутива (Settings → Resources → WSL Integration → ваш дистрибутив). Если Docker установлен внутри WSL2 (без Docker Desktop) — настройте `iptables: false` в `/etc/docker/daemon.json`: `{"iptables": false}`.

**iptables failed** — в WSL2 с новыми ядрами нужен `iptables` в legacy-режиме: `sudo update-alternatives --set iptables /usr/sbin/iptables-legacy`. Затем `sudo systemctl restart docker`.

### Проверка исправления

```bash
docker run --rm hello-world | grep "Hello from Docker" && echo "Docker OK"
docker compose version && echo "Compose OK"
```

---

## Проблемы с GPU / LLM

### Симптомы

- `CUDA not found` / `nvidia-smi: command not found`
- `ollama: error: out of memory`
- `ollama pull` зависает или выдаёт ошибку сети
- vLLM не стартует: `ImportError: torch`

### Диагностика

```bash
nvidia-smi                                # доступность GPU
ollama list                               # установленные модели
ollama ps                                 # запущенные модели
systemctl status ollama                   # статус сервиса Ollama
df -h ~/.ollama/models/                   # свободное место
nvidia-smi --query-gpu=memory.free --format=csv  # свободная VRAM
```

### Исправления

**CUDA not found** — установите драйвер NVIDIA (версия 525+). WSL2: драйвер ставится в Windows, не в WSL. Linux: `sudo apt install nvidia-driver-550`. Проверьте после установки: `nvidia-smi`. Не работает — перезагрузите систему.

**Out of memory (Ollama)** — модель слишком большая для вашего GPU. Проверьте свободную VRAM: `nvidia-smi --query-gpu=memory.free --format=csv`. Правило: размер модели в GB × 1.2 ≤ свободная VRAM. Используйте модель меньшего размера: `ollama pull qwen3:4b` вместо `qwen3:30b`. Остановите другие модели: `ollama stop <model>`.

**Модель не качается** — проверьте сеть: `curl -I https://ollama.com`. Если сайт недоступен (РФ) — VPN или прокси. Альтернатива: скачайте GGUF-файл модели вручную с Hugging Face и создайте Modelfile: `ollama create my-model -f Modelfile`.

**vLLM не стартует** — vLLM требует CUDA toolkit и PyTorch с CUDA. Проверьте: `python3 -c "import torch; print(torch.cuda.is_available())"`. Если False — переустановите PyTorch: `uv pip install torch --index-url https://download.pytorch.org/whl/cu118`. Проверьте совместимость версий CUDA: `nvcc --version` и `python3 -c "import torch; print(torch.version.cuda)"`.

### Проверка исправления

```bash
nvidia-smi | grep "Driver Version" && echo "GPU OK"
ollama run qwen3:1.8b "Say hello" 2>&1 | head -5 && echo "Ollama OK"
curl -s http://localhost:11434/api/tags | python3 -m json.tool | head -10
```
