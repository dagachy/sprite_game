"""UserPromptSubmit hook: block a large-context prompt after the prompt cache has expired.

The first submit is blocked with an explanation. Sending the same prompt again within
the confirm window goes through, so the user always keeps the final say.
"""

import hashlib
import sys
import time

from tg_lib import emit, fmt_k, last_turn, load_config, load_state, log_error, read_hook_input, save_state


def prompt_key(prompt):
    return hashlib.sha256((prompt or "").encode("utf-8")).hexdigest()


def main():
    data = read_hook_input()
    session_id = data.get("session_id")
    if not session_id:
        return

    cfg = load_config()
    state = load_state(session_id)
    prompt = data.get("prompt") or ""
    key = prompt_key(prompt)
    now = time.time()

    pending = state.get("expire_confirm") or {}
    if pending.get("key") == key and now - pending.get("ts", 0) <= cfg["expire_confirm_seconds"]:
        state.pop("expire_confirm", None)
        save_state(session_id, state)
        return

    turn = last_turn(data.get("transcript_path") or "")
    if not turn or turn["ts"] is None:
        return

    idle = now - turn["ts"]
    if idle <= cfg["expire_idle_seconds"] or turn["context"] <= cfg["expire_block_tokens"]:
        return

    state["expire_confirm"] = {"key": key, "ts": now}
    save_state(session_id, state)
    emit({
        "decision": "block",
        "reason": (
            f"[token-guard] 마지막 턴 이후 {int(idle // 60)}분 경과로 프롬프트 캐시가 만료됐습니다. "
            f"컨텍스트 {fmt_k(turn['context'])}을 전부 다시 쓰게 되니 비용이 큽니다. "
            "/handoff로 상태를 저장한 뒤 /clear를 권장합니다. "
            "그대로 진행하려면 같은 메시지를 한 번 더 보내세요."
        ),
    })


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log_error("prompt_submit", exc)
    sys.exit(0)
