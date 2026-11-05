class_name WorldClock extends RefCounted
## 월드 시간 관리 코어(Node 비의존). Engine.time_scale 은 쓰지 않는다.
## - 이유별 Pause 카운터, world_scale(감속), 히트스톱(월드만 정지, 겹치면 최대값, 초당 총량 상한).
## Battle.step(raw_dt) 가 매 틱 frame(raw_dt) 를 호출해 월드 dt 를 받는다.

var world_scale: float = 1.0
var hitstop_left: float = 0.0
var hitstop_budget_per_sec: float = 0.15

var _pauses: Dictionary = {}
var _hs_tokens: float = 0.15

func push_pause(reason: StringName) -> void:
	_pauses[reason] = int(_pauses.get(reason, 0)) + 1

func pop_pause(reason: StringName) -> void:
	var n: int = int(_pauses.get(reason, 0)) - 1
	if n <= 0:
		_pauses.erase(reason)
	else:
		_pauses[reason] = n

func is_paused() -> bool:
	return not _pauses.is_empty()

func pause_count(reason: StringName) -> int:
	return int(_pauses.get(reason, 0))

func clear_pauses() -> void:
	_pauses.clear()
	hitstop_left = 0.0

func hitstop(sec: float) -> void:
	var grant: float = minf(sec, _hs_tokens)
	if grant <= hitstop_left:
		return
	_hs_tokens -= (grant - hitstop_left)
	hitstop_left = grant

func frame(raw_dt: float) -> float:
	_hs_tokens = minf(_hs_tokens + hitstop_budget_per_sec * raw_dt, hitstop_budget_per_sec)
	if is_paused():
		return 0.0
	if hitstop_left > 0.0:
		hitstop_left = maxf(hitstop_left - raw_dt, 0.0)
		return 0.0
	return raw_dt * world_scale
