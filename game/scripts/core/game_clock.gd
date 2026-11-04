extends Node
## 월드 시간 관리. Engine.time_scale 은 쓰지 않는다.
## - 이유별 Pause 카운터: push_pause(&"levelup") / pop_pause(&"levelup")
## - world_scale: SlowPolicy 가 매 틱 설정 (감속 0.5 등)
## - 히트스톱: 월드 시간만 정지. UI/입력/카메라는 멈추지 않는다. 겹치면 가장 긴 것만, 초당 총량 상한.
## Battle.step(raw_dt) 가 매 틱 frame(raw_dt) 를 호출해 월드 dt 를 받는다.

signal pause_changed(is_paused: bool)

var world_scale: float = 1.0
var hitstop_left: float = 0.0
var hitstop_budget_per_sec: float = 0.15

var _pauses: Dictionary = {}   # StringName -> int
var _hs_tokens: float = 0.15

func push_pause(reason: StringName) -> void:
	var was := is_paused()
	_pauses[reason] = int(_pauses.get(reason, 0)) + 1
	if not was:
		pause_changed.emit(true)

func pop_pause(reason: StringName) -> void:
	var n := int(_pauses.get(reason, 0)) - 1
	if n <= 0:
		_pauses.erase(reason)
	else:
		_pauses[reason] = n
	if not is_paused():
		pause_changed.emit(false)

func is_paused() -> bool:
	return not _pauses.is_empty()

func pause_count(reason: StringName) -> int:
	return int(_pauses.get(reason, 0))

func clear_pauses() -> void:
	var was := is_paused()
	_pauses.clear()
	hitstop_left = 0.0
	if was:
		pause_changed.emit(false)

## 히트스톱 요청(초). 겹치면 max, 초당 총량 상한(token bucket).
func hitstop(sec: float) -> void:
	var grant := minf(sec, _hs_tokens)
	if grant <= hitstop_left:
		return
	_hs_tokens -= (grant - hitstop_left)
	hitstop_left = grant

## 매 틱 한 번 호출. 월드 dt(정지면 0)를 돌려준다.
func frame(raw_dt: float) -> float:
	_hs_tokens = minf(_hs_tokens + hitstop_budget_per_sec * raw_dt, hitstop_budget_per_sec)
	if is_paused():
		return 0.0
	if hitstop_left > 0.0:
		hitstop_left = maxf(hitstop_left - raw_dt, 0.0)
		return 0.0
	return raw_dt * world_scale
