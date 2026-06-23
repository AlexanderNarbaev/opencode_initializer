# Продвинутое руководство

Глубокое погружение в кастомизацию, оптимизацию и продвинутые сценарии.

## Пользовательская конфигурация

### Файл конфигурации

Постоянные настройки в `~/.config/opencode-setup/setup.conf`:

```bash
dev config
```

### Пользовательский ZSH

Добавьте свои плагины, темы и алиасы в `~/.zshrc.local`:

```bash
# ~/.zshrc.local — не управляется установщиком
export EDITOR=vim
alias k="kubectl"
alias tf="terraform"
```

### Пользовательский opencode.json

```bash
# Пересоздать
bash setup.sh --fix-config

# Или вручную
vim ~/opencode_initializer/opencode.json
```

## WSL2 — глубокое погружение

### Оптимизация .wslconfig

Установщик создаёт `%USERPROFILE%\.wslconfig` на Windows:

```ini
[wsl2]
memory=8GB
processors=4
localhostForwarding=true
nestedVirtualization=false
networkingMode=mirrored
```

Настройте под своё железо:

| RAM | Рекомендуемый memory= |
|-----|----------------------|
| 16 GB | 8 GB |
| 32 GB | 16 GB |
| 64 GB | 32 GB |

### DNS в WSL2

Установщик добавляет Google DNS в `/etc/resolv.conf`. Для корпоративного DNS:

```bash
sudo sh -c 'echo "[network]\ngenerateResolvConf = false" > /etc/wsl.conf'
sudo sh -c 'echo "nameserver 10.0.0.1" > /etc/resolv.conf'
```

### Производительность файлов WSL2

- Работайте внутри Linux-файловой системы (`~/projects/`), не в `/mnt/c/`
- Установщик задаёт `~/projects` как папку проектов по умолчанию
- Межфайловые операции медленнее в 10-100 раз

## Настройка GPU

### Драйверы NVIDIA (Windows хост)

1. Установите [NVIDIA драйверы для WSL2](https://developer.nvidia.com/cuda/wsl)
2. Проверьте: `nvidia-smi` внутри WSL2

### CUDA Toolkit

```bash
nvcc --version
# Если нет:
sudo apt install nvidia-cuda-toolkit
```

### GPU для Ollama

```bash
ollama run llama3.2 "Какой GPU ты используешь?"
nvidia-smi -l 1
```

### Лимиты памяти GPU

Ограничьте память Ollama в `~/.ollama/config.toml`:

```toml
[gpu]
num_gpu = 1
main_gpu = 0
low_vram = false
```

## Docker

### Постустановочные шаги

```bash
# Добавить пользователя в группу docker (делает установщик)
sudo usermod -aG docker $USER
newgrp docker

docker run hello-world
```

### Docker Compose

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_PASSWORD: dev
    ports:
      - "5432:5432"
  redis:
    image: redis:7
    ports:
      - "6379:6379"
EOF

docker compose up -d
```

## LLM и RAG

### Управление моделями Ollama

```bash
ollama list                # Список установленных
ollama pull llama3.2       # 2 GB — общего назначения
ollama pull codellama      # 3.8 GB — генерация кода
ollama pull deepseek-r1    # 4.7 GB — рассуждения
ollama rm unused-model     # Удалить ненужное
ollama pull llama3.2       # Обновить модель
```

### Пользовательский Modelfile

```bash
cat > Modelfile << 'EOF'
FROM llama3.2
SYSTEM "Ты — senior Go разработчик. Предлагай идиоматичные решения на Go."
PARAMETER temperature 0.3
EOF

ollama create go-expert -f Modelfile
ollama run go-expert
```

### RAG система

Опциональная RAG система (`21-rag.sh`):
- Корпоративный ассистент знаний
- ETL пайплайн + прокси + Qdrant + Gemma
- Ингестия документов и семантический поиск

```bash
bash setup.sh --interactive  # Выбрать "RAG System"
```

## ChromaDB и Muninn

### Muninn — память AI

Muninn обеспечивает постоянную память для сессий OpenCode:

```bash
systemctl --user status chromadb
ls ~/.cache/chromadb/
```

## Переключение версий языков

| Язык | Команда |
|------|---------|
| Node.js | `nvm install 22 && nvm use 22` |
| Java | `sdk use java 21.0.2-tem` |
| Go | `go install golang.org/dl/go1.25@latest && go1.25 download` |
| Python | `uv python install 3.13` |
| Rust | `rustup default stable` |
| .NET | `dotnet --list-sdks` |

### Советы по языкам

#### Go
```bash
export GOPROXY=https://goproxy.cn,direct
mkdir -p ~/go/{bin,src,pkg}
```

#### Python
```bash
uv venv
source .venv/bin/activate
uv pip install requests
```

#### Node.js
```bash
npm config set registry https://registry.npmmirror.com
```

## CI/CD интеграция

### GitHub Actions

```yaml
- name: Setup Dev Environment
  run: |
    curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --reinit
```

### Pre-commit хуки

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## Безопасность

### Trivy — сканер контейнеров

```bash
trivy image python:3.14
trivy fs /
```

### Qodana — качество кода

```bash
qodana scan --project-dir ~/my-project
```

## Диагностика

### Сбросить всё

```bash
rm ~/.cache/opencode-setup/progress
bash setup.sh --reinit
```

### Режим отладки

```bash
bash -x setup.sh 2>&1 | tee debug.log
grep -i error debug.log
```

### Проблемы с сетью

```bash
_curl https://github.com
echo $GOPROXY
npm config get registry
pip config get global.index-url
```
