class_name CapturePresets extends RefCounted
## 시드 프리셋 CAP-01~06 (P3 C3, user-acquisition-marketer §5). 디버그 빌드 전용.
## 호출부는 OS.is_debug_build() 가드 안에서 load() 로만 만든다. 이 폴더는 릴리스 export 에서 제외된다(AC-43).
## 결정성: Battle 을 프리셋 시드로 새로 만들고, 시간은 battle.step(STEP) 직접 호출로만 진행한다(D1·D2).
## 주의: forward_steps 와 slots 값은 [추정] 기본값이다. 청크 도달 시점은 실측 전까지 확정하지 않는다.

const STEP: float = 1.0 / 60.0
## 상한. 원래 600(10초)이었으나 CAP-06 보스 예고에 닿으려고 올렸다.
## 단위 주의: step 1회당 월드 시간 t 는 0.5s 증가한다(실측 12000 step = t 100.0s). forward_steps 는 step 수다.
## 실측: game/tools/cap_reach.gd (시드 12345, 무적 on, 3택 자동 첫 카드). 보스 예고 t=200.55 → 약 24066 step.
const MAX_STEPS: int = 60 * 420
## 진화 확정 대기 상한(step). 진화 지연 1.5s 를 실시간 dt 로 넘기는 데 충분한 값이다.
const EVOLVE_WAIT_MAX: int = 60 * 5
const MATCH_WEAPON := &"W01"
const MATCH_PASSIVE := &"P01"
## spawn_count 보충용 적 종류(고정).
const SUPPLEMENT_KIND := &"A1"

## 프리셋 데이터. 키는 §5.1 스키마를 따른다.
const PRESETS: Dictionary = {
	# forward_steps 실측(시드 12345, 무적 on, 입력 없음, 단위 step): cover_01 화면 진입 t=48.81s ≈ 5858 step,
	# hazard_01 진입 t=24.61s, choke_01 진입 t=72.84s ≈ 8741 step. 무적 off 는 t=23.0s 에 사망해 도달 전에 끝난다.
	&"CAP-01": {"label": "엄폐 방어", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": 5870, "god": true, "weapon": {}, "passives": {}, "pause_after": true,
		"note": "cover_01 화면 진입 시점(실측). 적 탄 부채가 엄폐물에 막히는지는 미확인 [추정]"},
	&"CAP-02": {"label": "지형 3종", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": 5870, "god": true, "weapon": {}, "passives": {}, "pause_after": true,
		"overrides": {"hazard_highlight": true},
		"note": "hazard_01 과 cover_01 이 함께 보이는 시점(실측 t=48.81s). 벽 존재 확인 미완. 위험 바닥 강조는 렌더 오버라이드 미구현 [추정]"},
	&"CAP-03": {"label": "병목 처치", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": 8760, "god": true, "weapon": {}, "passives": {}, "pause_after": true,
		"overrides": {"spawn_count": 12},
		"note": "choke_01 화면 진입 시점(실측 t=72.84s). 화면 내 12마리 이상(하한 보장)"},
	&"CAP-04": {"label": "3택 직전", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": MAX_STEPS, "god": false,
		"weapon": {MATCH_WEAPON: 4}, "passives": {MATCH_PASSIVE: 1}, "pause_after": true,
		"stop_on": "offer"},
	&"CAP-05": {"label": "진화", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": 0, "god": false, "weapon": {MATCH_WEAPON: 4}, "passives": {MATCH_PASSIVE: 1},
		"pause_after": true, "overrides": {"force_evolve": true},
		"note": "debug_trigger_chest 로 진화 큐를 넣고 확정까지 진행. 진화 결과 연출(E01 이펙트)은 렌더 확인 전 [추정]"},
	&"CAP-06": {"label": "보스 예고 직전", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": 24000, "god": true, "weapon": {}, "passives": {}, "pause_after": true,
		"note": "보스 예고(boss_tele_kind≠0) 첫 프레임 실측 t=200.55s ≈ 24066 step. 24000 step(t=200.0s)에서 정지. 알파 이월 가능"},
}

## 프리셋 ID 목록(정렬). 메뉴 버튼 순서에 쓴다.
static func ids() -> Array[StringName]:
	var keys: Array[String] = []
	for k in PRESETS.keys():
		keys.append(String(k))
	keys.sort()   # StringName 은 사전순 정렬이 아니므로 String 으로 정렬한다
	var out: Array[StringName] = []
	for k in keys:
		out.append(StringName(k))
	return out

## 프리셋으로 Battle 을 만든다. 무기·패시브 오버라이드를 적용한다(D1·D5).
## meta 는 프리셋 고정 값을 넣는다(D5). 저장 파일을 읽지 않는다.
static func make_battle(id: StringName, bal: Balance, db: Dictionary, meta: MetaState) -> Battle:
	var p: Dictionary = PRESETS[id]
	var b := Battle.new(bal, int(p["seed"]), p["class_id"], meta, bool(p["early_run"]), db)
	b.god_mode = bool(p.get("god", false))
	var weapons: Dictionary = p.get("weapon", {})
	for wid in weapons:
		b.debug_set_weapon(wid, int(weapons[wid]))
	var passives: Dictionary = p.get("passives", {})
	for pid in passives:
		b.debug_give_passive(pid, int(passives[pid]))
	return b

## 프리셋의 정지 조건까지 시간을 진행한다. 실제로 진행한 STEP 수를 돌려준다(D2).
## stop_on == "offer" 면 3택이 열리는 순간에 멈춘다. 그 밖에는 forward_steps 만큼 진행한다.
## 로직은 advance_chunk 하나뿐이다. 동기 호출은 청크 크기를 무한으로 반복 호출한다.
static func advance(b: Battle, id: StringName) -> int:
	var state: Dictionary = {}
	while not advance_chunk(b, id, state, MAX_STEPS):
		pass
	return int(state["n"])

## 청크 단위 진행. 한 번에 최대 max_steps 만큼 step 하고 완료되면 true 를 돌려준다.
## state 는 호출자가 빈 Dictionary 로 시작해 같은 객체를 계속 넘긴다. state["n"] 은 지금까지 진행한 step 수다.
## 결정성: delta 를 쓰지 않고(STEP 고정), 정지 판정은 전투 상태만 보며, 청크 사이에 외부 입력을 넣지 않는다.
## 후처리(3택 강제, 진화, spawn_count 보충)는 step 루프가 끝난 뒤 한 번 같은 호출 안에서 수행한다.
static func advance_chunk(b: Battle, id: StringName, state: Dictionary, max_steps: int) -> bool:
	if state.get("done", false):
		return true
	var p: Dictionary = PRESETS[id]
	var limit: int = mini(int(p.get("forward_steps", 0)), MAX_STEPS)
	var stop_offer: bool = p.get("stop_on", "") == "offer"
	var n: int = int(state.get("n", 0))
	var budget: int = maxi(max_steps, 1)
	while n < limit:
		if stop_offer and b.awaiting_pick:
			break
		if b.ended:
			break
		if budget <= 0:
			state["n"] = n
			return false
		# 3택이 열려 있으면 시간이 멈춘다. 정지 조건이 3택이 아니면 첫 카드로 넘겨 시간을 계속 진행한다(결정성).
		if b.awaiting_pick:
			b.pick(0)
		b.step(STEP)
		n += 1
		budget -= 1
	# [추정] 상한까지 3택이 자연히 열리지 않으면 레벨업 3택을 강제로 연다.
	# 무기 Lv4 를 시드 전투로 만들려면 XP 가 필요해 10초 안에 열리지 않는다.
	if stop_offer and not b.awaiting_pick and not b.ended:
		b.debug_force_offer()
	var ov: Dictionary = p.get("overrides", {})
	# force_evolve: 정예 상자 연출 없이 진화 큐를 넣고, 진화가 확정될 때까지 step 을 진행한다(결정성 유지).
	if bool(ov.get("force_evolve", false)):
		if not b.debug_trigger_chest():
			push_warning("CapturePresets: debug_trigger_chest() 실패, 진화 큐가 비어 있을 수 있다 (%s)" % String(id))
		var guard: int = 0
		while not b.evolve_queue.is_empty() and not b.ended and guard < EVOLVE_WAIT_MAX:
			b.step(STEP)
			n += 1
			guard += 1
	if ov.has("spawn_count"):
		_top_up_enemies(b, int(ov["spawn_count"]))
	state["n"] = n
	state["done"] = true
	return true

## 화면 안 적이 target 마리가 되도록 add_enemy 로 보충한다. 마지막 step 뒤 한 번만 호출한다.
## 종류는 SUPPLEMENT_KIND 고정, 좌표는 spawner.group_pos(앵커 = choke_01 의 S 마커). 화면 밖 적은 세지 않는다.
static func _top_up_enemies(b: Battle, target: int) -> void:
	var anchor: Vector2 = _choke_anchor(b)
	if anchor.x < 0.0:
		push_warning("CapturePresets: choke_01 앵커를 찾지 못해 spawn_count 보충을 건너뛴다")
		return
	var ti: int = EnemyPool.TYPE_IDS.find(SUPPLEMENT_KIND)
	var need: int = target - _on_screen_count(b)
	var player := Vector2(b.px, b.py)
	var guard: int = 0
	while need > 0 and guard < target * 4:
		guard += 1
		var pos: Vector2 = b.spawner.group_pos(b.strip, anchor.x, anchor.y, player)
		if b.add_enemy(ti, pos.x, pos.y) < 0:
			break
		need = target - _on_screen_count(b)

static func _on_screen_count(b: Battle) -> int:
	var c: int = 0
	for i in b.enemies.n:
		if b.enemies.hp[i] > 0.0 and b.enemies.x[i] >= 0.0 and b.enemies.x[i] < WorldStrip.WIDTH_PX \
				and b.enemies.y[i] >= 0.0 and b.enemies.y[i] < 384.0:
			c += 1
	return c

## choke_01 청크의 첫 S 마커 화면 좌표. 없으면 (-1, -1).
static func _choke_anchor(b: Battle) -> Vector2:
	for pl in b.strip.placed:
		if pl.def.id != &"choke_01":
			continue
		for m in pl.markers:
			if m["ch"] == "S":
				return Vector2(float(m["x"]), float(m["wy"]) + b.strip.scroll)
	return Vector2(-1.0, -1.0)

## 결정성 확인용 요약. 같은 프리셋이면 같은 값이어야 한다(수용 기준 1, 로그 대체).
static func state_digest(b: Battle) -> Dictionary:
	return {
		"t": snappedf(b.t, 0.0001),
		"enemies": b.enemies.n,
		"px": snappedf(b.px, 0.0001),
		"py": snappedf(b.py, 0.0001),
		"level": b.level,
		"awaiting_pick": b.awaiting_pick,
	}
