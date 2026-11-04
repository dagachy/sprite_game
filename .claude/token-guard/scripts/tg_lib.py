"""Shared helpers for token-guard hooks and analysis.

Stdlib only. Installed to ~/.claude/token-guard/scripts/.
"""

import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

INSTALL_DIR = Path(os.environ.get("TOKEN_GUARD_HOME", Path.home() / ".claude" / "token-guard"))
STATE_DIR = INSTALL_DIR / "state"

DEFAULTS = {
    "context_warn_tokens": 200000,
    "expire_block_tokens": 150000,
    "expire_idle_seconds": 300,
    "expire_confirm_seconds": 600,
    "agent_warn_count": 8,
    "read_block_bytes": 51200,
    "handoff_max_bytes": 8192,
    "big_creation_tokens": 300000,
    "cache_ttl_seconds": 300,
    "statusline": True,
}

# Files Read can legitimately load whole (images/PDF are sized differently).
NON_TEXT_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".pdf", ".ico", ".svg"}


def load_config():
    cfg = dict(DEFAULTS)
    try:
        cfg.update(json.loads((INSTALL_DIR / "config.json").read_text(encoding="utf-8")))
    except (OSError, ValueError):
        pass
    return cfg


def read_hook_input():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return {}
    return data if isinstance(data, dict) else {}


def emit(payload):
    """Write one JSON object to stdout; Claude Code reads it as the hook result."""
    sys.stdout.write(json.dumps(payload, ensure_ascii=False))
    sys.stdout.flush()


def parse_ts(value):
    if not isinstance(value, str):
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


def usage_of(entry):
    """Return a turn summary if the transcript entry is an assistant turn with usage."""
    if not isinstance(entry, dict) or entry.get("type") != "assistant":
        return None
    msg = entry.get("message")
    if not isinstance(msg, dict) or not isinstance(msg.get("usage"), dict):
        return None
    u = msg["usage"]
    create = u.get("cache_creation_input_tokens", 0) or 0
    read = u.get("cache_read_input_tokens", 0) or 0
    fresh = u.get("input_tokens", 0) or 0
    return {
        "ts": parse_ts(entry.get("timestamp")),
        "context": fresh + read + create,
        "create": create,
        "read": read,
        "output": u.get("output_tokens", 0) or 0,
    }


def last_turn(transcript_path, tail_bytes=4_000_000):
    """Find the last assistant turn by reading only the tail of a (possibly huge) transcript."""
    try:
        size = os.path.getsize(transcript_path)
        with open(transcript_path, "rb") as f:
            f.seek(max(0, size - tail_bytes))
            lines = f.read().decode("utf-8", errors="ignore").splitlines()
    except OSError:
        return None
    if size > tail_bytes and lines:
        lines = lines[1:]  # first line may be cut mid-record
    for line in reversed(lines):
        try:
            turn = usage_of(json.loads(line))
        except ValueError:
            continue
        if turn:
            return turn
    return None


def safe_session_id(session_id):
    return re.sub(r"[^A-Za-z0-9_-]", "", str(session_id or "unknown")) or "unknown"


def load_state(session_id):
    try:
        return json.loads((STATE_DIR / f"{safe_session_id(session_id)}.json").read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def save_state(session_id, state):
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        (STATE_DIR / f"{safe_session_id(session_id)}.json").write_text(
            json.dumps(state, ensure_ascii=False), encoding="utf-8"
        )
    except OSError:
        pass


def log_error(where, exc):
    """Hooks must never break a session; record failures for later inspection."""
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        with open(STATE_DIR / "errors.log", "a", encoding="utf-8") as f:
            f.write(f"{where}: {type(exc).__name__}: {exc}\n")
    except OSError:
        pass


def fmt_k(tokens):
    return f"{tokens / 1000:.0f}K"
