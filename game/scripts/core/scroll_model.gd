class_name ScrollModel extends RefCounted
## 스크롤 속도 상태 머신(level §4.3). 위치 기준 전환: 광장 상단이 plaza_decel_top_y 에 닿으면 감속 시작.
## step() 은 이번 틱에 월드가 아래로 움직일 px 를 돌려준다.

enum S { ZONE, PLAZA_DECEL, PLAZA_HOLD, PLAZA_ACCEL, ENTRY, SLIDE, ARENA }

var bal: Balance
var state: int = S.ZONE
var ratio: float = 1.0          # ZONE 의 현재 비율
var timer: float = 0.0
var speed_now: float = 0.0      # px/s
var _v0: float = 0.0

signal state_changed(new_state: int)

func _init(b: Balance) -> void:
	bal = b

func target_ratio(alive: int, elite_alive: bool) -> float:
	var t: float = 1.0
	if alive > bal.crowd_start:
		var f: float = clampf(float(alive - bal.crowd_start) / float(bal.crowd_end - bal.crowd_start), 0.0, 1.0)
		t = lerpf(1.0, bal.scroll_min_ratio, f)
	if elite_alive:
		t = minf(t, bal.elite_ratio)
	return t

func _go(s: int) -> void:
	state = s
	timer = 0.0
	state_changed.emit(s)

## plaza_top_y: 광장 위쪽 끝의 화면 y. g_y: 보스 문(G) 화면 y. arena_top_y: 아레나 위쪽 끝 화면 y.
func step(dt: float, alive: int, elite_alive: bool, plaza_top_y: float, g_y: float,
		arena_top_y: float, exit_now: bool) -> float:
	match state:
		S.ZONE:
			var tr: float = target_ratio(alive, elite_alive)
			ratio += (tr - ratio) * clampf(dt / bal.ratio_lerp_time, 0.0, 1.0)
			speed_now = bal.scroll_base * ratio
			if plaza_top_y >= bal.plaza_decel_top_y:
				_v0 = speed_now
				_go(S.PLAZA_DECEL)
		S.PLAZA_DECEL:
			timer += dt
			var f: float = clampf(timer / bal.plaza_decel_time, 0.0, 1.0)
			speed_now = _v0 * (1.0 - f * f * (3.0 - 2.0 * f))
			if timer >= bal.plaza_decel_time:
				speed_now = 0.0
				_go(S.PLAZA_HOLD)
		S.PLAZA_HOLD:
			speed_now = 0.0
			timer += dt
			if timer >= bal.plaza_hold_time or exit_now:
				_go(S.PLAZA_ACCEL)
		S.PLAZA_ACCEL:
			timer += dt
			speed_now = bal.scroll_base * clampf(timer / bal.plaza_accel_time, 0.0, 1.0)
			if timer >= bal.plaza_accel_time:
				_go(S.ENTRY)
		S.ENTRY:
			speed_now = bal.scroll_base * bal.entry_speed_mult
			if g_y >= 0.0:
				_go(S.SLIDE)
		S.SLIDE:
			var remain: float = bal.arena_top_y - arena_top_y
			speed_now = minf(bal.arena_slide_speed, maxf(2.0 * remain, 4.0))
			if remain <= 0.5:
				speed_now = maxf(remain, 0.0) / maxf(dt, 0.0001)
				_go(S.ARENA)
		S.ARENA:
			speed_now = 0.0
	return speed_now * dt
