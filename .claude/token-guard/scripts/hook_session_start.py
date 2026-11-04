"""SessionStart hook: restore HANDOFF.md into a fresh session after /clear or startup."""

import os
import sys

from tg_lib import emit, load_config, log_error, read_hook_input

RESTORE_SOURCES = {"clear", "startup"}


def main():
    data = read_hook_input()
    if data.get("source") not in RESTORE_SOURCES:
        return

    cwd = data.get("cwd") or os.getcwd()
    path = os.path.join(cwd, "HANDOFF.md")
    if not os.path.isfile(path):
        return

    cfg = load_config()
    with open(path, encoding="utf-8", errors="ignore") as f:
        body = f.read(cfg["handoff_max_bytes"])

    emit({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": (
                "[token-guard] 이전 세션의 핸드오프입니다. 이어서 작업하기 전에 확인하세요.\n\n" + body
            ),
        }
    })


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log_error("session_start", exc)
    sys.exit(0)
