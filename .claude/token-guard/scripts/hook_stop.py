"""Stop hook: record context size after each turn and warn when it gets large."""

import sys

from tg_lib import emit, fmt_k, last_turn, load_config, load_state, log_error, read_hook_input, save_state


def main():
    data = read_hook_input()
    session_id = data.get("session_id")
    turn = last_turn(data.get("transcript_path") or "")
    if not session_id or not turn:
        return

    cfg = load_config()
    state = load_state(session_id)
    state["context"] = turn["context"]
    state["last_turn_ts"] = turn["ts"]

    over = turn["context"] >= cfg["context_warn_tokens"]
    message = None
    if over and not state.get("warned"):
        message = (
            f"[token-guard] 컨텍스트 {fmt_k(turn['context'])} 도달. "
            "작업 단위가 끝났다면 /handoff로 상태를 저장하고 /clear를 권장합니다."
        )
    state["warned"] = over
    save_state(session_id, state)

    if message:
        emit({"systemMessage": message})


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # never break the session
        log_error("stop", exc)
    sys.exit(0)
