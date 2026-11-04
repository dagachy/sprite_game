"""PreToolUse(Agent) hook: count subagent spawns per session and nudge reuse past a limit."""

import sys

from tg_lib import emit, load_config, load_state, log_error, read_hook_input, save_state

MESSAGE = (
    "[token-guard] 이 세션의 서브에이전트 호출이 {count}회입니다. 각 에이전트는 컨텍스트를 처음부터 "
    "다시 쌓아 캐시 생성 비용이 큽니다. 같은 역할이면 새로 띄우지 말고 SendMessage로 기존 에이전트를 "
    "재사용하고, 작은 작업은 직접 처리하세요."
)


def main():
    data = read_hook_input()
    session_id = data.get("session_id")
    if not session_id:
        return

    cfg = load_config()
    state = load_state(session_id)
    count = state.get("agent_calls", 0) + 1
    state["agent_calls"] = count
    save_state(session_id, state)

    if count > cfg["agent_warn_count"]:
        message = MESSAGE.format(count=count)
        emit({
            "systemMessage": message,
            "hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": message},
        })


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log_error("pre_agent", exc)
    sys.exit(0)
