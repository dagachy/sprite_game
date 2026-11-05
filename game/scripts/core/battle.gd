class_name Battle extends RefCounted
## 전투 시뮬레이션 코어(Node·물리 엔진·Area2D 없음). 고정 델타로 step(dt) 을 직접 호출하면 헤드리스에서 돈다.
## 좌표: 화면 논리 좌표(216x384). 지형은 WorldStrip(scroll 반영), 적·보석·지뢰는 스크롤과 함께 아래로 밀린다.
## 입력: set_input(active, offset). 선택: pick(i), reroll(). UI 연결 기준은 scripts/core/README.md.

signal offer_ready(cards: Array, rerolls_left: int, source: StringName)
signal banner(key: String)
signal hint(key: String)
signal player_hurt(amount: float, cause: StringName)
signal run_ended(result: Dictionary)
signal evolved(weapon_id: StringName, result_id: StringName)
signal log_event(ev_name: String, data: Dictionary)

enum Phase { ZONE, PLAZA, APPROACH, BOSS, ENDED }

const SOLID: int = ChunkDef.BIT_WALL | ChunkDef.BIT_COVER
const GEM_CAP := 400
const MINE_CAP := 6
const SRC_HAZARD := 6
const SRC_OTHER := 7

# --- 설정/하위 시스템 ---
var bal: Balance
var meta: MetaState
var seed_value: int = 1
var class_id: StringName = &"sword"
var early_run: bool = false          # 판 1~3: 슬롯 고정, xp_need(1)=8
var strip: WorldStrip = WorldStrip.new()
var scroll_model: ScrollModel
var spawner: SpawnDirector
var clock: WorldClock = WorldClock.new()
var aim: AutoAim = AutoAim.new()
var hash: SpatialHash = SpatialHash.new(256)
var enemies: EnemyPool
var abul: BulletPool
var ebul: BulletPool
var rng_offer: RandomNumberGenerator = RandomNumberGenerator.new()
var rng_fx: RandomNumberGenerator = RandomNumberGenerator.new()
var chain: Array[StringName] = []

# --- 디버그 ---
var god_mode: bool = false

# --- 진행 ---
var phase: int = Phase.ZONE
var t: float = 0.0               # 월드 시간(감속 반영)
var run_time: float = 0.0        # 실시간 경과
var ended: bool = false
var cleared: bool = false
var boss_reached: bool = false
var zone_banner_done: bool = false
var level: int = 1
var xp: int = 0
var xp_need: int = 8
var kills: int = 0
var levelups: int = 0
var coins: int = 0
var picks: Array[StringName] = []

# --- 플레이어 ---
var px: float = 108.0
var py: float = 296.0
var pvx: float = 0.0
var pvy: float = 0.0
var hp: float = 100.0
var max_hp: float = 100.0
var invuln_left: float = 0.0
var haz_acc: float = 0.0
var crush_t: float = 0.0
var last_hit_cause: StringName = &""
var last_killer_kind: StringName = &""   # P3 Y·live-ops: 피해 출처 세분화(enemy 종류, boss, self 등)
var first_hit_hint: bool = false
var cover_hint: bool = false
var input_active: bool = false
var input_off: Vector2 = Vector2.ZERO
var anchor: Vector2 = Vector2.ZERO
var _was_active: bool = false
var slow_on: bool = false
var boss_gauge: float = 3.0
var boss_gauge_locked: bool = false
var player_dir: Vector2 = Vector2(0, -1)

# --- 성장 ---
var offer_state: OfferState = OfferState.new()
var current_offer: Array[Dictionary] = []
var rerolls_left: int = 0
var awaiting_pick: bool = false
var pending_levels: int = 0
var pending_free: int = 0
var offer_source: StringName = &"levelup"
var evolve_queue: Array[Array] = []   # [weapon_id, time_left]
var dmg_by_src: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0])
var wcd: Dictionary = {}
var swing_q: Array[Array] = []        # [time_left, angle_rad, weapon_id]
var orbit_angle: float = 0.0
var weapon_order: Array[StringName] = []
var aim_idx: int = -1
var cover_bonus: bool = false
var orb_n: int = 0
var orb_r: float = 0.0

# --- 월드 개체 ---
var gx: PackedFloat32Array = PackedFloat32Array()
var gy: PackedFloat32Array = PackedFloat32Array()
var gv: PackedInt32Array = PackedInt32Array()
var gs: PackedInt32Array = PackedInt32Array()
var gn: int = 0
var mx: PackedFloat32Array = PackedFloat32Array()
var my: PackedFloat32Array = PackedFloat32Array()
var mt: PackedFloat32Array = PackedFloat32Array()
var ms: PackedInt32Array = PackedInt32Array()
var mn: int = 0
var slashes: Array[Dictionary] = []   # 렌더용 참격 이펙트 {x,y,ang,arc,range,life,max}
var booms: Array[Dictionary] = []     # 폭발/충격 이펙트 {x,y,r,life,max,kind}
var tele: Array[Dictionary] = []      # 예고 표시(보스 띠 등) 렌더용

# --- 구간 ---
var elite_recover: float = 0.0
var marker_gap: float = 0.0
var heal_used: bool = false
var plaza_gems_done: bool = false
var plaza_exit_ready: bool = false
var boss_uid: int = -1
var boss_t: float = 0.0
var minion_t: float = 0.0
var boss_tele_kind: int = 0      # 0 없음, 1 B1 띠, 2 B2 조준선(뷰용)
var boss_tele_x: float = 0.0
var boss_tele_t: float = 0.0
var pillar_stuns: int = 0
var stats_spawn: int = 0
var spawn_log: Array[Dictionary] = []   # 테스트/로그용 {t,x,y,kind,source}
var spawn_log_enabled: bool = false

# --- 연출 요청(뷰가 읽음) ---
var shake_amp: float = 0.0
var shake_left: float = 0.0

# 타입별 캐시
var _t_hp: PackedFloat32Array = PackedFloat32Array()
var _t_atk: PackedFloat32Array = PackedFloat32Array()
var _t_spd: PackedFloat32Array = PackedFloat32Array()
var _t_rad: PackedFloat32Array = PackedFloat32Array()
var _t_xp: PackedInt32Array = PackedInt32Array()
var _t_kind: PackedInt32Array = PackedInt32Array()
var _qbuf: PackedInt32Array = PackedInt32Array()

func _init(balance: Balance = null, seed_v: int = 1, cls: StringName = &"sword",
		meta_state: MetaState = null, early: bool = false, chunk_db: Dictionary = {}) -> void:
	bal = balance if balance != null else Balance.new()
	meta = meta_state if meta_state != null else MetaState.new()
	seed_value = seed_v
	class_id = cls
	early_run = early
	rng_offer.seed = seed_v ^ 0x0FFE
	rng_fx.seed = seed_v ^ 0x0A11
	_qbuf.resize(96)
	enemies = EnemyPool.new(maxi(bal.stress_alive + 40, 192))
	abul = BulletPool.new(bal.ally_bullet_cap + 60)
	ebul = BulletPool.new(bal.enemy_bullet_cap + 40)
	gx.resize(GEM_CAP); gy.resize(GEM_CAP); gv.resize(GEM_CAP); gs.resize(GEM_CAP)
	mx.resize(MINE_CAP); my.resize(MINE_CAP); mt.resize(MINE_CAP); ms.resize(MINE_CAP)
	for id in EnemyPool.TYPE_IDS:
		var d: Dictionary = Defs.ENEMIES[id]
		_t_hp.append(float(d["hp"]))
		_t_atk.append(float(d["atk"]))
		_t_spd.append(float(d["speed"]))
		_t_rad.append(float(d["r"]))
		_t_xp.append(int(d["xp"]))
		_t_kind.append(int(d["kind"]))
	_t_hp[EnemyPool.T_BOSS] = bal.boss_hp
	if chunk_db.is_empty():
		chunk_db = ChunkDb.load_all()
	chain = StageRecipe.full_chain(seed_v, early)
	strip.build(chain, chunk_db)
	scroll_model = ScrollModel.new(bal)
	scroll_model.state_changed.connect(_on_scroll_state)
	spawner = SpawnDirector.new(bal, seed_v)
	_setup_player()

func _setup_player() -> void:
	px = bal.player_start.x
	py = bal.player_start.y
	max_hp = bal.max_hp * (1.0 + meta.stat(&"max_hp_mult"))
	hp = max_hp
	var start: StringName = Defs.CLASSES[class_id]["start"]
	offer_state.weapons[start] = 1
	weapon_order.append(start)
	offer_state.material_boost = bal.material_boost
	offer_state.material_pity = bal.material_pity
	offer_state.base_weight = bal.offer_base_weight
	offer_state.evolve_min_level = bal.evolve_min_level
	wcd[start] = 0.5
	boss_gauge = bal.boss_gauge_max
	xp_need = _need_for(level)

func _need_for(n: int) -> int:
	if n == 1 and early_run:
		return bal.xp_first_need_early
	return XpCurve.need(n, bal.xp_a, bal.xp_b, bal.xp_c, bal.xp_first_mult)

# ======================================================================
# 공개 API
# ======================================================================

func set_input(active: bool, offset: Vector2) -> void:
	input_active = active
	input_off = offset

func hp_scale() -> float:
	return exp(bal.hp_growth * t)

func atk_scale() -> float:
	return 1.0 + bal.atk_growth * t

func speed_scale() -> float:
	return minf(1.0 + bal.speed_growth * t, bal.speed_cap)

func passive_level(id: StringName) -> int:
	return int(offer_state.passives.get(id, 0))

func passive_val(id: StringName) -> float:
	return Defs.passive_value(id, passive_level(id))

func magnet_radius() -> float:
	return bal.base_magnet + passive_val(&"P03") + meta.stat(&"magnet")

func damage_mult() -> float:
	return bal.damage_mult * (1.0 + meta.stat(&"damage_mult"))

func zone_name() -> StringName:
	match phase:
		Phase.PLAZA: return &"plaza"
		Phase.APPROACH, Phase.BOSS: return &"boss"
	return &"A"

func alive_enemies() -> int:
	return enemies.alive_count()

## 현재 슬롯(플레이어 기준선에 걸친 청크)의 spawn_scale. 슬롯 0 은 0.7 (level §4.2).
func slot_scale() -> float:
	var p: WorldStrip.Placed = strip.chunk_at_world(py - strip.scroll)
	if p != null and p.slot == 0:
		return 0.7
	return 1.0

# ======================================================================
# step
# ======================================================================

func step(raw_dt: float) -> void:
	if ended:
		return
	if shake_left > 0.0:
		shake_left = maxf(shake_left - raw_dt, 0.0)
	_age_fx(raw_dt)
	if awaiting_pick:
		return
	run_time += raw_dt
	_update_slow(raw_dt)
	_update_evolve(raw_dt)     # 진화 지연은 히트스톱과 무관하게 실시간 1.5s
	var wdt: float = clock.frame(raw_dt)
	if wdt <= 0.0:
		return
	var pdt: float = wdt + (bal.slow_player_comp * (raw_dt - wdt) if slow_on else 0.0)
	t += wdt
	if not zone_banner_done and t >= 0.5:
		zone_banner_done = true
		banner.emit("ui.zone.a")
	if invuln_left > 0.0:
		invuln_left = maxf(invuln_left - wdt, 0.0)
	elite_recover = maxf(elite_recover - wdt, 0.0)
	marker_gap = maxf(marker_gap - wdt, 0.0)

	_move_player(pdt)
	_do_scroll(wdt)
	_spawn_step(wdt)
	hash.rebuild(enemies.x, enemies.y, enemies.hp, enemies.n)
	EnemyAI.update(self, wdt)
	WeaponSystem.update(self, wdt)
	hash.rebuild(enemies.x, enemies.y, enemies.hp, enemies.n)
	WeaponSystem.update_bullets(self, wdt)
	_update_enemy_bullets(wdt)
	_update_gems(wdt)
	_hazards(wdt)
	_contacts()
	_reap()
	_check_levelup()
	if ended:
		return
	if phase == Phase.BOSS:
		boss_t += wdt

func _age_fx(dt: float) -> void:
	var i: int = 0
	while i < slashes.size():
		slashes[i]["life"] = float(slashes[i]["life"]) - dt
		if float(slashes[i]["life"]) <= 0.0:
			slashes.remove_at(i)
		else:
			i += 1
	i = 0
	while i < booms.size():
		booms[i]["life"] = float(booms[i]["life"]) - dt
		if float(booms[i]["life"]) <= 0.0:
			booms.remove_at(i)
		else:
			i += 1

func _update_slow(raw_dt: float) -> void:
	var want: bool = not input_active
	if phase == Phase.BOSS or phase == Phase.APPROACH:
		if not bal.boss_gauge_enabled:
			pass
		elif boss_gauge_locked:
			want = false
		elif want and phase == Phase.BOSS:
			boss_gauge = maxf(boss_gauge - raw_dt, 0.0)
			if boss_gauge <= 0.0:
				boss_gauge_locked = true
				want = false
		if not want:
			boss_gauge = minf(boss_gauge + bal.boss_gauge_regen * raw_dt, bal.boss_gauge_max)
			if boss_gauge_locked and boss_gauge >= bal.boss_gauge_resume:
				boss_gauge_locked = false
	slow_on = want
	var target: float = bal.slow_world_scale if want else 1.0
	var k: float = bal.blend_in if want else bal.blend_out
	clock.world_scale = move_toward(clock.world_scale, target, absf(1.0 - bal.slow_world_scale) / maxf(k, 0.001) * raw_dt)

# ----------------------------------------------------------------------
# 플레이어 이동
# ----------------------------------------------------------------------

func _move_player(dt: float) -> void:
	var want := Vector2.ZERO
	if input_active:
		if not _was_active:
			anchor = Vector2(px, py)
		var target: Vector2 = anchor + input_off * bal.sensitivity
		var to: Vector2 = target - Vector2(px, py)
		var dist: float = to.length()
		if dist > bal.reanchor_radius:
			var dir: Vector2 = to / dist
			anchor -= to - dir * bal.reanchor_radius
			to = dir * bal.reanchor_radius
			dist = bal.reanchor_radius
		if dist > bal.deadzone_px and dist > bal.arrive_radius:
			want = (to / maxf(bal.follow_time, 0.001)).limit_length(bal.max_speed)
	_was_active = input_active
	var at: float = bal.accel_time if want != Vector2.ZERO else bal.decel_time
	var kk: float = clampf(dt / maxf(at, 0.001), 0.0, 1.0)
	pvx += (want.x - pvx) * kk
	pvy += (want.y - pvy) * kk
	var r: float = bal.player_radius
	var nx: float = px + pvx * dt
	if strip.circle_hits(nx, py, r, SOLID):
		pvx = 0.0
	else:
		px = nx
	var ny: float = py + pvy * dt
	if strip.circle_hits(px, ny, r, SOLID):
		pvy = 0.0
	else:
		py = ny
	px = clampf(px, WorldStrip.BORDER + r, WorldStrip.WIDTH_PX - WorldStrip.BORDER - r)
	py = clampf(py, bal.player_top_limit, bal.player_bottom_limit)
	if pvx * pvx + pvy * pvy > 4.0:
		player_dir = Vector2(pvx, pvy).normalized()

# ----------------------------------------------------------------------
# 스크롤
# ----------------------------------------------------------------------

func _marker_sy(p: WorldStrip.Placed, ch: String) -> float:
	if p == null:
		return -9999.0
	for m in p.markers:
		if m["ch"] == ch:
			return float(m["wy"]) + strip.scroll
	return -9999.0

func _do_scroll(wdt: float) -> void:
	var plaza_top: float = strip.plaza.origin_y + strip.scroll
	var g_y: float = _marker_sy(strip.entry, "G")
	var arena_top: float = strip.arena.origin_y + strip.scroll
	var exit_now: bool = plaza_exit_ready and py < plaza_top + 24.0
	var elite_alive: bool = elite_recover > 0.0 or _elite_alive()
	var ds: float = scroll_model.step(wdt, enemies.alive_count(), elite_alive, plaza_top, g_y, arena_top, exit_now)
	if ds <= 0.0:
		return
	strip.scroll += ds
	for i in enemies.n:
		enemies.y[i] += ds
	for i in gn:
		gy[i] += ds
	for i in mn:
		my[i] += ds
	# 벽이 플레이어를 밀어내는 경우(끼임 규칙)
	if strip.circle_hits(px, py, bal.player_radius, SOLID):
		py += ds
		if py > bal.player_bottom_limit or strip.circle_hits(px, py, bal.player_radius, SOLID):
			crush_t += wdt
			if crush_t >= 1.0:
				_resolve_crush()
		else:
			crush_t = 0.0
	else:
		crush_t = 0.0

func _resolve_crush() -> void:
	crush_t = 0.0
	var best := Vector2(px, py)
	var best_d: float = 1e9
	for dy in range(-6, 7):
		for dx in range(-6, 7):
			var cand := Vector2(px + dx * 8.0, py + dy * 8.0)
			if cand.y < bal.player_top_limit or cand.y > bal.player_bottom_limit:
				continue
			if strip.circle_hits(cand.x, cand.y, bal.player_radius, SOLID):
				continue
			var d: float = cand.distance_squared_to(Vector2(px, py))
			if d < best_d:
				best_d = d
				best = cand
	px = best.x
	py = best.y
	log_event.emit("crush", {"t": t})
	hurt(10.0, &"crush", true, true)

func _elite_alive() -> bool:
	for i in enemies.n:
		if enemies.type[i] == EnemyPool.T_EL and enemies.hp[i] > 0.0:
			return true
	return false

func _on_scroll_state(s: int) -> void:
	match s:
		ScrollModel.S.PLAZA_DECEL:
			phase = Phase.PLAZA
			log_event.emit("zone_enter", {"zone": "plaza", "t": t})
			banner.emit("ui.zone.plaza")
			spawner.start_grace(t, 9999.0)
		ScrollModel.S.PLAZA_HOLD:
			_clear_enemies()
			_plaza_setup()
			pending_free += 1
			_try_offer()
		ScrollModel.S.ENTRY:
			phase = Phase.APPROACH
		ScrollModel.S.SLIDE:
			banner.emit("ui.zone.boss")
		ScrollModel.S.ARENA:
			_start_boss()

func _clear_enemies() -> void:
	for i in enemies.n:
		enemies.hp[i] = -1.0
	ebul.clear()

func _plaza_setup() -> void:
	if plaza_gems_done:
		return
	plaza_gems_done = true
	if strip.plaza == null:
		return
	for m in strip.plaza.markers:
		if m["ch"] == "D":
			for k in 3:
				_add_gem(float(m["x"]) + rng_fx.randf_range(-8, 8), float(m["wy"]) + strip.scroll + rng_fx.randf_range(-8, 8), 2)

func _start_boss() -> void:
	phase = Phase.BOSS
	log_event.emit("zone_enter", {"zone": "boss", "t": t})
	boss_reached = true
	_clear_enemies()
	var sx: float = 0.0
	var sy: float = 0.0
	var c: int = 0
	for m in strip.arena.markers:
		if m["ch"] == "B":
			sx += float(m["x"])
			sy += float(m["wy"]) + strip.scroll
			c += 1
	if c > 0:
		sx /= c
		sy /= c
	else:
		sx = 108.0
		sy = strip.arena.origin_y + strip.scroll + 48.0
	var i: int = add_enemy(EnemyPool.T_BOSS, sx, sy, EnemyAI.BS_INTRO)
	if i >= 0:
		boss_uid = enemies.uid[i]
		enemies.tm[i] = bal.boss_intro
		enemies.aux2[i] = sy      # 홈 y
	minion_t = bal.minion_interval
	boss_t = 0.0
	log_event.emit("boss_start", {"t": t})

# ----------------------------------------------------------------------
# 스폰
# ----------------------------------------------------------------------

func add_enemy(type_idx: int, x: float, y: float, state: int = 0) -> int:
	var hs: float = hp_scale()
	var hp_v: float = _t_hp[type_idx] * hs
	if type_idx == EnemyPool.T_EL:
		hp_v *= bal.elite_hp_mult
	if type_idx == EnemyPool.T_BOSS:
		hp_v = bal.boss_hp
	var i: int = enemies.add(type_idx, x, y, hp_v, _t_spd[type_idx] * speed_scale(),
			_t_atk[type_idx] * atk_scale(), _t_rad[type_idx], _t_xp[type_idx], _t_kind[type_idx], state)
	if i >= 0:
		stats_spawn += 1
	return i

func _type_of(id: StringName) -> int:
	return EnemyPool.TYPE_IDS.find(id)

func _spawn_step(wdt: float) -> void:
	if phase != Phase.ZONE:
		return
	var alive: int = enemies.alive_count()
	if spawner.tick(wdt, t, alive, slot_scale()) > 0:
		var pos: Vector3 = spawner.ring_position(strip, Vector2(px, py))
		if pos.z >= 0.0:
			var kid: StringName = spawner.pick_kind()
			var ti: int = _type_of(kid)
			var side: bool = int(pos.z) == SpawnDirector.SRC_SIDE
			var i: int = add_enemy(ti, pos.x, pos.y, EnemyPool.ST_EMERGE if side else 0)
			if i >= 0:
				if side:
					enemies.tm[i] = 0.4
				_log_spawn(kid, pos.x, pos.y, &"ring_side" if side else &"ring_top")
	# 마커 (S 그룹, E 정예). 유예 중 창에 들어온 S 는 유예가 끝나면 y<=200 까지 한 번 발사한다(가장 위 마커 우선).
	var in_grace: bool = t < spawner.grace_until
	var best_m: Dictionary = {}
	var best_p: WorldStrip.Placed = null
	var best_sy: float = 1e9
	for p in strip.placed:
		var top: float = p.origin_y + strip.scroll
		if top > 200.0 or top + p.height_px < -64.0:
			continue
		for m in p.markers:
			if m["fired"]:
				continue
			var ch: String = m["ch"]
			if ch != "S" and ch != "E":
				continue
			var sy: float = float(m["wy"]) + strip.scroll
			if ch == "S":
				if sy >= -32.0 and sy <= 128.0:
					m["seen"] = true
				if not in_grace and m.get("seen", false) and sy <= 232.0 and sy < best_sy:
					best_sy = sy
					best_m = m
					best_p = p
			elif not in_grace and sy >= -16.0:
				m["fired"] = true
				var i: int = add_enemy(EnemyPool.T_EL, float(m["x"]), sy)
				if i >= 0:
					_log_spawn(&"EL", float(m["x"]), sy, &"marker")
	if best_p != null and marker_gap <= 0.0 and alive < bal.defer_alive:
		best_m["fired"] = true
		marker_gap = 0.8
		_spawn_group(best_p, float(best_m["x"]), best_sy)

func _spawn_group(p: WorldStrip.Placed, ax: float, ay: float) -> void:
	var count: int = p.def.spawn_budget
	var kid: StringName = spawner.pick_kind()
	if p.slot == 0:
		count = 3
		kid = &"A1"
	elif p.slot == 3:
		kid = &"B1"
		count = bal.shooter_group_size
	var ti: int = _type_of(kid)
	for k in count:
		var pos: Vector2 = spawner.group_pos(strip, ax, ay, Vector2(px, py))
		var i: int = add_enemy(ti, pos.x, pos.y)
		if i >= 0:
			_log_spawn(kid, pos.x, pos.y, &"marker")

func _log_spawn(kid: StringName, x: float, y: float, source: StringName) -> void:
	if spawn_log_enabled:
		spawn_log.append({"t": t, "x": x, "y": y, "kind": kid, "source": source, "px": px, "py": py, "bits": strip.bits_screen(x, y)})

# ----------------------------------------------------------------------
# 데미지 / 처치
# ----------------------------------------------------------------------

func request_shake(v: Vector2) -> void:
	if bal.shake_enabled and v.x >= shake_amp * 0.5:
		shake_amp = v.x
		shake_left = v.y

## 플레이어 피해. ignore_invuln: 위험 바닥·끼임. quiet: 연출 없음.
## killer_kind: 출처 세분화 키(예: "A1", "boss", "bullet"). 비면 cause 만 기록한다.
func hurt(amount: float, cause: StringName, ignore_invuln: bool = false, quiet: bool = false, killer_kind: StringName = &"") -> void:
	if ended or god_mode:
		return
	if invuln_left > 0.0 and not ignore_invuln:
		return
	var reduce: float = passive_val(&"P01")
	var dmg: float = amount * (1.0 - reduce)
	hp -= dmg
	last_hit_cause = cause
	last_killer_kind = killer_kind if killer_kind != &"" else cause
	if cause != &"hazard" and cause != &"crush":
		invuln_left = bal.hit_invuln + (bal.sword_invuln_bonus if class_id == &"sword" else 0.0)
	if not quiet and cause != &"hazard":
		clock.hitstop(bal.hs_player_hit)
		request_shake(bal.shake_player_hit)
	if not first_hit_hint:
		first_hit_hint = true
		hint.emit("hint.slow")
	player_hurt.emit(dmg, cause)
	if hp <= 0.0:
		hp = 0.0
		_end_run(false)

func heal(amount: float) -> void:
	hp = minf(hp + amount, max_hp)

func damage_enemy(i: int, dmg: float, src: int) -> void:
	if enemies.hp[i] <= 0.0 or enemies.st[i] == EnemyPool.ST_EMERGE:
		return
	var d: float = dmg * damage_mult()
	if enemies.type[i] == EnemyPool.T_BOSS:
		d = EnemyAI.boss_damage_filter(self, i, d)
		if d <= 0.0:
			return
	enemies.hp[i] -= d
	enemies.flash[i] = 0.08
	if enemies.type[i] == EnemyPool.T_EL:
		clock.hitstop(bal.hs_elite_hit)
	dmg_by_src[src] += d
	if enemies.hp[i] <= 0.0:
		_kill(i, src)

func knock(i: int, dx: float, dy: float, dist: float) -> void:
	var tp: int = enemies.type[i]
	if tp == EnemyPool.T_BOSS:
		return
	var f: float = dist * 12.0
	if tp == EnemyPool.T_EL:
		f *= 1.0 - float(Defs.ENEMIES[&"EL"]["kb_resist"])
	var l: float = sqrt(dx * dx + dy * dy)
	if l < 0.001:
		return
	enemies.kx[i] += dx / l * f
	enemies.ky[i] += dy / l * f

func _kill(i: int, src: int) -> void:
	kills += 1
	var tp: int = enemies.type[i]
	if tp == EnemyPool.T_BOSS:
		clock.hitstop(bal.hs_boss_kill)
		request_shake(bal.shake_boss_kill)
		_clear_enemies()
		enemies.hp[i] = 0.0
		_end_run(true)
		return
	_add_gem(enemies.x[i], enemies.y[i], enemies.xpv[i])
	if tp == EnemyPool.T_EL:
		clock.hitstop(bal.hs_elite_kill)
		request_shake(bal.shake_elite_kill)
		elite_recover = 1.0
		heal(max_hp * bal.elite_heal_drop)
		_on_elite_chest()
		log_event.emit("elite_kill", {"t": t})

func _on_elite_chest() -> void:
	for wid in Defs.EVOLUTIONS.keys():
		if offer_state.evolved.has(wid) or not offer_state.weapons.has(wid):
			continue
		if int(offer_state.weapons[wid]) < bal.evolve_min_level:
			continue
		if offer_state.passives.has(Defs.EVOLUTIONS[wid]["passive"]):
			evolve_queue.append([wid, bal.evolve_delay])
			return

func _update_evolve(wdt: float) -> void:
	var i: int = 0
	while i < evolve_queue.size():
		evolve_queue[i][1] = float(evolve_queue[i][1]) - wdt
		if float(evolve_queue[i][1]) <= 0.0:
			var wid: StringName = evolve_queue[i][0]
			offer_state.evolved[wid] = true
			evolve_queue.remove_at(i)
			evolved.emit(wid, Defs.EVOLUTIONS[wid]["result"])
			log_event.emit("evolve", {"weapon": String(wid), "t": t})
		else:
			i += 1

func _reap() -> void:
	var i: int = 0
	while i < enemies.n:
		if enemies.hp[i] <= 0.0:
			enemies.remove(i)
		else:
			i += 1

# ----------------------------------------------------------------------
# 적 탄 / 접촉 / 위험 바닥
# ----------------------------------------------------------------------

func fire_enemy_bullet(x: float, y: float, dirx: float, diry: float, speed: float, dmg: float) -> void:
	ebul.add(x, y, dirx * speed, diry * speed, dmg, 8.0)

func _update_enemy_bullets(dt: float) -> void:
	var i: int = 0
	var pr: float = bal.player_radius + 2.0
	while i < ebul.n:
		var nx: float = ebul.x[i] + ebul.vx[i] * dt
		var ny: float = ebul.y[i] + ebul.vy[i] * dt
		ebul.x[i] = nx
		ebul.y[i] = ny
		ebul.life[i] -= dt
		var dead: bool = ebul.life[i] <= 0.0 or nx < 0.0 or nx > 216.0 or ny < -40.0 or ny > 420.0
		if not dead:
			var b: int = strip.bits_screen(nx, ny)
			if b & SOLID:
				dead = true
				if b & ChunkDef.BIT_COVER and not cover_hint:
					cover_hint = true
					hint.emit("hint.cover")
		if not dead and invuln_left <= 0.0:
			var dx: float = nx - px
			var dy: float = ny - py
			if dx * dx + dy * dy <= pr * pr:
				hurt(ebul.dmg[i], &"projectile", false, false, &"bullet")
				dead = true
		if dead:
			ebul.remove(i)
		else:
			i += 1

func _contacts() -> void:
	if invuln_left > 0.0 or ended:
		return
	var pr: float = bal.player_radius
	for i in enemies.n:
		if enemies.hp[i] <= 0.0 or enemies.st[i] == EnemyPool.ST_EMERGE:
			continue
		var k: int = enemies.kind[i]
		if k == Defs.K_SHOOTER:
			continue
		var rr: float = enemies.rad[i] + pr - 1.0
		var dx: float = enemies.x[i] - px
		var dy: float = enemies.y[i] - py
		if dx * dx + dy * dy <= rr * rr:
			var dmg: float = enemies.atk[i]
			if k == Defs.K_BOSS:
				dmg = bal.b1_contact_dmg
			hurt(dmg, &"contact", false, false, EnemyPool.TYPE_IDS[enemies.type[i]])
			if k == Defs.K_EXPLODER and enemies.st[i] == 0:
				enemies.st[i] = 1
				enemies.tm[i] = 0.0
			return

func _hazards(wdt: float) -> void:
	var tick: float = bal.hazard_tick
	# 플레이어
	if strip.bits_screen(px, py) & ChunkDef.BIT_HAZARD:
		if haz_acc == 0.0 and not _ever_hazard_hint():
			hint.emit("hint.hazard")
		haz_acc += wdt
		while haz_acc >= tick - 0.0001:
			haz_acc -= tick
			hurt(bal.hazard_player_tick, &"hazard", true, true)
			if ended:
				return
		if haz_acc < 0.0:
			haz_acc = 0.0
	else:
		haz_acc = 0.0
	# 적
	for i in enemies.n:
		if enemies.hp[i] <= 0.0:
			continue
		var tp: int = enemies.type[i]
		if tp == EnemyPool.T_BOSS:
			continue
		if strip.bits_screen(enemies.x[i], enemies.y[i]) & ChunkDef.BIT_HAZARD:
			enemies.hacc[i] += wdt
			while enemies.hacc[i] >= tick - 0.0001:
				enemies.hacc[i] -= tick
				var v: float = bal.hazard_elite_tick if tp == EnemyPool.T_EL else bal.hazard_enemy_tick
				enemies.hp[i] -= v
				enemies.flash[i] = 0.05
				dmg_by_src[SRC_HAZARD] += v
				if enemies.hp[i] <= 0.0:
					_kill(i, SRC_HAZARD)
					break
		else:
			enemies.hacc[i] = 0.0

var _haz_hint_done: bool = false
func _ever_hazard_hint() -> bool:
	var was: bool = _haz_hint_done
	_haz_hint_done = true
	return was

# ----------------------------------------------------------------------
# 보석 / 경험치
# ----------------------------------------------------------------------

func _add_gem(x: float, y: float, v: int) -> void:
	if v <= 0:
		return
	if gn >= GEM_CAP:
		gv[0] += v      # 가득 차면 가장 오래된 보석에 합친다
		return
	gx[gn] = x; gy[gn] = y; gv[gn] = v; gs[gn] = 0
	gn += 1

func _update_gems(dt: float) -> void:
	var mag: float = magnet_radius()
	var m2: float = mag * mag
	var i: int = 0
	while i < gn:
		var dx: float = px - gx[i]
		var dy: float = py - gy[i]
		var d2: float = dx * dx + dy * dy
		if gs[i] == 0 and d2 <= m2:
			gs[i] = 1
		var take: bool = false
		if gs[i] == 1:
			var d: float = sqrt(d2)
			if d < 7.0:
				take = true
			else:
				var sp: float = 200.0 * dt
				gx[i] += dx / d * minf(sp, d)
				gy[i] += dy / d * minf(sp, d)
		elif d2 < 49.0:
			take = true
		if take:
			xp += gv[i]
			gn -= 1
			gx[i] = gx[gn]; gy[i] = gy[gn]; gv[i] = gv[gn]; gs[i] = gs[gn]
		elif gy[i] > 420.0:
			gn -= 1
			gx[i] = gx[gn]; gy[i] = gy[gn]; gv[i] = gv[gn]; gs[i] = gs[gn]
		else:
			i += 1
	# 광장 회복 샘
	if phase == Phase.PLAZA and not heal_used and strip.plaza != null:
		for m in strip.plaza.markers:
			if m["ch"] == "R":
				var rx: float = float(m["x"]) - px
				var ry: float = float(m["wy"]) + strip.scroll - py
				if rx * rx + ry * ry < 18.0 * 18.0:
					heal_used = true
					heal(max_hp * bal.plaza_heal_ratio)
					break

func _check_levelup() -> void:
	while xp >= xp_need:
		xp -= xp_need
		level += 1
		levelups += 1
		pending_levels += 1
		xp_need = _need_for(level)
	if (pending_levels > 0 or pending_free > 0) and not awaiting_pick:
		_try_offer()

# ----------------------------------------------------------------------
# 3택
# ----------------------------------------------------------------------

func _try_offer() -> void:
	if awaiting_pick or ended:
		return
	if pending_levels > 0:
		pending_levels -= 1
		offer_source = &"levelup"
	elif pending_free > 0:
		pending_free -= 1
		offer_source = &"plaza"
	else:
		return
	rerolls_left = bal.free_rerolls + int(meta.stat(&"reroll"))
	var bias: Dictionary = Defs.CLASSES[class_id]["bias"]
	current_offer = OfferGenerator.generate(offer_state, bias, rng_offer)
	awaiting_pick = true
	log_event.emit("offer", {"t": t, "src": String(offer_source)})
	offer_ready.emit(current_offer, rerolls_left, offer_source)

func reroll() -> bool:
	if not awaiting_pick or rerolls_left <= 0:
		return false
	rerolls_left -= 1
	var ex: Array = []
	for c in current_offer:
		ex.append(c["id"])
	var bias: Dictionary = Defs.CLASSES[class_id]["bias"]
	current_offer = OfferGenerator.generate(offer_state, bias, rng_offer, ex)
	log_event.emit("reroll", {"t": t})
	offer_ready.emit(current_offer, rerolls_left, offer_source)
	return true

func pick(index: int) -> bool:
	if not awaiting_pick or index < 0 or index >= current_offer.size():
		return false
	var card: Dictionary = current_offer[index]
	OfferGenerator.commit(offer_state, current_offer)
	_apply_card(card)
	picks.append(card["id"])
	log_event.emit("pick", {"id": String(card["id"]), "lv": int(card["level"]), "t": t})
	awaiting_pick = false
	current_offer = []
	if offer_source == &"plaza":
		plaza_exit_ready = true
		hint.emit("hint.exit")
	if pending_levels > 0 or pending_free > 0:
		_try_offer()
	return true

## 디버그 API (P3 C7·UA 질문 1). 릴리스 빌드에서는 호출하지 않는다(호출부는 OS.is_debug_build() 가드).
## 무기 레벨을 직접 설정한다. lv 0 이면 제거. 성공 여부를 돌려준다.
func debug_set_weapon(id: StringName, lv: int) -> bool:
	if not Defs.is_weapon(id):
		return false
	lv = clampi(lv, 0, Defs.MAX_LEVEL)
	if lv == 0:
		offer_state.weapons.erase(id)
		weapon_order.erase(id)
		wcd.erase(id)
		return true
	if not offer_state.weapons.has(id):
		wcd[id] = 0.3
		weapon_order.append(id)
	offer_state.weapons[id] = lv
	return true

## 패시브를 n 레벨 올린다(카드 적용과 같은 경로). 성공 여부를 돌려준다.
func debug_give_passive(id: StringName, levels: int = 1) -> bool:
	if not Defs.is_passive(id):
		return false
	for _i in range(maxi(levels, 0)):
		_apply_card({"id": id, "kind": &"passive", "level": 1})
	return true

## 정예 상자 연출 없이 진화 큐를 즉시 검사한다(짝 패시브 조건 그대로). 큐에 넣었는지 돌려준다.
func debug_trigger_chest() -> bool:
	var before: int = evolve_queue.size()
	_on_elite_chest()
	return evolve_queue.size() > before

## 레벨업 3택을 즉시 연다(C3 CAP-04 정지 조건 보조). 3택이 열렸는지 돌려준다.
func debug_force_offer() -> bool:
	pending_levels += 1
	_try_offer()
	return awaiting_pick

func _apply_card(card: Dictionary) -> void:
	var id: StringName = card["id"]
	match card["kind"]:
		&"weapon":
			var lv: int = int(offer_state.weapons.get(id, 0)) + 1
			offer_state.weapons[id] = mini(lv, Defs.MAX_LEVEL)
			if lv == 1:
				wcd[id] = 0.3
				weapon_order.append(id)
		&"passive":
			var lp: int = int(offer_state.passives.get(id, 0)) + 1
			offer_state.passives[id] = mini(lp, Defs.MAX_LEVEL)
			if id == &"P04":
				var old: float = max_hp
				max_hp = bal.max_hp * (1.0 + meta.stat(&"max_hp_mult") + passive_val(&"P04"))
				hp += max_hp - old
		_:
			match id:
				&"heal": heal(max_hp * 0.3)
				&"coin": coins += 10
				&"xp": xp += 6

# ----------------------------------------------------------------------
# 종료
# ----------------------------------------------------------------------

func _end_run(win: bool) -> void:
	if ended:
		return
	ended = true
	cleared = win
	var zone: StringName = zone_name()
	phase = Phase.ENDED
	var result: Dictionary = {
		"cleared": win, "boss_reached": boss_reached, "duration": run_time, "world_time": t,
		"death_cause": &"" if win else last_hit_cause, "death_zone": zone,
		"killer_kind": &"" if win else last_killer_kind,
		"level": level, "levelups": levelups, "kills": kills, "seed": seed_value,
		"class": class_id, "pick_log": picks.duplicate(), "top_items": top_items(3),
	}
	# P3 이벤트 정본 중 P0 필수 (run_death, run_end)
	if not win:
		log_event.emit("run_death", {"cause": String(last_hit_cause), "killer": String(last_killer_kind),
			"zone": String(zone), "t": t})
	log_event.emit("run_end", {"cleared": win, "zone": String(zone), "duration_s": snappedf(run_time, 0.01), "t": t})
	run_ended.emit(result)

const SRC_NAMES: Array[String] = ["w.w01", "w.w02", "w.w03", "w.w04", "e.w01", "e.w02", "src.hazard", "src.other"]

## 결과 롤업용: 피해량 상위 항목 n 개 [{key, value}]
func top_items(n: int) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for i in dmg_by_src.size():
		if dmg_by_src[i] > 0.0:
			items.append({"key": SRC_NAMES[i], "value": int(dmg_by_src[i])})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["value"]) > int(b["value"]))
	var out: Array[Dictionary] = []
	for k in mini(n, items.size()):
		out.append(items[k])
	return out
