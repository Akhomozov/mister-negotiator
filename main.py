"""
Mr. Negotiator — глобальный хоткей для преобразования текста в деловой стиль.

Хоткей: Ctrl+Alt+N
  1. Читает выделенный текст (X11 PRIMARY selection)
  2. Отправляет в LLM
  3. Кладёт результат в буфер обмена (CLIPBOARD)
  4. Показывает уведомление — жмёшь Ctrl+V для вставки
"""

import threading
from pynput import keyboard
from clipboard import read_selection, write_clipboard, notify
from transformer import transform


HOTKEY = "<ctrl>+<alt>+n"


def on_activate():
    notify("Mr. Negotiator", "Обрабатываю...")
    text = read_selection()

    if not text:
        notify("Mr. Negotiator", "Текст не выделен")
        return

    try:
        result = transform(text)
        write_clipboard(result)
        notify("Mr. Negotiator", "Готово — вставляй Ctrl+V")
    except Exception as e:
        notify("Mr. Negotiator ❌", str(e))


def run_in_thread():
    """Запускаем трансформацию в отдельном потоке, чтобы не блокировать listener."""
    thread = threading.Thread(target=on_activate, daemon=True)
    thread.start()


if __name__ == "__main__":
    print(f"Mr. Negotiator запущен. Хоткей: {HOTKEY}")
    print("Выдели текст и нажми Ctrl+Alt+N")
    print("Ctrl+C для выхода")

    with keyboard.GlobalHotKeys({HOTKEY: run_in_thread}) as hotkey_listener:
        hotkey_listener.join()
