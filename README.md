# Mr. Negotiator

Глобальный хоткей для превращения выделенного текста в деловой стиль через LLM.

**Как работает:**
1. Выделяешь текст в любом приложении
2. Нажимаешь `Ctrl+Alt+N`
3. Получаешь уведомление — нажимаешь `Ctrl+V` (или `Cmd+V` на Mac)

Требует подключения к OpenAI-совместимому LLM API.

## Установка

```bash
curl -fsSL https://raw.githubusercontent.com/Akhomozov/mister-negotiator/main/install.sh | bash
```

Скрипт установит зависимости, спросит параметры LLM и настроит автозапуск при входе в систему.

**Поддерживаемые ОС:** Ubuntu (и другие Debian-based), macOS

### Требования

- Python 3.10+
- git
- **Ubuntu:** `xclip`, `libnotify-bin` (скрипт установит автоматически через apt)
- **macOS:** после установки нужно разрешить доступ к Accessibility для Terminal:
  `Системные настройки → Конфиденциальность и безопасность → Универсальный доступ`

## Конфигурация

При установке скрипт спросит три параметра:

| Параметр | Описание | Пример |
|---|---|---|
| `LLM_URL` | Base URL OpenAI-совместимого API | `https://api.example.com/v1` |
| `LLM_TOKEN` | API токен | `sk-...` |
| `LLM_MODEL` | Название модели | `Qwen/Qwen3-Coder-Next-FP8` |

Конфиг хранится в `~/.mister-negotiator/.env`. Чтобы перенастроить — удали этот файл и запусти установщик снова.

## Обновление

Повторный запуск команды установки обновит код и перезапишет автозапуск, не трогая `.env`.

## Удаление

```bash
# Ubuntu
rm -rf ~/.mister-negotiator
rm ~/.config/autostart/mister-negotiator.desktop

# macOS
launchctl unload ~/Library/LaunchAgents/com.mister-negotiator.plist
rm -rf ~/.mister-negotiator
rm ~/Library/LaunchAgents/com.mister-negotiator.plist
```
