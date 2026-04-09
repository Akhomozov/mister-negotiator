#!/usr/bin/env bash
# Mr. Negotiator — установщик
# Использование: curl -fsSL https://raw.githubusercontent.com/Akhomozov/mister-negotiator/main/install.sh | bash

set -euo pipefail

REPO_URL="https://github.com/Akhomozov/mister-negotiator"
INSTALL_DIR="$HOME/.mister-negotiator"
PYTHON_MIN="3.10"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[mr-neg]${NC} $*"; }
warn()    { echo -e "${YELLOW}[mr-neg]${NC} $*"; }
error()   { echo -e "${RED}[mr-neg] ОШИБКА:${NC} $*" >&2; exit 1; }

# ── Определяем ОС ─────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="mac" ;;
  Linux)  PLATFORM="linux" ;;
  *)      error "Поддерживаются только macOS и Linux (получили: $OS)" ;;
esac

# ── Python ────────────────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  error "python3 не найден. Установи Python $PYTHON_MIN+ и попробуй снова."
fi

PY_VER="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
PY_OK="$(python3 -c "import sys; print(sys.version_info >= ($( echo $PYTHON_MIN | tr '.' ', ' )))")"
[[ "$PY_OK" == "True" ]] || error "Нужен Python $PYTHON_MIN+, найден $PY_VER"
info "Python $PY_VER — OK"

# ── Системные зависимости ─────────────────────────────────────────────────────
if [[ "$PLATFORM" == "linux" ]]; then
  MISSING=()
  command -v xclip      &>/dev/null || MISSING+=("xclip")
  command -v notify-send &>/dev/null || MISSING+=("libnotify-bin")

  if [[ ${#MISSING[@]} -gt 0 ]]; then
    warn "Не хватает пакетов: ${MISSING[*]}"
    if command -v apt-get &>/dev/null; then
      info "Устанавливаю через apt-get..."
      sudo apt-get update -qq
      sudo apt-get install -y "${MISSING[@]}"
    else
      error "Установи вручную: ${MISSING[*]}"
    fi
  fi
  info "Системные зависимости — OK"
fi

if [[ "$PLATFORM" == "mac" ]]; then
  info "macOS: pbcopy/pbpaste и osascript встроены — OK"
  warn "После установки разреши доступ к Accessibility:"
  warn "  Системные настройки → Конфиденциальность и безопасность → Универсальный доступ"
  warn "  Добавь Terminal (или iTerm) в список разрешённых приложений"
fi

# ── Скачиваем / обновляем репозиторий ─────────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
  info "Обновляю существующую установку в $INSTALL_DIR ..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  info "Клонирую репозиторий в $INSTALL_DIR ..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# ── Виртуальное окружение и зависимости ───────────────────────────────────────
info "Создаю виртуальное окружение..."
python3 -m venv "$INSTALL_DIR/.venv"

info "Устанавливаю Python-зависимости..."
"$INSTALL_DIR/.venv/bin/pip" install --quiet --upgrade pip
"$INSTALL_DIR/.venv/bin/pip" install --quiet -r "$INSTALL_DIR/requirements.txt"

# ── Конфигурация ──────────────────────────────────────────────────────────────
ENV_FILE="$INSTALL_DIR/.env"

if [[ -f "$ENV_FILE" ]]; then
  warn ".env уже существует. Пропускаю конфигурацию (удали $ENV_FILE чтобы перенастроить)."
else
  echo ""
  info "Настройка LLM-подключения:"
  echo ""

  read -rp "  LLM_URL (API base URL): " llm_url
  read -rp "  LLM_TOKEN (API токен): " llm_token
  read -rp "  LLM_MODEL [Qwen/Qwen3-Coder-Next-FP8]: " llm_model
  llm_model="${llm_model:-Qwen/Qwen3-Coder-Next-FP8}"

  cat > "$ENV_FILE" <<EOF
LLM_URL=${llm_url}
LLM_TOKEN=${llm_token}
LLM_MODEL=${llm_model}
EOF
  info ".env создан"
fi

# ── Автозапуск ────────────────────────────────────────────────────────────────
PYTHON_BIN="$INSTALL_DIR/.venv/bin/python"
MAIN_PY="$INSTALL_DIR/main.py"

if [[ "$PLATFORM" == "linux" ]]; then
  AUTOSTART_DIR="$HOME/.config/autostart"
  DESKTOP_FILE="$AUTOSTART_DIR/mister-negotiator.desktop"
  mkdir -p "$AUTOSTART_DIR"
  cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Mr. Negotiator
Exec=$PYTHON_BIN $MAIN_PY
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
  info "Автозапуск настроен: $DESKTOP_FILE"
fi

if [[ "$PLATFORM" == "mac" ]]; then
  PLIST_DIR="$HOME/Library/LaunchAgents"
  PLIST_FILE="$PLIST_DIR/com.mister-negotiator.plist"
  mkdir -p "$PLIST_DIR"
  cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.mister-negotiator</string>
  <key>ProgramArguments</key>
  <array>
    <string>${PYTHON_BIN}</string>
    <string>${MAIN_PY}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <false/>
  <key>StandardOutPath</key>
  <string>${HOME}/.mister-negotiator/mister-negotiator.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/.mister-negotiator/mister-negotiator.log</string>
</dict>
</plist>
EOF
  launchctl unload "$PLIST_FILE" 2>/dev/null || true
  launchctl load "$PLIST_FILE"
  info "LaunchAgent настроен и запущен: $PLIST_FILE"
fi

# ── Запуск ────────────────────────────────────────────────────────────────────
echo ""
info "Установка завершена!"
echo ""
echo "  Запустить сейчас:    $PYTHON_BIN $MAIN_PY"
echo "  Хоткей:              Ctrl+Alt+N"
echo "  Логи (mac):          ~/.mister-negotiator/mister-negotiator.log"
echo ""
