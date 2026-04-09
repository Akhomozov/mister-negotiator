import platform
import subprocess
import time


_IS_MAC = platform.system() == "Darwin"


def read_selection() -> str:
    """Читает выделенный текст.

    Linux: X11 PRIMARY selection (текст доступен сразу после выделения).
    Mac: симулирует Cmd+C, чтобы скопировать выделение в буфер обмена.
    """
    if _IS_MAC:
        from pynput.keyboard import Controller, Key
        kb = Controller()
        with kb.pressed(Key.cmd):
            kb.tap("c")
        time.sleep(0.15)  # ждём, пока буфер обновится
        result = subprocess.run(["pbpaste"], capture_output=True, text=True)
    else:
        result = subprocess.run(
            ["xclip", "-selection", "primary", "-o"],
            capture_output=True,
            text=True,
        )
    return result.stdout.strip()


def write_clipboard(text: str) -> None:
    """Записывает текст в буфер обмена (для последующего Ctrl+V / Cmd+V)."""
    if _IS_MAC:
        subprocess.run(["pbcopy"], input=text, text=True)
    else:
        subprocess.run(["xclip", "-selection", "clipboard"], input=text, text=True)


def notify(title: str, message: str) -> None:
    """Показывает desktop-уведомление."""
    if _IS_MAC:
        safe_title = title.replace('"', '\\"')
        safe_msg = message.replace('"', '\\"')
        script = f'display notification "{safe_msg}" with title "{safe_title}"'
        subprocess.run(["osascript", "-e", script], check=False)
    else:
        subprocess.run(["notify-send", title, message], check=False)
