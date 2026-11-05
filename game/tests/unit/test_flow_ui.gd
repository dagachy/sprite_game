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

const HOST_SRC: String = "extends Node\nvar cur_preset: StringName = &\"\"\nvar debug_granted: bool = false\nvar world_paused: bool = false\nvar touch_idx: int = -1\nvar battle = null\n"

func _make_host(preset: StringName, granted: bool) -> Node:
	var sc := GDScript.new()
	sc.source_code = HOST_SRC
	sc.reload()
	var h := Node.new()
	h.set_script(sc)
	h.set("cur_preset", preset)
	h.set("debug_granted", granted)
	return h

## PAUSE 에서 포기 확인까지 진행한다. 반환: [flow, ui, host, abandoned 횟수(Array[int]), 포기 버튼]
func _pause_confirm(preset: StringName, granted: bool) -> Array:
	var a := _make(true)
	var f: Flow = a[0]; var ui: FlowUI = a[1]
	var h := _make_host(preset, granted)
	ui.host = h
	var hits: Array[int] = [0]
	f.abandoned.connect(func() -> void: hits[0] += 1)
	f.press_start()
	f.pause()
	ui._set_confirm(true)
	var bs: Array = []
	_buttons(ui.pause_confirm_box, bs)
	return [f, ui, h, hits, bs]

func test_forfeit_dialog_layout() -> void:
	var r := _pause_confirm(&"", false)
	var ui: FlowUI = r[1]; var bs: Array = r[4]
	check(ui.pause_confirm_box.visible and not ui.pause_menu_box.visible, "확인 대화상자 표시")
	check_eq(bs.size(), 2, "대화상자 버튼 2개")
	for b in bs:
		check(b.custom_minimum_size.x >= 44.0 and b.custom_minimum_size.y >= 44.0, "대화상자 터치 44")
	r[2].free()
	ui.free()

func test_forfeit_normal_run_settles_to_result() -> void:
	var r := _pause_confirm(&"", false)
	var f: Flow = r[0]; var ui: FlowUI = r[1]; var hits: Array[int] = r[3]
	r[4][1].pressed.emit()
	check_eq(hits[0], 1, "A: abandoned 1회")
	check(not ui.pause_confirm_box.visible and ui.pause_menu_box.visible, "A: 대화상자 닫힘")
	check_eq(f.state, Flow.State.PAUSE, "A: 정산 전 PAUSE 유지")
	f.run_ended()
	check_eq(f.state, Flow.State.RESULT, "A: 정산 후 RESULT")
	r[2].free()
	ui.free()

func test_forfeit_preset_run_goes_title() -> void:
	var r := _pause_confirm(&"CAP-01", false)
	var f: Flow = r[0]; var ui: FlowUI = r[1]; var hits: Array[int] = r[3]
	r[4][1].pressed.emit()
	check_eq(f.state, Flow.State.TITLE, "B: 프리셋 판은 TITLE")
	check_eq(hits[0], 0, "B: abandoned 미발화")
	r[2].free()
	ui.free()

func test_forfeit_debug_granted_goes_title() -> void:
	var r := _pause_confirm(&"", true)
	var f: Flow = r[0]; var ui: FlowUI = r[1]; var hits: Array[int] = r[3]
	r[4][1].pressed.emit()
	check_eq(f.state, Flow.State.TITLE, "C: 부여 판은 TITLE")
	check_eq(hits[0], 0, "C: abandoned 미발화")
	r[2].free()
	ui.free()

func test_forfeit_cancel_keeps_pause() -> void:
	var r := _pause_confirm(&"", false)
	var f: Flow = r[0]; var ui: FlowUI = r[1]; var hits: Array[int] = r[3]
	r[4][0].pressed.emit()
	check_eq(f.state, Flow.State.PAUSE, "D: 취소는 PAUSE 유지")
	check(ui.pause_menu_box.visible and not ui.pause_confirm_box.visible, "D: 메뉴 복귀")
	check_eq(hits[0], 0, "D: abandoned 없음")
	r[2].free()
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

func test_item_keys_one_to_one_with_src_names() -> void:
	for id in Battle.SRC_NAMES:
		var k := StringName("item." + id)
		check(GameStrings.TABLE.has(k), "%s 문구 존재" % id)
		check_eq(GameStrings.find_banned(GameStrings.get_text(k)), [] as Array[String], "%s 금지어 없음" % id)
	var n := 0
	for k in GameStrings.TABLE:
		if String(k).begins_with("item."):
			n += 1
			check(Battle.SRC_NAMES.has(String(k).substr(5)), "%s 는 항목 ID 와 대응" % k)
	check_eq(n, Battle.SRC_NAMES.size(), "item. 키 수 == SRC_NAMES 수")

func test_top_items_shown_with_text() -> void:
	var a := _make(true)
	var ui: FlowUI = a[1]
	ui.result = {"cleared": false, "top_items": [{"key": "w.w01", "value": 99}, {"key": "zz.none", "value": 5}]}
	var t: String = ui.result_summary_text()
	check(t.contains("초승달 베기  99"), "문구 있는 항목 표시")
	check(not t.contains("zz.none") and not t.contains("w.w01"), "문구 없는 키/내부 키 숨김")
	ui.free()

func test_death_keys_one_to_one_with_defs() -> void:
	var keys := {}
	for id in Defs.ENEMIES:
		var dk: String = String(Defs.ENEMIES[id].get("death", ""))
		check(dk != "" and GameStrings.TABLE.has(StringName(dk)), "%s death 문구 존재" % id)
		keys[dk] = true
		check_eq(GameStrings.find_banned(GameStrings.get_text(StringName(dk))), [] as Array[String], "%s 금지어 없음" % id)
	var n := 0
	for k in GameStrings.TABLE:
		if String(k).begins_with("death."):
			n += 1
			check(keys.has(String(k)), "%s 는 defs death 필드와 대응" % k)
	check_eq(n, keys.size(), "death. 키 수 == defs death 키 수")

func test_death_line_shown_or_hidden() -> void:
	var a := _make(true)
	var ui: FlowUI = a[1]
	ui.result = {"cleared": false, "killer_kind": &"A1"}
	check(ui.result_summary_text().contains("그늘 무리에 둘러싸여 쓰러졌다."), "A1 사유 줄 표시")
	ui.result = {"cleared": false, "killer_kind": &"boss"}
	check(ui.result_summary_text().contains("거대 그늘 앞에서"), "boss 사유 줄 표시")
	ui.result = {"cleared": false, "killer_kind": &"hazard"}
	check(ui.death_line_text() == "", "대응 없으면 숨김")
	ui.result = {"cleared": true, "killer_kind": &"A1"}
	check(ui.death_line_text() == "", "클리어는 숨김")
	ui.free()

func _root() -> Node:
	return (Engine.get_meta(&"test_tree") as SceneTree).root

func test_ready_after_attach_before_add_child() -> void:
	var f := Flow.new(SettingsStore.new(TMP))
	var ui := FlowUI.new()
	ui.attach(_root(), f)
	_root().add_child(ui)
	f.boot(false)
	check_eq(f.state, Flow.State.TITLE, "boot(false) -> TITLE")
	check(ui.title_screen.visible, "title 패널 visible")
	ui.queue_free()

func test_add_child_before_attach_no_crash() -> void:
	var f := Flow.new(SettingsStore.new(TMP))
	var ui := FlowUI.new()
	_root().add_child(ui)
	ui.attach(_root(), f)
	ui._apply_state(Flow.State.TITLE)
	check(ui.title_screen.visible, "역순 attach 후 _apply_state 정상")
	ui.queue_free()

func test_add_child_without_flow_no_crash() -> void:
	var ui := FlowUI.new()
	_root().add_child(ui)
	check(ui.flow == null and ui.pause_confirm_box == null, "flow/UI 없음 상태 유지")
	ui.queue_free()

func test_real_tree_cleanup() -> void:
	var f := Flow.new(SettingsStore.new(TMP))
	var ui := FlowUI.new()
	ui.attach(_root(), f)
	_root().add_child(ui)
	check(ui.is_inside_tree(), "트리에 붙음")
	ui.queue_free()
