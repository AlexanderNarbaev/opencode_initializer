# История изменений

Заметки о релизах и история версий OpenCode Initializer.

См. также [полный CHANGELOG.md на GitHub](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/CHANGELOG.md).

## [Невыпущенное]

### Безопасность

* **deps:** закреплены две оставшиеся уязвимые транзитивные зависимости через корневое поле `overrides` — `toml` 4.3.0→5.0.1 (CVE-2026-114141, CVE-2026-114143, CVE-2026-114144; подтягивается через `effect@4.0.0-beta.83`) и `zod` 4.1.8→4.6.6 (CVE-2023-54404; закреплён точной версией в `@opencode-ai/plugin@1.19.0`) — вместе с уже существующим закрепением `overrides.npm=11.21.1`. Гейт `trivy` (CRITICAL/HIGH) по `package-lock.json` снова чист на актуальной базе advisories.
