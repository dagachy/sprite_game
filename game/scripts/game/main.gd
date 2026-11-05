extends Node2D
## 프로토타입 진입점: Battle 코어 구동, 터치 입력, 최소 HUD / 3택 / 결과 / 노드 구매 화면(텍스트, P0 디버그).
## ui-implementer 가 정식 UI 로 교체할 때는 Battle 의 시그널·공개 API 만 쓰면 된다(scripts/core/README.md).
## 디버그: F1 무적, F2 배속(1/2/4/8), F3 시드 고정, F5 새 판, F6 캡처, F7 월드 정지, F8 한 프레임, F9 HUD 숨김. 1~3 카드 선택, R 리롤, WASD/방향키 이동.

const STEP: float = 1.0 / 60.0

var bal: Balance
var db: Dictionary
var battle: Battle
var view: Node2D
var ui: CanvasLayer
var hud_label: Label
var debug_label: Label
var banner_label: Label
var hint_label: Label
var hp_bar: ColorRect
var hp_back: ColorRect
var xp_bar: ColorRect
var offer_box: VBoxContainer
var offer_buttons: Array[Button] = []
var reroll_button: Button
var result_box: VBoxContainer
var result_dim: ColorRect
var result_label: Label
var shop_buttons: Array[Button] = []

var accum: float = 0.0
var speed_mult: float = 1.0
var fixed_seed: bool = false
var fixed_seed_value: int = 12345
var god: bool = false
var touch_idx: int = -1
var touch_start: Vector2 = Vector2.ZERO
var banner_t: float = 0.0
var hint_t: float = 0.0
var result_shown: bool = false
var cap: RefCounted = null   # 디버그 캡처 도구 (디버그 빌드에서만 생성, C1·C2·C5)
var world_paused: bool = false   # C2 월드 정지 (F7). 정지 중 F8 은 한 프레임 이동
var step_once: bool = false
var offer_lock: OfferLock = OfferLock.new()   # 3택 입력 잠금 0.5s (AC-35)
var last_points: int = 0
var run_seq: int = 0
var run_id_cur: String = ""   # 현재 판 run_id (P3 형식). start_run 에서 설정
var cur_preset: StringName = &""   # 현재 판의 C3 프리셋 ID (일반 판이면 빈 값)
var preset_pick: OptionButton      # 디버그 패널: 프리셋 선택 (디버그 빌드에서만 생성)

func _ready() -> void:
	bal = Balance.load_default()
	db = ChunkDb.load_all()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			fixed_seed = true
			fixed_seed_value = int(a.substr(7))
	view = load("res://scripts/game/battle_view.gd").new()
	add_child(view)
	_build_ui()
	if OS.is_debug_build():
		cap = load("res://scripts/debug/capture_rig.gd").new()
	start_run()

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	hp_back = ColorRect.new(); hp_back.color = Palette.T3; hp_back.position = Vector2(6, 6); hp_back.size = Vector2(90, 6)
	hp_bar = ColorRect.new(); hp_bar.color = Palette.HEAL; hp_bar.position = Vector2(6, 6); hp_bar.size = Vector2(90, 6)
	xp_bar = ColorRect.new(); xp_bar.color = Palette.XP; xp_bar.position = Vector2(6, 14); xp_bar.size = Vector2(0, 3)
	for n in [hp_back, hp_bar, xp_bar]:
		ui.add_child(n)
	hud_label = _label(Vector2(100, 2), 9)
	# 디버그 HUD 는 디버그 빌드에서만 노드로 만든다 (AC-43, UA R1~R5)
	if OS.is_debug_build():
		debug_label = _label(Vector2(6, 20), 8)
		_build_preset_panel()
	banner_label = _label(Vector2(0, 96), 14)
	banner_label.size = Vector2(216, 24)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label = _label(Vector2(0, 330), 9)
	hint_label.size = Vector2(216, 20)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_box = VBoxContainer.new()
	offer_box.position = Vector2(14, 90); offer_box.size = Vector2(188, 200)
	for i in 3:
		var bt := Button.new()
		bt.custom_minimum_size = Vector2(188, 40)
		bt.add_theme_font_size_override("font_size", 10)
		bt.pressed.connect(_on_pick.bind(i))
		offer_box.add_child(bt)
		offer_buttons.append(bt)
	reroll_button = Button.new()
	reroll_button.custom_minimum_size = Vector2(188, 28)
	reroll_button.add_theme_font_size_override("font_size", 10)
	reroll_button.pressed.connect(_on_reroll)
	offer_box.add_child(reroll_button)
	offer_box.visible = false
	ui.add_child(offer_box)
	# 결과·사망 화면 대비: 뒤 게임 장면을 딤 처리 (글자 대비 확보)
	result_dim = ColorRect.new()
	result_dim.color = Color(Palette.VOID, 0.72)
	result_dim.position = Vector2.ZERO; result_dim.size = Vector2(216, 384)
	result_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_dim.visible = false
	ui.add_child(result_dim)
	result_box = VBoxContainer.new()
	result_box.position = Vector2(14, 40); result_box.size = Vector2(188, 300)
	result_label = Label.new()
	result_label.add_theme_font_size_override("font_size", 10)
	result_box.add_child(result_label)
	for nd in MetaState.NODES:
		var sb := Button.new()
		sb.custom_minimum_size = Vector2(188, 26)
		sb.add_theme_font_size_override("font_size", 9)
		sb.pressed.connect(_on_buy.bind(nd["id"]))
		result_box.add_child(sb)
		shop_buttons.append(sb)
	var again := Button.new()
	again.text = "다시 시작 (F5)"
	again.custom_minimum_size = Vector2(188, 30)
	again.add_theme_font_size_override("font_size", 10)
	again.pressed.connect(start_run)
	result_box.add_child(again)
	result_box.visible = false
	ui.add_child(result_box)

## C3 프리셋 패널 (디버그 전용). 하단에 선택 메뉴와 시작 버튼을 둔다. 릴리스에서는 호출되지 않는다.
func _build_preset_panel() -> void:
	preset_pick = OptionButton.new()
	preset_pick.position = Vector2(6, 352)
	preset_pick.custom_minimum_size = Vector2(150, 24)
	preset_pick.add_theme_font_size_override("font_size", 8)
	for id in CapturePresets.ids():
		var idx: int = preset_pick.item_count
		preset_pick.add_item("%s %s" % [String(id), String(CapturePresets.PRESETS[id]["label"])])
		preset_pick.set_item_metadata(idx, id)
	ui.add_child(preset_pick)
	var go := Button.new()
	go.text = "프리셋 시작"
	go.position = Vector2(160, 352)
	go.custom_minimum_size = Vector2(50, 24)
	go.add_theme_font_size_override("font_size", 8)
	go.pressed.connect(_on_preset_go)
	ui.add_child(go)

func _label(pos: Vector2, size_px: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", Palette.WHITE)
	l.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	l.add_theme_constant_override("outline_size", 3)
	ui.add_child(l)
	return l

## preset 이 비어 있지 않으면 C3 시드 프리셋으로 시작한다(디버그 전용). 비어 있으면 일반 판.
func start_run(preset: StringName = &"") -> void:
	run_seq += 1
	cur_preset = preset
	var sv: int = fixed_seed_value if fixed_seed else int(Time.get_ticks_usec() & 0x7FFFFFFF)
	if preset != &"":
		sv = int(CapturePresets.PRESETS[preset]["seed"])
	# P3 run_id: {UTC일자}-{UTC시각}-{seed 8hex}-{run_idx}. run_idx = 설치 후 누적 판 번호(정산 전 기준 +1)
	var utc := Time.get_datetime_dict_from_system(true)
	run_id_cur = "%04d%02d%02d-%02d%02d%02d-%08x-%d" % [utc["year"], utc["month"], utc["day"],
		utc["hour"], utc["minute"], utc["second"], sv & 0xFFFFFFFF, RunState.meta.runs_played + 1]
	Log.run_id = run_id_cur
	if preset != &"":
		# D5: 프리셋은 저장 메타를 읽지 않고 고정 메타(빈 MetaState)를 쓴다
		battle = CapturePresets.make_battle(preset, bal, db, MetaState.new())
	else:
		battle = Battle.new(bal, sv, &"sword", RunState.meta, RunState.is_early_run(), db)
		battle.god_mode = god   # 프리셋은 자체 god 설정을 유지해야 결정성이 지켜진다
	battle.offer_ready.connect(_on_offer_ready)
	battle.banner.connect(_on_banner)
	battle.hint.connect(_on_hint)
	battle.run_ended.connect(_on_run_ended)
	battle.log_event.connect(func(n: String, d: Dictionary) -> void: Log.event(n, d))
	# P3 이벤트 정본 중 P0 필수 (run_start, 구역 A 진입)
	Log.event("run_start", {"seed": sv, "class": "sword", "early": battle.early_run})
	Log.event("zone_enter", {"zone": "A", "t": 0.0})
	view.battle = battle
	offer_box.visible = false
	result_box.visible = false
	result_dim.visible = false
	result_shown = false
	touch_idx = -1
	accum = 0.0
	if preset != &"":
		# 신호 연결 뒤에 진행해야 3택 UI 가 열린다. 도달 후 C2 정지로 화면을 고정한다
		CapturePresets.advance(battle, preset)
		world_paused = true
		step_once = false

## 디버그 패널: 선택한 프리셋으로 판을 시작한다.
func _on_preset_go() -> void:
	var idx: int = preset_pick.selected
	if idx < 0:
		return
	start_run(preset_pick.get_item_metadata(idx))

func _process(delta: float) -> void:
	if battle == null:
		return
	if touch_idx < 0:
		var d := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
		if Input.is_physical_key_pressed(KEY_A): d.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D): d.x += 1.0
		if Input.is_physical_key_pressed(KEY_W): d.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S): d.y += 1.0
		if d != Vector2.ZERO:
			battle.set_input(true, d.limit_length(1.0) * 30.0)
		else:
			battle.set_input(false, Vector2.ZERO)
	offer_lock.tick(delta)
	if world_paused:
		# C2: 월드 정지. 누적 시간을 버리고, 요청된 한 프레임만 진행한다
		accum = 0.0
		if step_once:
			battle.step(STEP)
			step_once = false
	else:
		accum += minf(delta, 0.1) * speed_mult
		var guard: int = 0
		while accum >= STEP and guard < 16:
			battle.step(STEP)
			accum -= STEP
			guard += 1
	view.position = Vector2.ZERO
	if bal.shake_enabled and battle.shake_left > 0.0:
		view.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * battle.shake_amp
	view.queue_redraw()
	_update_hud(delta)

func _update_hud(delta: float) -> void:
	var b: Battle = battle
	hp_bar.size.x = 90.0 * clampf(b.hp / b.max_hp, 0.0, 1.0)
	xp_bar.size.x = 90.0 * clampf(float(b.xp) / float(b.xp_need), 0.0, 1.0)
	hud_label.text = "Lv%d  %d:%02d  처치 %d" % [b.level, int(b.run_time) / 60, int(b.run_time) % 60, b.kills]
	if debug_label != null:
		debug_label.text = "x%.0f 시드 %d%s%s 적 %d %d fps" % [speed_mult, b.seed_value, " [고정]" if fixed_seed else "",
				" [무적]" if b.god_mode else "", b.enemies.n, Engine.get_frames_per_second()]
	if banner_t > 0.0:
		banner_t -= delta
		if banner_t <= 0.0:
			banner_label.text = ""
	if hint_t > 0.0:
		hint_t -= delta
		if hint_t <= 0.0:
			hint_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if battle == null or battle.awaiting_pick or battle.ended:
		return
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed and touch_idx < 0:
			touch_idx = st.index
			touch_start = st.position
			battle.set_input(true, Vector2.ZERO)
		elif not st.pressed and st.index == touch_idx:
			touch_idx = -1
			battle.set_input(false, Vector2.ZERO)
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		if sd.index == touch_idx:
			battle.set_input(true, sd.position - touch_start)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: InputEventKey = event
	# F1~F9 디버그 단축키는 디버그 빌드에서만 동작한다 (AC-43)
	if not OS.is_debug_build() and k.keycode in [KEY_F1, KEY_F2, KEY_F3, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9]:
		return
	match k.keycode:
		KEY_F6:
			_capture()
		KEY_F7:
			world_paused = not world_paused
			step_once = false
		KEY_F8:
			if world_paused:
				step_once = true
		KEY_F9:
			ui.visible = not ui.visible
		KEY_F1:
			god = not god
			battle.god_mode = god
		KEY_F2:
			speed_mult = 1.0 if speed_mult >= 8.0 else speed_mult * 2.0
		KEY_F3:
			fixed_seed = not fixed_seed
		KEY_F5:
			start_run()
		KEY_1, KEY_2, KEY_3:
			if battle.awaiting_pick:
				_on_pick(k.keycode - KEY_1)
		KEY_R:
			if battle.awaiting_pick:
				_on_reroll()

# --- Battle 시그널 ---------------------------------------------------------

## C5: 현재 화면을 user://captures/ 에 PNG 로 저장한다(디버그 전용).
func _capture() -> void:
	if cap == null:
		return
	var path: String = await cap.snap(get_tree(), String(cur_preset))
	print("capture: ", ProjectSettings.globalize_path(path))

func _card_text(c: Dictionary) -> String:
	var tag: String = "신규" if c["is_new"] else "강화"
	if c["kind"] == &"fallback":
		return "[보상] %s" % String(c["id"])
	return "[%s] %s  Lv%d" % [tag, String(c["id"]), int(c["level"])]

func _on_offer_ready(cards: Array, rerolls_left: int, _source: StringName) -> void:
	for i in 3:
		offer_buttons[i].text = _card_text(cards[i]) if i < cards.size() else ""
		offer_buttons[i].visible = i < cards.size()
	reroll_button.text = "리롤 (남은 %d)" % rerolls_left
	reroll_button.disabled = rerolls_left <= 0
	offer_box.visible = true
	touch_idx = -1
	offer_lock.arm()

func _on_pick(i: int) -> void:
	if offer_lock.is_locked():
		return
	if battle.pick(i):
		offer_box.visible = battle.awaiting_pick

func _on_reroll() -> void:
	if offer_lock.is_locked():
		return
	battle.reroll()

func _on_banner(key: String) -> void:
	banner_label.text = key
	banner_t = 1.5

func _on_hint(key: String) -> void:
	hint_label.text = key
	hint_t = 3.0

func _on_run_ended(result: Dictionary) -> void:
	if result_shown:
		return
	result_shown = true
	last_points = RunState.meta.settle(result, bal)
	RunState.save_meta()
	var lines: PackedStringArray = []
	lines.append("판 종료: %s" % ("클리어" if result["cleared"] else "쓰러짐 (%s)" % String(result["death_cause"])))
	lines.append("각인 +%d (보유 %d)" % [last_points, RunState.meta.points])
	for it in result["top_items"]:
		lines.append("  %s  %d" % [it["key"], it["value"]])
	result_label.text = "\n".join(lines)
	_refresh_shop()
	result_box.visible = true
	result_dim.visible = true
	offer_box.visible = false
	# runs.jsonl 필드는 P3 §2.3 정본. 릴리스에서는 debug 값이 기본값(false/1.0)으로 고정된다.
	var dbg: bool = OS.is_debug_build()
	Log.run_record({"run_id": run_id_cur, "seed": int(result["seed"]), "class": String(result["class"]),
		"result": "cleared" if result["cleared"] else "died",
		"death_cause": String(result["death_cause"]), "death_zone": String(result["death_zone"]),
		"killer_kind": String(result["killer_kind"]),
		"duration_s": snappedf(float(result["duration"]), 0.01),
		"points": last_points, "levelups": int(result["levelups"]), "kills": int(result["kills"]),
		"boss_reached": bool(result["boss_reached"]), "quit_midrun": false,
		"retry_taps": null, "restart_latency_s": null,
		"pick_log": result["pick_log"].map(func(x: StringName) -> String: return String(x)),
		"debug": {"god": dbg and god, "time_scale": speed_mult if dbg else 1.0,
			"terrain_off": false, "seed_fixed": dbg and fixed_seed}})

func _refresh_shop() -> void:
	for i in MetaState.NODES.size():
		var nd: Dictionary = MetaState.NODES[i]
		var owned: bool = RunState.meta.owned.has(nd["id"])
		shop_buttons[i].text = "%s (%d)%s" % [nd["name"], nd["cost"], " 보유" if owned else ""]
		shop_buttons[i].disabled = owned or not RunState.meta.can_buy(nd["id"])

func _on_buy(id: StringName) -> void:
	if RunState.meta.buy(id):
		RunState.save_meta()
		result_label.text += "\n구매: %s" % String(id)
	_refresh_shop()
