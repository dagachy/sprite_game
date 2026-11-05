class_name FlowUI extends CanvasLayer
## 판 밖 UI 일체(타이틀, 컷, 결과, 설정, 일시정지)를 코드로 빌드한다(decision5 D8, .tscn 없음).
## 로직은 Flow/CutPlayer 에 있고 여기서는 표시와 입력 전달만 한다.
##
## 연결(main.gd 쪽 필요 변경, 이 파일은 main.gd 를 고치지 않는다):
##   _boot_flow() 에서 flow 를 만든 직후, flow.boot() 호출 전에
##     var fui := FlowUI.new(); add_child(fui); fui.attach(self, flow)
##   그리고 flow_ui_ready = true (흐름 담당이 확인 후 변경).
## host(main) 에서 읽는 공개 변수: battle, world_paused, touch_idx, cur_preset, debug_granted,
##   last_points, offer_box, prep_active, result_box, result_dim, bal. host 가 null 이어도 동작한다(테스트).

const LAYER_UI: int = 20
const MIN_TOUCH: float = 44.0          # 논리 px, 사용자 지시(44). ux 문서의 26보다 엄격하게 적용
const SAFE_MIN := {"top": 12.0, "bottom": 8.0, "left": 6.0, "right": 6.0}   # ux §1.1
const CONTENT_W: float = 192.0
const FONT_S: int = 9
const FONT_M: int = 11
const FONT_L: int = 14

var flow: Flow
var host: Node = null
var cut: CutPlayer = null
var cut_mode: StringName = &""          # &"intro" / &"clear"
var result: Dictionary = {}
var _tracked_battle: Object = null
var _result_pending: bool = false       # 클리어 컷이 끝날 때까지 결과 화면을 미룬다

var title_screen: Control
var cut_screen: Control
var result_screen: Control
var settings_screen: Control
var pause_screen: Control
var hud_layer: Control
var pause_button: Button
var cut_label: Label
var cut_hint: Label
var result_summary: Label
var result_shop: VBoxContainer
var shop_buttons: Array[Button] = []
var shop_ids: Array[StringName] = []
var pause_menu_box: VBoxContainer
var pause_confirm_box: VBoxContainer
var pause_settings_btn: Button
var settings_buttons: Dictionary = {}   # key -> Button
var _safe_margins: Array[MarginContainer] = []

const SETTING_ROWS: Array = [
	["screen_shake", &"ui.settings.shake", true],
	["motion_reduced", &"ui.settings.motion_reduced", false],
	["haptics", &"ui.settings.haptics", true],
]

# ---- 구성 ----

func attach(host_node: Node, f: Flow) -> void:
	host = host_node
	setup(f)

## 노드를 만들고 flow 시그널을 연결한다. attach 는 host 를 지정하고 이 함수를 부른다.
func setup(f: Flow) -> void:
	flow = f
	layer = LAYER_UI
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	_build_title()
	_build_cut()
	_build_result()
	_build_settings()
	_build_pause()
	flow.state_changed.connect(_on_state_changed)
	_show_only(null)

func _ready() -> void:
	get_tree().quit_on_go_back = false   # SceneTree 속성. 뒤로 가기가 곧바로 앱 종료로 이어지지 않게 한다
	get_viewport().size_changed.connect(update_safe_area)
	update_safe_area()
	if flow == null or pause_confirm_box == null:
		push_warning("FlowUI._ready: setup/attach 전에 트리에 들어왔다. 상태 적용을 건너뛴다.")
		return
	_apply_state(flow.state)

## 세이프 영역(px) -> 논리 여백. 기기 값이 최소보다 크면 기기 값을 쓴다. 안전 영역을 못 얻으면 최소값.
static func compute_safe_margins(win: Vector2, safe: Rect2i, logical: Vector2) -> Dictionary:
	var m: Dictionary = SAFE_MIN.duplicate()
	if win.x <= 0.0 or win.y <= 0.0 or safe.size.x <= 0 or safe.size.y <= 0:
		return m
	var sx: float = logical.x / win.x
	var sy: float = logical.y / win.y
	m["left"] = maxf(m["left"], safe.position.x * sx)
	m["right"] = maxf(m["right"], (win.x - safe.end.x) * sx)
	m["top"] = maxf(m["top"], safe.position.y * sy)
	m["bottom"] = maxf(m["bottom"], (win.y - safe.end.y) * sy)
	return m

func update_safe_area() -> void:
	var logical := Vector2(216, 384)
	if is_inside_tree():
		logical = get_viewport().get_visible_rect().size
	var m: Dictionary = compute_safe_margins(Vector2(DisplayServer.window_get_size()),
		DisplayServer.get_display_safe_area(), logical)
	for mc in _safe_margins:
		mc.add_theme_constant_override("margin_left", int(ceil(m["left"])))
		mc.add_theme_constant_override("margin_right", int(ceil(m["right"])))
		mc.add_theme_constant_override("margin_top", int(ceil(m["top"])))
		mc.add_theme_constant_override("margin_bottom", int(ceil(m["bottom"])))

# ---- 빌드 헬퍼 ----

func _new_screen(bg: Color) -> Array:
	var s := Control.new()
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.mouse_filter = Control.MOUSE_FILTER_STOP   # 뒤 게임으로 입력이 새지 않게 막는다
	s.visible = false
	add_child(s)
	var r := ColorRect.new()
	r.color = bg
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(r)
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(mc)
	_safe_margins.append(mc)
	return [s, mc]

func _vbox(sep: int = 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v

func _centered(content: Control, mc: MarginContainer) -> void:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_child(cc)
	content.custom_minimum_size.x = CONTENT_W
	cc.add_child(content)

func _lbl(text: String, size_px: int, align: int = HORIZONTAL_ALIGNMENT_CENTER, color: Color = Palette.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _btn(text: String, size_px: int, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", size_px)
	b.custom_minimum_size = Vector2(maxf(min_size.x, MIN_TOUCH), maxf(min_size.y, MIN_TOUCH))
	return b

func _build_hud() -> void:
	hud_layer = Control.new()
	hud_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_layer)
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(mc)
	_safe_margins.append(mc)
	var v := _vbox(0)
	mc.add_child(v)
	var spacer := Control.new()   # 좌상단 HP/경험치 바와 HUD 문자와 겹치지 않게 아래로 내린다
	spacer.custom_minimum_size = Vector2(0, 18)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_END
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	pause_button = _btn(GameStrings.get_text(&"ui.pause.button"), FONT_M, Vector2(MIN_TOUCH, MIN_TOUCH))
	pause_button.pressed.connect(func() -> void: flow.pause())
	h.add_child(pause_button)
	hud_layer.visible = false

func _build_title() -> void:
	var a: Array = _new_screen(Palette.VOID)
	title_screen = a[0]
	var v := _vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_lbl(String(ProjectSettings.get_setting("application/config/name", "")), FONT_L))
	var start := _btn(GameStrings.get_text(&"ui.title.start"), FONT_L, Vector2(160, 52))
	start.pressed.connect(func() -> void: flow.press_start())
	var st := _btn(GameStrings.get_text(&"ui.title.settings"), FONT_M, Vector2(160, MIN_TOUCH))
	st.pressed.connect(func() -> void: flow.open_settings())
	v.add_child(start)
	v.add_child(st)
	_centered(v, a[1])

func _build_cut() -> void:
	var a: Array = _new_screen(Palette.VOID)
	cut_screen = a[0]
	cut_screen.gui_input.connect(_on_cut_gui_input)
	var v := _vbox(6)
	a[1].add_child(v)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skip := _btn(GameStrings.get_text(&"ui.cut.skip"), FONT_S, Vector2(72, MIN_TOUCH))
	skip.pressed.connect(_on_cut_skip)
	top.add_child(skip)
	v.add_child(top)
	cut_label = _lbl("", FONT_M)
	cut_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cut_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cut_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cut_label.custom_minimum_size = Vector2(160, 0)
	v.add_child(cut_label)
	cut_hint = _lbl(GameStrings.get_text(&"ui.cut.tap_hint"), FONT_S, HORIZONTAL_ALIGNMENT_CENTER, Palette.T6)
	v.add_child(cut_hint)

func _build_result() -> void:
	var a: Array = _new_screen(Color(Palette.VOID, 0.92))
	result_screen = a[0]
	var v := _vbox(6)
	a[1].add_child(v)
	v.add_child(_lbl(GameStrings.get_text(&"ui.result.title"), FONT_L))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var body := _vbox(4)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(body)
	result_summary = _lbl("", FONT_M, HORIZONTAL_ALIGNMENT_LEFT)
	result_summary.custom_minimum_size = Vector2(160, 0)
	body.add_child(result_summary)
	result_shop = _vbox(4)
	body.add_child(result_shop)
	for nd in MetaState.NODES:
		var sb := _btn("", FONT_S, Vector2(CONTENT_W, MIN_TOUCH))
		sb.pressed.connect(_on_buy.bind(nd["id"]))
		result_shop.add_child(sb)
		shop_buttons.append(sb)
		shop_ids.append(nd["id"])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var again := _btn(GameStrings.get_text(&"ui.result.again"), FONT_M, Vector2(100, 48))
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(func() -> void: flow.retry())
	var home := _btn(GameStrings.get_text(&"ui.result.home"), FONT_M, Vector2(64, 48))
	home.pressed.connect(func() -> void: flow.quit_to_title())
	row.add_child(again)
	row.add_child(home)
	v.add_child(row)

func _build_settings() -> void:
	var a: Array = _new_screen(Palette.VOID)
	settings_screen = a[0]
	var v := _vbox(6)
	a[1].add_child(v)
	v.add_child(_lbl(GameStrings.get_text(&"ui.settings.title"), FONT_L))
	for row in SETTING_ROWS:
		var key: String = row[0]
		var b := _btn("", FONT_M, Vector2(CONTENT_W, MIN_TOUCH))
		b.pressed.connect(_on_setting_toggled.bind(key))
		v.add_child(b)
		settings_buttons[key] = b
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(filler)
	var back := _btn(GameStrings.get_text(&"ui.settings.back"), FONT_M, Vector2(80, 48))
	back.pressed.connect(_on_settings_back)
	v.add_child(back)

func _build_pause() -> void:
	var a: Array = _new_screen(Color(Palette.VOID, 0.7))
	pause_screen = a[0]
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + s, 8)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(inner)
	var holder := _vbox(6)
	inner.add_child(holder)
	pause_menu_box = _vbox(6)
	holder.add_child(pause_menu_box)
	pause_menu_box.add_child(_lbl(GameStrings.get_text(&"ui.pause.title"), FONT_M))
	var resume := _btn(GameStrings.get_text(&"ui.pause.resume"), FONT_M, Vector2(136, 48))
	resume.pressed.connect(func() -> void: flow.resume())
	pause_settings_btn = _btn(GameStrings.get_text(&"ui.pause.settings"), FONT_M, Vector2(136, MIN_TOUCH))
	pause_settings_btn.pressed.connect(func() -> void: flow.open_settings())
	var quit := _btn(GameStrings.get_text(&"ui.pause.quit"), FONT_M, Vector2(136, MIN_TOUCH))
	quit.pressed.connect(func() -> void: _set_confirm(true))
	pause_menu_box.add_child(resume)
	pause_menu_box.add_child(pause_settings_btn)
	pause_menu_box.add_child(quit)
	pause_confirm_box = _vbox(6)
	pause_confirm_box.add_child(_lbl(GameStrings.get_text(&"ui.pause.confirm"), FONT_M))
	var keep := _btn(GameStrings.get_text(&"ui.pause.confirm_continue"), FONT_M, Vector2(136, 48))   # 기본 포커스
	keep.pressed.connect(func() -> void: _set_confirm(false))   # 취소: 일시정지 화면 유지
	var giveup := _btn(GameStrings.get_text(&"ui.pause.confirm_quit"), FONT_M, Vector2(136, MIN_TOUCH))
	giveup.pressed.connect(_do_forfeit)
	pause_confirm_box.add_child(keep)
	pause_confirm_box.add_child(giveup)
	pause_confirm_box.visible = false
	holder.add_child(pause_confirm_box)
	_centered(panel, a[1])
	panel.custom_minimum_size.x = 160

## 포기 확인. 일반 판은 abandoned -> main 정산 -> RESULT, 프리셋·부여 판은 기록 없이 TITLE (Flow.abandon).
func _do_forfeit() -> void:
	_set_confirm(false)
	var no_record: bool = (_hv("cur_preset", &"") != &"") or bool(_hv("debug_granted", false))
	flow.abandon(no_record)

func _set_confirm(on: bool) -> void:
	pause_confirm_box.visible = on
	pause_menu_box.visible = not on

# ---- 상태 전환 ----

func _on_state_changed(_old: Flow.State, new_state: Flow.State) -> void:
	_apply_state(new_state)

func _apply_state(s: Flow.State) -> void:
	_set_confirm(false)
	hud_layer.visible = false
	match s:
		Flow.State.TITLE:
			_world_paused(true)
			_apply_settings_to_host()
			_show_only(title_screen)
		Flow.State.INTRO:
			_world_paused(true)
			_start_cut(&"intro", GameStrings.INTRO_KEYS)
		Flow.State.RUN:
			_world_paused(false)
			_show_only(null)
			hud_layer.visible = true
		Flow.State.PAUSE:
			_world_paused(true)
			_release_touch()
			pause_settings_btn.visible = not flow.direct_run   # 직접 경로는 settings 를 읽지도 쓰지도 않는다
			_show_only(pause_screen)
		Flow.State.SETTINGS:
			_refresh_settings()
			_show_only(settings_screen)
		Flow.State.RESULT:
			_world_paused(true)
			_enter_result()

func _show_only(s: Control) -> void:
	for c in [title_screen, cut_screen, result_screen, settings_screen, pause_screen]:
		c.visible = (c == s)
	set_process(true)

func _world_paused(on: bool) -> void:
	if host != null:
		host.set("world_paused", on)

func _release_touch() -> void:
	if host == null:
		return
	host.set("touch_idx", -1)
	var b: Variant = host.get("battle")
	if b != null:
		b.set_input(false, Vector2.ZERO)

func _hv(name: String, default_value: Variant) -> Variant:
	if host == null:
		return default_value
	var v: Variant = host.get(name)
	return default_value if v == null else v

# ---- 컷 ----

func _start_cut(mode: StringName, keys: Array[StringName]) -> void:
	cut_mode = mode
	cut = CutPlayer.new()
	cut.cut_shown.connect(_on_cut_shown)
	cut.finished.connect(_on_cut_finished)
	_show_only(cut_screen)
	cut.start(keys)

func _on_cut_shown(_key: StringName, text: String, _i: int, _n: int) -> void:
	cut_label.text = text
	cut_label.modulate.a = 0.0
	cut_hint.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(cut_label, "modulate:a", 1.0, 0.2)
	tw.tween_property(cut_hint, "modulate:a", 1.0, 0.0).set_delay(CutPlayer.MIN_SECONDS - 0.2)   # 탭 가능 시점에 힌트

func _on_cut_gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if cut != null:
			cut.tap()

func _on_cut_skip() -> void:
	if cut != null:
		cut.skip()

func _on_cut_finished(_skipped: bool) -> void:
	var mode: StringName = cut_mode
	cut = null
	cut_mode = &""
	if mode == &"intro":
		flow.intro_finished()
	elif mode == &"clear":
		_show_result_screen()

func _process(delta: float) -> void:
	if hud_layer == null or flow == null:   # setup 전(안전망 경로)에는 갱신하지 않는다
		return
	if cut != null:
		cut.update(delta)
	if hud_layer.visible:
		pause_button.visible = not (bool(_hv("prep_active", false)) or _offer_open())
	_track_battle()

func _offer_open() -> bool:
	var ob: Variant = _hv("offer_box", null)
	return ob != null and ob.visible

## main 이 새 판마다 battle 을 만든다. 새 battle 의 run_ended 에 (main 핸들러 뒤에) 연결한다.
func _track_battle() -> void:
	if host == null:
		return
	var b: Variant = host.get("battle")
	if b != null and b != _tracked_battle:
		_tracked_battle = b
		b.run_ended.connect(_on_run_ended)

func _on_run_ended(r: Dictionary) -> void:
	result = r
	# main 의 임시 결과 화면은 숨기고 이 화면으로 대체한다
	for n in ["result_box", "result_dim"]:
		var c: Variant = _hv(n, null)
		if c != null:
			c.visible = false
	flow.run_ended()

# ---- 결과 ----

## RunState 는 오토로드라 정적 참조하면 오토로드가 없는 테스트 러너에서 컴파일이 실패한다.
func _run_state() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("RunState") if tree != null else null

func is_record_off() -> bool:
	return StringName(_hv("cur_preset", &"")) != &"" or bool(_hv("debug_granted", false))

func _enter_result() -> void:
	if bool(result.get("cleared", false)) and not is_record_off() and GameStrings.has_keys(GameStrings.CLEAR_KEYS):
		_start_cut(&"clear", GameStrings.CLEAR_KEYS)   # 키가 없으면 건너뛴다
	else:
		_show_result_screen()

func result_summary_text() -> String:
	var lines: PackedStringArray = []
	var cur: String = GameStrings.get_text(&"res.currency")
	if bool(result.get("cleared", false)):
		lines.append(GameStrings.get_text(&"res.cleared"))
	else:
		lines.append(GameStrings.get_text(&"res.fell"))   # 임시 키 defeat_placeholder 는 확정 문구로 대체됨
		lines.append(GameStrings.get_text(&"ui.result.fell_note"))
		var dl: String = death_line_text()
		if dl != "":
			lines.append(dl)
	if is_record_off():
		lines.append(GameStrings.get_text(&"ui.result.no_record"))
	elif not result.is_empty() and _run_state() != null:
		lines.append("%s +%d (%d)" % [cur, int(_hv("last_points", 0)), int(_run_state().meta.points)])
	for it in result.get("top_items", []):
		var nm: String = GameStrings.get_text(StringName("item." + String(it["key"])))
		if nm != "":   # R2: item.* 문구 등록됨. 표시 이름이 없으면 내부 키를 노출하지 않고 숨긴다
			lines.append("%s  %d" % [nm, it["value"]])
	return "\n".join(lines)

## 사유 줄. killer_kind(A1, boss 등)를 Defs.ENEMIES 의 "death" 키로 찾는다. 문구가 없으면 "" (줄 숨김).
func death_line_text() -> String:
	if bool(result.get("cleared", false)):
		return ""
	var kk: String = String(result.get("killer_kind", ""))
	var id: StringName = StringName(kk.to_upper())
	if not Defs.ENEMIES.has(id):
		return ""
	return GameStrings.get_text(StringName(String(Defs.ENEMIES[id].get("death", ""))))

func _show_result_screen() -> void:
	result_summary.text = result_summary_text()
	_refresh_shop()
	_show_only(result_screen)

func _refresh_shop() -> void:
	var rs: Node = _run_state()
	if rs == null:
		return
	var off: bool = is_record_off()
	for i in shop_buttons.size():
		var nd: Dictionary = MetaState.NODES[i]
		var owned: bool = _run_state().meta.owned.has(nd["id"])
		shop_buttons[i].text = "%s (%d)%s" % [nd["name"], nd["cost"], " *" if owned else ""]
		shop_buttons[i].disabled = off or owned or not _run_state().meta.can_buy(nd["id"])

func _on_buy(id: StringName) -> void:
	if is_record_off():
		return   # 프리셋·부여 판에서는 실제 메타를 바꾸는 구매를 막는다(main._on_buy 와 같은 규칙)
	if _run_state() != null and _run_state().meta.buy(id):
		_run_state().save_meta()
	_refresh_shop()

# ---- 설정 ----

func _setting(key: String, def: bool) -> bool:
	return flow.settings.get_bool(key, def)

func _refresh_settings() -> void:
	for row in SETTING_ROWS:
		var on: bool = _setting(row[0], row[2])
		var state_txt: String = GameStrings.get_text(&"ui.settings.on" if on else &"ui.settings.off")
		settings_buttons[row[0]].text = "%s  %s" % [GameStrings.get_text(row[1]), state_txt]

func _on_setting_toggled(key: String) -> void:
	var def: bool = true
	for row in SETTING_ROWS:
		if row[0] == key:
			def = row[2]
	flow.settings.data[key] = not _setting(key, def)   # 저장은 나갈 때(ux §6.2)
	_refresh_settings()
	_apply_settings_to_host()

func _on_settings_back() -> void:
	if not flow.direct_run:
		flow.settings.save_file()
	flow.close_settings()

## 변경 즉시 적용. 현재 실제로 반영되는 항목은 화면 흔들림뿐이고 나머지는 저장만 한다.
func _apply_settings_to_host() -> void:
	if host == null or flow.direct_run:
		return
	var bal: Variant = host.get("bal")
	if bal != null:
		bal.shake_enabled = _setting("screen_shake", true)

# ---- 뒤로 가기 ----

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		auto_pause()

## 백그라운드/포커스 이탈: RUN 이면 기존 pause() 로 전환. 복귀 시 자동 재개하지 않는다.
func auto_pause() -> void:
	if flow != null and flow.state == Flow.State.RUN:
		flow.pause()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		handle_back()

func handle_back() -> void:
	match flow.state:
		Flow.State.RUN:
			flow.pause()
		Flow.State.PAUSE:
			if pause_confirm_box.visible:
				_set_confirm(false)
			else:
				flow.resume()
		Flow.State.SETTINGS:
			_on_settings_back()
		Flow.State.INTRO:
			_on_cut_skip()
		Flow.State.RESULT:
			if cut != null:
				_on_cut_skip()
			else:
				flow.quit_to_title()
		Flow.State.TITLE:
			get_tree().quit()
