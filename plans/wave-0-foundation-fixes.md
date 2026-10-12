# Wave 0: Foundation Fixes - План работ

## Цель
Исправить критические проблемы стабильности и документации перед началом основных волн трансформации.

## Задачи

### 1. Исправление broken links в документации (17 ссылок)
- [ ] Найти все битые ссылки в docs/
- [ ] Исправить ссылки на agent-system.en.md и agent-system.ru.md
- [ ] Исправить ссылки на файлы вне docs/
- [ ] Обновить навигацию mkdocs.yml

### 2. Error Recovery Framework
- [ ] Добавить retry logic в 00-core.sh
- [ ] Реализовать continue-on-error для некритичных шагов
- [ ] Добавить graceful degradation

### 3. WAL Race Condition Fix
- [ ] Добавить file locking в WAL операции
- [ ] Реализовать атомарные записи

### 4. Provider Registry Cleanup
- [ ] Удалить дублированный registry (26-providers + 18-opencode-json)
- [ ] Удалить мёртвый код minimax

### 5. Documentation fixes
- [ ] Исправить 14 warnings в strict mode
- [ ] Добавить missing agent-system.md файлы
- [ ] Настроить proper i18n игнорирование

## Метрики успеха
- ✅ 0 broken links в документации
- ✅ dev autoupdate завершается без критических ошибок
- ✅ mkdocs build --strict проходит без warnings
- ✅ Все тесты проходят

## Timeline
- Начало: 2026-09-21
- Окончание: 2026-09-28
- Статус: IN PROGRESS
