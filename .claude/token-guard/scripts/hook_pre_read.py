"""PreToolUse(Read) hook: deny whole-file reads of large text files.

A bounded read (offset/limit) or a search (grep) keeps the context small. Images and PDFs
are not blocked here because they are read as attachments.
"""

import os
import sys

from tg_lib import NON_TEXT_EXTENSIONS, emit, load_config, log_error, read_hook_input


def main():
    data = read_hook_input()
    if data.get("tool_name") != "Read":
        return

    tool_input = data.get("tool_input") or {}
    path = tool_input.get("file_path") or ""
    if not path or tool_input.get("offset") or tool_input.get("limit"):
        return
    if os.path.splitext(path)[1].lower() in NON_TEXT_EXTENSIONS:
        return

    cfg = load_config()
    try:
        size = os.path.getsize(path)
    except OSError:
        return
    if size <= cfg["read_block_bytes"]:
        return

    kb = size // 1024
    emit({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f"[token-guard] 파일이 {kb}KB라서 전체 읽기를 막았습니다. "
                "grep으로 필요한 줄을 찾거나 offset/limit으로 구간만 읽으세요. "
                "넓은 탐색은 서브에이전트에 경로만 넘겨 결론만 받는 것이 더 쌉니다."
            ),
        }
    })


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log_error("pre_read", exc)
    sys.exit(0)
