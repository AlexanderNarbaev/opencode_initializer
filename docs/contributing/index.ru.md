# Участие в проекте

Мы любим вклад сообщества! Вот как помочь сделать opencode_initializer лучше.

## :fontawesome-solid-code: Кодекс поведения

Проект следует [Contributor Covenant 2.1](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/CODE_OF_CONDUCT.md). Пожалуйста, прочитайте перед участием.

## :fontawesome-solid-bug: Сообщение об ошибках

1. Проверьте [существующие issues](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
2. Используйте [шаблон баг-репорта](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=bug_report.md)
3. Укажите: ОС, версию оболочки, версию установщика, полный вывод ошибки

## :fontawesome-solid-lightbulb: Предложения функций

1. Проверьте [существующие issues](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
2. Используйте [шаблон запроса функции](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=feature_request.md)
3. Опишите: проблему, предлагаемое решение, рассмотренные альтернативы

## :fontawesome-solid-code-pull-request: Pull Request'ы

### Настройка

```bash
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git
cd opencode_initializer
```

### Процесс разработки

1. **Создайте ветку**: `git checkout -b feat/my-feature`
2. **Внесите изменения**: скрипты, тесты, документация
3. **Тестируйте**: запустите набор тестов
4. **Линтинг**: ShellCheck и shfmt
5. **Коммит**: следуйте [Conventional Commits](https://www.conventionalcommits.org/)
6. **Пуш**: `git push origin feat/my-feature`
7. **PR**: создайте pull request на GitHub

### Стиль кода

| Правило | Пример |
|---------|--------|
| **2 пробела для отступа** | `  local var="value"` |
| **snake_case переменные** | `my_variable`, `SCRIPT_DIR` для глобальных |
| **`[[ ]]` вместо `[ ]`** | `if [[ -f "$file" ]]; then` |
| **`$(cmd)` вместо бэктиков** | `result=$(command)` |
| **`local` для всех переменных функций** | `local name="$1"` |
| **Кавычки вокруг переменных** | `"$HOME"`, не `$HOME` |
| **Без захардкоженных секретов** | Используйте CLI аргументы или env vars |
| **`set -euo pipefail`** | В начале каждого скрипта |
| **`set -o inherit_errexit`** | В setup.sh |

### Тестирование

```bash
# Полный набор тестов
bash tests/run_tests.sh

# Только проверка синтаксиса
bash -n setup.sh
for f in src/lib/*.sh src/modes/*.sh; do bash -n "$f"; done

# ShellCheck
shellcheck setup.sh src/lib/*.sh src/modes/*.sh

# Проверка форматирования
shfmt -d -i 2 -ci setup.sh src/lib/*.sh src/modes/*.sh
```

### Pre-commit хуки

```bash
pip install pre-commit
pre-commit install
```

Автоматически запускает ShellCheck, shfmt и gitleaks при каждом коммите.

## :fontawesome-solid-book: Документация

Документация собирается с помощью MkDocs Material:

```bash
source .venv-docs/bin/activate
mkdocs serve     # Локальный сервер
mkdocs build     # Сборка
mkdocs gh-deploy # Деплой (только мейнтейнеры)
```

## :fontawesome-solid-list-check: Чеклист PR

- [ ] Код следует стилю (2 пробела, snake_case)
- [ ] Нет захардкоженных секретов
- [ ] Новые функции покрыты тестами
- [ ] `bash -n` проходит на всех изменённых файлах
- [ ] `bash tests/run_tests.sh` проходит
- [ ] `AGENTS.md` обновлён при изменениях архитектуры
- [ ] Коммиты в формате conventional commits

## :fontawesome-solid-shield-halved: Безопасность

- **Никогда не коммитьте секреты.** Используйте CLI аргументы или переменные окружения.
- **Сообщайте об уязвимостях** приватно: см. [SECURITY.md](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/SECURITY.md)
- **gitleaks** pre-commit хук ловит распространённые паттерны секретов

## :fontawesome-solid-sitemap: Структура проекта

```
opencode_initializer/
├── setup.sh              # Оркестратор (352 строки)
├── dev.sh                # CLI инструмент
├── opencode.json         # AI конфиг
├── mkdocs.yml            # Конфиг документации
├── src/
│   ├── lib/              # 29 модулей
│   └── modes/            # 5 режимных скриптов
├── tests/                # Наборы тестов
├── docs/                 # Документация (этот сайт)
├── migrations/           # Миграции
├── scripts/              # Утилиты
├── .github/              # CI + шаблоны
└── AGENTS.md             # Инструкции для AI
```

## :fontawesome-solid-trophy: Признание

Контрибьюторы отмечены в [графе контрибьюторов GitHub](https://github.com/AlexanderNarbaev/opencode_initializer/graphs/contributors) и в заметках к релизам.

---

:fontawesome-solid-heart: **Спасибо за вклад!**
