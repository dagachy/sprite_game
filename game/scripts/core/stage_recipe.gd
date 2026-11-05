class_name StageRecipe extends RefCounted
## 단축판 구성(level §4.2). 슬롯 선택은 시드 RNG 로 슬롯 순서대로 1회씩 뽑는다(스폰 RNG 와 분리).

const SLOTS: Array = [
	["open_01"],
	["open_02", "hazard_01"],
	["choke_02", "hazard_01", "open_02"],
	["cover_01"],
	["choke_01"],
	["cover_02", "hazard_02", "open_02"],
]
const PLAZA := &"plaza_01"
const ENTRY := &"boss_entry"
const ARENA := &"boss_arena"
const FALLBACK := &"open_02"

## fixed_early: 판 1~3 슬롯 고정(슬롯 1 open_02, 슬롯 2 hazard_01) - p4 결정 5
static func pick_slots(seed_value: int, fixed_early: bool = false) -> Array[StringName]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: Array[StringName] = []
	var last_hazard: bool = false
	for s in SLOTS.size():
		var cands: Array = SLOTS[s]
		var roll: int = rng.randi_range(0, cands.size() - 1)   # 항상 1회 소비(고정 슬롯 포함)
		var chosen: StringName = &""
		if fixed_early and s == 1:
			chosen = &"open_02"
		elif fixed_early and s == 2:
			chosen = &"hazard_01"
		else:
			var ok: Array[StringName] = []
			for c in cands:
				var sc := StringName(c)
				if out.has(sc):
					continue
				if String(sc).begins_with("hazard") and last_hazard:
					continue
				ok.append(sc)
			if ok.is_empty():
				chosen = FALLBACK if not out.has(FALLBACK) else StringName(cands[0])
			else:
				chosen = ok[roll % ok.size()]
		out.append(chosen)
		last_hazard = String(chosen).begins_with("hazard")
	return out

static func full_chain(seed_value: int, fixed_early: bool = false) -> Array[StringName]:
	var ids: Array[StringName] = pick_slots(seed_value, fixed_early)
	ids.append(PLAZA)
	ids.append(ENTRY)
	ids.append(ARENA)
	return ids
