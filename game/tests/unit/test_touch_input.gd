extends TestCase
## 터치 입력 경로 검증: 실제 InputEventScreenTouch/Drag 객체를 main.gd 의 _unhandled_input 에 주입한다.
## Input.parse_input_event 는 SceneTree 전달 경로(뷰포트 GUI/씬 순회)가 필요해 헤드리스 러너에서 쓰지 않고 핸들러를 직접 호출한다.
## main.gd 는 트리에 넣지 않고(_ready 미실행) battle 만 주입한다. 실기기 멀티터치·좌표 보정은 확인하지 못한다.

func _main() -> Node2D:
	var scr: GDScript = load("res://scripts/game/main.gd") as GDScript
	var m: Node2D = scr.new()
	m.set("battle", Battle.new(Balance.new(), 1, &"sword", null, false))
	return m

func _touch(idx: int, pressed: bool, pos: Vector2) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.pressed = pressed
	e.position = pos
	return e

func _drag(idx: int, pos: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = pos
	return e

func test_first_finger_press_activates_input() -> void:
	var m := _main()
	var b: Battle = m.get("battle")
	m._unhandled_input(_touch(0, true, Vector2(100, 200)))
	check_eq(m.get("touch_idx"), 0, "touch_idx = 0")
	check(b.input_active, "battle.input_active")
	check_eq(b.input_off, Vector2.ZERO, "press 직후 오프셋 0")
	m._unhandled_input(_drag(0, Vector2(130, 180)))
	check_eq(b.input_off, Vector2(30, -20), "drag 오프셋 = pos - start")
	m.free()

func test_second_finger_ignored() -> void:
	var m := _main()
	var b: Battle = m.get("battle")
	m._unhandled_input(_touch(0, true, Vector2(100, 200)))
	m._unhandled_input(_touch(1, true, Vector2(300, 300)))
	check_eq(m.get("touch_idx"), 0, "두 번째 press 후에도 touch_idx 유지")
	check_eq(m.get("touch_start"), Vector2(100, 200), "touch_start 유지")
	m._unhandled_input(_drag(1, Vector2(500, 500)))
	check_eq(b.input_off, Vector2.ZERO, "두 번째 손가락 drag 무시")
	m._unhandled_input(_touch(1, false, Vector2(300, 300)))
	check_eq(m.get("touch_idx"), 0, "두 번째 release 도 첫 손가락 상태 유지")
	check(b.input_active, "입력 활성 유지")
	m.free()

func test_first_finger_release_clears() -> void:
	var m := _main()
	var b: Battle = m.get("battle")
	m._unhandled_input(_touch(0, true, Vector2(100, 200)))
	m._unhandled_input(_drag(0, Vector2(150, 200)))
	m._unhandled_input(_touch(0, false, Vector2(150, 200)))
	check_eq(m.get("touch_idx"), -1, "touch_idx 해제")
	check(not b.input_active, "input_active 해제")
	check_eq(b.input_off, Vector2.ZERO, "오프셋 0")
	m._unhandled_input(_touch(2, true, Vector2(10, 10)))
	check_eq(m.get("touch_idx"), 2, "해제 후 새 손가락 수락")
	m.free()

func test_offer_ready_resets_touch_idx_and_blocks_input() -> void:
	# main.gd 484행: 3택이 뜨면 touch_idx 를 -1 로 리셋한다. (pause 진입 시 리셋 코드는 main.gd 에 없음)
	var m := _main()
	var b: Battle = m.get("battle")
	var btns: Array[Button] = []
	for i in 3:
		btns.append(Button.new())
	m.set("offer_buttons", btns)
	m.set("reroll_button", Button.new())
	m.set("offer_box", VBoxContainer.new())
	m._unhandled_input(_touch(0, true, Vector2(100, 200)))
	check_eq(m.get("touch_idx"), 0, "사전: 활성")
	m._on_offer_ready([], 1, &"level")
	check_eq(m.get("touch_idx"), -1, "offer 열림 시 touch_idx 리셋")
	b.awaiting_pick = true
	m._unhandled_input(_touch(3, true, Vector2(5, 5)))
	check_eq(m.get("touch_idx"), -1, "awaiting_pick 중 터치 무시")
	(m.get("reroll_button") as Node).free()
	(m.get("offer_box") as Node).free()
	for x in btns:
		x.free()
	m.free()

func test_ended_or_prep_ignores_touch() -> void:
	var m := _main()
	var b: Battle = m.get("battle")
	b.ended = true
	m._unhandled_input(_touch(0, true, Vector2(1, 1)))
	check_eq(m.get("touch_idx"), -1, "ended 중 무시")
	b.ended = false
	m.set("prep_active", true)
	m._unhandled_input(_touch(0, true, Vector2(1, 1)))
	check_eq(m.get("touch_idx"), -1, "prep_active 중 무시")
	m.free()

func _main_with_flow() -> Node2D:
	var m := _main()
	var f := Flow.new()
	f.state_changed.connect(m._on_flow_state_changed)
	f.boot(true)   # direct -> RUN (run_requested 미연결)
	m.set("flow", f)
	return m

func test_pause_resets_touch_and_input() -> void:
	var m := _main_with_flow()
	var b: Battle = m.get("battle")
	m._unhandled_input(_touch(0, true, Vector2(100, 200)))
	m._unhandled_input(_drag(0, Vector2(150, 200)))
	check_eq(m.get("touch_idx"), 0, "사전: 터치 중")
	(m.get("flow") as Flow).pause()
	check_eq(m.get("touch_idx"), -1, "PAUSE 전환 시 touch_idx 리셋")
	check(not b.input_active, "input_active 해제")
	check_eq(b.input_off, Vector2.ZERO, "이동 입력 0")
	m.free()

func test_pause_lost_release_then_new_touch_accepted() -> void:
	var m := _main_with_flow()
	var f: Flow = m.get("flow")
	m._unhandled_input(_touch(0, true, Vector2(100, 200)))
	f.pause()
	# PAUSE 중 해제 이벤트는 전달되지 않음(유실)
	f.resume()
	m._unhandled_input(_touch(5, true, Vector2(40, 40)))
	check_eq(m.get("touch_idx"), 5, "RUN 복귀 후 새 터치가 touch_idx 확보")
	check_eq(m.get("touch_start"), Vector2(40, 40), "touch_start 갱신")
	m.free()

func test_pause_reenables_keyboard_branch() -> void:
	# main.gd _process 의 `if touch_idx < 0` 키보드 분기. 키 입력 없음 -> set_input(false, 0) 로 stale 입력을 지운다.
	var m := _main_with_flow()
	var b: Battle = m.get("battle")
	m._unhandled_input(_touch(0, true, Vector2(100, 200)))
	check(m.get("touch_idx") >= 0, "사전: 키보드 분기 차단 상태")
	(m.get("flow") as Flow).pause()
	check(m.get("touch_idx") < 0, "키보드 분기 조건 touch_idx < 0 충족")
	b.set_input(true, Vector2(30, 0))   # stale 입력 가정
	m._poll_keyboard()
	check(not b.input_active, "_poll_keyboard 가 키보드 분기를 실행해 입력 해제")
	m.free()
