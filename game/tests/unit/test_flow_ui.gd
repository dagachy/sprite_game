extends TestCase
## FlowUI 헤드리스 검증: 화면 가시성, 터치 최소 크기, 세이프 영역 계산, 클리어 컷 키 가드.
## 레이아웃·가독성·실제 터치는 헤드리스로 확인하지 못한다(실화면 확인 안 함).

const TMP: String = "user://test_flowui_tmp.cfg"

func _make(first_done: bool) -> Array:
	var st := SettingsStore.new(TMP)
	st.data["first_run_done"] = first_done
	var f := Flow.new(st)
	var ui := FlowUI.new()
	ui.setup(f)
	f.state = Flow.State.TITLE
	ui._apply_state(Flow.State.TITLE)
	return [f, ui]

func _visible_names(ui: FlowUI) -> Array:
	var out: Array = []
	for n in ["title_screen", "cut_screen", "result_screen", "settings_screen", "pause_screen"]:
		if ui.get(n).visible:
			out.append(n)
	return out

func _buttons(n: Node, out: Array) -> void:
	if n is Button:
		out.append(n)
	for c in n.get_children():
		_buttons(c, out)

func test_screens_follow_flow_states() -> void:
	var a := _make(true)
	var f: Flow = a[0]; var ui: FlowUI = a[1]
	check_eq(_visible_names(ui), ["title_screen"], "TITLE")
	f.press_start()
	check_eq(_visible_names(ui), [], "RUN 은 화면 없음")
	check(ui.hud_layer.visible, "RUN 에서 일시정지 버튼 표시")
	f.pause()
	check_eq(_visible_names(ui), ["pause_screen"], "PAUSE")
	f.open_settings()
	check_eq(_visible_names(ui), ["settings_screen"], "SETTINGS")
	f.close_settings()
	check_eq(_visible_names(ui), ["pause_screen"], "PAUSE 복귀")
	f.resume()
	f.run_ended()
	check_eq(_visible_names(ui), ["result_screen"], "RESULT")
	f.quit_to_title()
	check_eq(_visible_names(ui), ["title_screen"], "TITLE 복귀")
	ui.free()

func test_first_run_cut_flow_and_skip() -> void:
	var a := _make(false)
	var f: Flow = a[0]; var ui: FlowUI = a[1]
	f.press_start()
	check_eq(f.state, Flow.State.INTRO, "INTRO")
	check_eq(_visible_names(ui), ["cut_screen"], "컷 화면")
	check_eq(ui.cut_label.text, GameStrings.get_text(&"cut.intro1"), "intro1 표시")
	ui._on_cut_gui_input(_click())
	check_eq(ui.cut_label.text, GameStrings.get_text(&"cut.intro1"), "1.2초 전 탭 무시")
	ui.cut.update(1.3)
	ui._on_cut_gui_input(_click())
	check_eq(ui.cut_label.text, GameStrings.get_text(&"cut.intro2"), "탭으로 다음 컷")
	ui._on_cut_skip()
	check_eq(f.state, Flow.State.RUN, "스킵하면 RUN")
	ui.free()
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))

func _click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.pressed = true
	e.button_index = MOUSE_BUTTON_LEFT
	return e

func test_touch_targets_at_least_44() -> void:
	var a := _make(true)
	var ui: FlowUI = a[1]
	var bs: Array = []
	_buttons(ui, bs)
	check(bs.size() >= 10, "버튼 수집")
	for b in bs:
		check(b.custom_minimum_size.x >= 44.0 and b.custom_minimum_size.y >= 44.0, "터치 44 이상: %s" % b.text)
	ui.free()

func test_safe_area_margins() -> void:
	var m := FlowUI.compute_safe_margins(Vector2(1080, 2400), Rect2i(0, 0, 0, 0), Vector2(216, 480))
	check_eq(m["top"], 12.0, "안전영역 없음 -> 최소 상단")
	var n := FlowUI.compute_safe_margins(Vector2(1080, 2400), Rect2i(0, 150, 1080, 2150), Vector2(216, 480))
	check_eq(n["top"], 30.0, "상단 150px -> 30 논리")
	check(n["bottom"] >= 8.0, "하단 최소 유지")
	check_eq(n["left"], 6.0, "좌측 최소")

func test_clear_cut_guard_and_wording() -> void:
	check(GameStrings.has_keys(GameStrings.CLEAR_KEYS), "클리어 키 존재")
	check(not GameStrings.has_keys([&"cut.nope"] as Array[StringName]), "키 없으면 false")
	var a := _make(true)
	var f: Flow = a[0]; var ui: FlowUI = a[1]
	f.press_start()
	ui.result = {"cleared": true, "top_items": []}
	f.run_ended()
	check_eq(_visible_names(ui), ["cut_screen"], "클리어는 컷 먼저")
	check_eq(ui.cut_label.text, GameStrings.get_text(&"cut.clear1"), "clear1")
	ui._on_cut_skip()
	check_eq(_visible_names(ui), ["result_screen"], "컷 후 결과")
	ui.free()
	var b := _make(true)
	var ui2: FlowUI = b[1]
	ui2.result = {"cleared": false, "top_items": []}
	var t: String = ui2.result_summary_text()
	check(t.contains("쓰러졌다"), "쓰러졌다 표기")
	check(not t.contains("쓰러짐") and not t.contains("포인트"), "구 표기 제거")
	ui2.free()

func test_forfeit_dialog() -> void:
	var a := _make(true)
	var f: Flow = a[0]; var ui: FlowUI = a[1]
	var hits: Array[int] = [0]
	ui.forfeit_requested.connect(func() -> void: hits[0] += 1)
	f.press_start()
	f.pause()
	ui._set_confirm(true)
	check(ui.pause_confirm_box.visible and not ui.pause_menu_box.visible, "확인 대화상자 표시")
	var bs: Array = []
	_buttons(ui.pause_confirm_box, bs)
	check_eq(bs.size(), 2, "대화상자 버튼 2개")
	for b in bs:
		check(b.custom_minimum_size.x >= 44.0 and b.custom_minimum_size.y >= 44.0, "대화상자 터치 44")
	bs[0].pressed.emit()   # 취소
	check_eq(f.state, Flow.State.PAUSE, "취소는 PAUSE 유지")
	check(ui.pause_menu_box.visible and hits[0] == 0, "취소는 포기 신호 없음")
	ui._set_confirm(true)
	bs[1].pressed.emit()   # 포기
	check_eq(hits[0], 1, "포기 신호 1회")
	check(f.state != Flow.State.TITLE, "quit_to_title 직행 아님")
	ui.free()

func test_auto_pause_and_top_items_hidden() -> void:
	var a := _make(true)
	var f: Flow = a[0]; var ui: FlowUI = a[1]
	ui.auto_pause()
	check_eq(f.state, Flow.State.TITLE, "RUN 아니면 무시")
	f.press_start()
	ui.auto_pause()
	check_eq(f.state, Flow.State.PAUSE, "RUN 에서 자동 일시정지")
	ui.auto_pause()
	check_eq(f.state, Flow.State.PAUSE, "복귀 시 자동 재개 없음")
	ui.result = {"cleared": false, "top_items": [{"key": "w.w01", "value": 99}]}
	check(not ui.result_summary_text().contains("w.w01"), "내부 키 숨김")
	ui.free()
