# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Mr. Negotiator** — Linux desktop utility (~100 LOC, 3 files). Global hotkey Ctrl+Alt+N:
1. Reads selected text from X11 PRIMARY selection (xclip)
2. Sends to LLM for transformation into professional business style
3. Writes result to CLIPBOARD
4. Shows desktop notification to paste (Ctrl+V)

## Setup & Run

```bash
# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure LLM access (copy and fill in token)
cp .env.example .env

# Run
python main.py
```

## System Dependencies

Requires X11 environment:
- `xclip` — clipboard read/write (`apt install xclip`)
- `notify-send` — desktop notifications (`apt install libnotify-bin`)
- X11 display (Wayland not supported)

## Environment Variables (.env)

| Variable | Description |
|---|---|
| `LLM_URL` | OpenAI-compatible API base URL |
| `LLM_TOKEN` | API token |
| `LLM_MODEL` | Model name (default: Qwen/Qwen3-Coder-Next-FP8) |

## Architecture

Three modules, minimal coupling:

- **`main.py`** — entry point, registers Ctrl+Alt+N via `pynput.GlobalHotKeys`, runs transformation in a daemon thread
- **`clipboard.py`** — shell-out to `xclip` for PRIMARY/CLIPBOARD selections; `notify()` wraps `notify-send`
- **`transformer.py`** — OpenAI SDK client pointed at internal LLM endpoint; `transform(text)` → returns business-style text

The LLM call uses `temperature=0.3` for deterministic output.
