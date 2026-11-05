extends SceneTree
## CAP-01~06 도달 시점 실측(측정 전용). 밸런스·프리셋 값은 바꾸지 않는다.
## 실행: godot --headless --path game --script res://tools/cap_reach.gd
## 각 프리셋을 시드대로 새 Battle 로 만들고 STEP 단위로 진행하며, 다음 시점의 월드 시간 t 를 기록한다.
##  - slot_on_screen[k]: 슬롯 k 청크가 화면(0~384) 과 처음 겹친 t
##  - hazard+cover 동시 가시(CAP-02 근사): 슬롯 1·2 중 hazard 와 슬롯 3 cover 가 함께 보인 첫 t
##  - boss_tele: 보스 예고(boss_tele_kind != 0) 첫 t, phase 가 APPROACH 가 된 첫 t
##  - 사망·종료 t 와 원인. god 프리셋은 무적으로 진행한다.

const STEP: float = 1.0 / 60.0
const MAX_STEPS: int = 60 * 600   # 10분 상한(보스 도달 측정용)

var _frame: int = 0
var _done: bool = false

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 2:
		return false   # autoload 초기화 후에 로드한다
	if _done:
		return false
	_done = true
	var bal: Balance = Balance.load_default()
	var db: Dictionary = ChunkDb.load_all()
	var lines: PackedStringArray = []
	var presets: Array = CapturePresets.ids()
	for id in presets:
		lines.append(_measure(id, bal, db))
	# 검증: 프리셋 advance() 경로로 실제 정지 상태를 확인한다
	lines.append("--- advance() check ---")
	for id in presets:
		var b: Battle = CapturePresets.make_battle(id, bal, db, MetaState.new())
		var n: int = CapturePresets.advance(b, id)
		var vis: Dictionary = _visible_slots(b)
		var names: PackedStringArray = []
		for k in vis:
			names.append(_slot_id(b, k))
		lines.append("%s steps=%d t=%.2f ended=%s awaiting_pick=%s tele=%d visible=[%s]" % [
			String(id), n, b.t, str(b.ended), str(b.awaiting_pick), b.boss_tele_kind, ", ".join(names)])
	var text: String = "\n".join(lines)
	print(text)
	var f := FileAccess.open("user://cap_reach.txt", FileAccess.WRITE)
	if f != null:
		f.store_string(text + "\n")
	quit(0)
	return false

func _measure(id: StringName, bal: Balance, db: Dictionary) -> String:
	var p: Dictionary = CapturePresets.PRESETS[id]
	var b: Battle = CapturePresets.make_battle(id, bal, db, MetaState.new())
	var slot_t: Dictionary = {}     # slot index -> first t
	var both_t: float = -1.0        # hazard(1|2) + cover(3) 동시 가시
	var approach_t: float = -1.0
	var tele_t: float = -1.0
	var n: int = 0
	var s_now: int = 0
	var death_t: float = -1.0
	while n < MAX_STEPS and not b.ended:
		if b.awaiting_pick:
			b.pick(0)   # 측정용: 3택은 첫 카드로 넘긴다(결정성: 항상 같은 선택)
		b.step(STEP)
		n += 1
		var vis: Dictionary = _visible_slots(b)
		for k in vis:
			if not slot_t.has(k):
				slot_t[k] = b.t
		if both_t < 0.0 and vis.has(3) and (vis.has(1) or vis.has(2)):
			# 슬롯 1·2 중 hazard_01 이 있는지 확인
			for k in [1, 2]:
				if vis.has(k) and _slot_id(b, k) == "hazard_01":
					both_t = b.t
		if approach_t < 0.0 and b.phase == Battle.Phase.APPROACH:
			approach_t = b.t
		if tele_t < 0.0 and b.boss_tele_kind != 0:
			tele_t = b.t
		s_now = n
		if n % 1800 == 0 and String(id) == "CAP-01":
			print("  trace t=%.1f scroll=%.1f alive=%d speed=%.2f phase=%d px=%.1f py=%.1f hp=%.1f" % [
				b.t, b.strip.scroll, b.enemies.alive_count(), b.scroll_model.speed_now, b.phase, b.px, b.py, b.hp])
	if b.ended:
		death_t = b.t
	var ids: String = ""
	for pl in b.strip.placed:
		ids += "%s " % String(pl.def.id)
	var parts: PackedStringArray = []
	for k in [0, 1, 2, 3, 4, 5]:
		parts.append("s%d=%s" % [k, _fmt(slot_t.get(k, -1.0))])
	return "%s seed=%d god=%s chain=[%s]\n  %s\n  hazard+cover_visible=%s approach=%s boss_tele=%s end_t=%s ended=%s steps=%d" % [
		String(id), int(p["seed"]), str(bool(p.get("god", false))), ids.strip_edges(),
		" ".join(parts), _fmt(both_t), _fmt(approach_t), _fmt(tele_t), _fmt(death_t if b.ended else -1.0), str(b.ended), s_now]

## 화면과 겹치는 청크의 slot 인덱스 집합
func _visible_slots(b: Battle) -> Dictionary:
	var out: Dictionary = {}
	for pl in b.strip.placed:
		var top: float = pl.origin_y + b.strip.scroll
		var bottom: float = top + pl.height_px
		if bottom > 0.0 and top < 384.0:
			out[pl.slot] = true
	return out

func _slot_id(b: Battle, k: int) -> String:
	for pl in b.strip.placed:
		if pl.slot == k:
			return String(pl.def.id)
	return ""

func _fmt(v: float) -> String:
	return "%.2f" % v if v >= 0.0 else "-"
